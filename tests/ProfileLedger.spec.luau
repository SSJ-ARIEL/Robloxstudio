-- Pure receipt ledger tests: exercise durable commits whose acknowledgements
-- fail, stale autosave snapshots, and gameplay changes while a save yields.
local Ledger = require("../src/shared/ProfileLedger")
local LIMIT = 1000
local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS " .. name)
end
local function fresh(coins)
	return {
		Coins = coins or 100,
		Wins = 2,
		Selected = 1,
		Owned = { ["1"] = true },
		Receipts = {},
		Progress = { XP = 80, Day = 20000, Counts = { Rounds = 2, Actions = 4, Wins = 1 }, Claimed = {} },
	}
end

do
	local localData, persisted = fresh(), fresh()
	local committed, granted = Ledger.grant(localData, persisted, "receipt-A", 50, LIMIT)
	check("new receipt credits currency and writes its exact amount together", committed ~= nil and granted == true and committed.Coins == 150 and committed.Receipts["receipt-A"] == 50)
	check("grant never mutates caller or persisted inputs", localData.Coins == 100 and persisted.Coins == 100 and next(localData.Receipts) == nil and next(persisted.Receipts) == nil)
	local replay, replayGranted = Ledger.grant(committed, committed, "receipt-A", 50, LIMIT)
	check("receipt replay credits zero additional currency", replay ~= nil and replayGranted == false and replay.Coins == 150 and replay.Receipts["receipt-A"] == 50)
	replay, replayGranted = Ledger.grant(localData, committed, "receipt-A", 50, LIMIT)
	check("ambiguous commit recovery credits a stale local snapshot only once", replay ~= nil and replayGranted == false and replay.Coins == 150 and replay.Receipts["receipt-A"] == 50)
	replay, replayGranted = Ledger.grant(localData, committed, "receipt-A", 500, LIMIT)
	check("changing product price cannot rewrite an already committed receipt", replay ~= nil and replayGranted == false and replay.Coins == 150 and replay.Receipts["receipt-A"] == 50)
	local second, secondGranted = Ledger.grant(committed, committed, "receipt-B", 75, LIMIT)
	check("distinct receipts each credit their own configured amount", second ~= nil and secondGranted == true and second.Coins == 225 and second.Receipts["receipt-A"] == 50 and second.Receipts["receipt-B"] == 75)
end

do
	local stale = fresh()
	local committed = Ledger.grant(stale, fresh(), "receipt-A", 50, LIMIT)
	local autosave = Ledger.merge(stale, committed, LIMIT)
	check("autosave after lost commit acknowledgement retains purchased credit", autosave ~= nil and autosave.Coins == 150 and autosave.Receipts["receipt-A"] == 50)
	local repeated = Ledger.merge(autosave, committed, LIMIT)
	check("repeated autosave cannot add the same recovered receipt again", repeated ~= nil and repeated.Coins == 150)
	stale.Coins = 70
	stale.Wins = 4
	stale.Progress.XP = 140
	stale.Progress.Counts.Actions = 8
	stale.Progress.Claimed.repair8 = true
	stale.Owned["2"] = true
	stale.Selected = 2
	local recovered = Ledger.reconcile(stale, autosave, LIMIT)
	check("reconciliation preserves free currency spending while save yielded", recovered == 50 and stale.Coins == 120 and stale.Receipts["receipt-A"] == 50)
	check("reconciliation preserves concurrent victories, missions and equipment", stale.Wins == 4 and stale.Progress.XP == 140 and stale.Progress.Counts.Actions == 8 and stale.Progress.Claimed.repair8 == true and stale.Owned["2"] == true and stale.Selected == 2)
	local again = Ledger.reconcile(stale, autosave, LIMIT)
	check("reconciliation is idempotent after recovering a receipt", again == 0 and stale.Coins == 120 and stale.Progress.XP == 140)
	local finalSave = Ledger.merge(stale, autosave, LIMIT)
	check("later autosave preserves spending instead of restoring old balance", finalSave ~= nil and finalSave.Coins == 120)
	stale.Receipts["receipt-B"] = 75
	check("in-place reconciliation leaves committed state independent", autosave.Coins == 150 and autosave.Progress.XP == 80 and autosave.Receipts["receipt-B"] == nil)
end

do
	local localData = fresh(110)
	localData.Receipts["receipt-A"] = 50
	local persisted = fresh(225)
	persisted.Receipts["receipt-A"] = 50
	persisted.Receipts["receipt-B"] = 75
	local merged = Ledger.merge(localData, persisted, LIMIT)
	check("merge adds only paid receipts missing from its base snapshot", merged ~= nil and merged.Coins == 185 and merged.Receipts["receipt-A"] == 50 and merged.Receipts["receipt-B"] == 75)
	localData.Receipts["receipt-C"] = 30
	localData.Coins = 140
	merged = Ledger.merge(localData, persisted, LIMIT)
	check("merge retains receipts known only by the local snapshot", merged ~= nil and merged.Coins == 215 and merged.Receipts["receipt-C"] == 30 and merged.Receipts["receipt-B"] == 75)
	merged.Progress.Counts.Rounds = 99
	merged.Progress.Claimed.play3 = true
	merged.Owned["3"] = true
	merged.Receipts["receipt-D"] = 100
	check("merged nested profile data and receipt ledger are independent copies", localData.Progress.Counts.Rounds == 2 and localData.Progress.Claimed.play3 == nil and localData.Owned["3"] == nil and localData.Receipts["receipt-D"] == nil and persisted.Receipts["receipt-D"] == nil)
end

do
	local base = fresh(950)
	local cap, granted = Ledger.grant(base, base, "receipt-cap", 50, LIMIT)
	check("purchase at exact currency cap retains all paid currency", cap ~= nil and granted == true and cap.Coins == LIMIT)
	local failed = Ledger.grant(cap, cap, "receipt-overflow", 1, LIMIT)
	check("overflow rejects the receipt without truncating purchased currency", failed == nil and cap.Coins == LIMIT and cap.Receipts["receipt-overflow"] == nil)
	local duplicate, duplicateGranted = Ledger.grant(cap, cap, "receipt-cap", 50, LIMIT)
	check("already committed receipt remains acknowledged at currency cap", duplicate ~= nil and duplicateGranted == false and duplicate.Coins == LIMIT)
	local stale = fresh(980)
	local persisted = fresh()
	persisted.Receipts["receipt-missing"] = 50
	check("overflow during recovery aborts instead of marking unpaid truncation", Ledger.merge(stale, persisted, LIMIT) == nil and stale.Coins == 980 and stale.Receipts["receipt-missing"] == nil)
end

do
	local safe = true
	for _, id in ipairs({ "", string.rep("x", 201), false, 123, {} }) do
		local result = Ledger.grant(fresh(), fresh(), id, 50, LIMIT)
		safe = safe and result == nil
	end
	check("invalid receipt identifiers cannot be granted", safe and Ledger.grant(fresh(), fresh(), nil, 50, LIMIT) == nil)
	safe = true
	for _, amount in ipairs({ 0, -1, 1.5, "50", false, 0 / 0, math.huge, -math.huge, 1001 }) do
		safe = safe and Ledger.grant(fresh(), fresh(), "receipt-invalid", amount, LIMIT) == nil
	end
	check("invalid configured amounts cannot create or mark paid currency", safe and Ledger.grant(fresh(), fresh(), "receipt-invalid", nil, LIMIT) == nil)
end

do
	local uncommitted = fresh()
	uncommitted.Receipts["receipt-local"] = 50
	check("receipt present only in local memory cannot be acknowledged as durable", Ledger.grant(uncommitted, fresh(), "receipt-local", 50, LIMIT) == nil)
	local cleaned = Ledger.cleanReceipts({ ["good"] = 50, ["empty"] = 0, ["negative"] = -1, ["fraction"] = 0.5, ["string"] = "50", ["boolean"] = true, ["infinite"] = math.huge, ["nan"] = 0 / 0, [1] = 50, [""] = 50, [string.rep("x", 201)] = 50 })
	local count = 0
	for _ in pairs(cleaned) do count += 1 end
	check("stored ledger accepts only valid receipt IDs and integer positive amounts", count == 1 and cleaned.good == 50)
	check("malformed stored receipt ledgers normalize safely", next(Ledger.cleanReceipts(nil)) == nil and next(Ledger.cleanReceipts(false)) == nil and next(Ledger.cleanReceipts("corrupt")) == nil)
end

assert(passed == 25, "Unexpected profile ledger check count")
print(string.format("All %d profile ledger checks passed.", passed))
