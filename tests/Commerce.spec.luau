-- Behavioral commerce checks without invoking the Roblox engine or billing.
local Commerce = require("../src/server/Commerce")

local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS commerce: " .. name)
end

local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			table.insert(callbacks, callback)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, callback in ipairs(callbacks) do callback(...) end
		end,
		Count = function() return #callbacks end,
	}
end

local function fixture(config)
	local player = { UserId = 81 }
	local f = {
		Player = player, Online = true, Time = 10, Queries = 0, Prompts = {},
		Notifications = {}, Refreshes = 0, GrantCalls = 0, Ownership = false,
		GrantResult = true, WarningCount = 0,
		Record = { Writable = true, Data = { Coins = 50 }, VIP = false },
	}
	f.Players = {
		GetPlayerByUserId = function(_, id)
			return f.Online and id == player.UserId and player or nil
		end,
		PlayerRemoving = signal(),
	}
	f.Marketplace = {
		PromptGamePassPurchaseFinished = signal(),
		PromptProductPurchaseFinished = signal(),
		UserOwnsGamePassAsync = function(_, userId, passId)
			assert(userId == 81 and passId == 902)
			f.Queries += 1
			if f.DuringOwnership then f.DuringOwnership() end
			if f.OwnershipThrows then error("API unavailable") end
			return f.Ownership
		end,
		PromptProductPurchase = function(_, who, id)
			if f.PromptThrows then error("Prompt unavailable") end
			table.insert(f.Prompts, { Player = who, Kind = "Product", Id = id })
		end,
		PromptGamePassPurchase = function(_, who, id)
			if f.PromptThrows then error("Prompt unavailable") end
			table.insert(f.Prompts, { Player = who, Kind = "Pass", Id = id })
		end,
	}
	f.Commerce = Commerce.new({
		Config = config or { Commerce = {
			Products = { { Key = "coins100", ProductId = 901, Name = "100 monedas", Coins = 100 } },
			VIP = { Key = "vip", PassId = 902 },
		} },
		Players = f.Players,
		MarketplaceService = f.Marketplace,
		GetProfile = function(who) return who == player and f.Record or nil end,
		PersistentGrant = function(who, receipt, product)
			f.GrantCalls += 1
			assert(who == player and receipt.PlayerId == who.UserId and product.ProductId == receipt.ProductId)
			if f.GrantThrows then error("Persistence unavailable") end
			if f.DurableGrant then return f.DurableGrant(who, receipt, product) end
			return f.GrantResult, "Compra guardada."
		end,
		Notify = function(_, message) table.insert(f.Notifications, message) end,
		Refresh = function()
			f.Refreshes += 1
			if f.RefreshThrows then error("Presentation failed") end
		end,
		Clock = function() return f.Time end,
		PurchaseDecision = { NotProcessedYet = "RETRY", PurchaseGranted = "GRANTED" },
		Warn = function() f.WarningCount += 1 end,
	})
	f.Commerce.start()
	f.Receipt = function(overrides)
		local receipt = { PlayerId = 81, ProductId = 901, PurchaseId = "purchase-example-1" }
		for key, value in pairs(overrides or {}) do receipt[key] = value end
		return f.Marketplace.ProcessReceipt(receipt)
	end
	return f
end

do
	local f = fixture()
	check("durable confirmation grants the matching configured product", f.Receipt() == "GRANTED" and f.GrantCalls == 1)
	check("successful commit updates presentation", f.Refreshes == 1 and #f.Notifications == 1)
	local callback = f.Marketplace.ProcessReceipt
	f.Commerce.start()
	check("start installs one receipt callback and one event listener", callback == f.Marketplace.ProcessReceipt and f.Marketplace.PromptProductPurchaseFinished.Count() == 1)
end

do
	local f = fixture()
	for _, invalid in ipairs({ 0, -1, 901.5, math.huge, -math.huge, 0 / 0, "901", true, {} }) do
		check("invalid receipt product IDs remain unresolved", f.Receipt({ ProductId = invalid }) == "RETRY")
	end
	check("unknown products are not acknowledged", f.Receipt({ ProductId = 999 }) == "RETRY")
	check("malformed receipt tables are not acknowledged", f.Marketplace.ProcessReceipt(nil) == "RETRY" and f.Marketplace.ProcessReceipt("bad") == "RETRY")
	check("invalid purchase identifiers are not acknowledged", f.Receipt({ PurchaseId = "" }) == "RETRY" and f.Receipt({ PurchaseId = 12 }) == "RETRY")
	check("invalid player identifiers are not acknowledged", f.Receipt({ PlayerId = 81.5 }) == "RETRY" and f.Receipt({ PlayerId = "81" }) == "RETRY")
	check("malformed receipts never reach persistence", f.GrantCalls == 0)
end

do
	local f = fixture()
	f.Online = false
	check("offline receipts remain unresolved", f.Receipt() == "RETRY")
	f.Online, f.Record.Ready = true, false
	check("unloaded profiles cannot receive a purchase", f.Receipt() == "RETRY")
	f.Record.Ready, f.Record.Writable = true, false
	check("readonly profiles cannot acknowledge a purchase", f.Receipt() == "RETRY")
	f.Record.Writable, f.GrantResult = true, false
	check("failed persistence remains unresolved", f.Receipt() == "RETRY")
	f.GrantResult = 1
	check("truthy values are not durable confirmation", f.Receipt() == "RETRY")
	f.GrantThrows = true
	check("persistence exceptions remain unresolved", f.Receipt() == "RETRY")
	f.GrantThrows, f.GrantResult, f.RefreshThrows = false, true, true
	check("presentation failure cannot revoke a durable purchase", f.Receipt() == "GRANTED")
end

do
	local f, durableReceipts, balance = fixture(), {}, 0
	f.DurableGrant = function(_, receipt, product)
		if not durableReceipts[receipt.PurchaseId] then
			durableReceipts[receipt.PurchaseId] = true
			balance += product.Coins
		end
		return true
	end
	check("first receipt credits through atomic persistence hook", f.Receipt() == "GRANTED" and balance == 100)
	check("duplicate callback delegates idempotence without re-crediting", f.Receipt() == "GRANTED" and balance == 100 and f.GrantCalls == 2)
end

do
	local f = fixture()
	local catalog = f.Commerce.getCatalog(f.Player)
	check("catalog exposes configured identity and no universal price", catalog[1].Id == 901 and catalog[1].Available == true and catalog[1].Price == nil)
	catalog[1].Id = 777
	check("client-facing catalog cannot mutate server IDs", f.Commerce.requestPurchase(f.Player, "Product", "coins100") and f.Prompts[1].Id == 901)
	check("opening a prompt does not credit currency", f.Record.Data.Coins == 50 and f.GrantCalls == 0)
	f.Marketplace.PromptProductPurchaseFinished:Fire(81, 901, true)
	check("product prompt success never credits currency", f.Record.Data.Coins == 50 and f.GrantCalls == 0)
	check("prompt close retains a short anti-spam cooldown", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 1)
	f.Time = 14
	check("another deliberate purchase is allowed after closing", f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 2)
	f.Time = 18
	check("unfinished prompt blocks overlapping dialogs", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 2)
	f.Marketplace.PromptProductPurchaseFinished:Fire(81, 999, true)
	check("unrelated close events cannot release an active prompt", not f.Commerce.requestPurchase(f.Player, "Product", "coins100"))
end

do
	local f = fixture()
	for _, kind in ipairs({ "product", "Asset", "Passes", true, {} }) do
		check("purchase kind is strictly allowlisted", not f.Commerce.requestPurchase(f.Player, kind, "coins100"))
	end
	check("raw product IDs are not accepted from clients", not f.Commerce.requestPurchase(f.Player, "Product", 901))
	check("unknown keys cannot prompt a purchase", not f.Commerce.requestPurchase(f.Player, "Product", "coins999"))
	f.Record.Writable = false
	check("Studio or failed persistence disables consumable purchases", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 0)
	check("readonly catalog marks consumables unavailable", f.Commerce.getCatalog(f.Player)[1].Available == false)
	f.Record.Writable, f.Record.Data.Coins = true, 100000000
	check("purchased currency is not silently lost at wallet limit", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and not f.Commerce.getCatalog(f.Player)[1].Available)
	f.Record.Data.Coins, f.PromptThrows = 0, true
	check("prompt API errors never grant a purchase", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and f.GrantCalls == 0)
	f.PromptThrows, f.Time = false, 14
	check("failed prompts release reservation for a later retry", f.Commerce.requestPurchase(f.Player, "Product", "coins100"))
end

do
	local f = fixture()
	check("ownership lookup alone confirms no VIP entitlement", f.Commerce.refreshPasses(f.Player) and f.Record.VIP == false)
	f.Marketplace.PromptGamePassPurchaseFinished:Fire(f.Player, 902, true)
	check("claimed pass purchase cannot override server ownership", f.Record.VIP == false and f.Queries == 2)
	f.Ownership = true
	f.Marketplace.PromptGamePassPurchaseFinished:Fire(f.Player, 902, false)
	check("verified pass ownership grants cosmetic entitlement", f.Record.VIP == true and f.Queries == 3)
	check("owned pass is marked owned in the catalog", f.Commerce.getCatalog(f.Player)[2].Owned == true)
	check("already-owned pass does not open another prompt", not f.Commerce.requestPurchase(f.Player, "Pass", "vip") and #f.Prompts == 0)
	f.OwnershipThrows = true
	check("ownership outage preserves previously confirmed VIP", not f.Commerce.refreshPasses(f.Player) and f.Record.VIP == true)
	local queries = f.Queries
	f.Marketplace.PromptGamePassPurchaseFinished:Fire(f.Player, 903, true)
	f.Marketplace.PromptGamePassPurchaseFinished:Fire({ UserId = 81 }, 902, true)
	check("unrelated passes and forged players do not refresh entitlement", f.Queries == queries)
end

do
	local f = fixture()
	local nestedResult
	f.DuringOwnership = function()
		f.DuringOwnership = nil
		nestedResult = f.Commerce.requestPurchase(f.Player, "Pass", "vip")
	end
	check("valid pass uses the server-configured pass ID", f.Commerce.requestPurchase(f.Player, "Pass", "vip") and f.Prompts[1].Id == 902)
	check("overlap during yielding ownership checks is blocked", nestedResult == false and #f.Prompts == 1)
	f.Time = 14
	f.Marketplace.PromptGamePassPurchaseFinished:Fire(f.Player, 902, false)
	check("cancelled pass dialog permits a later request", f.Commerce.requestPurchase(f.Player, "Pass", "vip") and #f.Prompts == 2)
	f.Players.PlayerRemoving:Fire(f.Player)
	check("departure clears stale purchase reservations", f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 3)
end

do
	local f = fixture()
	f.DuringOwnership = function() f.Online = false end
	check("player leaving during ownership lookup cannot prompt", not f.Commerce.requestPurchase(f.Player, "Pass", "vip") and #f.Prompts == 0)
	f = fixture()
	f.OwnershipThrows = true
	check("unconfirmed pass ownership cannot trigger a charge", not f.Commerce.requestPurchase(f.Player, "Pass", "vip") and #f.Prompts == 0)
end

do
	for _, field in ipairs({ "Saving", "Leaving", "PendingPaid", "UncertainReceipt", "LastSaveFailed" }) do
		local f = fixture()
		f.Record[field] = if field == "PendingPaid" then 100 else if field == "UncertainReceipt" then "older-purchase" else true
		check("pending state " .. field .. " disables new product prompts", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 0)
		check("pending state " .. field .. " disables catalog availability", not f.Commerce.getCatalog(f.Player)[1].Available)
		check("pending state " .. field .. " keeps existing receipt retry path", f.Receipt() == "GRANTED" and f.GrantCalls == 1)
		f.Record[field] = nil
		check("resolved state " .. field .. " restores product availability", f.Commerce.getCatalog(f.Player)[1].Available)
	end
	local f = fixture({ MaxReceipts = 2, Commerce = {
		Products = { { Key = "coins100", ProductId = 901, Coins = 100 } },
		VIP = { Key = "vip", PassId = 902 },
	} })
	f.Record.Data.Receipts = { ["older-purchase"] = 100 }
	check("receipt history below limit still allows purchases", f.Commerce.getCatalog(f.Player)[1].Available)
	f.Record.Data.Receipts["purchase-example-1"] = 100
	check("receipt history at limit disables new charges", not f.Commerce.requestPurchase(f.Player, "Product", "coins100") and #f.Prompts == 0 and not f.Commerce.getCatalog(f.Player)[1].Available)
	check("receipt history at limit keeps duplicate acknowledgement path", f.Receipt() == "GRANTED" and f.GrantCalls == 1)
	check("receipt history is preserved instead of purged", f.Record.Data.Receipts["older-purchase"] == 100 and f.Record.Data.Receipts["purchase-example-1"] == 100)
	f = fixture()
	f.Record.Data.Receipts = {}
	for index = 1, 10000 do f.Record.Data.Receipts[tostring(index)] = 100 end
	check("default receipt safety budget disables new charges at ten thousand", not f.Commerce.getCatalog(f.Player)[1].Available and not f.Commerce.requestPurchase(f.Player, "Product", "coins100"))
	f = fixture()
	check("absent optional status flags keep ordinary purchases enabled", f.Commerce.getCatalog(f.Player)[1].Available and f.Commerce.requestPurchase(f.Player, "Product", "coins100"))
end

do
	local f = fixture({ Commerce = { Products = {
		{ Key = "one", ProductId = 901, Coins = 100 },
		{ Key = "two", ProductId = 901, Coins = 400 },
	}, VIP = { PassId = 0 } } })
	check("duplicate developer product IDs fail closed with warnings", f.Receipt() == "RETRY" and f.WarningCount == 2)
	local catalog = f.Commerce.getCatalog(f.Player)
	check("ambiguous products and absent pass are unavailable", not catalog[1].Available and not catalog[2].Available and not catalog[3].Available)
	check("unconfigured VIP never performs an ownership request", f.Commerce.refreshPasses(f.Player) and f.Queries == 0 and not f.Record.VIP)
	f = fixture({ Commerce = { Products = {
		{ Key = "same", ProductId = 901, Coins = 100 },
		{ Key = "same", ProductId = 904, Coins = 400 },
	} } })
	check("duplicate purchase keys cannot select a different product", f.Receipt() == "RETRY" and not f.Commerce.requestPurchase(f.Player, "Product", "same"))
	f = fixture({ Commerce = { Products = { { Key = "bad", ProductId = 901, Coins = -100 } } } })
	check("invalid promised currency cannot activate a product", f.Receipt() == "RETRY" and not f.Commerce.getCatalog(f.Player)[1].Available)
	f = fixture({ Commerce = { Products = { { Key = "bad", ProductId = math.huge, Coins = 100 } } } })
	check("nonfinite configured IDs never reach Roblox purchase prompts", not f.Commerce.requestPurchase(f.Player, "Product", "bad") and #f.Prompts == 0)
end

print(string.format("All %d commerce checks passed.", passed))
