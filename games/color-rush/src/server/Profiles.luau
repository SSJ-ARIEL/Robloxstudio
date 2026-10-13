-- Server-owned profiles. Paid grants and their receipt metadata commit atomically.
-- Studio uses session-only progress and never charges developer products.
local Profiles = {}

local function whole(value, cap)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return 0 end
	return math.min(math.floor(value), cap)
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

function Profiles.new(deps)
	local config = deps.Config
	local shared = not deps.Ledger and game:GetService("ReplicatedStorage"):WaitForChild("ColorRush") or nil
	local Ledger = deps.Ledger or require(shared.Ledger)
	local Progression = deps.Progression or require(shared.Progression)
	local tasks, now = deps.Tasks or task, deps.Clock or os.time
	local warnMessage = deps.Warn or warn
	local notify = deps.Notify or function() end
	local refresh = deps.Refresh or function() end
	local players = deps.Players
	local store = deps.DataStoreService:GetDataStore(config.DataStoreName or "ColorRush_v1")
	local maxCoins, maxCredits, maxReceipts = config.MaxCoins or 100000000, config.MaxReviveCredits or 1000, config.MaxReceipts or 10000
	local session = deps.HttpService:GenerateGUID(false)
	local savingEnabled = not deps.RunService:IsStudio()
	local records, loading = {}, {}
	local controller, closing, started = {}, false, false

	local function send(player, message) pcall(notify, player, message) end
	local function online(player) return players:GetPlayerByUserId(player.UserId) == player end
	local function clean(raw)
		raw = type(raw) == "table" and raw or {}
		local owned = { ["1"] = true }
		for index, trail in ipairs(config.Trails or {}) do
			if trail.Access ~= "VIP" and type(raw.OwnedTrails) == "table" and raw.OwnedTrails[tostring(index)] == true then owned[tostring(index)] = true end
		end
		local selected = whole(raw.SelectedTrail, #(config.Trails or {}))
		if selected < 1 then selected = 1 end
		local selectedConfig = (config.Trails or {})[selected]
		if not owned[tostring(selected)] and not (selectedConfig and selectedConfig.Access == "VIP") then selected = 1 end
		return { Coins = whole(raw.Coins, maxCoins), Wins = whole(raw.Wins, 100000000),
			SelectedTrail = selected, OwnedTrails = owned, ReviveCredits = whole(raw.ReviveCredits, maxCredits),
			AutoRevive = raw.AutoRevive == true, Receipts = Ledger.cleanReceipts(raw.Receipts),
			Progress = Progression.clean(raw.Progress, now(), config) }
	end

	local function snapshot(data)
		local result = clone(data)
		result.Progress = Progression.clean(data.Progress, now(), config)
		return result
	end

	local function envelope(data, release, token)
		local result = { Data = data, Session = session, LeaseUntil = now() + 240, Commit = token }
		if release then result.Session, result.LeaseUntil = nil, nil end
		return result
	end

	function controller.get(player) return records[player] end

	function controller.load(player)
		if records[player] then return records[player] end
		if closing or loading[player] then return nil end
		loading[player] = true
		local data, writable = clean(nil), false
		if savingEnabled then
			for attempt = 1, 3 do
				local token = deps.HttpService:GenerateGUID(false)
				local ok, committed = pcall(function()
					return store:UpdateAsync("Player_" .. player.UserId, function(old)
						if type(old) == "table" and old.Session and old.Session ~= session and (tonumber(old.LeaseUntil) or 0) > now() then return nil end
						local raw = type(old) == "table" and (old.Data or old) or nil
						-- Corrupted receipt histories are never overwritten or forgotten.
						if type(raw) == "table" and not Ledger.validReceipts(raw.Receipts) then return nil end
						return envelope(clean(raw), false, token)
					end)
				end)
				if ok and type(committed) == "table" and committed.Session == session and committed.Commit == token then
					data, writable = clean(committed.Data), true
					break
				end
				if attempt < 3 and online(player) and not closing then tasks.wait(attempt * 2) else break end
			end
		end
		local record = { Data = data, Writable = writable, Ready = true, Saving = false,
			Revision = 0, SavedRevision = 0, VIP = false, VIPKnown = false, LastSaveFailed = false }
		records[player], loading[player] = record, nil
		if not online(player) or closing then
			record.Leaving = true
			controller.save(player, true)
			records[player] = nil
			return nil
		end
		if savingEnabled and not writable then send(player, "No pudimos cargar el guardado. Esta sesión no conserva progreso ni permite compras.") end
		pcall(refresh, player)
		return record
	end

	function controller.save(player, release)
		local record = records[player]
		if not record or not record.Writable then return false end
		while record.Saving do tasks.wait(0.1) end
		if records[player] ~= record or not record.Writable then return false end
		record.Saving = true
		local base, revision, token = snapshot(record.Data), record.Revision, deps.HttpService:GenerateGUID(false)
		local lostLock = false
		local ok, committed = pcall(function()
			return store:UpdateAsync("Player_" .. player.UserId, function(old)
				lostLock = false
				if type(old) ~= "table" or old.Session ~= session then lostLock = true; return nil end
				local merged = Ledger.merge(base, old.Data, maxCoins, maxCredits)
				return merged and envelope(merged, release, token) or nil
			end)
		end)
		local recovered = ok and type(committed) == "table" and committed.Commit == token
			and Ledger.reconcile(record.Data, committed.Data, maxCoins, maxCredits) or nil
		if recovered then
			if recovered.Coins > 0 or recovered.Credits > 0 then record.Revision += 1 end
			record.PendingPaid, record.UncertainReceipt = nil, nil
			record.LastSaveFailed, record.SavedRevision = false, revision
			if release then record.Writable = false end
		else
			record.LastSaveFailed = true
			if lostLock then record.Writable = false end
			warnMessage("Color Rush: guardado no confirmado para " .. player.UserId)
			if not record.Leaving then send(player, "No se pudo confirmar el guardado. Estamos reintentando; las compras están pausadas.") end
		end
		record.Saving = false
		pcall(refresh, player)
		return recovered ~= nil
	end

	function controller.grantReceipt(player, receipt, product)
		local record = records[player]
		if not record or not record.Writable or record.Leaving then return false end
		while record.Saving do tasks.wait(0.1) end
		if records[player] ~= record or not record.Writable or record.Leaving then return false end
		if record.UncertainReceipt and record.UncertainReceipt ~= receipt.PurchaseId then return false end
		record.Saving = true
		local grant = { Coins = product.Coins or 0, Credits = product.Credits or 0 }
		record.PendingPaid = grant
		local base, token, lostLock, newlyGranted = snapshot(record.Data), deps.HttpService:GenerateGUID(false), false, false
		local ok, committed = pcall(function()
			return store:UpdateAsync("Player_" .. player.UserId, function(old)
				lostLock, newlyGranted = false, false
				if type(old) ~= "table" or old.Session ~= session then lostLock = true; return nil end
				local receipts = Ledger.cleanReceipts(type(old.Data) == "table" and old.Data.Receipts or nil)
				if not receipts[receipt.PurchaseId] then
					local count = 0
					for _ in pairs(receipts) do count += 1 end
					if count >= maxReceipts then return nil end
				end
				local updated, isNew = Ledger.grant(base, old.Data, receipt.PurchaseId, grant, maxCoins, maxCredits)
				newlyGranted = isNew == true
				return updated and envelope(updated, false, token) or nil
			end)
		end)
		local recovered = ok and type(committed) == "table" and committed.Commit == token
			and Ledger.reconcile(record.Data, committed.Data, maxCoins, maxCredits) or nil
		if recovered then
			record.Revision += 1
			record.LastSaveFailed, record.PendingPaid, record.UncertainReceipt = false, nil, nil
		else
			record.LastSaveFailed, record.UncertainReceipt = true, receipt.PurchaseId
			if lostLock then record.Writable = false end
		end
		record.Saving = false
		if not recovered then
			tasks.delay(2, function()
				if records[player] == record and record.Writable and not record.Leaving then controller.save(player, false) end
			end)
			return false
		end
		pcall(refresh, player)
		local message = ""
		if newlyGranted then
			message = grant.Credits > 0 and ("Compra guardada: +" .. grant.Credits .. " reentrada(s). Si terminó la partida, siguen disponibles.")
				or ("Compra entregada: +" .. grant.Coins .. " monedas.")
		end
		return true, message
	end

	function controller.public(player)
		local record = records[player]
		if not record then return nil end
		local view = Progression.view(record.Data.Progress, now(), config)
		return { Coins = record.Data.Coins, Wins = record.Data.Wins, Level = view.Level, XP = view.XP,
			SelectedTrail = record.Data.SelectedTrail, OwnedTrails = clone(record.Data.OwnedTrails),
			ReviveCredits = record.Data.ReviveCredits, VIP = record.VIP == true, AutoRevive = record.Data.AutoRevive == true }
	end

	function controller.progression(player)
		local record = records[player]
		return record and Progression.view(record.Data.Progress, now(), config) or nil
	end

	function controller.mutate(player, callback)
		local record = records[player]
		if not record or not record.Ready or record.Saving or record.Leaving then return false, "Espera a que termine el guardado." end
		local candidate = snapshot(record.Data)
		local ok, accepted, message = pcall(callback, candidate)
		if not ok then warnMessage("Color Rush: mutación de perfil rechazada."); return false, "No se pudo aplicar el cambio." end
		if accepted == false then return false, message end
		record.Data, record.Revision = candidate, record.Revision + 1
		return true, message
	end

	function controller.reward(player, coins, wins, rounds, actions)
		local record = records[player]
		if not record or record.Leaving then return false end
		local reserved = record.PendingPaid and record.PendingPaid.Coins or 0
		local granted = math.min(whole(coins, maxCoins), math.max(0, maxCoins - reserved - record.Data.Coins))
		record.Data.Coins += granted
		record.Data.Wins = math.min(record.Data.Wins + whole(wins, 100000000), 100000000)
		Progression.record(record.Data.Progress, { Wins = wins, Rounds = rounds, Actions = actions }, now(), config)
		record.Revision += 1
		return true, granted
	end

	function controller.claim(player, key)
		return controller.mutate(player, function(data)
			for _, mission in ipairs(config.DailyMissions or {}) do
				if mission.Key == key and data.Coins + (records[player].PendingPaid and records[player].PendingPaid.Coins or 0) + mission.Reward > maxCoins then return false, "Gasta algunas monedas antes de reclamar." end
			end
			local reward, message = Progression.claim(data.Progress, key, now(), config)
			if reward <= 0 then return false, message end
			data.Coins += reward
			return true, message
		end)
	end

	function controller.trail(player, index)
		local record = records[player]
		if type(index) ~= "number" or index % 1 ~= 0 or not (config.Trails or {})[index] then return false, "Estela inválida." end
		local trail = config.Trails[index]
		return controller.mutate(player, function(data)
			if trail.Access == "VIP" then
				if not record or not record.VIP then return false, "Esta estela requiere el pase VIP Prisma." end
			elseif not data.OwnedTrails[tostring(index)] then
				local cost = whole(trail.Cost, maxCoins)
				if data.Coins < cost then return false, "Te faltan monedas para esta estela." end
				data.Coins -= cost
				data.OwnedTrails[tostring(index)] = true
			end
			data.SelectedTrail = index
			return true, "Estela equipada."
		end)
	end

	function controller.autoRevive(player, enabled)
		if type(enabled) ~= "boolean" then return false, "Configuración inválida." end
		return controller.mutate(player, function(data) data.AutoRevive = enabled; return true end)
	end

	-- Match eligibility MUST be checked by Main immediately before this nonyielding call.
	-- No purchase callback itself revives a player or reverses an announced winner.
	function controller.consumeRevive(player)
		local record = records[player]
		if not record or (savingEnabled and not record.Writable) or record.PendingPaid or record.UncertainReceipt or record.LastSaveFailed then
			return false, "Espera a que se confirme tu guardado antes de usar una reentrada."
		end
		local ok, message = controller.mutate(player, function(data)
			if data.ReviveCredits < 1 then return false, "No tienes reentradas disponibles." end
			data.ReviveCredits -= 1
			return true, "Reentrada utilizada."
		end)
		if ok and record.Writable then tasks.defer(controller.save, player, false) end
		return ok, message
	end

	function controller.remove(player)
		local record = records[player]
		if not record then return end
		record.Leaving = true
		controller.save(player, true)
		if records[player] == record then records[player] = nil end
	end

	function controller.start()
		if started then return end
		started = true
		tasks.spawn(function()
			while not closing do
				tasks.wait(config.SaveInterval or 75)
				if closing then break end
				for player, record in pairs(records) do
					if record.Writable and not record.Leaving then tasks.spawn(controller.save, player, false) end
				end
			end
		end)
	end

	function controller.close()
		closing = true
		local pending = 0
		for player, record in pairs(records) do
			record.Leaving = true
			pending += 1
			tasks.spawn(function() controller.save(player, true); pending -= 1 end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do tasks.wait(0.1) end
	end

	return controller
end

return Profiles
