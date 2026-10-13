-- Currency, reentry credits and their receipts always commit together.
-- Never prune receipt IDs: old Roblox callbacks must remain idempotent.
local Ledger = {}

local function integer(value)
	return type(value) == "number" and value == value and value >= 0
		and value < math.huge and value % 1 == 0
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

local function validGrant(value)
	return type(value) == "table" and integer(value.Coins) and integer(value.Credits)
		and value.Coins + value.Credits > 0
end

function Ledger.cleanReceipts(raw)
	local result = {}
	if type(raw) ~= "table" then return result end
	for id, grant in pairs(raw) do
		if type(id) == "string" and #id > 0 and #id <= 200 and validGrant(grant) then
			result[id] = { Coins = grant.Coins, Credits = grant.Credits }
		end
	end
	return result
end

function Ledger.validReceipts(raw)
	if raw == nil then return true end
	if type(raw) ~= "table" then return false end
	for id, grant in pairs(raw) do
		if type(id) ~= "string" or #id == 0 or #id > 200 or not validGrant(grant) then return false end
	end
	return true
end

function Ledger.merge(base, persisted, maxCoins, maxCredits)
	if type(base) ~= "table" or not integer(base.Coins) or not integer(base.ReviveCredits)
		or not Ledger.validReceipts(base.Receipts) then return nil end
	if type(persisted) == "table" and not Ledger.validReceipts(persisted.Receipts) then return nil end
	local result = copy(base)
	result.Receipts = Ledger.cleanReceipts(base.Receipts)
	for id, grant in pairs(Ledger.cleanReceipts(type(persisted) == "table" and persisted.Receipts or nil)) do
		if result.Receipts[id] == nil then
			result.Coins += grant.Coins
			result.ReviveCredits += grant.Credits
		end
		result.Receipts[id] = grant
	end
	if result.Coins > maxCoins or result.ReviveCredits > maxCredits then return nil end
	return result
end

function Ledger.grant(base, persisted, receiptId, grant, maxCoins, maxCredits)
	if type(receiptId) ~= "string" or #receiptId == 0 or #receiptId > 200 or not validGrant(grant) then return nil end
	local result = Ledger.merge(base, persisted, maxCoins, maxCredits)
	if not result then return nil end
	local receipts = Ledger.cleanReceipts(type(persisted) == "table" and persisted.Receipts or nil)
	if receipts[receiptId] then return result, false end
	if result.Receipts[receiptId] then return nil end -- unpersisted local IDs are not payment proof
	if result.Coins + grant.Coins > maxCoins or result.ReviveCredits + grant.Credits > maxCredits then return nil end
	result.Coins += grant.Coins
	result.ReviveCredits += grant.Credits
	result.Receipts[receiptId] = { Coins = grant.Coins, Credits = grant.Credits }
	return result, true
end

function Ledger.reconcile(localData, committed, maxCoins, maxCredits)
	local merged = Ledger.merge(localData, committed, maxCoins, maxCredits)
	if not merged then return nil end
	local recovered = { Coins = merged.Coins - localData.Coins, Credits = merged.ReviveCredits - localData.ReviveCredits }
	localData.Coins, localData.ReviveCredits, localData.Receipts = merged.Coins, merged.ReviveCredits, merged.Receipts
	return recovered
end

return Ledger
