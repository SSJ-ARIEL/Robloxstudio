-- Atomic persistence simulation, including a committed receipt whose response
-- is lost and a transform that runs without a successful final commit.
local Profiles = require("../src/server/Profiles")
local Economy = require("../src/shared/Economy")
local Ledger = require("../src/shared/ProfileLedger")
local Commerce = require("../src/server/Commerce")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1; print("PASS profiles: " .. name) end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = copy(child) end; return result
end
local function raw(coins)
	return { Coins = coins or 100, Wins = 2, Selected = 8, Owned = { ["1"] = true, ["8"] = true }, Receipts = { legacy = 400 }, Progress = { XP = 250 } }
end
local function fixture(options)
	options = options or {}
	local f = { Now = 2000000000, Calls = 0, Online = true, Delayed = {}, Saved = {}, Messages = {}, Held = {}, Value = options.Initial }
	f.Config = { MaxCoins = 1000, MaxReceipts = options.MaxReceipts or 10000, DailyMissions = {} }
	f.Player = { UserId = 81 }
	local store = { UpdateAsync = function(_, key, transform)
		assert(key == "Player_81", "upgrade must keep old profile keys")
		f.Calls += 1
		if f.Before then local callback = f.Before; f.Before = nil; callback() end
		if f.FailBefore then error("store offline") end
		local updated = transform(copy(f.Value))
		if f.RetryTransform then updated = transform(copy(f.Value)) end
		if f.CancelAfterTransform then return nil end
		if updated then f.Value = copy(updated) end
		if f.After then local callback = f.After; f.After = nil; callback() end
		if f.FailAfter then f.FailAfter = false; error("reply lost after successful commit") end
		if f.ReturnWrongToken then local wrong = copy(updated); if wrong then wrong.Commit = "wrong" end; return wrong end
		return copy(updated)
	end }
	f.Profiles = Profiles.new({ Config = f.Config, Economy = Economy, Ledger = Ledger,
		Store = if options.NoStore then nil else store, Enabled = options.Enabled,
		SessionId = "this-server", Now = function() return f.Now end,
		Clock = function() return f.Now end,
		IsOnline = function() return f.Online end,
		Tasks = { wait = function(seconds) f.Now += seconds end, delay = function(_, callback) table.insert(f.Delayed, callback) end,
			spawn = function(callback) if f.HoldSpawns then table.insert(f.Held, callback) else callback() end end },
		OnSaved = function(_, data) table.insert(f.Saved, copy(data)) end,
		Notify = function(_, message) table.insert(f.Messages, message) end, Warn = function() end,
	})
	f.Load = function() return f.Profiles.load(f.Player) end
	f.Save = function(release) return f.Profiles.save(f.Player, release) end
	f.Grant = function(id, amount) return f.Profiles.grantReceipt(f.Player, { PurchaseId = id or "A" }, { Coins = amount or 50 }) end
	f.Correct = function()
		local record = f.Profiles.get(f.Player)
		Economy.correct(record.Data, f.Now, f.Config, record.PendingPaid or 0)
		f.Profiles.markDirty(f.Player)
	end
	return f
end

do
	local f = fixture({ Initial = { Data = raw(), Session = "old-server", LeaseUntil = 1999999999 } })
	local record = f.Load()
	check("expired lease migrates profile in the same datastore envelope", record.Writable and f.Value.Session == "this-server" and f.Value.LeaseUntil == f.Now + 240)
	check("legacy owned auras selected aura XP coins and receipt survive migration", record.Data.Coins == 100 and record.Data.Wins == 2 and record.Data.Selected == 8 and record.Data.Owned["8"] and record.Data.Progress.XP == 250 and record.Data.Receipts.legacy == 400)
	check("new profile currencies cannot manufacture paid history", record.Data.Gems == 0 and record.Data.FreeGifts == 0 and record.Data.CurrentStreak == 0)
	check("duplicate load reuses the existing record", f.Load() == record and f.Calls == 1)
	check("public profile hides receipts lock and pending paid amounts", f.Profiles.public(f.Player).Receipts == nil and f.Profiles.public(f.Player).Session == nil and f.Profiles.public(f.Player).PendingPaid == nil)
	f.Correct()
	check("autosave persists new rewards and reports durable leaderboard snapshot", f.Save() and f.Value.Data.Coins == 108 and f.Value.Data.CurrentStreak == 1 and f.Saved[1].CorrectDoors == 1)
	check("release commits with no remaining session owner", f.Save(true) and f.Value.Session == nil and not record.Writable)
	check("released writer cannot grant Robux products", not f.Grant("A", 10))
end

do
	local f = fixture({ Enabled = false, Initial = { Data = raw() } })
	local record = f.Load()
	check("Studio/session mode makes no datastore calls", record and not record.Writable and f.Calls == 0)
	check("session mode still supports free gameplay and cosmetics", (function() f.Correct(); return record.Data.Coins == 8 and record.Data.CurrentStreak == 1 end)())
	check("session mode cannot acknowledge a paid product", not f.Grant("A", 10) and not f.Save() and f.Calls == 0)
	f = fixture({ NoStore = true })
	check("missing datastore still loads a free session", f.Load() ~= nil and f.Calls == 0)
	f = fixture({ Initial = { Data = raw(), Session = "other", LeaseUntil = 2000000200 } })
	record = f.Load()
	check("live lock cannot be stolen", not record.Writable and f.Value.Session == "other" and f.Value.Data.Coins == 100)
	check("failed loading warns once and never exposes paid purchase success", #f.Messages == 1 and not f.Grant("A", 10))
	f = fixture({ Initial = { Data = { Coins = 900, Receipts = { invalid = true } } } })
	record = f.Load()
	check("invalid receipt history remains untouched rather than being discarded", not record.Writable and f.Value.Data.Receipts.invalid == true and f.Value.Data.Coins == 900)
	f = fixture()
	f.CancelAfterTransform = true
	record = f.Load()
	check("load transform execution alone is not proof of ownership", not record.Writable and f.Value == nil)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.RetryTransform = true
	check("retried transform grants paid coins exactly once", f.Grant("A", 50) and record.Data.Coins == 150 and f.Value.Data.Receipts.A == 50)
	check("existing receipt replay cannot credit twice", f.Grant("A", 50) and record.Data.Coins == 150)
	check("changed product amount cannot rewrite earlier purchase", f.Grant("A", 500) and record.Data.Coins == 150 and f.Value.Data.Receipts.A == 50)
	f.RetryTransform = false
	f.Before = function()
		check("shop mutations wait while paid transaction yields", not f.Profiles.mutate(f.Player, function(data) data.Coins = 0; return true end))
		for _ = 1, 5 do f.Correct() end
	end
	check("match rewards continue during the atomic purchase", f.Grant("B", 25) and record.Data.Coins == 215 and record.Data.FreeGifts == 1 and record.Data.CurrentStreak == 5)
	check("leaderboard callback uses only the committed snapshot", f.Saved[#f.Saved].CurrentStreak == 0 and f.Saved[#f.Saved].FreeGifts == 0)
	check("following autosave persists concurrent streak and gift", f.Save() and f.Value.Data.CurrentStreak == 5 and f.Value.Data.FreeGifts == 1 and f.Value.Data.Coins == 215)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.FailAfter = true
	check("lost purchase response cannot acknowledge success", not f.Grant("A", 50) and record.Data.Coins == 100)
	check("unknown commit reserves paid balance and keeps durable receipt", record.PendingPaid == 50 and record.UncertainReceipt == "A" and record.LastSaveFailed and f.Value.Data.Receipts.A == 50)
	check("second receipt cannot overwrite the uncertain receipt", not f.Grant("B", 10) and record.UncertainReceipt == "A")
	f.Correct()
	check("autosave recovers committed receipt without losing later free reward", f.Save() and record.Data.Coins == 158 and record.Data.CurrentStreak == 1 and f.Value.Data.Coins == 158)
	check("recovery clears purchase hold", record.PendingPaid == nil and record.UncertainReceipt == nil and not record.LastSaveFailed)
	check("Roblox receipt retry acknowledges recovered grant without extra coins", f.Grant("A", 50) and record.Data.Coins == 158)
	f.CancelAfterTransform = true
	local savedCount = #f.Saved
	check("grant callback result cannot substitute for datastore commit", not f.Grant("B", 10) and f.Value.Data.Receipts.B == nil and record.Data.Receipts.B == nil and #f.Saved == savedCount)
	f.CancelAfterTransform = false
	check("autosave can clear a cancelled transaction hold safely", f.Save() and record.PendingPaid == nil and record.Data.Coins == 158)
end

do
	local f = fixture({ Initial = { Data = raw(990) } })
	local record = f.Load()
	f.Before = f.Correct
	check("free rewards cannot consume space reserved for paid currency", f.Grant("cap", 10) and record.Data.Coins == 1000 and record.Data.CurrentStreak == 1 and f.Value.Data.Receipts.cap == 10)
	check("over-cap paid benefit remains unresolved rather than truncated", not f.Grant("overflow", 1) and f.Value.Data.Receipts.overflow == nil and record.Data.Coins == 1000)
	f = fixture({ Initial = { Data = raw() }, MaxReceipts = 2 })
	record = f.Load()
	check("receipt history budget counts legacy purchases", f.Grant("A", 10) and f.Value.Data.Receipts.legacy == 400)
	check("full receipt history still permits already-persisted acknowledgment", f.Grant("A", 10))
	check("full receipt budget never removes a historical receipt", not f.Grant("B", 10) and f.Value.Data.Receipts.legacy == 400 and f.Value.Data.Receipts.A == 10 and f.Value.Data.Receipts.B == nil)
end

do
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	local prior = record.Data.Coins
	check("throwing user mutation cannot partly debit balance", not f.Profiles.mutate(f.Player, function(data) data.Coins = 0; error("bad change") end) and record.Data.Coins == prior)
	check("explicit mutation rejection keeps current data", not f.Profiles.mutate(f.Player, function(data) data.Coins = 0; return false, "no" end) and record.Data.Coins == prior)
	check("successful cosmetic purchase updates ownership once", f.Profiles.mutate(f.Player, function(data) return Economy.purchase(data, "emote_cheer", false) end) and record.Data.Coins == 20 and record.Data.CosmeticsOwned.emote_cheer)
	f.ReturnWrongToken = true
	check("mismatched returned commit cannot report save confirmation", not f.Save() and record.LastSaveFailed and #f.Saved == 0)
	f.ReturnWrongToken = false
	check("retry confirms the correct commit token", f.Save() and not record.LastSaveFailed and #f.Saved == 1)
	f.Value.Session = "other-server"
	check("lost lease disables the writer without replacing another owner", not f.Save() and not record.Writable and f.Value.Session == "other-server")
	f = fixture({ Initial = { Data = raw() } })
	record = f.Load()
	f.Profiles.remove(f.Player)
	check("leaving persists progress releases lease and removes memory", f.Profiles.get(f.Player) == nil and f.Value.Session == nil and f.Value.Data.Coins == 100)
	f = fixture({ Initial = { Data = raw() } })
	f.Before = function() f.Online = false end
	check("leaving while load yields releases a newly acquired profile", f.Load() == nil and f.Value.Session == nil)
	f = fixture()
	f.Load()
	f.Profiles.close()
	check("shutdown releases records and rejects further loading", f.Profiles.get(f.Player) == nil and f.Value.Session == nil and f.Load() == nil)
	f = fixture()
	record = f.Load()
	f.HoldSpawns = true
	local started = f.Now
	check("shutdown gives slow saves a bounded twenty-five-second window", not f.Profiles.close() and f.Now - started >= 25 and f.Now - started < 25.2)
	check("all shutdown records pause purchases before asynchronous saving", record.Leaving and #f.Held == 1 and not f.Grant("shutdown", 10))
	f.Held[1]()
	check("slow save can still release its lease after the bounded wait", f.Profiles.get(f.Player) == nil and f.Value.Session == nil)
end

do
	-- Exercise the existing purchase dispatcher against the new real persistence
	-- controller, rather than a callback that merely pretends to grant a receipt.
	local f = fixture({ Initial = { Data = raw() } })
	local record = f.Load()
	f.Config.Commerce = {
		Products = { { Key = "coins100", Name = "100 monedas", ProductId = 101, Coins = 100 } },
		VIP = { Key = "vip", PassId = 201 },
	}
	local function event() return { Connect = function() return {} end } end
	local marketplace = { PromptProductPurchaseFinished = event(), PromptGamePassPurchaseFinished = event(),
		UserOwnsGamePassAsync = function() return false end, PromptProductPurchase = function() end }
	local commerce = Commerce.new({ Config = f.Config, GetProfile = f.Profiles.get, PersistentGrant = f.Profiles.grantReceipt,
		Players = { GetPlayerByUserId = function(_, id) return f.Online and id == 81 and f.Player or nil end, PlayerRemoving = event() },
		MarketplaceService = marketplace, PurchaseDecision = { PurchaseGranted = "GRANTED", NotProcessedYet = "PENDING" },
		Clock = function() return f.Now end, Warn = function() end,
	})
	commerce.start()
	local function receipt(id) return marketplace.ProcessReceipt({ PlayerId = 81, ProductId = 101, PurchaseId = id }) end
	check("existing Commerce grants through the new atomic profile controller", receipt("integration-A") == "GRANTED" and record.Data.Coins == 200 and f.Value.Data.Receipts["integration-A"] == 100)
	check("Commerce replay preserves the numeric historical receipt schema", receipt("integration-A") == "GRANTED" and record.Data.Coins == 200 and f.Value.Data.Receipts.legacy == 400)
	f.FailAfter = true
	check("Commerce returns pending when a durable write loses its response", receipt("integration-B") == "PENDING" and record.Data.Coins == 200 and f.Value.Data.Receipts["integration-B"] == 100)
	check("Commerce catalog pauses more purchases during recovery", not commerce.getCatalog(f.Player)[1].Available)
	check("profile autosave restores purchase availability after reconciliation", f.Save() and record.Data.Coins == 300 and commerce.getCatalog(f.Player)[1].Available)
	check("Commerce acknowledges the recovered receipt without another benefit", receipt("integration-B") == "GRANTED" and record.Data.Coins == 300)
	f.Online = false
	check("Commerce leaves offline receipts unresolved", receipt("integration-offline") == "PENDING" and f.Value.Data.Receipts["integration-offline"] == nil)
end

do
	local saved, queue, roster, instant, sawAllStarted = {}, {}, {}, 0, false
	local controller
	controller = Profiles.new({ Config = {}, Economy = Economy, Ledger = Ledger, SessionId = "shutdown-server",
		Now = function() return 2000000000 end, Clock = function() return instant end,
		Store = { UpdateAsync = function(_, key, transform)
			local result = transform(copy(saved[key])); if result then saved[key] = copy(result) end; return result
		end }, Warn = function() end,
		Tasks = { spawn = function(callback) table.insert(queue, callback) end,
			wait = function(seconds)
				instant += seconds
				sawAllStarted = #queue == 20
				local callbacks = queue; queue = {}
				for _, callback in ipairs(callbacks) do callback() end
			end },
	})
	for id = 1, 20 do
		local player = { UserId = id }
		table.insert(roster, player)
		local record = controller.load(player)
		record.Data.Coins = id
	end
	check("shutdown launches all twenty saves before waiting on any one", controller.close() and sawAllStarted and instant < 1)
	local complete = true
	for _, player in ipairs(roster) do
		local durable = saved["Player_" .. player.UserId]
		complete = complete and durable.Session == nil and durable.Data.Coins == player.UserId and controller.get(player) == nil
	end
	check("parallel shutdown keeps every player profile separate and releases all locks", complete)
end

print(string.format("All %d profiles checks passed.", passed))
