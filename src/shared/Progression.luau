-- Deterministic daily goals and lifetime XP. Call with server-owned counters
-- and an explicit Unix time; clients never decide rewards or progress.
local Progression = {}

local METRICS = { "Rounds", "Actions", "Wins" }
local MAX_COUNT = 1000000
local LEVEL_XP = 100
local MAX_LEVEL = 1000
local MAX_XP = (MAX_LEVEL - 1) * LEVEL_XP

local function whole(value, maximum)
	if type(value) ~= "number" or value ~= value or value <= 0 or value == math.huge then
		return 0
	end
	return math.min(math.floor(value), maximum)
end

local function currentDay(now)
	return math.floor(whole(now, 100000000000) / 86400)
end

local function missions(config)
	if type(config) == "table" and type(config.DailyMissions) == "table" then
		return config.DailyMissions
	end
	return {}
end

local function validMission(mission)
	if type(mission) ~= "table" or type(mission.Key) ~= "string" or mission.Key == "" then
		return false
	end
	local recognized = mission.Metric == "Rounds" or mission.Metric == "Actions" or mission.Metric == "Wins"
	return recognized and whole(mission.Target, MAX_COUNT) > 0
end

function Progression.clean(raw, now, config)
	local progress = {
		XP = 0,
		Day = currentDay(now),
		Counts = { Rounds = 0, Actions = 0, Wins = 0 },
		Claimed = {},
	}
	if type(raw) ~= "table" then
		return progress
	end
	progress.XP = whole(raw.XP, MAX_XP)
	-- Unknown, past or future dates cannot carry daily rewards into today.
	if raw.Day ~= progress.Day then
		return progress
	end
	if type(raw.Counts) == "table" then
		for _, metric in ipairs(METRICS) do
			progress.Counts[metric] = whole(raw.Counts[metric], MAX_COUNT)
		end
	end
	if type(raw.Claimed) == "table" then
		for _, mission in ipairs(missions(config)) do
			if validMission(mission) and raw.Claimed[mission.Key] == true then
				progress.Claimed[mission.Key] = true
			end
		end
	end
	return progress
end

local function refresh(progress, now, config)
	local clean = Progression.clean(progress, now, config)
	if type(progress) ~= "table" then
		return clean
	end
	progress.XP = clean.XP
	progress.Day = clean.Day
	progress.Counts = clean.Counts
	progress.Claimed = clean.Claimed
	return progress
end

function Progression.record(progress, delta, now, config)
	progress = refresh(progress, now, config)
	delta = if type(delta) == "table" then delta else {}
	local increments = {}
	for _, metric in ipairs(METRICS) do
		increments[metric] = whole(delta[metric], MAX_COUNT)
		progress.Counts[metric] = math.min(progress.Counts[metric] + increments[metric], MAX_COUNT)
	end
	local roundXP = if type(config) == "table" then whole(config.XPPerRound, MAX_XP) else 0
	local winXP = if type(config) == "table" then whole(config.XPPerWin, MAX_XP) else 0
	progress.XP = math.min(progress.XP + increments.Rounds * roundXP + increments.Wins * winXP, MAX_XP)
	return progress
end

function Progression.claim(progress, key, now, config)
	progress = refresh(progress, now, config)
	if type(key) ~= "string" then
		return 0, "Misión inválida."
	end
	for _, mission in ipairs(missions(config)) do
		if validMission(mission) and mission.Key == key then
			if progress.Claimed[key] then
				return 0, "Ya recogiste esta recompensa hoy."
			end
			if progress.Counts[mission.Metric] < whole(mission.Target, MAX_COUNT) then
				return 0, "Completa la misión para recoger su recompensa."
			end
			local reward = whole(mission.Reward, MAX_COUNT)
			if reward <= 0 then
				return 0, "La recompensa no está disponible."
			end
			progress.Claimed[key] = true
			return reward, "Recompensa de misión recogida."
		end
	end
	return 0, "Misión inválida."
end

function Progression.view(progress, now, config)
	local clean = Progression.clean(progress, now, config)
	local level = math.min(math.floor(clean.XP / LEVEL_XP) + 1, MAX_LEVEL)
	local view = {
		XP = clean.XP,
		Level = level,
		NextLevelXP = LEVEL_XP,
		LevelProgress = if level == MAX_LEVEL then LEVEL_XP else clean.XP % LEVEL_XP,
		Missions = {},
	}
	for _, mission in ipairs(missions(config)) do
		if validMission(mission) then
			local target = whole(mission.Target, MAX_COUNT)
			local count = clean.Counts[mission.Metric]
			table.insert(view.Missions, {
				Key = mission.Key,
				Name = if type(mission.Name) == "string" then mission.Name else mission.Key,
				Count = math.min(count, target),
				Target = target,
				Reward = whole(mission.Reward, MAX_COUNT),
				Claimed = clean.Claimed[mission.Key] == true,
				Complete = count >= target,
			})
		end
	end
	return view
end

return Progression
