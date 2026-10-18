-- Real pure reward/catalogue code; these checks never call Roblox or bill users.
local Economy = require("../src/shared/Economy")
local Catalog = require("../src/shared/Catalog")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1; print("PASS economy: " .. name) end
local NOW = 2000000000
local CONFIG = { MaxCoins = 1000, DailyMissions = { { Key = "repair8", Metric = "Actions", Target = 8, Reward = 40 } } }
local function fresh(raw) return Economy.clean(raw, NOW, CONFIG) end

do
	local data = fresh({ Coins = 40, Wins = 7, Selected = 5, Owned = { ["1"] = true, ["8"] = true },
		Receipts = { earlier = 100 }, Progress = { XP = 360 }, CurrentStreak = 4 })
	check("legacy coins wins aura and numeric receipts survive migration", data.Coins == 40 and data.Wins == 7 and data.Selected == 5 and data.Owned["8"] and data.Receipts.earlier == 100)
	check("legacy XP survives and new earned-currency starts empty", data.Progress.XP == 360 and data.Gems == 0 and data.FreeGifts == 0)
	check("defaults include one free suit emote reaction and disabled trail", data.CosmeticsOwned.suit_base and data.CosmeticsOwned.emote_wave and data.CosmeticsOwned.reaction_star and data.Equipped.Trail == "trail_none")
	check("streak maximum cannot be smaller than current streak", data.BestStreak == 4)
	local view = Economy.view(data, NOW)
	check("public progress excludes paid receipts and derives level", view.Receipts == nil and view.Level == 4 and view.LevelProgress == 60)
	view.CosmeticsOwned.suit_mint = true
	view.Equipped.Suit = "suit_mint"
	check("public inventories cannot change server ownership", not data.CosmeticsOwned.suit_mint and data.Equipped.Suit == "suit_base")
	local dirty = fresh({ Coins = 0 / 0, Gems = math.huge, Wins = -5, FreeGifts = "10", CurrentStreak = -1,
		CosmeticsOwned = { suit_fake = true, suit_prism = true }, Equipped = { Suit = "suit_fake", Trail = "suit_mint" } })
	check("malformed progress cannot inject currencies cosmetics or slots", dirty.Coins == 0 and dirty.Gems == 0 and dirty.Wins == 0 and dirty.FreeGifts == 0 and dirty.Equipped.Suit == "suit_base" and not dirty.CosmeticsOwned.suit_prism)
end

do
	local data = fresh()
	for i = 1, 4 do Economy.correct(data, NOW, CONFIG) end
	check("four correct doors give deterministic coins XP and no gift", data.Coins == 32 and data.Progress.XP == 40 and data.CurrentStreak == 4 and data.FreeGifts == 0)
	local reward = Economy.correct(data, NOW, CONFIG)
	check("fifth consecutive correct door gives one free gift", reward.FreeGifts == 1 and data.FreeGifts == 1 and data.CurrentStreak == 5 and data.BestStreak == 5)
	local win = Economy.win(data, NOW, CONFIG)
	check("victory grants fixed coins gems XP and preserves streak", win.Coins == 60 and win.Gems == 10 and data.Wins == 1 and data.Coins == 100 and data.Progress.XP == 85 and data.CurrentStreak == 5)
	for i = 1, 5 do Economy.correct(data, NOW, CONFIG) end
	check("streak continues across victories and gifts again at ten", data.FreeGifts == 2 and data.CurrentStreak == 10 and data.BestStreak == 10)
	Economy.fail(data)
	check("a wrong answer resets current streak but not historical record", data.CurrentStreak == 0 and data.BestStreak == 10)
	Economy.correct(data, NOW, CONFIG)
	check("new streak cannot reclaim an old threshold instantly", data.CurrentStreak == 1 and data.FreeGifts == 2)
	data.Coins = 990
	reward = Economy.correct(data, NOW, CONFIG, 10)
	check("free reward reserves all room for an in-flight paid receipt", data.Coins == 990 and reward.Coins == 0)
	data.CurrentStreak, data.FreeGifts = 100000000, 0
	Economy.correct(data, NOW, CONFIG)
	check("streak saturation cannot repeatedly award threshold gifts", data.FreeGifts == 0)
end

do
	local data = fresh()
	check("time gift cannot be claimed before server time elapses", not Economy.claimTimeGift(data, "time2", NOW, CONFIG))
	check("client-like forged duration is capped per server tick", Economy.advanceTime(data, 9000, NOW) == 5 and data.Timers.Seconds == 5)
	check("invalid or negative elapsed time cannot earn gifts", Economy.advanceTime(data, 0 / 0, NOW) == 0 and Economy.advanceTime(data, -5, NOW) == 0 and Economy.advanceTime(data, math.huge, NOW) == 0)
	for i = 1, 23 do Economy.advanceTime(data, 5, NOW) end
	local ok, _, gift = Economy.claimTimeGift(data, "time2", NOW, CONFIG)
	check("two played minutes earn twenty diamonds", ok and gift.Gems == 20 and data.Gems == 20)
	check("claimed time reward cannot repeat within the day", not Economy.claimTimeGift(data, "time2", NOW, CONFIG) and data.Gems == 20)
	for i = 1, 216 do Economy.advanceTime(data, 5, NOW) end
	check("five-minute suit is permanent and requires no Robux", Economy.claimTimeGift(data, "time5", NOW, CONFIG) and data.CosmeticsOwned.suit_mint)
	check("ten-minute emote is permanent", Economy.claimTimeGift(data, "time10", NOW, CONFIG) and data.CosmeticsOwned.emote_spark)
	check("fifteen-minute reaction is permanent", Economy.claimTimeGift(data, "time15", NOW, CONFIG) and data.CosmeticsOwned.reaction_heart)
	check("twenty minutes gives one earned roll", Economy.claimTimeGift(data, "time20", NOW, CONFIG) and data.FreeGifts == 1)
	check("invalid milestone identifiers cannot claim a gift", not Economy.claimTimeGift(data, "time0", NOW, CONFIG))
	local view = Economy.view(data, NOW)
	check("gift view exposes claimed states and no negative countdown", #view.TimeGifts == 5 and view.TimeGifts[1].Claimed and view.TimeGifts[1].Remaining == 0)
	local future = NOW + 86400
	view = Economy.view(data, future)
	check("new day display resets eligibility even before timer ticks", not view.TimeGifts[1].Claimed and not view.TimeGifts[1].Ready and view.PlaySeconds == 0)
	Economy.advanceTime(data, 1, future)
	check("daily rollover resets time and claims while keeping cosmetics", data.Timers.Seconds == 1 and not data.Timers.Claimed.time2 and data.CosmeticsOwned.suit_mint)
	data.Timers.Seconds = 300
	ok, _, gift = Economy.claimTimeGift(data, "time5", future, CONFIG)
	check("duplicate daily cosmetic becomes fifteen diamonds", ok and gift.Duplicate and data.Gems == 35)
end

do
	local data = fresh({ Coins = 1000, Gems = 1000 })
	check("currencies cannot buy a random reward", not Economy.openGift(data, 1, 1, CONFIG) and data.Coins == 1000 and data.Gems == 1000)
	check("fixed-price cosmetic purchase grants and equips exact item", Economy.purchase(data, "suit_nova", false) and data.Coins == 820 and data.CosmeticsOwned.suit_nova and data.Equipped.Suit == "suit_nova")
	check("already-owned cosmetics are not charged again", Economy.purchase(data, "suit_nova", false) and data.Coins == 820)
	check("diamonds directly buy a known item", Economy.purchase(data, "trail_ocean", false) and data.Gems == 945 and data.Equipped.Trail == "trail_ocean")
	check("equipping an unowned item cannot buy it implicitly", not Economy.equip(data, "suit_meteor", false) and data.Gems == 945)
	check("VIP requires server-confirmed pass", not Economy.purchase(data, "suit_prism", false) and not Economy.equip(data, "trail_rainbow", false))
	check("verified VIP only unlocks cosmetic equipment", Economy.equip(data, "suit_prism", true) and data.Wins == 0 and data.CurrentStreak == 0 and data.Gems == 945)
	check("invalid cosmetic identifiers are rejected safely", not Economy.purchase(data, {}, true) and not Economy.equip(data, "fake", true))
	data.Coins, data.Gems = 0, 0
	check("insufficient coins or diamonds cannot partly spend", not Economy.purchase(data, "suit_coral", false) and not Economy.purchase(data, "suit_meteor", false) and data.Coins == 0 and data.Gems == 0)
end

do
	local frequency = {}
	for roll = 1, 100 do
		local data = fresh({ FreeGifts = 1 })
		local ok, _, reward = Economy.openGift(data, roll, 1, CONFIG)
		assert(ok and data.FreeGifts == 0, "single earned gift is consumed exactly once")
		frequency[reward.Kind] = (frequency[reward.Kind] or 0) + 1
		assert(not Economy.openGift(data, roll, 1, CONFIG), "same gift cannot be replayed")
	end
	check("every integer outcome exactly matches published category probabilities", frequency.Coins == 45 and frequency.Gems == 30 and frequency.Suit == 15 and frequency.Emote == 6 and frequency.Reaction == 4)
	local data = fresh({ FreeGifts = 2 })
	check("invalid random outcome keeps earned gift", not Economy.openGift(data, 101, 1, CONFIG) and not Economy.openGift(data, 1.5, 1, CONFIG) and data.FreeGifts == 2)
	check("invalid item outcome keeps earned gift", not Economy.openGift(data, 80, 0, CONFIG) and data.FreeGifts == 2)
	Economy.openGift(data, 80, 1, CONFIG)
	local ok, _, reward = Economy.openGift(data, 80, 1, CONFIG)
	check("duplicate random cosmetic grants deterministic diamonds", ok and reward.Duplicate and data.Gems == 15 and data.FreeGifts == 0)
	local counts, totalChance = {}, 0
	for _, item in ipairs(Catalog.Items) do
		counts[item.Kind] = (counts[item.Kind] or 0) + 1
		assert(Catalog.ById[item.Id] == item and (item.Currency == "Coins" or item.Currency == "Gems") and item.Cost >= 0)
	end
	for _, row in ipairs(Economy.GiftOdds) do totalChance += row.Chance end
	check("catalogue contains all promised categories and probabilities sum to 100", counts.Suit == 8 and counts.Emote == 6 and counts.Reaction == 8 and counts.Trail == 6 and totalChance == 100)
	for _, pool in pairs(Catalog.RewardPools) do
		for _, id in ipairs(pool) do assert(Catalog.ById[id].Access ~= "VIP" and Catalog.ById[id].Cost > 0) end
	end
	check("random pools contain real earned cosmetics and no paid-exclusive rewards", true)
end

print(string.format("All %d economy checks passed.", passed))
