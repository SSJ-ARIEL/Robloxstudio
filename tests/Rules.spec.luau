-- Run from the repository root: luau tests/Rules.spec.luau
-- Behavioral checks for persistence sanitization and server-owned economics.
-- These tests deliberately send corrupted persistence and remote payload types.
local Rules: any = require("../src/shared/Rules")

local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS " .. name)
end

local palettes = {
	{ Cost = 0 },
	{ Cost = 80 },
	{ Cost = 150 },
	{ Cost = 220 },
}
local function fresh(coins)
	return Rules.cleanProfile({ Coins = coins }, #palettes)
end

do
	local profile = Rules.cleanProfile(nil, #palettes)
	check("new player gets usable free equipment", profile.Coins == 0 and profile.Wins == 0 and profile.Selected == 1 and profile.Owned["1"] == true)
end

do
	local safe = true
	local malformedProfiles: { any } = { false, "corrupt datastore", 19 }
	for _, corrupt in ipairs(malformedProfiles) do
		local profile = Rules.cleanProfile(corrupt, #palettes)
		safe = safe and profile.Coins == 0 and profile.Wins == 0 and profile.Selected == 1
	end
	check("non-table save data cannot grant progress", safe)
end

do
	local profile = Rules.cleanProfile({ Coins = 92.9, Wins = 3.8 }, #palettes)
	check("fractional stored progress becomes whole currency and wins", profile.Coins == 92 and profile.Wins == 3)
	profile = Rules.cleanProfile({ Coins = 1e12, Wins = 1e12 }, #palettes)
	check("finite oversized progress stays within persistence limits", profile.Coins == 100000000 and profile.Wins == 100000000)
end

do
	local safe = true
	local malformedProgress: { any } = { 0 / 0, math.huge, -math.huge, -15, "1000", false }
	for _, corrupt in ipairs(malformedProgress) do
		local profile = Rules.cleanProfile({ Coins = corrupt, Wins = corrupt }, #palettes)
		safe = safe and profile.Coins == 0 and profile.Wins == 0
	end
	check("NaN, infinity and malformed progress never become spendable", safe)
end

do
	local profile = Rules.cleanProfile({ Owned = { ["1"] = false, ["2"] = true, ["3"] = "true", ["4"] = 1, ["99"] = true, [2] = true } }, #palettes)
	check("ownership accepts only known persisted IDs with boolean true", profile.Owned["1"] == true and profile.Owned["2"] == true and profile.Owned["3"] == nil and profile.Owned["4"] == nil and profile.Owned["99"] == nil and profile.Owned[2] == nil)
	profile = Rules.cleanProfile({ Owned = "corrupt", Selected = 2 }, #palettes)
	check("malformed inventory cannot equip locked cosmetics", profile.Selected == 1 and profile.Owned["1"] == true and profile.Owned["2"] == nil)
end

do
	local safe = true
	local malformedSelection: { any } = { 3, 2.5, "2", 0 / 0, math.huge, -1 }
	for _, selected in ipairs(malformedSelection) do
		local profile = Rules.cleanProfile({ Owned = { ["2"] = true }, Selected = selected }, #palettes)
		safe = safe and profile.Selected == 1
	end
	check("invalid or unowned selected ID falls back to the free palette", safe)
	local profile = Rules.cleanProfile({ Owned = { ["2"] = true }, Selected = 2 }, #palettes)
	check("valid owned palette survives save loading", profile.Selected == 2)
end

do
	local raw = { Coins = 100, Owned = { ["2"] = true } }
	local profile = Rules.cleanProfile(raw, #palettes)
	profile.Owned["3"] = true
	raw.Owned["2"] = false
	check("loaded profile does not alias the original saved inventory", raw.Owned["3"] == nil and profile.Owned["2"] == true)
end

do
	local profile = fresh(79)
	local ok = Rules.purchase(profile, 2, palettes)
	check("insufficient funds leave coins, inventory and equipment untouched", not ok and profile.Coins == 79 and profile.Owned["2"] == nil and profile.Selected == 1)
	profile = fresh(80)
	ok = Rules.purchase(profile, 2, palettes)
	check("exact-price purchase deducts once and immediately equips", ok and profile.Coins == 0 and profile.Owned["2"] == true and profile.Selected == 2)
	ok = Rules.purchase(profile, 2, palettes)
	check("repeated equip cannot charge an already owned palette", ok and profile.Coins == 0 and profile.Selected == 2)
	ok = Rules.purchase(profile, 1, palettes)
	check("returning to free equipment preserves paid ownership", ok and profile.Coins == 0 and profile.Selected == 1 and profile.Owned["2"] == true)
end

do
	local safe = true
	local invalid: { any } = { "2", {}, false, 2.5, 0, -1, 99, 0 / 0, math.huge, -math.huge }
	for _, index in ipairs(invalid) do
		local profile = fresh(500)
		local ok = Rules.purchase(profile, index, palettes)
		safe = safe and not ok and profile.Coins == 500 and profile.Selected == 1 and profile.Owned["2"] == nil
	end
	local profile = fresh(500)
	local ok = Rules.purchase(profile, nil, palettes)
	check("malformed purchase payloads never charge or equip", safe and not ok and profile.Coins == 500 and profile.Selected == 1)
end

do
	local coins, wins = Rules.reward(true, true, true, 35, 10)
	check("contributing survivor receives victory reward", coins == 35 and wins == 1)
	coins, wins = Rules.reward(false, true, true, 35, 10)
	check("failed round pays participation without a win", coins == 10 and wins == 0)
	coins, wins = Rules.reward(true, true, false, 35, 10)
	check("eliminated contributor gets participation even when team wins", coins == 10 and wins == 0)
	coins, wins = Rules.reward(false, true, false, 35, 10)
	check("eliminated contributor retains participation after failure", coins == 10 and wins == 0)
	local safe = true
	for _, success in ipairs({ false, true }) do
		for _, alive in ipairs({ false, true }) do
			coins, wins = Rules.reward(success, false, alive, 35, 10)
			safe = safe and coins == 0 and wins == 0
		end
	end
	check("spectators and idle players cannot collect round rewards", safe)
end

assert(passed == 20, "Unexpected behavioral check count")
print(string.format("All %d behavioral checks passed.", passed))
