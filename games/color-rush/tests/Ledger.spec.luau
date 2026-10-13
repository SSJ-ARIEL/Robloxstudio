local Ledger = require("../src/shared/Ledger")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1; print("PASS ledger: " .. name) end
local function fresh(coins, credits)
	return { Coins = coins or 100, ReviveCredits = credits or 2, Wins = 1, Receipts = {},
		SelectedTrail = 1, OwnedTrails = { ["1"] = true }, Progress = { XP = 20, Counts = { Wins = 0 } } }
end
local function grant(base, old, id, coins, credits) return Ledger.grant(base, old, id, { Coins = coins, Credits = credits }, 1000, 10) end

do
	local base, old = fresh(), fresh()
	local committed, isNew = grant(base, old, "A", 50, 3)
	check("both currencies and receipt metadata commit together", committed and isNew and committed.Coins == 150 and committed.ReviveCredits == 5 and committed.Receipts.A.Coins == 50 and committed.Receipts.A.Credits == 3)
	check("input records are never mutated", base.Coins == 100 and base.ReviveCredits == 2 and next(old.Receipts) == nil)
	local replay, replayNew = grant(base, committed, "A", 500, 8)
	check("lost acknowledgment recovery uses original durable amounts", replay and not replayNew and replay.Coins == 150 and replay.ReviveCredits == 5 and replay.Receipts.A.Coins == 50)
	local repeated = Ledger.merge(replay, committed, 1000, 10)
	check("repeated reconciliation is idempotent", repeated and repeated.Coins == 150 and repeated.ReviveCredits == 5)
	base.Coins, base.ReviveCredits, base.Wins = 70, 1, 3
	base.Progress.XP, base.OwnedTrails["2"] = 60, true
	local recovered = Ledger.reconcile(base, committed, 1000, 10)
	check("concurrent free spending and credit consumption survive receipt recovery", recovered and recovered.Coins == 50 and recovered.Credits == 3 and base.Coins == 120 and base.ReviveCredits == 4)
	check("concurrent wins and cosmetics survive", base.Wins == 3 and base.Progress.XP == 60 and base.OwnedTrails["2"] == true)
	local consumed = Ledger.merge(base, committed, 1000, 10)
	check("later autosave does not restore spent paid credits", consumed and consumed.ReviveCredits == 4 and consumed.Coins == 120)
	check("durable record retains independent nested metadata", committed.ReviveCredits == 5 and committed.Progress.XP == 20 and committed.OwnedTrails["2"] == nil)
end

do
	local base = fresh(950, 9)
	local exact = grant(base, base, "cap", 50, 1)
	check("exact currency and credit cap preserves all paid value", exact and exact.Coins == 1000 and exact.ReviveCredits == 10)
	check("coin overflow refuses purchase without inserting receipt", grant(exact, exact, "overflow", 1, 0) == nil and exact.Receipts.overflow == nil)
	check("credit overflow refuses purchase without inserting receipt", grant(exact, exact, "overflow", 0, 1) == nil and exact.Receipts.overflow == nil)
	local replay, isNew = grant(exact, exact, "cap", 50, 1)
	check("duplicates remain acknowledged at both caps", replay and isNew == false and replay.Coins == 1000 and replay.ReviveCredits == 10)
	local unsafe = fresh(990, 10)
	check("overflow recovery refuses silent truncation", Ledger.merge(unsafe, exact, 1000, 10) == nil and unsafe.Coins == 990)
end

do
	local localOnly = fresh()
	localOnly.Receipts.fake = { Coins = 10, Credits = 1 }
	check("local-only receipt cannot masquerade as durable proof", grant(localOnly, fresh(), "fake", 10, 1) == nil)
	for _, amount in ipairs({ -1, 1.5, math.huge, 0 / 0, false, "1" }) do
		check("invalid coin grant rejected", grant(fresh(), fresh(), "bad", amount, 0) == nil)
		check("invalid credit grant rejected", grant(fresh(), fresh(), "bad", 0, amount) == nil)
	end
	check("zero-value purchase rejected", grant(fresh(), fresh(), "zero", 0, 0) == nil)
	for _, id in ipairs({ "", string.rep("x", 201), 4, false }) do
		check("malformed receipt ID rejected", grant(fresh(), fresh(), id, 10, 0) == nil)
	end
	check("malformed stored receipt metadata fails closed", Ledger.merge(fresh(), { Receipts = { broken = true } }, 1000, 10) == nil)
	check("missing legacy receipt field is valid", Ledger.validReceipts(nil))
	check("string receipt history is invalid", not Ledger.validReceipts("bad"))
	check("cleaned receipts retain only exact valid grants", Ledger.cleanReceipts({ ok = { Coins = 0, Credits = 1 }, bad = { Coins = 0, Credits = 0 } }).ok.Credits == 1)
end

print(string.format("All %d ledger checks passed.", passed))
