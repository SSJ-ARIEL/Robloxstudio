-- Server-owned, deterministic Robux purchases. Never grant from prompt events.
-- Persistence is deliberately delegated: currency and receipt ID must commit in
-- the same UpdateAsync before PersistentGrant returns true.
local Commerce = {}

local function positiveInteger(value)
	return type(value) == "number" and value == value and value > 0
		and value <= 9007199254740991 and value % 1 == 0
end

local function validKey(value)
	return type(value) == "string" and #value > 0 and #value <= 80
end

function Commerce.new(deps)
	assert(type(deps) == "table", "Commerce requires dependencies")
	assert(type(deps.GetProfile) == "function", "Commerce requires GetProfile")
	assert(type(deps.PersistentGrant) == "function", "Commerce requires atomic PersistentGrant")
	local config = deps.Config or {}
	local settings = type(config.Commerce) == "table" and config.Commerce or {}
	local marketplace, players = deps.MarketplaceService, deps.Players
	local decision = deps.PurchaseDecision or Enum.ProductPurchaseDecision
	local clock = deps.Clock or os.clock
	local warnMessage = deps.Warn or warn
	local notify = deps.Notify or function() end
	local refresh = deps.Refresh or function() end
	local maxCoins = positiveInteger(config.MaxCoins) and config.MaxCoins or 100000000
	local maxReceipts = positiveInteger(config.MaxReceipts) and config.MaxReceipts or 10000
	local products, productByKey, productById = {}, {}, {}
	local keyCounts, idCounts = {}, {}
	local lastRequests, pending = {}, {}
	local started = false
	local controller = {}

	for _, raw in ipairs(type(settings.Products) == "table" and settings.Products or {}) do
		if type(raw) == "table" and validKey(raw.Key) then
			local item = {
				Key = raw.Key,
				Kind = "Product",
				Name = type(raw.Name) == "string" and raw.Name or raw.Key,
				Description = type(raw.Description) == "string" and raw.Description or "Monedas para cosméticos de resultado conocido.",
				ProductId = raw.ProductId,
				Coins = raw.Coins,
			}
			table.insert(products, item)
			keyCounts[item.Key] = (keyCounts[item.Key] or 0) + 1
			if positiveInteger(item.ProductId) then
				idCounts[item.ProductId] = (idCounts[item.ProductId] or 0) + 1
			end
		end
	end
	for _, item in ipairs(products) do
		item.Valid = positiveInteger(item.ProductId) and positiveInteger(item.Coins)
			and item.Coins <= maxCoins and keyCounts[item.Key] == 1 and idCounts[item.ProductId] == 1
		if item.Valid then
			productById[item.ProductId], productByKey[item.Key] = item, item
		elseif keyCounts[item.Key] ~= 1 or (positiveInteger(item.ProductId) and idCounts[item.ProductId] ~= 1) then
			warnMessage("Color Chaos: producto desactivado por ID o clave duplicados: " .. item.Key)
		elseif item.ProductId ~= nil and item.ProductId ~= 0 then
			warnMessage("Color Chaos: configuración de producto inválida: " .. item.Key)
		end
	end
	local rawPass = type(settings.VIP) == "table" and settings.VIP or {}
	local pass = {
		Key = validKey(rawPass.Key) and rawPass.Key or "vip",
		Kind = "Pass",
		Name = type(rawPass.Name) == "string" and rawPass.Name or "VIP Prisma",
		Description = type(rawPass.Description) == "string" and rawPass.Description or "Distintivo y efectos cosméticos permanentes; no cambia las rondas.",
		PassId = rawPass.PassId,
		Valid = positiveInteger(rawPass.PassId),
	}

	local function online(player)
		return player ~= nil and positiveInteger(player.UserId)
			and players:GetPlayerByUserId(player.UserId) == player
	end

	local function loaded(player)
		if not online(player) then return nil end
		local record = deps.GetProfile(player)
		return record and record.Ready ~= false and record or nil
	end

	local function purchaseBusy(record)
		return record and (record.PendingPaid ~= nil or record.UncertainReceipt ~= nil
			or record.LastSaveFailed == true or record.Leaving == true or record.Saving == true)
	end

	local function hasReceiptRoom(record)
		local receipts = record and record.Data and record.Data.Receipts
		if type(receipts) ~= "table" then return true end
		local count = 0
		for _ in pairs(receipts) do
			count += 1
			if count >= maxReceipts then return false end
		end
		return true
	end

	local function roomForProduct(record, product)
		local coins = record and record.Data and record.Data.Coins
		return not purchaseBusy(record) and hasReceiptRoom(record)
			and type(coins) == "number" and coins == coins and coins >= 0
			and coins <= maxCoins - product.Coins
	end

	local function reject(player, message)
		notify(player, message)
		return false, message
	end

	function controller.getCatalog(player)
		local record, result = loaded(player), {}
		for _, product in ipairs(products) do
			table.insert(result, {
				Key = product.Key, Kind = "Product", Name = product.Name,
				Description = product.Description, Coins = product.Coins,
				Id = positiveInteger(product.ProductId) and product.ProductId or 0,
				Available = product.Valid and record ~= nil and record.Writable == true and roomForProduct(record, product),
				Owned = false,
			})
		end
		table.insert(result, {
			Key = pass.Key, Kind = "Pass", Name = pass.Name, Description = pass.Description,
			Id = positiveInteger(pass.PassId) and pass.PassId or 0,
			Available = pass.Valid and record ~= nil,
			Owned = record ~= nil and record.VIP == true,
		})
		return result
	end

	function controller.refreshPasses(player)
		local record = loaded(player)
		if not record then return false, "Tu perfil todavía no está disponible." end
		if not pass.Valid then
			record.VIP, record.VIPKnown = false, true
			return true
		end
		local ok, owns = pcall(function()
			return marketplace:UserOwnsGamePassAsync(player.UserId, pass.PassId)
		end)
		if not ok or type(owns) ~= "boolean" then
			return false, "Roblox no pudo confirmar tu pase. Intenta de nuevo más tarde."
		end
		-- A player may leave or obtain another profile while the API yields.
		if loaded(player) ~= record then return false, "Tu sesión cambió." end
		record.VIP, record.VIPKnown = owns, true
		pcall(refresh, player)
		return true
	end

	function controller.requestPurchase(player, kind, key)
		local record = loaded(player)
		if not record then return reject(player, "Espera a que termine de cargar tu perfil.") end
		if (kind ~= "Product" and kind ~= "Pass") or not validKey(key) then
			return reject(player, "Compra no válida.")
		end
		local now, userId = clock(), player.UserId
		if lastRequests[userId] and now - lastRequests[userId] < 3 then
			return false, "Espera un momento antes de abrir otra compra."
		end
		if pending[userId] and now - pending[userId].At < 90 then
			return false, "Termina o cierra la compra que tienes abierta."
		end
		local id, item
		if kind == "Product" then
			item = productByKey[key]
			if not item then return reject(player, "Este producto todavía no está configurado.") end
			if record.Writable ~= true then
				return reject(player, "Las compras requieren guardado activo. No se cobran productos en esta sesión.")
			end
			if purchaseBusy(record) then
				return reject(player, "Estamos confirmando tu progreso o una compra anterior. Espera antes de comprar otra vez.")
			end
			if not hasReceiptRoom(record) then
				return reject(player, "Este perfil alcanzó el límite seguro de compras. Puedes seguir jugando y usar tus monedas.")
			end
			if not roomForProduct(record, item) then
				return reject(player, "Gasta algunas monedas antes de comprar otro paquete.")
			end
			id = item.ProductId
		else
			if key ~= pass.Key or not pass.Valid then
				return reject(player, "Este pase todavía no está configurado.")
			end
			-- Ownership lookup yields too: reserve before it, not just before
			-- PromptGamePassPurchase, to prevent simultaneous pass requests.
			lastRequests[userId] = now
			pending[userId] = { Kind = kind, Id = pass.PassId, At = now }
			local verified, message = controller.refreshPasses(player)
			if not verified then
				pending[userId] = nil
				return reject(player, message)
			end
			if record.VIP == true then
				pending[userId] = nil
				return reject(player, "Ya tienes el pase VIP Prisma.")
			end
			id = pass.PassId
		end
		-- Reserve before a yielding platform prompt, so overlapping remotes cannot
		-- open multiple prompts. Only configured server IDs reach Marketplace.
		lastRequests[userId] = now
		pending[userId] = { Kind = kind, Id = id, At = now }
		local ok = pcall(function()
			if kind == "Product" then
				marketplace:PromptProductPurchase(player, id)
			else
				marketplace:PromptGamePassPurchase(player, id)
			end
		end)
		if not ok then
			pending[userId] = nil
			return reject(player, "Roblox no pudo abrir la compra. Intenta más tarde.")
		end
		return true, "Compra abierta en Roblox."
	end

	function controller.start()
		if started then return end
		started = true
		marketplace.ProcessReceipt = function(receipt)
			if type(receipt) ~= "table" or not positiveInteger(receipt.ProductId)
				or not positiveInteger(receipt.PlayerId) or type(receipt.PurchaseId) ~= "string"
				or #receipt.PurchaseId == 0 or #receipt.PurchaseId > 200 then
				return decision.NotProcessedYet
			end
			local product = productById[receipt.ProductId]
			if not product then return decision.NotProcessedYet end
			local player = players:GetPlayerByUserId(receipt.PlayerId)
			local record = loaded(player)
			if not record or record.Writable ~= true then return decision.NotProcessedYet end
			local ok, committed, message = pcall(deps.PersistentGrant, player, receipt, product)
			if not ok or committed ~= true then return decision.NotProcessedYet end
			-- Refresh failures cannot undo a receipt that already committed durably.
			pcall(refresh, player)
			if type(message) == "string" and #message > 0 then pcall(notify, player, message) end
			return decision.PurchaseGranted
		end
		marketplace.PromptProductPurchaseFinished:Connect(function(userId, productId)
			local request = pending[userId]
			if request and request.Kind == "Product" and request.Id == productId then
				pending[userId] = nil
			end
			-- Closing the prompt is never proof of payment. No rewards here.
		end)
		marketplace.PromptGamePassPurchaseFinished:Connect(function(player, passId)
			if not pass.Valid or passId ~= pass.PassId or not online(player) then return end
			local request = pending[player.UserId]
			if request and request.Kind == "Pass" and request.Id == passId then pending[player.UserId] = nil end
			local verified, message = controller.refreshPasses(player)
			if not verified then notify(player, message) end
		end)
		players.PlayerRemoving:Connect(function(player)
			lastRequests[player.UserId], pending[player.UserId] = nil, nil
		end)
	end

	return controller
end

return Commerce
