local Leaderboards = require("../src/server/Leaderboards")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1 end
local function fixture(enabled)
	local f = { Time = 0, Opens = 0, Writes = 0, Reads = 0, Names = 0, Warnings = 0, Saved = {}, Pages = {}, FailWrites = false, FailReads = false }
	local service = {}
	function service:GetOrderedDataStore(name)
		f.Opens += 1
		if f.FailOpen then error("offline") end
		f.Saved[name] = f.Saved[name] or {}
		return {
			UpdateAsync = function(_, key, callback)
				f.Writes += 1
				if f.FailWrites then error("offline") end
				local result = callback(f.Saved[name][key])
				if f.CancelWrite then return nil end
				f.Saved[name][key] = result
				if f.LostAck then f.LostAck = false; error("commit acknowledgement lost") end
				return result
			end,
			GetSortedAsync = function(_, ascending, count)
				f.Reads += 1
				assert(ascending == false and count == 10, "Rank query requests top ten descending")
				if f.FailReads then error("offline") end
				return { GetCurrentPage = function() return f.Pages[name] or {} end }
			end,
		}
	end
	f.Board = Leaderboards.new({
		Enabled = enabled, Config = { DataStoreName = "TestProfile" }, DataStoreService = service,
		Now = function() return f.Time end, Warn = function() f.Warnings += 1 end,
		NameForUser = function(id) f.Names += 1; if f.FailNames then error("offline") end; return "Nombre" .. id end,
	})
	return f
end
local function progress(wins, streak, xp) return { Wins = wins, BestStreak = streak, Progress = { XP = xp } } end
local player = { UserId = 123, Name = "Nombre123" }
local winsKey, streakKey, levelKey = "TestProfile_GlobalWins_v2", "TestProfile_GlobalStreak_v2", "TestProfile_GlobalLevel_v2"

do
	local f = fixture(false)
	check("Studio publication performs no global writes", not f.Board.publish(player, progress(10, 5, 500)))
	check("Studio refresh performs no global reads", not f.Board.refresh())
	check("Studio never opens OrderedDataStores", f.Opens == 0 and f.Reads == 0 and f.Writes == 0)
	check("disabled board does not invent competitors", #f.Board.snapshot().Wins == 0)
end

do
	local f = fixture(true)
	check("confirmed profile publishes all global metrics", f.Board.publish(player, progress(2, 5, 350)) and f.Writes == 3)
	check("wins and best streak are stored in distinct boards", f.Saved[winsKey]["123"] == 2 and f.Saved[streakKey]["123"] == 5)
	check("global level derives from persisted XP", f.Saved[levelKey]["123"] == 4)
	f.Board.publish(player, progress(3, 6, 400))
	check("repeated writes inside cooldown are suppressed", f.Writes == 3)
	f.Time = 60
	f.Board.publish(player, progress(3, 6, 400))
	check("updated progress writes after cooldown", f.Writes == 6 and f.Saved[winsKey]["123"] == 3)
	f.Time = 120
	f.Board.publish(player, progress(3, 6, 400))
	check("unchanged progress does not consume write quota", f.Writes == 6)
	f.Board.publish(player, progress(1, 2, 0))
	check("late lower local snapshot cannot reduce a board", f.Writes == 6 and f.Saved[winsKey]["123"] == 3)
	check("stores are cached per metric", f.Opens == 3)
end

do
	local f = fixture(true)
	f.Board.publish(player, progress(1, 2, 0))
	f.Saved[winsKey]["123"] = 40
	f.Saved[streakKey]["123"] = 50
	f.Saved[levelKey]["123"] = 12
	f.Time = 60
	f.Board.publish(player, progress(2, 3, 100))
	check("concurrent higher persisted score is retained atomically", f.Saved[winsKey]["123"] == 40 and f.Saved[streakKey]["123"] == 50 and f.Saved[levelKey]["123"] == 12)
	f.Time = 120
	f.Board.publish(player, progress(3, 4, 200))
	check("actual UpdateAsync result suppresses stale repeat attempts", f.Writes == 6)
end

do
	local f = fixture(true)
	f.FailWrites = true
	check("write outages are caught", not f.Board.publish(player, progress(1, 5, 100)))
	check("each failed metric is reported", f.Warnings == 3)
	f.Board.publish(player, progress(1, 5, 100))
	check("failures are throttled too", f.Writes == 3)
	f.FailWrites, f.Time = false, 60
	check("failed writes remain retryable", f.Board.publish(player, progress(1, 5, 100)) and f.Saved[winsKey]["123"] == 1)
end

do
	local f = fixture(true)
	f.CancelWrite = true
	check("nil UpdateAsync result is not reported committed", not f.Board.publish(player, progress(1, 5, 100)))
	f.CancelWrite, f.Time = false, 60
	check("cancelled transactions retry after cooldown", f.Board.publish(player, progress(1, 5, 100)))
	local lost = fixture(true)
	lost.LostAck = true
	lost.Board.publish(player, progress(1, 5, 100))
	lost.Time = 60
	lost.Board.publish(player, progress(1, 5, 100))
	check("lost acknowledgement retries safely without increasing scores", lost.Saved[winsKey]["123"] == 1 and lost.Writes == 4)
end

do
	local f = fixture(true)
	check("malformed user ID cannot be written", not f.Board.publish({ UserId = -3 }, progress(1, 5, 100)))
	check("fractional user ID cannot be written", not f.Board.publish({ UserId = 1.5 }, progress(1, 5, 100)))
	check("malformed progress cannot be written", not f.Board.publish(player, { Wins = 0/0, BestStreak = math.huge, Progress = "bad" }))
	check("invalid data performs no calls", f.Writes == 0 and f.Opens == 0)
	f.Board.publish(player, progress(1, 5, 100000000))
	check("level is limited to game progression maximum", f.Saved[levelKey]["123"] == 1000)
end

do
	local f = fixture(true)
	f.Pages[winsKey] = {
		{ key = "123", value = 9 }, { key = "124", value = 5 },
		{ key = "not-a-user", value = 9 }, { key = "-3", value = 8 },
		{ key = "7.1", value = 7 }, { key = "125", value = math.huge },
		{ key = "123", value = 1 },
	}
	f.Pages[streakKey] = { { key = "123", value = 20 } }
	f.Pages[levelKey] = { { key = "123", value = 4 } }
	check("refresh returns actual populated pages", f.Board.refresh())
	local snapshot = f.Board.snapshot()
	check("malformed and duplicate ranking IDs are filtered", #snapshot.Wins == 2)
	check("ranking rows show actual username and persisted value", snapshot.Wins[1].Name == "Nombre123" and snapshot.Wins[1].Value == 9)
	check("names cache across all three boards", f.Names == 2)
	check("board exposes distinct wins streak and level", snapshot.Streak[1].Value == 20 and snapshot.Level[1].Value == 4)
	snapshot.Wins[1].Value = 999
	table.clear(snapshot.Streak)
	check("consumers cannot mutate cached rankings", f.Board.snapshot().Wins[1].Value == 9 and #f.Board.snapshot().Streak == 1)
	check("cached refresh respects quota", not f.Board.refresh() and f.Reads == 3)
	f.Time, f.FailReads = 60, true
	check("read failure preserves previous known rankings", not f.Board.refresh() and f.Board.snapshot().Wins[1].Value == 9)
	check("cached failure is marked as temporarily disconnected", string.find(f.Board.snapshot().Status, "sin conexión", 1, true) ~= nil)
	f.Time, f.FailReads = 120, false
	f.Pages[winsKey] = {}
	f.Board.refresh()
	check("valid empty page clears former rows without invented fillers", #f.Board.snapshot().Wins == 0)
end

do
	local f = fixture(true)
	f.FailOpen = true
	check("store acquisition failures do not break refresh", not f.Board.refresh())
	f.Time, f.FailOpen, f.FailNames = 60, false, true
	f.Pages[winsKey] = { { key = "123", value = 9 } }
	f.Board.refresh()
	check("username outage still shows an honest stable identifier", f.Board.snapshot().Wins[1].Name == "Jugador 123")
	f.Time, f.FailNames = 120, false
	f.Board.refresh()
	check("failed username lookup is retried later", f.Board.snapshot().Wins[1].Name == "Nombre123")
end

print(string.format("Leaderboards: %d behavioral checks passed", passed))
