-- Paid grants and their receipt IDs live in the SAME atomic profile update.
-- Merge protects receipts even if a committed UpdateAsync loses its response.
local Ledger = {}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

function Ledger.cleanReceipts(raw)
	local result = {}
	if type(raw) ~= "table" then return result end
	for id, amount in pairs(raw) do
		if type(id) == "string" and #id > 0 and #id <= 200 and type(amount) == "number"
			and amount == amount and amount > 0 and amount < math.huge and amount % 1 == 0 then
			result[id] = amount
		end
	end
	return result
end

function Ledger.merge(base, persisted, maxCoins)
	local result = copy(base)
	result.Receipts = Ledger.cleanReceipts(base.Receipts)
	for id, amount in pairs(Ledger.cleanReceipts(type(persisted) == "table" and persisted.Receipts or nil)) do
		if result.Receipts[id] == nil then
			result.Coins += amount
			result.Receipts[id] = amount
		end
		-- The durable record is authoritative even if local metadata is damaged.
		result.Receipts[id] = amount
	end
	if result.Coins > maxCoins then return nil end
	return result
end

function Ledger.grant(base, persisted, receiptId, amount, maxCoins)
	if type(receiptId) ~= "string" or #receiptId == 0 or #receiptId > 200 then return nil end
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge or amount % 1 ~= 0 then return nil end
	local result = Ledger.merge(base, persisted, maxCoins)
	if not result then return nil end
	local receipts = Ledger.cleanReceipts(type(persisted) == "table" and persisted.Receipts or nil)
	if receipts[receiptId] then return result, false end
	if result.Receipts[receiptId] then return nil end -- never trust an unpersisted ID
	if result.Coins + amount > maxCoins then return nil end
	result.Coins += amount
	result.Receipts[receiptId] = amount
	return result, true
end

function Ledger.reconcile(localData, committed, maxCoins)
	local merged = Ledger.merge(localData, committed, maxCoins)
	if not merged then return nil end
	local recovered = merged.Coins - localData.Coins
	localData.Coins, localData.Receipts = merged.Coins, merged.Receipts
	return recovered
end

return Ledger
