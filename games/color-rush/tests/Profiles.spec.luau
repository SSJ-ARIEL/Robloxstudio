-- Real profile controller with simulated atomic datastore failures.
-- These tests do not invoke Roblox APIs or charge accounts.
local Profiles = require("../src/server/Profiles")
local Ledger = require("../src/shared/Ledger")
local Progression = require("../src/shared/Progression")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1; print("PASS profiles: " .. name) end
local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = clone(child) end; return result
end
local function raw(coins, credits)
	return { Coins = coins or 100, ReviveCredits = credits or 2, Wins = 1, SelectedTrail = 1,
		OwnedTrails = { ["1"] = true }, Receipts = {}, AutoRevive = false }
end
local function fixture(options)
	options = options or {}
	local f = { Now = 2000000000, Online = true, Calls = 0, Delayed = {}, Deferred = {}, Messages = {}, Refreshes = 0 }
	f.Player = { UserId = 81 }
	f.Value = options.Initial
	f.Config = { DataStoreName = "ColorRush_Player_v1", MaxCoins = 1000, MaxReviveCredits = 10,
		MaxReceipts = options.MaxReceipts or 10000, XPPerRound = 15, XPPerWin = 35,
		Trails = { { Cost = 0 }, { Cost = 50 }, { Cost = 0, Access = "VIP" } },
		DailyMissions = { { Key = "run3", Metric = "Rounds", Target = 3, Reward = 30 } } }
	local taskMock = {
		wait = function(duration) f.Now += duration or 0; if f.Wait then f.Wait() end end,
		delay = function(_, callback) table.insert(f.Delayed, callback) end,
		defer = function(callback, ...) table.insert(f.Deferred, { Callback = callback, Args = { ... } }) end,
		spawn = function(callback, ...) callback(...) end,
	}
	local sequence = 0
	f.Profiles = Profiles.new({
		Config = f.Config, Ledger = Ledger, Progression = Progression,
		Clock = function() return f.Now end, Tasks = taskMock,
		Players = { GetPlayerByUserId = function(_, id) return f.Online and id == 81 and f.Player or nil end },
		RunService = { IsStudio = function() return options.Studio == true end },
		HttpService = { GenerateGUID = function() sequence += 1; return "GUID_" .. sequence end },
		DataStoreService = { GetDataStore = function(_, name)
			assert(name == "ColorRush_Player_v1")
			return { UpdateAsync = function(_, key, transform)
				assert(key == "Player_81")
				f.Calls += 1
				if f.Before then local callback = f.Before; f.Before = nil; callback() end
				if f.FailBefore then error("datastore unavailable") end
				local updated = transform(clone(f.Value))
				if f.RetryTransform then updated = transform(clone(f.Value)) end
				if updated then f.Value = clone(updated) end
				if f.After then local callback = f.After; f.After = nil; callback() end
				if f.FailAfter then f.FailAfter = false; error("commit acknowledged too late") end
				return clone(updated)
			end }
		end },
		Notify = function(_, message) table.insert(f.Messages, message) end,
		Refresh = function() f.Refreshes += 1 end,
		Warn = function() end,
	})
	f.Load = function() return f.Profiles.load(f.Player) end
	f.Save = function(release) return f.Profiles.save(f.Player, release) end
	f.Grant = function(id, coins, credits)
		return f.Profiles.grantReceipt(f.Player, { PurchaseId = id or "receipt-A" }, { Coins = coins or 0, Credits = credits or 0 })
	end
	f.FlushDeferred = function()
		local pending = f.Deferred; f.Deferred = {}
		for _, item in ipairs(pending) do item.Callback(table.unpack(item.Args)) end
	end
	return f
end

do
	local f = fixture()
	local record = f.Load()
	check("fresh published session owns a distinct profile datastore lock", record and record.Writable and f.Value.Session == "GUID_1" and f.Value.LeaseUntil == f.Now + 240)
	check("first profile gets free default trail without paid credits", record.Data.Coins == 0 and record.Data.ReviveCredits == 0 and record.Data.OwnedTrails["1"] == true)
	check("duplicate load reuses profile without another datastore operation", f.Load() == record and f.Calls == 1)
	check("public payload never exposes receipts or session keys", f.Profiles.public(f.Player).Receipts == nil and f.Profiles.public(f.Player).Session == nil)
	f.Profiles.reward(f.Player, 100, 1, 3, 8)
	check("server reward advances XP and wins", record.Data.Coins == 100 and record.Data.Wins == 1 and f.Profiles.public(f.Player).XP == 80)
	check("completed daily mission grants exact known reward", f.Profiles.claim(f.Player, "run3") and record.Data.Coins == 130)
	check("daily reward cannot be claimed twice", not f.Profiles.claim(f.Player, "run3") and record.Data.Coins == 130)
	check("cosmetic purchase charges once and owns permanently", f.Profiles.trail(f.Player, 2) and record.Data.Coins == 80 and record.Data.SelectedTrail == 2 and record.Data.OwnedTrails["2"] == true)
	check("equipping owned trail is free", f.Profiles.trail(f.Player, 2) and record.Data.Coins == 80)
	check("unverified VIP cannot equip VIP trail", not f.Profiles.trail(f.Player, 3))
	record.VIP = true
	check("server-verified VIP equips cosmetic without buying wins", f.Profiles.trail(f.Player, 3) and record.Data.Coins == 80 and record.Data.Wins == 1)
	check("trail indexes strictly validated", not f.Profiles.trail(f.Player, 0) and not f.Profiles.trail(f.Player, 1.5) and not f.Profiles.trail(f.Player, "2"))
	check("automatic reentry requires exact boolean", not f.Profiles.autoRevive(f.Player, "true") and f.Profiles.autoRevive(f.Player, true) and record.Data.AutoRevive)
	check("normal autosave renews lease and persists equipped cosmetic", f.Save(false) and f.Value.Data.SelectedTrail == 3 and f.Value.Data.AutoRevive)
	check("public copies cannot mutate owned cosmetics", (function() local public = f.Profiles.public(f.Player); public.OwnedTrails["2"] = false; return record.Data.OwnedTrails["2"] end)())
	check("release save removes lock and disables this writer", f.Save(true) and f.Value.Session == nil and not record.Writable)
end

do
	local f = fixture({ Initial = { Data = raw(), Session = "other-server", LeaseUntil = 2000000200 } })
	local record = f.Load()
	check("live session lock is never stolen", record and not record.Writable and f.Value.Session == "other-server")
	check("blocked profile cannot charge purchases or consume paid credits", not f.Grant("A", 10, 1) and not f.Profiles.consumeRevive(f.Player))
	check("readonly fallback informs player", #f.Messages == 1)
	f = fixture({ Initial = { Data = raw(), Session = "expired", LeaseUntil = 1999999999 } })
	record = f.Load()
	check("expired lease safely reacquires existing progress", record.Writable and record.Data.Coins == 100 and record.Data.ReviveCredits == 2 and f.Value.Session == "GUID_1")
	f = fixture({ Studio = true, Initial = { Data = raw() } })
	record = f.Load()
	check("Studio never reads or writes real player progress", not record.Writable and f.Calls == 0 and not f.Save() and f.Calls == 0)
	check("Studio consumables never acknowledge payment", not f.Grant("A", 10, 1))
	f = fixture({ Initial = { Data = { Coins = 900, Receipts = { damaged = true } } } })
	record = f.Load()
	check("corrupted receipt history is retained and protected from overwrite", not record.Writable and f.Value.Data.Receipts.damaged == true and f.Value.Data.Coins == 900)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.RetryTransform = true
	check("retrying UpdateAsync transform does not duplicate grant", f.Grant("A", 50, 3) and record.Data.Coins == 150 and record.Data.ReviveCredits == 5 and f.Value.Data.Receipts.A.Credits == 3)
	check("same receipt replay is idempotent", f.Grant("A", 50, 3) and record.Data.Coins == 150 and record.Data.ReviveCredits == 5)
	check("changed product amounts cannot rewrite historical paid value", f.Grant("A", 500, 8) and record.Data.Coins == 150 and record.Data.ReviveCredits == 5)
	f.RetryTransform = false
	f.Before = function()
		check("profile mutations blocked while atomic purchase yields", not f.Profiles.trail(f.Player, 2))
		f.Profiles.reward(f.Player, 15, 1, 1, 1)
	end
	check("gameplay advances concurrently with atomic purchase", f.Grant("B", 25, 1) and record.Data.Coins == 190 and record.Data.Wins == 2 and record.Data.ReviveCredits == 6)
	check("purchase receipts remain independent for each grant", f.Value.Data.Receipts.A.Coins == 50 and f.Value.Data.Receipts.B.Coins == 25)
	check("later save persists concurrent rewards", f.Save() and f.Value.Data.Coins == 190 and f.Value.Data.Wins == 2)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.FailAfter = true
	check("lost purchase acknowledgment does not claim success", not f.Grant("A", 50, 3) and record.Data.Coins == 100 and record.Data.ReviveCredits == 2)
	check("unknown purchase is reserved while durable receipt exists", record.UncertainReceipt == "A" and record.PendingPaid.Coins == 50 and f.Value.Data.Receipts.A.Credits == 3 and record.LastSaveFailed)
	check("unconfirmed purchase cannot consume credit or replace pending receipt", not f.Profiles.consumeRevive(f.Player) and not f.Grant("B", 10, 1))
	f.Profiles.reward(f.Player, 15, 1, 1, 1)
	check("autosave merges committed receipt after lost acknowledgment", f.Save() and record.Data.Coins == 165 and record.Data.ReviveCredits == 5 and record.Data.Wins == 2)
	check("recovery clears busy purchase state", record.PendingPaid == nil and record.UncertainReceipt == nil and not record.LastSaveFailed)
	check("Roblox retry acknowledges recovered purchase exactly once", f.Grant("A", 50, 3) and record.Data.Coins == 165 and record.Data.ReviveCredits == 5)
	check("credit consumption is immediate and exactly one", f.Profiles.consumeRevive(f.Player) and record.Data.ReviveCredits == 4)
	check("credit consumption schedules durable save without yielding match", #f.Deferred == 1 and not record.Saving)
	f.FlushDeferred()
	check("consumed credit persists and cannot return from receipt replay", f.Value.Data.ReviveCredits == 4 and f.Grant("A", 50, 3) and record.Data.ReviveCredits == 4)
end

do
	local f = fixture({ Initial = { Data = raw(990, 9) } })
	local record = f.Load()
	f.Before = function() f.Profiles.reward(f.Player, 100, 0, 0, 0) end
	check("free coins reserve room for in-flight paid value", f.Grant("cap", 10, 1) and record.Data.Coins == 1000 and record.Data.ReviveCredits == 10)
	check("over-cap grant never truncates paid benefit", not f.Grant("overflow", 1, 0) and f.Value.Data.Receipts.overflow == nil and record.Data.Coins == 1000)
	f = fixture({ Initial = { Data = raw() }, MaxReceipts = 1 })
	record = f.Load()
	check("first receipt fills configured history budget", f.Grant("A", 10, 1))
	check("full receipt history still acknowledges old receipt", f.Grant("A", 10, 1))
	check("full history keeps a new charge unresolved rather than deleting IDs", not f.Grant("B", 10, 1) and f.Value.Data.Receipts.A ~= nil and f.Value.Data.Receipts.B == nil)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.Value.Session = "new-server"
	check("save rejects lost lock and disables writer", not f.Save() and not record.Writable and f.Value.Session == "new-server")
	check("lost writer cannot grant product", not f.Grant("A", 10, 1))
	f = fixture({ Initial = { Data = raw() } })
	record = f.Load()
	local before = record.Data.Coins
	check("throwing mutation cannot alter profile partially", not f.Profiles.mutate(f.Player, function(data) data.Coins = 0; error("bad callback") end) and record.Data.Coins == before)
	check("explicitly rejected mutation is rolled back", not f.Profiles.mutate(f.Player, function(data) data.Coins = 0; return false end) and record.Data.Coins == before)
	f.Profiles.remove(f.Player)
	check("departure persists progress and releases session", f.Profiles.get(f.Player) == nil and f.Value.Session == nil and f.Value.Data.Coins == before)
	check("missing profiles have no personal payload", f.Profiles.public(f.Player) == nil and f.Profiles.progression(f.Player) == nil)
	f = fixture({ Initial = { Data = raw() } })
	f.Before = function() f.Online = false end
	check("departure during load releases acquired session", f.Load() == nil and f.Value.Session == nil)
end

print(string.format("All %d profiles checks passed.", passed))
