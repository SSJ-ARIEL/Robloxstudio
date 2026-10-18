-- Pure, server-owned progress. Randomness is injected by the server; gifts are
-- earned only. Purchased Coins cannot buy rolls or change the answer.
local Catalog = if script then require(script.Parent.Catalog) else require("./Catalog")
local Ledger = if script then require(script.Parent.ProfileLedger) else require("./ProfileLedger")
local Progression = if script then require(script.Parent.Progression) else require("./Progression")
local Economy = {}
local MAX_COINS, MAX_GEMS, MAX_COUNT, MAX_XP = 100000000, 10000000, 100000000, 99900
Economy.TimeGifts = table.freeze({
	table.freeze({ Key = "time2", Seconds = 120, Name = "20 diamantes", Kind = "Gems", Amount = 20 }),
	table.freeze({ Key = "time5", Seconds = 300, Name = "Traje Explorador Menta", Kind = "Suit", ItemId = "suit_mint" }),
	table.freeze({ Key = "time10", Seconds = 600, Name = "Emote Vuelta Estelar", Kind = "Emote", ItemId = "emote_spark" }),
	table.freeze({ Key = "time15", Seconds = 900, Name = "Reacción Corazón", Kind = "Reaction", ItemId = "reaction_heart" }),
	table.freeze({ Key = "time20", Seconds = 1200, Name = "Regalo gratuito", Kind = "FreeGifts", Amount = 1 }),
})
Economy.GiftOdds = table.freeze({
	table.freeze({ Kind = "Coins", Chance = 45, Amount = 50 }),
	table.freeze({ Kind = "Gems", Chance = 30, Amount = 15 }),
	table.freeze({ Kind = "Suit", Chance = 15 }),
	table.freeze({ Kind = "Emote", Chance = 6 }),
	table.freeze({ Kind = "Reaction", Chance = 4 }),
})

local function whole(value, cap)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return 0 end
	return math.min(math.floor(value), cap)
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = copy(child) end; return result
end
local function day(now) return math.floor(whole(now, 100000000000) / 86400) end
local function coinCap(config)
	local configured = type(config) == "table" and whole(config.MaxCoins, MAX_COINS) or 0
	return configured > 0 and configured or MAX_COINS
end
local function addCoins(data, amount, config, reservedCoins)
	local received = math.min(amount, math.max(0, coinCap(config) - whole(reservedCoins, MAX_COINS) - data.Coins))
	data.Coins += received
	return received
end
local function addGems(data, amount)
	local received = math.min(amount, math.max(0, MAX_GEMS - data.Gems))
	data.Gems += received
	return received
end
local function refresh(data, now, config)
	if data.Timers.Day ~= day(now) then data.Timers = { Day = day(now), Seconds = 0, Claimed = {} } end
	data.Progress = Progression.clean(data.Progress, now, config)
end
local function addXP(data, amount) data.Progress.XP = math.min(MAX_XP, data.Progress.XP + amount) end
local function ownItem(data, id)
	local item = Catalog.ById[id]
	if data.CosmeticsOwned[id] then
		return { Kind = "Gems", Gems = addGems(data, 15), Amount = 15, ItemId = id, Name = item.Name, Duplicate = true }
	end
	data.CosmeticsOwned[id] = true
	return { Kind = item.Kind, ItemId = id, Name = item.Name, Duplicate = false }
end

function Economy.clean(raw, now, config)
	raw = type(raw) == "table" and raw or {}
	local owned = { ["1"] = true }
	-- Keep all former cosmetic entitlements, even when the new catalogue differs.
	for id, value in pairs(type(raw.Owned) == "table" and raw.Owned or {}) do
		if type(id) == "string" and #id <= 30 and value == true then owned[id] = true end
	end
	local selected = whole(raw.Selected, 100000)
	if selected < 1 then selected = 1 end
	local cosmetics, equipped = {}, {}
	for kind, id in pairs(Catalog.Defaults) do cosmetics[id], equipped[kind] = true, id end
	for id, value in pairs(type(raw.CosmeticsOwned) == "table" and raw.CosmeticsOwned or {}) do
		local item = Catalog.ById[id]
		if value == true and item and item.Access ~= "VIP" then cosmetics[id] = true end
	end
	for kind, id in pairs(type(raw.Equipped) == "table" and raw.Equipped or {}) do
		local item = type(id) == "string" and Catalog.ById[id] or nil
		if item and item.Kind == kind and (cosmetics[id] or item.Access == "VIP") then equipped[kind] = id end
	end
	local timer = type(raw.Timers) == "table" and raw.Timers or {}
	local timers = { Day = day(now), Seconds = 0, Claimed = {} }
	if timer.Day == timers.Day then
		timers.Seconds = whole(timer.Seconds, 86400)
		for _, gift in ipairs(Economy.TimeGifts) do
			if type(timer.Claimed) == "table" and timer.Claimed[gift.Key] == true then timers.Claimed[gift.Key] = true end
		end
	end
	local streak = whole(raw.CurrentStreak, MAX_COUNT)
	return {
		Coins = whole(raw.Coins, coinCap(config)), Gems = whole(raw.Gems, MAX_GEMS), Wins = whole(raw.Wins, MAX_COUNT),
		Selected = selected, Owned = owned, Receipts = Ledger.cleanReceipts(raw.Receipts),
		Progress = Progression.clean(raw.Progress, now, config), BestStreak = math.max(streak, whole(raw.BestStreak, MAX_COUNT)),
		CurrentStreak = streak, CorrectDoors = whole(raw.CorrectDoors, MAX_COUNT),
		CosmeticsOwned = cosmetics, Equipped = equipped, FreeGifts = whole(raw.FreeGifts, 1000000), Timers = timers,
	}
end

function Economy.correct(data, now, config, reservedCoins)
	refresh(data, now, config)
	local previous = data.CurrentStreak
	data.CurrentStreak = math.min(MAX_COUNT, previous + 1)
	data.BestStreak = math.max(data.BestStreak, data.CurrentStreak)
	data.CorrectDoors = math.min(MAX_COUNT, data.CorrectDoors + 1)
	data.Progress.Counts.Actions = math.min(1000000, data.Progress.Counts.Actions + 1)
	addXP(data, 10)
	local gifts = if data.CurrentStreak > previous and data.CurrentStreak % 5 == 0 and data.FreeGifts < 1000000 then 1 else 0
	data.FreeGifts += gifts
	return { Coins = addCoins(data, 8, config, reservedCoins), XP = 10, Streak = data.CurrentStreak, FreeGifts = gifts }
end

function Economy.fail(data) data.CurrentStreak = 0 end

function Economy.win(data, now, config, reservedCoins)
	refresh(data, now, config)
	data.Wins = math.min(MAX_COUNT, data.Wins + 1)
	data.Progress.Counts.Wins = math.min(1000000, data.Progress.Counts.Wins + 1)
	data.Progress.Counts.Rounds = math.min(1000000, data.Progress.Counts.Rounds + 1)
	addXP(data, 35)
	return { Coins = addCoins(data, 60, config, reservedCoins), Gems = addGems(data, 10), XP = 35, Wins = 1 }
end

function Economy.advanceTime(data, dt, now)
	if data.Timers.Day ~= day(now) then data.Timers = { Day = day(now), Seconds = 0, Claimed = {} } end
	if type(dt) ~= "number" or dt ~= dt or dt <= 0 or dt == math.huge then return 0 end
	local elapsed = math.min(dt, 5, 86400 - data.Timers.Seconds)
	data.Timers.Seconds += elapsed
	return elapsed
end

function Economy.claimTimeGift(data, key, now, config, reservedCoins)
	refresh(data, now, config)
	for _, gift in ipairs(Economy.TimeGifts) do
		if gift.Key == key then
			if data.Timers.Claimed[key] then return false, "Ya recogiste este regalo hoy." end
			if data.Timers.Seconds < gift.Seconds then return false, "Sigue jugando para desbloquear este regalo." end
			local reward
			if gift.ItemId then reward = ownItem(data, gift.ItemId)
			elseif gift.Kind == "Gems" then reward = { Kind = "Gems", Gems = addGems(data, gift.Amount), Amount = gift.Amount }
			elseif gift.Kind == "FreeGifts" then
				if data.FreeGifts >= 1000000 then return false, "Abre uno de tus regalos antes de recoger este." end
				data.FreeGifts += gift.Amount
				reward = { Kind = "FreeGifts", FreeGifts = gift.Amount, Amount = gift.Amount }
			end
			data.Timers.Claimed[key] = true
			return true, "Regalo recogido: " .. gift.Name .. ".", reward
		end
	end
	return false, "Regalo no disponible."
end

function Economy.openGift(data, roll, itemRoll, config, reservedCoins)
	if data.FreeGifts < 1 then return false, "Gana cinco aciertos seguidos para conseguir un regalo gratis." end
	if type(roll) ~= "number" or roll % 1 ~= 0 or roll < 1 or roll > 100 then return false, "No se pudo abrir el regalo." end
	local selected, boundary = nil, 0
	for _, chance in ipairs(Economy.GiftOdds) do
		boundary += chance.Chance
		if roll <= boundary then selected = chance; break end
	end
	local reward
	if selected.Kind == "Coins" then reward = { Kind = "Coins", Coins = addCoins(data, 50, config, reservedCoins), Amount = 50 }
	elseif selected.Kind == "Gems" then reward = { Kind = "Gems", Gems = addGems(data, 15), Amount = 15 }
	else
		local pool = Catalog.RewardPools[selected.Kind]
		if type(itemRoll) ~= "number" or itemRoll % 1 ~= 0 or itemRoll < 1 or itemRoll > #pool then return false, "No se pudo abrir el regalo." end
		reward = ownItem(data, pool[itemRoll])
	end
	data.FreeGifts -= 1
	local label = reward.Name or (reward.Amount .. (reward.Kind == "Coins" and " monedas" or " diamantes"))
	if reward.Duplicate then label = "15 diamantes por cosmético repetido" end
	return true, "Tu regalo: " .. label .. ".", reward
end

function Economy.purchase(data, id, vip)
	local item = type(id) == "string" and Catalog.ById[id] or nil
	if not item then return false, "Cosmético no disponible." end
	if item.Access == "VIP" then
		if vip ~= true then return false, "Este cosmético pertenece al pase VIP Prisma." end
	elseif not data.CosmeticsOwned[id] then
		if data[item.Currency] < item.Cost then return false, item.Currency == "Coins" and "Necesitas más monedas." or "Necesitas más diamantes. Puedes ganarlos jugando." end
		data[item.Currency] -= item.Cost
		data.CosmeticsOwned[id] = true
	end
	data.Equipped[item.Kind] = id
	return true, item.Name .. " equipado."
end

function Economy.equip(data, id, vip)
	local item = type(id) == "string" and Catalog.ById[id] or nil
	if not item then return false, "Cosmético no disponible." end
	if item.Access == "VIP" then
		if vip ~= true then return false, "Este cosmético pertenece al pase VIP Prisma." end
	elseif not data.CosmeticsOwned[id] then return false, "Todavía no tienes este cosmético." end
	data.Equipped[item.Kind] = id
	return true, item.Name .. " equipado."
end

function Economy.view(data, now)
	local timers = if data.Timers.Day == day(now) then data.Timers else { Seconds = 0, Claimed = {} }
	local gifts = {}
	for _, gift in ipairs(Economy.TimeGifts) do
		local row = copy(gift)
		row.Claimed = timers.Claimed[gift.Key] == true
		row.Ready = timers.Seconds >= gift.Seconds and not row.Claimed
		row.Remaining = math.max(0, math.ceil(gift.Seconds - timers.Seconds))
		table.insert(gifts, row)
	end
	return {
		Coins = data.Coins, Gems = data.Gems, Wins = data.Wins, XP = data.Progress.XP,
		Level = math.min(1000, math.floor(data.Progress.XP / 100) + 1), LevelProgress = data.Progress.XP % 100,
		BestStreak = data.BestStreak, CurrentStreak = data.CurrentStreak, Streak = data.CurrentStreak,
		CorrectDoors = data.CorrectDoors, FreeGifts = data.FreeGifts, CosmeticsOwned = copy(data.CosmeticsOwned),
		Equipped = copy(data.Equipped), Selected = data.Selected, Owned = copy(data.Owned),
		TimeGifts = gifts, PlaySeconds = math.floor(timers.Seconds), GiftOdds = copy(Economy.GiftOdds),
	}
end

return Economy
