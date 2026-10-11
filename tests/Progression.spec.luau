-- Run from the repository root: luau tests/Progression.spec.luau
local Progression = require("../src/shared/Progression")
local config = {
	DailyMissions = {
		{ Key = "play3", Name = "Completa 3 rondas", Metric = "Rounds", Target = 3, Reward = 30 },
		{ Key = "repair8", Name = "Realiza 8 acciones", Metric = "Actions", Target = 8, Reward = 40 },
		{ Key = "win2", Name = "Gana 2 rondas", Metric = "Wins", Target = 2, Reward = 50 },
	},
	XPPerRound = 15,
	XPPerWin = 25,
}
local now = 20000 * 86400 + 86399
local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS " .. name)
end
local function fresh()
	return Progression.clean(nil, now, config)
end

do
	local progress = fresh()
	local view = Progression.view(progress, now, config)
	check("new players have three available free goals and level one", progress.Day == 20000 and progress.XP == 0 and view.Level == 1 and #view.Missions == 3 and view.Missions[1].Count == 0 and not view.Missions[1].Complete and not view.Missions[1].Claimed)
	check("empty progress cannot claim a reward", Progression.claim(progress, "play3", now, config) == 0 and next(progress.Claimed) == nil)
end

do
	local safe = true
	for _, raw in ipairs({ false, "corrupt", 99 }) do
		local progress = Progression.clean(raw, now, config)
		safe = safe and progress.XP == 0 and progress.Counts.Rounds == 0
	end
	check("non-table saves reset safely", safe)
	local invalid = { -1, false, "3", 0 / 0, math.huge, -math.huge }
	for _, value in ipairs(invalid) do
		local progress = Progression.clean({ XP = value, Day = 20000, Counts = { Rounds = value, Actions = value, Wins = value } }, now, config)
		safe = safe and progress.XP == 0 and progress.Counts.Rounds == 0 and progress.Counts.Actions == 0 and progress.Counts.Wins == 0
	end
	check("malformed counts and XP never become usable progress", safe)
	local progress = Progression.clean({ XP = 101.9, Day = 20000, Counts = { Rounds = 3.9 } }, now, config)
	check("saved fractions become whole progress", progress.XP == 101 and progress.Counts.Rounds == 3)
end

do
	local progress = fresh()
	local same = Progression.record(progress, { Rounds = 1, Actions = 4, Wins = 1 }, now, config)
	check("server records mutate the original progress and grant correct XP", same == progress and progress.XP == 40 and progress.Counts.Rounds == 1 and progress.Counts.Actions == 4 and progress.Counts.Wins == 1)
	Progression.record(progress, { Actions = 4 }, now, config)
	check("actions complete goals without granting fabricated round XP", progress.XP == 40 and progress.Counts.Actions == 8)
	local reward = Progression.claim(progress, "repair8", now, config)
	check("completed action goal grants its configured reward", reward == 40 and progress.Claimed.repair8 == true)
	reward = Progression.claim(progress, "repair8", now, config)
	check("repeated claim cannot pay twice", reward == 0 and progress.Claimed.repair8 == true)
	check("partial round and win goals stay unclaimable", Progression.claim(progress, "play3", now, config) == 0 and Progression.claim(progress, "win2", now, config) == 0)
	Progression.record(progress, { Rounds = 2, Wins = 1 }, now, config)
	check("round and win goals grant independent fixed rewards", Progression.claim(progress, "play3", now, config) == 30 and Progression.claim(progress, "win2", now, config) == 50 and progress.XP == 95)
end

do
	local progress = fresh()
	Progression.record(progress, { Rounds = 3, Actions = 8, Wins = 2 }, now, config)
	Progression.claim(progress, "play3", now, config)
	local nextDay = now + 1
	check("UTC midnight resets unclaimed as well as claimed daily goals", Progression.claim(progress, "repair8", nextDay, config) == 0 and progress.Day == 20001 and progress.Counts.Rounds == 0 and progress.Counts.Actions == 0 and next(progress.Claimed) == nil)
	check("UTC rollover preserves lifetime XP", progress.XP == 95)
	Progression.record(progress, { Rounds = 3 }, nextDay, config)
	check("next UTC day can earn and claim the same goal again", Progression.claim(progress, "play3", nextDay, config) == 30 and progress.XP == 140)
	local view = Progression.view(progress, nextDay, config)
	check("level thresholds use 100 lifetime XP per level", view.Level == 2 and view.LevelProgress == 40 and view.NextLevelXP == 100)
end

do
	local safe = true
	for _, day in ipairs({ 19999, 20001, false, "20000", 20000.1 }) do
		local progress = Progression.clean({ XP = 500, Day = day, Counts = { Rounds = 3 }, Claimed = { play3 = true } }, now, config)
		safe = safe and progress.XP == 500 and progress.Counts.Rounds == 0 and next(progress.Claimed) == nil
	end
	local missing = Progression.clean({ XP = 500, Counts = { Rounds = 3 } }, now, config)
	check("unknown and future saved dates cannot carry daily rewards", safe and missing.Counts.Rounds == 0 and missing.XP == 500)
end

do
	local raw = { XP = 80, Day = 20000, Counts = { Rounds = 3 }, Claimed = { play3 = true, repair8 = "true", unknown = true } }
	local progress = Progression.clean(raw, now, config)
	check("claimed flags accept known boolean entries only", progress.Claimed.play3 == true and progress.Claimed.repair8 == nil and progress.Claimed.unknown == nil)
	check("persisted claim flag does not replay currency", Progression.claim(progress, "play3", now, config) == 0)
	progress.Counts.Rounds = 10
	progress.Claimed.win2 = true
	check("cleaned state does not alias stored counters or claims", raw.Counts.Rounds == 3 and raw.Claimed.win2 == nil)
	local corrupt = Progression.clean({ Day = 20000, Counts = { Rounds = "3", Actions = math.huge, Wins = 0 / 0 }, Claimed = { play3 = "true", repair8 = 1 } }, now, config)
	check("corrupted persisted progress cannot unlock currency", Progression.claim(corrupt, "play3", now, config) == 0 and Progression.claim(corrupt, "repair8", now, config) == 0 and Progression.claim(corrupt, "win2", now, config) == 0)
end

do
	local progress = fresh()
	local safe = true
	for _, key in ipairs({ false, {}, 1, "unknown", "" }) do
		safe = safe and Progression.claim(progress, key, now, config) == 0
	end
	check("invalid remote mission keys grant nothing", safe and Progression.claim(progress, nil, now, config) == 0 and next(progress.Claimed) == nil)
	Progression.record(progress, { Rounds = "3", Actions = math.huge, Wins = 0 / 0 }, now, config)
	Progression.record(progress, nil, now, config)
	check("malformed deltas cannot create goals or XP", progress.XP == 0 and progress.Counts.Rounds == 0 and progress.Counts.Actions == 0 and progress.Counts.Wins == 0)
	Progression.record(progress, { Rounds = -3, Actions = 2.9, Wins = false }, now, config)
	check("negative deltas cannot erase progress and fractional actions floor", progress.Counts.Rounds == 0 and progress.Counts.Actions == 2 and progress.XP == 0)
	Progression.record(progress, { Rounds = 1e20, Actions = 1e20, Wins = 1e20 }, now, config)
	local view = Progression.view(progress, now, config)
	check("oversized finite counts and XP stay bounded", progress.Counts.Rounds == 1000000 and progress.Counts.Actions == 1000000 and progress.Counts.Wins == 1000000 and progress.XP == 99900 and view.Level == 1000 and view.LevelProgress == 100)
end

do
	local progress = fresh()
	Progression.record(progress, { Rounds = 4 }, now, config)
	local view = Progression.view(progress, now, config)
	check("mission display caps counts at target and reports readiness", view.Missions[1].Count == 3 and view.Missions[1].Complete and not view.Missions[1].Claimed and not view.Missions[2].Complete)
	view.Missions[1].Claimed = true
	view.Missions[1].Count = 0
	check("client projection cannot mutate authoritative mission state", progress.Counts.Rounds == 4 and progress.Claimed.play3 == nil)
	view = Progression.view(progress, now + 1, config)
	check("view shows daily reset without mutating the stored state", view.Missions[1].Count == 0 and not view.Missions[1].Complete and progress.Day == 20000 and progress.Counts.Rounds == 4 and view.XP == 60)
end

do
	local progress = Progression.clean(nil, now, nil)
	local view = Progression.view(progress, now, nil)
	Progression.record(progress, { Rounds = 2, Wins = 1 }, now, nil)
	check("absent mission configuration is safely empty", #view.Missions == 0 and Progression.claim(progress, "play3", now, nil) == 0 and progress.XP == 0)
	local invalidConfig = { DailyMissions = { { Key = "bad", Metric = "Coins", Target = 1, Reward = 500 }, { Key = "zero", Metric = "Rounds", Target = 0, Reward = 500 } } }
	check("invalid mission definitions cannot create free rewards", #Progression.view(progress, now, invalidConfig).Missions == 0 and Progression.claim(progress, "bad", now, invalidConfig) == 0)
end

assert(passed == 29, "Unexpected progression check count")
print(string.format("All %d progression checks passed.", passed))
