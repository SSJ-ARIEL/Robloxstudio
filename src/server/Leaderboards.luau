-- Global boards contain confirmed persisted progress only. The controller invokes
-- publish after a profile save succeeds; API failure never prevents joining a game.
local Leaderboards = {}
local METRICS = {
	{ Key = "Wins", Suffix = "GlobalWins_v2" },
	{ Key = "Streak", Suffix = "GlobalStreak_v2" },
	{ Key = "Level", Suffix = "GlobalLevel_v2" },
}

local function finiteInteger(value, maximum)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge or value < 0 then return nil end
	return math.min(maximum, math.floor(value))
end

local function copyRows(rows)
	local copy = {}
	for _, row in ipairs(rows) do table.insert(copy, table.clone(row)) end
	return copy
end

function Leaderboards.new(dependencies)
	local enabled = dependencies.Enabled == true
	local now = dependencies.Now or os.clock
	local warnFn = dependencies.Warn or warn
	local config = dependencies.Config or {}
	local refreshSeconds = config.LeaderboardRefreshSeconds or 60
	local writeSeconds = config.LeaderboardWriteSeconds or 60
	local maximum = config.MaxCoins or 100000000
	local stores, writes, names = {}, {}, {}
	local current = { Wins = {}, Streak = {}, Level = {}, Status = enabled and "Cargando clasificación global…" or "Disponible en servidores publicados." }
	local lastRefresh, refreshing = -math.huge, false
	local api = {}

	local function getStore(metric)
		if stores[metric.Key] then return stores[metric.Key] end
		local ok, value = pcall(function()
			return dependencies.DataStoreService:GetOrderedDataStore((config.DataStoreName or "ColorChaos_Player_v1") .. "_" .. metric.Suffix)
		end)
		if ok and value then stores[metric.Key] = value; return value end
		warnFn("[ColorChaos] No se pudo abrir la clasificación " .. metric.Key)
		return nil
	end

	local function nameFor(id)
		if names[id] then return names[id] end
		if dependencies.NameForUser then
			local ok, name = pcall(dependencies.NameForUser, id)
			if ok and type(name) == "string" and #name > 0 then names[id] = name; return name end
		end
		-- A failed lookup is not cached so subsequent refreshes can restore the name.
		return "Jugador " .. tostring(id)
	end

	function api.publish(player, data)
		if not enabled or type(data) ~= "table" or not player then return false end
		local id = finiteInteger(player.UserId, 9007199254740991)
		if not id or id <= 0 or player.UserId ~= id then return false end
		local progress = type(data.Progress) == "table" and data.Progress or {}
		local xp = finiteInteger(progress.XP, 100000000)
		local values = {
			Wins = data.Wins,
			Streak = data.BestStreak,
			Level = xp and math.min(1000, math.floor(xp / 100) + 1) or nil,
		}
		local anySuccess = false
		for _, metric in ipairs(METRICS) do
			local value = finiteInteger(values[metric.Key], maximum)
			if value then
				local key = tostring(id) .. ":" .. metric.Key
				local previous = writes[key]
				if not previous or (not previous.Busy and value > previous.Value and now() - previous.At >= writeSeconds) then
					local store = getStore(metric)
					if store then
						local marker = previous or { At = -math.huge, Value = -1 }
						marker.Busy = true
						writes[key] = marker
						local ok, confirmed = pcall(function()
							return store:UpdateAsync(tostring(id), function(persisted)
								return math.max(value, finiteInteger(persisted, 9007199254740991) or 0)
							end)
						end)
						marker.Busy = false
						local committed = finiteInteger(confirmed, maximum)
						if ok and committed and committed >= value then
							marker.Value, marker.At = committed, now()
							anySuccess = true
						else
							-- Failed attempts are throttled as well, but remain retryable.
							marker.At = now()
							warnFn("[ColorChaos] No se pudo actualizar la clasificación " .. metric.Key)
						end
					end
				end
			end
		end
		return anySuccess
	end

	function api.refresh()
		if not enabled or refreshing or now() - lastRefresh < refreshSeconds then return false end
		refreshing, lastRefresh = true, now()
		local successCount = 0
		for _, metric in ipairs(METRICS) do
			local store = getStore(metric)
			if store then
				local ok, entries = pcall(function() return store:GetSortedAsync(false, 10):GetCurrentPage() end)
				if ok and type(entries) == "table" then
					local rows, seen = {}, {}
					for _, entry in ipairs(entries) do
						local rawId = type(entry) == "table" and tonumber(entry.key) or nil
						local id = finiteInteger(rawId, 9007199254740991)
						local value = type(entry) == "table" and finiteInteger(entry.value, maximum) or nil
						if id and id > 0 and rawId == id and value and not seen[id] then
							seen[id] = true
							table.insert(rows, { UserId = id, Name = nameFor(id), Value = value })
							if #rows == 10 then break end
						end
					end
					current[metric.Key] = rows
					successCount += 1
				end
			end
		end
		refreshing = false
		current.Status = successCount == #METRICS and "Clasificación global" or "Clasificación temporalmente sin conexión."
		return successCount > 0
	end

	function api.snapshot()
		return {
			Wins = copyRows(current.Wins), Streak = copyRows(current.Streak), Level = copyRows(current.Level),
			Status = current.Status,
		}
	end

	return api
end

return Leaderboards
