-- Ciudad Prisma: presentation only. Physical movement selects a door;
-- the server owns answers, gifts, progression and every purchase.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local function required(parent, name)
	local child = parent:WaitForChild(name, 20)
	assert(child, "Color Chaos: falta " .. parent.Name .. "." .. name)
	return child
end
local shared = required(ReplicatedStorage, "ColorChaos")
local Config = require(required(shared, "Config"))
local Characters = require(required(shared, "Characters"))
local Portrait = require(required(shared, "Portrait"))
local Catalog = require(required(shared, "Catalog"))
local remotes = required(shared, "Remotes")
local stateEvent, actionEvent = required(remotes, "State"), required(remotes, "Action")
local latest, lastRequests = {}, {}
local currentPage, currentTab, albumPage = nil, nil, 1
local renderPage, showPage, refreshSpectator, redrawWorld, adaptScreen
local spectating, observedId = false, nil
local worldCards, worldSignature, referenceSignature = {}, "", ""
local quoteCache, quotePending, quoteButtons = {}, {}, {}
local toastSerial, renderedProfile = 0, ""
local C = {
	Ink = Color3.fromRGB(19, 29, 56), Panel = Color3.fromRGB(27, 41, 72),
	Card = Color3.fromRGB(37, 54, 86), Muted = Color3.fromRGB(178, 194, 214),
	White = Color3.fromRGB(249, 246, 233), Mint = Color3.fromRGB(102, 232, 204),
	Lilac = Color3.fromRGB(190, 169, 255), Gold = Color3.fromRGB(255, 211, 111),
	Rose = Color3.fromRGB(255, 145, 169), Line = Color3.fromRGB(66, 87, 119),
}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "ColorChaosUI", false
gui.ZIndexBehavior, gui.DisplayOrder = Enum.ZIndexBehavior.Sibling, 10
gui:SetAttribute("Ready", false)
gui.Parent = player:WaitForChild("PlayerGui")

local function corners(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius, item.Parent = UDim.new(0, radius or 14), parent
end
local function stroke(parent, color, thickness)
	local item = Instance.new("UIStroke")
	item.Color, item.Thickness, item.Transparency = color or C.Line, thickness or 1, 0.25
	item.Parent = parent
	return item
end
local function frame(parent, name, position, size, color)
	local item = Instance.new("Frame")
	item.Name, item.Position, item.Size = name, position, size
	item.BorderSizePixel, item.BackgroundColor3 = 0, color or C.Panel
	item.Parent = parent
	corners(item)
	return item
end
local function label(parent, name, content, position, size, textSize, color)
	local item = Instance.new("TextLabel")
	item.Name, item.Text, item.Position, item.Size = name, content, position, size
	item.BackgroundTransparency, item.TextColor3 = 1, color or C.White
	item.TextSize, item.Font = textSize or 16, Enum.Font.GothamMedium
	item.TextWrapped, item.TextXAlignment = true, Enum.TextXAlignment.Left
	item.Parent = parent
	return item
end
local function fit(item, minimum, maximum)
	item.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize = minimum or 11, maximum or item.TextSize
	limit.Parent = item
	return item
end
local function button(parent, name, content, position, size, callback, color)
	local item = Instance.new("TextButton")
	item.Name, item.Text, item.Position, item.Size = name, content, position, size
	item.BorderSizePixel, item.BackgroundColor3 = 0, color or C.Card
	item.TextColor3, item.Font, item.TextSize = C.White, Enum.Font.GothamBold, 14
	item.TextWrapped, item.AutoButtonColor = true, true
	item.Parent = parent
	corners(item, 11)
	item.Activated:Connect(callback)
	return item
end
local function viewport(parent, name, position, size)
	local item = Instance.new("ViewportFrame")
	item.Name, item.Position, item.Size = name, position, size
	item.BackgroundTransparency, item.BorderSizePixel = 1, 0
	item.Parent = parent
	return item
end
local function number(value)
	value = math.max(0, math.floor(tonumber(value) or 0))
	if value >= 1000000 then return string.format("%.1f M", value / 1000000) end
	if value >= 10000 then return string.format("%.1f mil", value / 1000) end
	return tostring(value)
end
local function duration(value)
	value = math.max(0, math.ceil(tonumber(value) or 0))
	return string.format("%d:%02d", math.floor(value / 60), value % 60)
end
local function profile() return type(latest.Profile) == "table" and latest.Profile or {} end
local function send(action, payload, cooldown)
	local now = os.clock()
	if now - (lastRequests[action] or -100) < (cooldown or 0.35) then return end
	lastRequests[action] = now
	actionEvent:FireServer(action, payload)
end
local toast = frame(gui, "Toast", UDim2.new(0.5, 0, 0, 108), UDim2.new(0.86, 0, 0, 56))
toast.AnchorPoint, toast.Visible, toast.ZIndex = Vector2.new(0.5, 0), false, 50
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize, toastLimit.Parent = Vector2.new(560, 70), toast
stroke(toast, C.Mint)
local toastText = fit(label(toast, "Message", "", UDim2.fromOffset(15, 8), UDim2.new(1, -30, 1, -16), 16), 12, 16)
local function showToast(message)
	if type(message) ~= "string" or message == "" then return end
	toastSerial += 1
	local serial = toastSerial
	toastText.Text, toast.Visible = message, true
	task.delay(4.5, function() if toastSerial == serial then toast.Visible = false end end)
end

-- Compact HUD keeps the five paths visible and mobile controls accessible.
local hud = frame(gui, "RoundHUD", UDim2.new(0.5, 0, 0, 8), UDim2.new(0.94, 0, 0, 88))
hud.AnchorPoint, hud.BackgroundTransparency = Vector2.new(0.5, 0), 0.04
local hudLimit = Instance.new("UISizeConstraint")
hudLimit.MaxSize, hudLimit.Parent = Vector2.new(820, 88), hud
stroke(hud)
local brand = fit(label(hud, "Brand", "COLOR CHAOS", UDim2.fromOffset(15, 9), UDim2.new(0.43, 0, 0, 23), 20), 12, 20)
brand.Font = Enum.Font.GothamBlack
local phaseLabel = fit(label(hud, "Phase", "CIUDAD PRISMA", UDim2.new(0.43, 0, 0, 9), UDim2.new(0.4, -8, 0, 23), 13, C.Mint), 10, 13)
phaseLabel.TextXAlignment = Enum.TextXAlignment.Right
local timer = label(hud, "Timer", "--", UDim2.new(1, -64, 0, 8), UDim2.fromOffset(49, 26), 24, C.Gold)
timer.TextXAlignment, timer.Font = Enum.TextXAlignment.Right, Enum.Font.GothamBold
local messageLabel = fit(label(hud, "Message", "Bienvenido a Ciudad Prisma", UDim2.fromOffset(15, 36), UDim2.new(1, -30, 0, 23), 15), 11, 15)
local roundLabel = fit(label(hud, "Details", "Explora, recuerda y cruza la puerta correcta", UDim2.fromOffset(15, 63), UDim2.new(1, -30, 0, 17), 12, C.Muted), 10, 12)
local stageBar = frame(hud, "StageProgress", UDim2.new(0, 0, 1, -3), UDim2.new(1, 0, 0, 3), C.Line)
local stageFill = frame(stageBar, "Fill", UDim2.fromScale(0, 0), UDim2.fromScale(0, 1), C.Mint)
local wallet = frame(gui, "Wallet", UDim2.new(0, 14, 1, -60), UDim2.fromOffset(246, 46))
local walletText = fit(label(wallet, "Balances", "0 monedas · 0 diamantes", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 20), 13, C.Gold), 10, 13)
local levelText = fit(label(wallet, "Level", "Nivel 1 · Racha 0", UDim2.fromOffset(10, 25), UDim2.new(1, -20, 0, 16), 11, C.Muted), 9, 11)
local menuButton = button(gui, "Menu", "MENÚ", UDim2.new(0.5, -56, 1, -59), UDim2.fromOffset(112, 44), function()
	showPage(if currentPage then nil else "Inicio")
end, C.Panel)
stroke(menuButton, C.Mint)
local quickButton = button(gui, "QuickEmote", "GESTOS", UDim2.new(0.5, 64, 1, -59), UDim2.fromOffset(92, 44), function() showPage("Armario", "Emote") end)
local spectator = frame(gui, "SpectatorControls", UDim2.new(0.5, 0, 1, -110), UDim2.fromOffset(340, 42))
spectator.AnchorPoint, spectator.Visible = Vector2.new(0.5, 0), false
local ghostButton = button(spectator, "Ghost", "Jugar fantasma", UDim2.fromOffset(4, 4), UDim2.fromOffset(136, 34), function()
	send(if latest.Mode == "GHOST" then "LeaveGhost" else "EnterGhost")
	spectating = false
	refreshSpectator()
end)
local observeButton = button(spectator, "Observe", "Observar", UDim2.fromOffset(145, 4), UDim2.fromOffset(121, 34), function()
	spectating = not spectating
	refreshSpectator()
end)
local nextObserved = button(spectator, "NextObserved", ">", UDim2.fromOffset(271, 4), UDim2.fromOffset(65, 34), function()
	local ids = latest.SpectatorIds or {}
	local index = table.find(ids, observedId) or 0
	observedId = ids[(index % math.max(1, #ids)) + 1]
	spectating = true
	refreshSpectator()
end)
local reference = frame(gui, "ReferenceCard", UDim2.fromOffset(14, 108), UDim2.fromOffset(144, 178), C.White)
reference.Visible = false
local refBorder = stroke(reference, C.Mint, 2)
local refHeading = fit(label(reference, "Heading", "RECUERDA", UDim2.fromOffset(8, 7), UDim2.new(1, -16, 0, 19), 14, C.Ink), 11, 14)
refHeading.TextXAlignment, refHeading.Font = Enum.TextXAlignment.Center, Enum.Font.GothamBold
local refView = viewport(reference, "Portrait", UDim2.fromOffset(4, 25), UDim2.new(1, -8, 1, -54))
local refName = fit(label(reference, "CharacterName", "", UDim2.new(0, 8, 1, -29), UDim2.new(1, -16, 0, 24), 11, C.Ink), 9, 12)
refName.TextXAlignment = Enum.TextXAlignment.Center

local giftReveal = frame(gui, "GiftReveal", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(300, 254), C.Panel)
giftReveal.AnchorPoint, giftReveal.Visible, giftReveal.ZIndex = Vector2.new(0.5, 0.5), false, 40
stroke(giftReveal, C.Gold, 2)
local giftScale = Instance.new("UIScale")
giftScale.Parent = giftReveal
local giftTag = label(giftReveal, "Tag", "TU REGALO GRATUITO", UDim2.fromOffset(14, 14), UDim2.new(1, -28, 0, 24), 13, C.Mint)
giftTag.TextXAlignment, giftTag.Font = Enum.TextXAlignment.Center, Enum.Font.GothamBold
local giftIcon = label(giftReveal, "Icon", "✦", UDim2.fromOffset(14, 43), UDim2.new(1, -28, 0, 65), 54, C.Gold)
giftIcon.TextXAlignment = Enum.TextXAlignment.Center
local giftName = fit(label(giftReveal, "Name", "", UDim2.fromOffset(16, 111), UDim2.new(1, -32, 0, 43), 22), 14, 22)
giftName.TextXAlignment, giftName.Font = Enum.TextXAlignment.Center, Enum.Font.GothamBold
local giftNote = label(giftReveal, "Note", "Ya está en tu colección", UDim2.fromOffset(14, 159), UDim2.new(1, -28, 0, 31), 12, C.Muted)
giftNote.TextXAlignment = Enum.TextXAlignment.Center
local giftTween
button(giftReveal, "CloseGift", "¡GENIAL!", UDim2.new(0.5, -75, 1, -54), UDim2.fromOffset(150, 40), function() giftReveal.Visible = false end, C.Card)

-- One reusable window. Album portraits exist only while their page is open.
local overlay = frame(gui, "Overlay", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.new(0, 0, 0))
overlay.BackgroundTransparency, overlay.Visible, overlay.ZIndex = 0.30, false, 20
local panel = frame(overlay, "Panel", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.93, 0.84), C.Ink)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize, panelLimit.Parent = Vector2.new(820, 640), panel
stroke(panel)
local panelTitle = fit(label(panel, "Title", "CIUDAD PRISMA", UDim2.fromOffset(18, 7), UDim2.new(1, -124, 0, 29), 24), 16, 24)
panelTitle.Font = Enum.Font.GothamBold
local panelWallet = fit(label(panel, "Balance", "0 monedas · 0 diamantes", UDim2.fromOffset(18, 38), UDim2.new(1, -36, 0, 17), 12, C.Gold), 10, 12)
button(panel, "Close", "Cerrar", UDim2.new(1, -92, 0, 12), UDim2.fromOffset(76, 34), function() showPage(nil) end)
local backButton = button(panel, "Back", "< Menú", UDim2.fromOffset(14, 63), UDim2.fromOffset(82, 36), function() showPage("Inicio") end)
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name, tabBar.Position, tabBar.Size = "Tabs", UDim2.fromOffset(104, 63), UDim2.new(1, -118, 0, 43)
tabBar.BackgroundTransparency, tabBar.BorderSizePixel, tabBar.ScrollBarThickness = 1, 0, 2
tabBar.ScrollingDirection, tabBar.AutomaticCanvasSize = Enum.ScrollingDirection.X, Enum.AutomaticSize.X
tabBar.CanvasSize, tabBar.Parent = UDim2.fromOffset(0, 0), panel
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection, tabLayout.Padding, tabLayout.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 7), tabBar
local content = Instance.new("ScrollingFrame")
content.Name, content.Position, content.Size = "Content", UDim2.fromOffset(14, 114), UDim2.new(1, -28, 1, -128)
content.BackgroundTransparency, content.BorderSizePixel, content.ScrollBarThickness = 1, 0, 5
content.ScrollBarImageColor3 = C.Lilac
content.CanvasSize, content.AutomaticCanvasSize = UDim2.fromOffset(0, 0), Enum.AutomaticSize.Y
content.ScrollingDirection, content.Parent = Enum.ScrollingDirection.Y, panel
local function clear(parent)
	for _, child in ipairs(parent:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
end
local function tabs(entries, selected)
	clear(tabBar)
	for _, item in ipairs(entries) do
		local key, title = item[1], item[2]
		local b = button(tabBar, key, title, UDim2.fromOffset(0, 0), UDim2.fromOffset(math.max(90, #title * 7 + 26), 36), function()
			currentTab = key; renderPage()
		end, if key == selected then C.Mint else C.Card)
		if key == selected then b.TextColor3 = C.Ink end
	end
end
local function row(y, height, title, subtitle, accent)
	local item = frame(content, "Row", UDim2.fromOffset(0, y), UDim2.new(1, -7, 0, height))
	frame(item, "Accent", UDim2.fromOffset(0, 12), UDim2.fromOffset(3, height - 24), accent or C.Mint)
	fit(label(item, "Title", title, UDim2.fromOffset(15, 10), UDim2.new(1, -156, 0, 26), 16), 11, 16)
	label(item, "Description", subtitle, UDim2.fromOffset(15, 38), UDim2.new(1, -156, 1, -45), 12, C.Muted)
	return item
end
local function paragraph(y, title, body, height)
	local item = frame(content, "Paragraph", UDim2.fromOffset(0, y), UDim2.new(1, -7, 0, height))
	fit(label(item, "Title", title, UDim2.fromOffset(15, 12), UDim2.new(1, -30, 0, 28), 18, C.Mint), 12, 18)
	local bodyLabel = label(item, "Body", body, UDim2.fromOffset(15, 47), UDim2.new(1, -30, 1, -58), 14, C.Muted)
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	return item
end
local function rowButton(parent, title, callback, enabled, accent)
	local b = button(parent, "Action", title, UDim2.new(1, -134, 0.5, -20), UDim2.fromOffset(120, 40), function()
		if enabled ~= false then callback() end
	end, if enabled == false then C.Card else accent or C.Mint)
	b.TextColor3 = if enabled == false then C.Muted else C.Ink
	return b
end
local kindNames = { Suit = "Traje", Trail = "Estela", Emote = "Gesto", Reaction = "Reacción" }
local function owned(item)
	return (profile().CosmeticsOwned or {})[item.Id] == true or (item.Access == "VIP" and (profile().VIP or latest.VIP) == true)
end
local function commerceCatalog()
	local list = latest.Commerce or {}
	return list.Catalog or list
end
local function updateQuoteButtons(key)
	for _, entry in ipairs(quoteButtons[key] or {}) do
		if entry.Button.Parent then
			entry.Button.Text = if entry.Owned then "Ya lo tienes" elseif not entry.Available then "No disponible" elseif quoteCache[key] then "R$ " .. quoteCache[key] else "Ver precio"
		end
	end
end
local function fetchQuote(offer)
	if type(offer.Id) ~= "number" or offer.Id <= 0 then return end
	local key = offer.Kind .. ":" .. tostring(offer.Id)
	if quotePending[key] or quoteCache[key] then return end
	quotePending[key] = true
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(offer.Id, if offer.Kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		quotePending[key] = nil
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then quoteCache[key] = info.PriceInRobux end
		updateQuoteButtons(key)
	end)
end
local function renderHome()
	tabs({}, nil)
	local p = profile()
	paragraph(0, "Tu próxima puerta empieza aquí", "Memoriza el color durante dos segundos. Elige uno de los cinco caminos. Acierta, cruza la puerta y sigue avanzando por Ciudad Prisma.", 148)
	local entries = {
		{ "Tienda", "TIENDA", "Cosméticos con monedas, diamantes o Robux.", C.Gold },
		{ "Armario", "ARMARIO", "Tus trajes, estelas, gestos, reacciones y auras.", C.Lilac },
		{ "Regalos", "REGALOS", "Gratis por tiempo y cinco aciertos seguidos.", C.Mint },
		{ "Clasificación", "CLASIFICACIÓN", "Tu sala y las mejores marcas del mundo.", C.Gold },
		{ "Álbum", "ÁLBUM 3D", "250 habitantes originales de Prisma.", C.Lilac },
		{ "Ayuda", "CÓMO JUGAR", "Puertas, fantasmas, regalos y final.", C.Mint },
	}
	for i, item in ipairs(entries) do
		local card = row(160 + (i - 1) * 94, 84, item[2], item[3], item[4])
		rowButton(card, "Abrir", function() showPage(item[1]) end, true, item[4])
	end
	label(content, "Stats", string.format("%s victorias · Mejor racha %s · Nivel %s", number(p.Wins), number(p.BestStreak), number(p.Level or 1)), UDim2.fromOffset(7, 728), UDim2.new(1, -14, 0, 38), 13, C.Muted)
end
local function renderShop()
	currentTab = currentTab or "Gratis"
	tabs({ { "Gratis", "Monedas / diamantes" }, { "Robux", "Robux" } }, currentTab)
	if currentTab == "Robux" then
		paragraph(0, "Compras de resultado conocido", "Monedas para cosméticos o el pase VIP Prisma. Roblox muestra el precio de tu cuenta y pide confirmación antes de cobrar.", 146)
		for i, offer in ipairs(commerceCatalog()) do
			local description = if offer.Kind == "Pass" then "Pase permanente: aura, título y estilos VIP." else number(offer.Coins) .. " monedas para auras y estilos."
			local item = row(158 + (i - 1) * 130, 118, offer.Name or offer.Key, description, C.Gold)
			local enabled = offer.Available == true and offer.Owned ~= true
			local b = rowButton(item, if offer.Owned then "Ya lo tienes" elseif enabled then "Ver precio" else "No disponible", function()
				send("Purchase", { Kind = offer.Kind, Key = offer.Key }, 2)
			end, enabled, C.Gold)
			local key = tostring(offer.Kind) .. ":" .. tostring(offer.Id)
			quoteButtons[key] = quoteButtons[key] or {}
			table.insert(quoteButtons[key], { Button = b, Owned = offer.Owned, Available = offer.Available })
			updateQuoteButtons(key)
			if enabled then fetchQuote(offer) end
		end
		return
	end
	paragraph(0, "Se consiguen jugando", "Gana monedas y diamantes con tus aciertos y regalos. Cada cosmético es un objeto concreto de tu armario; elige el que más te guste.", 146)
	local index = 0
	for _, cosmetic in ipairs(Catalog.Items) do
		if cosmetic.Cost > 0 then
			index += 1
			local price = number(cosmetic.Cost) .. (if cosmetic.Currency == "Gems" then " diamantes" else " monedas")
			local item = row(158 + (index - 1) * 108, 96, cosmetic.Name, (kindNames[cosmetic.Kind] or "Cosmético") .. " · " .. price, if cosmetic.Currency == "Gems" then C.Lilac else C.Gold)
			rowButton(item, if owned(cosmetic) then "Ya lo tienes" else "Desbloquear", function() send("BuyCosmetic", cosmetic.Id) end, not owned(cosmetic))
		end
	end
end
local function renderWardrobe()
	currentTab = currentTab or "Suit"
	tabs({ { "Suit", "Trajes" }, { "Trail", "Estelas" }, { "Emote", "Gestos" }, { "Reaction", "Reacciones" }, { "Aura", "Auras" } }, currentTab)
	if currentTab == "Aura" then
		local p = profile()
		for i, palette in ipairs(Config.Palettes or {}) do
			local has = (p.Owned or {})[tostring(i)] == true or (p.Owned or {})[i] == true or palette.Access == "VIP" and (p.VIP or latest.VIP) == true
			local selected = p.Selected == i
			local item = row((i - 1) * 106, 96, palette.Name, if palette.Access == "VIP" then "Incluida con VIP Prisma" elseif has then "Forma parte de tu colección" else number(palette.Cost) .. " monedas", C.Lilac)
			rowButton(item, if selected then "Puesta" elseif has then "Equipar" elseif palette.Access == "VIP" then "VIP" else "Desbloquear", function() send("Palette", i) end, not selected and (palette.Access ~= "VIP" or has), C.Lilac)
		end
		return
	end
	local index = 0
	for _, cosmetic in ipairs(Catalog.Items) do
		if cosmetic.Kind == currentTab then
			index += 1
			local has, selected = owned(cosmetic), (profile().Equipped or {})[cosmetic.Kind] == cosmetic.Id
			local title = cosmetic.Name .. (if selected then " · puesto" else "")
			local description = if cosmetic.Access == "VIP" then "Incluido con VIP Prisma" elseif has then "Disponible en tu colección" else "Consíguelo en regalos o tienda"
			local item = row((index - 1) * 106, 96, title, description, if has then C.Lilac else C.Line)
			local usable = cosmetic.Kind == "Emote" or cosmetic.Kind == "Reaction"
			rowButton(item, if not has then "Bloqueado" elseif usable then "Usar" elseif selected then "Puesto" else "Equipar", function()
				if usable then send(cosmetic.Kind, cosmetic.Id, 1) else send("EquipCosmetic", { Kind = cosmetic.Kind, Id = cosmetic.Id }) end
			end, has and (usable or not selected), C.Lilac)
		end
	end
end
local function renderGifts()
	currentTab = currentTab or "Tiempo"
	tabs({ { "Tiempo", "Por tiempo" }, { "Racha", "Por racha" }, { "Premios", "Probabilidades" } }, currentTab)
	local p = profile()
	if currentTab == "Tiempo" then
		paragraph(0, "El tiempo también tiene premio", "Tu tiempo cuenta en el lobby, la partida y como fantasma. Reclama los regalos disponibles. Vuelve a esta ventana para ver cuánto falta.", 146)
		for i, gift in ipairs(p.TimeGifts or {}) do
			local item = row(158 + (i - 1) * 102, 92, gift.Name, "A los " .. math.floor(gift.Seconds / 60) .. " minutos de juego", C.Mint)
			local b = rowButton(item, if gift.Claimed then "Reclamado" elseif gift.Ready then "Reclamar" else duration(gift.Remaining), function() send("ClaimTimeGift", gift.Key, 0.75) end, gift.Ready and not gift.Claimed)
			b:SetAttribute("TimeGiftId", gift.Key)
		end
	elseif currentTab == "Racha" then
		local streak, count = p.Streak or 0, p.FreeGifts or 0
		paragraph(0, "Cinco aciertos, una sorpresa", "Cada cinco aciertos consecutivos recibes un regalo aleatorio gratuito. Fallar reinicia la racha. Ganar conserva tu racha para la próxima partida.", 158)
		local item = row(170, 100, "Racha actual: " .. number(streak), tostring(streak % 5) .. " / 5 hacia el próximo regalo", C.Lilac)
		rowButton(item, if count > 0 then "Abrir (" .. number(count) .. ")" else "Sin regalos", function() send("OpenGift", nil, 0.8) end, count > 0, C.Lilac)
		paragraph(282, "La suerte es un regalo", "Estos regalos se ganan jugando. No se compran con Robux ni con monedas. Los fantasmas no obtienen aciertos ni regalos de racha.", 146)
	else
		paragraph(0, "Todos los resultados a la vista", "Cada regalo elige un tipo de premio de esta lista. Los cosméticos de cada tipo tienen la misma probabilidad. Si ya tienes el cosmético, recibes 15 diamantes.", 170)
		for i, reward in ipairs(p.GiftOdds or {}) do
			local title = if reward.Kind == "Coins" then number(reward.Amount) .. " monedas" elseif reward.Kind == "Gems" then number(reward.Amount) .. " diamantes" else kindNames[reward.Kind] or reward.Kind
			local count = #(Catalog.RewardPools[reward.Kind] or {})
			local detail = if count > 0 then tostring(count) .. " opciones · " .. string.format("%.2f%%", reward.Chance / count) .. " cada una" else "Cantidad garantizada al salir este resultado"
			local item = row(182 + (i - 1) * 100, 90, title, detail, C.Lilac)
			local odds = label(item, "Odds", string.format("%g%%", reward.Chance), UDim2.new(1, -130, 0, 12), UDim2.fromOffset(116, 58), 22, C.Mint)
			odds.TextXAlignment = Enum.TextXAlignment.Center
		end
	end
end
local function renderBoards()
	currentTab = currentTab or "Room"
	tabs({ { "Room", "Esta sala" }, { "Wins", "Global: victorias" }, { "Streak", "Global: racha" }, { "Level", "Global: nivel" } }, currentTab)
	local isRoom, boards = currentTab == "Room", latest.GlobalBoards or {}
	local values = if isRoom then latest.RoomBoard or {} else boards[currentTab] or {}
	values = values.Rows or values
	local status = if isRoom then "Esta partida · Aciertos y orden de llegada" else latest.LeaderboardStatus or boards.Status or "Las marcas globales se actualizan periódicamente"
	label(content, "BoardStatus", tostring(status), UDim2.fromOffset(6, 0), UDim2.new(1, -12, 0, 40), 12, C.Muted)
	for i, entry in ipairs(values) do
		local item = frame(content, "Rank" .. i, UDim2.fromOffset(0, 48 + (i - 1) * 66), UDim2.new(1, -7, 0, 58), if entry.UserId == player.UserId then C.Card else C.Panel)
		local rank = label(item, "Rank", tostring(entry.Rank or i), UDim2.fromOffset(8, 5), UDim2.fromOffset(36, 46), 23, if i <= 3 then C.Gold else C.Muted)
		rank.TextXAlignment = Enum.TextXAlignment.Center
		fit(label(item, "Name", entry.DisplayName or entry.Name or "Jugador", UDim2.fromOffset(50, 7), UDim2.new(1, -180, 0, 25), 16), 11, 16)
		local detail = if isRoom then (if entry.Alive then "En carrera" else "En el lobby") else "Ciudad Prisma"
		label(item, "Details", detail, UDim2.fromOffset(50, 34), UDim2.new(1, -170, 0, 17), 11, C.Muted)
		local score = if isRoom then number(entry.CorrectThisMatch) .. " aciertos" else number(entry.Value or entry.Score)
		local scoreLabel = fit(label(item, "Score", score, UDim2.new(1, -120, 0, 10), UDim2.fromOffset(107, 38), 17, C.Mint), 11, 17)
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
	end
	if #values == 0 then paragraph(52, "Las primeras marcas están por llegar", "Las clasificaciones aparecerán aquí cuando haya resultados disponibles.", 130) end
end
local function renderAlbum()
	tabs({}, nil)
	local pages = math.max(1, math.ceil(#Characters.All / 10))
	albumPage = math.clamp(albumPage, 1, pages)
	button(content, "Previous", "< Anterior", UDim2.fromOffset(0, 0), UDim2.fromOffset(100, 36), function() albumPage -= 1; renderPage() end)
	button(content, "Next", "Siguiente >", UDim2.new(1, -112, 0, 0), UDim2.fromOffset(104, 36), function() albumPage += 1; renderPage() end)
	local pageLabel = label(content, "AlbumPage", albumPage .. " / " .. pages, UDim2.new(0.5, -42, 0, 2), UDim2.fromOffset(84, 32), 14, C.Muted)
	pageLabel.TextXAlignment = Enum.TextXAlignment.Center
	for slot = 1, 10 do
		local character = Characters.All[(albumPage - 1) * 10 + slot]
		if not character then break end
		local col, line = (slot - 1) % 2, math.floor((slot - 1) / 2)
		local item = frame(content, "Character" .. character.Id, UDim2.new(col * 0.5, 0, 0, 48 + line * 196), UDim2.new(0.5, -9, 0, 186), C.White)
		local view = viewport(item, "Portrait", UDim2.fromOffset(2, 3), UDim2.new(1, -4, 0, 143))
		Portrait.mount(view, character, character.TargetRGB)
		local name = fit(label(item, "Name", character.Name, UDim2.fromOffset(7, 147), UDim2.new(1, -14, 0, 20), 13, C.Ink), 10, 13)
		name.TextXAlignment = Enum.TextXAlignment.Center
		local family = label(item, "Family", "#" .. character.Id .. " · " .. (character.Family or "Prisma"), UDim2.fromOffset(7, 168), UDim2.new(1, -14, 0, 13), 10, C.Ink)
		family.TextXAlignment = Enum.TextXAlignment.Center
	end
end
local function renderHelp()
	tabs({}, nil)
	local entries = {
		{ "1 · Dos segundos para recordar", "Memoriza el color del personaje. Después la imagen central cambia a un color falso: las cinco puertas muestran las alternativas.", 152 },
		{ "2 · Elige con tus pies", "Entra en la zona marcada delante de una puerta. Tu primera elección queda confirmada. Si aciertas, se abre el camino y avanzas al siguiente sector.", 164 },
		{ "3 · La final es una carrera", "En la final gana el primero que llega a la opción correcta. Si todos fallan, no hay ganador. Una partida individual es práctica y no suma victorias.", 164 },
		{ "4 · Vuelve como fantasma", "Si fallas, vuelves al lobby. Puedes observar o activar Jugar fantasma para recorrer los retos sin premios de aciertos, racha o victoria. También puedes hacerlo si llegaste tarde.", 188 },
		{ "5 · Regalos a tu ritmo", "Cada cinco aciertos seguidos ganas un regalo aleatorio gratuito. También hay premios por tiempo. El armario guarda tus trajes, estelas, gestos, reacciones y auras.", 176 },
	}
	local y = 0
	for _, item in ipairs(entries) do paragraph(y, item[1], item[2], item[3]); y += item[3] + 12 end
end
renderPage = function()
	if not currentPage then return end
	clear(content)
	quoteButtons = {}
	panelTitle.Text, backButton.Visible = string.upper(currentPage), currentPage ~= "Inicio"
	local renderers = { Inicio = renderHome, Tienda = renderShop, Armario = renderWardrobe, Regalos = renderGifts, ["Clasificación"] = renderBoards, ["Álbum"] = renderAlbum, Ayuda = renderHelp }
	local renderer = renderers[currentPage] or renderHome
	renderer()
end
showPage = function(page, tab)
	if page == "Álbum" and latest.Mode == "ALIVE" and (latest.Phase == "PREVIEW" or latest.Phase == "CHOOSE") then
		showToast("El álbum vuelve a estar disponible al terminar este reto.")
		return
	end
	currentPage, currentTab, overlay.Visible = page, tab, page ~= nil
	menuButton.Text = if page then "VOLVER" else "MENÚ"
	content.CanvasPosition = Vector2.new(0, 0)
	if page then renderPage() else clear(content) end
	if adaptScreen then adaptScreen() end
end

local function rgbKey(rgb)
	if type(rgb) ~= "table" then return "" end
	return tostring(rgb[1]) .. ":" .. tostring(rgb[2]) .. ":" .. tostring(rgb[3])
end
local function colorName(rgb)
	local r, g, b = rgb[1], rgb[2], rgb[3]
	if math.max(r, g, b) - math.min(r, g, b) < 25 then return "NEUTRO" end
	if r >= g and r >= b then
		if g > r * 0.78 then return "AMARILLO" end
		if g > b * 1.3 and g > r * 0.35 then return "NARANJA" end
		return if b > g * 1.3 then "ROSA" else "CORAL"
	elseif g >= r and g >= b then return if b > g * 0.72 then "TURQUESA" else "VERDE"
	else return if r > b * 0.62 then "VIOLETA" else "AZUL" end
end
local function makeWorldCard(anchor, name, title, character, rgb, big)
	local billboard = Instance.new("BillboardGui")
	billboard.Name, billboard.Adornee = name, anchor
	billboard.Size = if big then UDim2.fromScale(21, 24) else UDim2.fromScale(14, 17)
	-- Keep the large reference above the five alternatives, not in front of the
	-- middle door. The HUD also carries the reference for short/mobile viewports.
	if big then billboard.StudsOffsetWorldSpace = Vector3.new(0, 20, -20) end
	billboard.AlwaysOnTop, billboard.MaxDistance, billboard.LightInfluence = false, 165, 0
	billboard.Parent = gui
	local card = frame(billboard, "Card", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C.White)
	stroke(card, C.Mint, 2)
	local heading = fit(label(card, "Title", title, UDim2.new(0.04, 0, 0.02, 0), UDim2.new(0.92, 0, 0.12, 0), 25, C.Ink), 12, 25)
	heading.TextXAlignment, heading.Font = Enum.TextXAlignment.Center, Enum.Font.GothamBold
	local view = viewport(card, "Portrait", UDim2.new(0.02, 0, 0.14, 0), UDim2.new(0.96, 0, 0.69, 0))
	Portrait.mount(view, character, rgb)
	local caption = fit(label(card, "Caption", if big then character.Name else colorName(rgb), UDim2.new(0.04, 0, 0.85, 0), UDim2.new(0.92, 0, 0.12, 0), 21, C.Ink), 11, 21)
	caption.TextXAlignment = Enum.TextXAlignment.Center
	table.insert(worldCards, billboard)
	return card
end
redrawWorld = function()
	local signature = tostring(latest.Stage) .. ":" .. tostring(latest.CharacterId) .. ":" .. tostring(latest.Phase) .. ":" .. rgbKey(latest.ReferenceRGB) .. ":" .. tostring(latest.CorrectLane)
	for _, rgb in ipairs(latest.Choices or {}) do signature ..= ":" .. rgbKey(rgb) end
	if signature == worldSignature then return end
	for _, card in ipairs(worldCards) do card:Destroy() end
	worldCards = {}
	local character = Characters.get(latest.CharacterId)
	if not character or not latest.Stage or latest.Phase == "LOBBY" or latest.Phase == "RESULTS" then worldSignature = signature; return end
	local world = workspace:FindFirstChild("ColorChaosWorld")
	local stages = world and world:FindFirstChild("Stages")
	local stage = stages and stages:FindFirstChild(string.format("Stage%02d", latest.Stage))
	if not stage then return end -- A streamed sector may arrive after its snapshot.
	local anchor = stage:FindFirstChild("ReferenceAnchor")
	if anchor and type(latest.ReferenceRGB) == "table" then
		makeWorldCard(anchor, "WorldReference", if latest.Phase == "PREVIEW" then "RECUERDA EL COLOR" else "¿CUÁL ERA SU COLOR?", character, latest.ReferenceRGB, true)
	end
	local gates, complete = stage:FindFirstChild("Gates"), anchor ~= nil
	for lane, rgb in ipairs(latest.Choices or {}) do
		local gate = gates and gates:FindFirstChild("Gate" .. lane)
		local portraitAnchor = gate and gate:FindFirstChild("PortraitAnchor")
		if not portraitAnchor then complete = false end
		if portraitAnchor and type(rgb) == "table" and latest.Phase ~= "PREVIEW" then
			local card = makeWorldCard(portraitAnchor, "WorldChoice" .. lane, string.char(64 + lane) .. " · CAMINO " .. lane, character, rgb, false)
			if latest.CorrectLane == lane and (latest.Phase == "REVEAL" or latest.Phase == "TRAVEL") then card.BackgroundColor3 = C.Mint end
		end
	end
	if complete then worldSignature = signature end
end
refreshSpectator = function()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if latest.Mode == "ALIVE" or latest.Mode == "GHOST" or latest.Phase == "LOBBY" or latest.Phase == "RESULTS" then spectating = false end
	local target = player
	if spectating then
		local ids = latest.SpectatorIds or {}
		if not table.find(ids, observedId) then observedId = ids[1] end
		target = observedId and Players:GetPlayerByUserId(observedId) or nil
		if not target then spectating, target = false, player end
	end
	local humanoid = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then camera.CameraType, camera.CameraSubject = Enum.CameraType.Custom, humanoid end
	observeButton.Text = if spectating then "Volver al lobby" else "Observar"
end
local viewportConnection
adaptScreen = function()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local screen = camera.ViewportSize
	local compact = screen.X < 700 or (UserInputService.TouchEnabled and screen.Y < 520)
	wallet.Visible = not compact
	if compact then
		menuButton.Position, menuButton.Size = UDim2.new(0.5, -106, 1, -55), UDim2.fromOffset(102, 40)
		quickButton.Position, quickButton.Size = UDim2.new(0.5, 4, 1, -55), UDim2.fromOffset(102, 40)
		spectator.Position = UDim2.new(0.5, 0, 1, -105)
	else
		menuButton.Position, menuButton.Size = UDim2.new(0.5, -56, 1, -59), UDim2.fromOffset(112, 44)
		quickButton.Position, quickButton.Size = UDim2.new(0.5, 64, 1, -59), UDim2.fromOffset(92, 44)
		spectator.Position = UDim2.new(0.5, 0, 1, -110)
	end
	if latest.Phase == "PREVIEW" then
		reference.AnchorPoint = Vector2.new(0.5, 0.5)
		reference.Position = UDim2.new(0.5, 0, 0.53, 0)
		reference.Size = UDim2.fromOffset(if screen.Y < 500 then 176 else 224, if screen.Y < 500 then 202 else 264)
	else
		reference.AnchorPoint = Vector2.new(0, 0)
		reference.Position = UDim2.fromOffset(14, 107)
		reference.Size = UDim2.fromOffset(if compact then 98 else 144, if compact then 128 else 178)
	end
end
local function watchCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	if workspace.CurrentCamera then viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptScreen) end
	adaptScreen(); refreshSpectator()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
player.CharacterAdded:Connect(function() task.defer(refreshSpectator) end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then showPage(if currentPage then nil else "Inicio") end
	if input.KeyCode == Enum.KeyCode.Escape and currentPage then showPage(nil) end
end)

local function profileSignature(p)
	local values = { tostring(p.Coins), tostring(p.Gems), tostring(p.FreeGifts), tostring(p.Streak), tostring(p.VIP), tostring(p.Selected) }
	for _, item in ipairs(Catalog.Items) do
		table.insert(values, tostring((p.CosmeticsOwned or {})[item.Id]))
		table.insert(values, tostring((p.Equipped or {})[item.Kind]))
	end
	for i in ipairs(Config.Palettes or {}) do table.insert(values, tostring((p.Owned or {})[tostring(i)])) end
	for _, offer in ipairs(commerceCatalog()) do table.insert(values, tostring(offer.Available) .. tostring(offer.Owned)) end
	return table.concat(values, ":")
end
local phaseNames = { LOBBY = "CIUDAD PRISMA", PREVIEW = "MEMORIZA", CHOOSE = "ELIGE TU CAMINO", REVEAL = "RESULTADO", TRAVEL = "AVANZA", RESULTS = "FIN DE PARTIDA" }
local function applyState(payload)
	if type(payload) ~= "table" then return end
	if payload.Toast then showToast(payload.Toast) end
	if payload.GiftResult then
		local gift = payload.GiftResult
		local title = if type(gift) == "string" then gift elseif gift.Name then gift.Name elseif gift.Kind == "Gems" then number(gift.Amount) .. " diamantes" elseif gift.Kind == "Coins" then number(gift.Amount) .. " monedas" else "Regalo recibido"
		if type(gift) == "table" and gift.Duplicate then title ..= " · Repetido: +15 diamantes" end
		showToast("Tu regalo: " .. title)
		giftName.Text, giftReveal.Visible = title, true
		local kind = type(gift) == "table" and gift.Kind or "Cosmetic"
		giftIcon.Text = if kind == "Coins" then "+" .. number(gift.Amount) elseif kind == "Gems" then "◆" elseif kind == "Reaction" then "★" else "✦"
		giftIcon.TextColor3 = if kind == "Gems" then C.Lilac else C.Gold
		giftNote.Text = if kind == "Coins" or kind == "Gems" then "Añadido a tu saldo" elseif kind == "FreeGifts" then "Puedes abrirlo en Regalos → Por racha" else "Ya está en tu armario"
		if giftTween then giftTween:Cancel() end
		giftScale.Scale = 0.86
		giftTween = TweenService:Create(giftScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		giftTween:Play()
	end
	if not phaseNames[payload.Phase] or type(payload.Profile) ~= "table" then return end
	local previousPhase = latest.Phase
	latest = payload -- Full snapshots clear previous answers and stale selections.
	gui:SetAttribute("Ready", true)
	local p, phase = profile(), latest.Phase
	local mode = latest.Mode or (if latest.Alive then "ALIVE" else "LOBBY")
	local modeName = if mode == "GHOST" then "FANTASMA · sin premios de ronda" elseif mode == "ALIVE" then (if latest.Solo then "PRÁCTICA" else "EN CARRERA") else "LOBBY"
	phaseLabel.Text = if latest.Final and phase == "CHOOSE" then "FINAL · ¡CORRE!" else phaseNames[phase] or phase
	timer.Text = if latest.Seconds ~= nil then tostring(math.max(0, math.ceil(latest.Seconds))) else "--"
	timer.TextColor3 = if latest.Seconds and latest.Seconds <= 3 and phase == "CHOOSE" then C.Rose else C.Gold
	messageLabel.Text = latest.Message or "Explora Ciudad Prisma"
	if latest.MyChoice and phase == "CHOOSE" then messageLabel.Text = "Elegiste el camino " .. latest.MyChoice .. " · Espera el resultado" end
	local stage, stages = tonumber(latest.Stage) or 0, tonumber(latest.StageCount) or 8
	roundLabel.Text = if phase == "LOBBY" then string.format("%s · %s jugadores · Tu racha: %s", modeName, number(latest.ReadyCount), number(p.Streak)) else string.format("%s · Etapa %d / %d · %s en carrera", modeName, stage, stages, number(latest.AliveCount))
	stageFill.Size = UDim2.fromScale(math.clamp(stage / math.max(1, stages), 0, 1), 1)
	walletText.Text = number(p.Coins) .. " monedas · " .. number(p.Gems) .. " diamantes"
	panelWallet.Text = walletText.Text .. " · Nivel " .. number(p.Level or 1)
	levelText.Text = "Nivel " .. number(p.Level or 1) .. " · Racha " .. number(p.Streak)
	local active = phase ~= "LOBBY" and phase ~= "RESULTS"
	spectator.Visible = active and mode ~= "ALIVE"
	ghostButton.Text = if mode == "GHOST" then "Volver al lobby" else "Jugar fantasma"
	observeButton.Visible, nextObserved.Visible = mode ~= "GHOST", mode ~= "GHOST"
	if mode == "ALIVE" and phase == "PREVIEW" and previousPhase ~= "PREVIEW" then showPage(nil); giftReveal.Visible = false end
	local character = Characters.get(latest.CharacterId)
	reference.Visible = character ~= nil and type(latest.ReferenceRGB) == "table" and active and (mode == "ALIVE" or mode == "GHOST" or spectating)
	local signature = tostring(latest.CharacterId) .. ":" .. rgbKey(latest.ReferenceRGB)
	if reference.Visible and type(latest.ReferenceRGB) == "table" and signature ~= referenceSignature then
		Portrait.mount(refView, character, latest.ReferenceRGB)
		refName.Text, referenceSignature = character.Name, signature
	end
	refHeading.Text = if phase == "PREVIEW" then "RECUERDA" else "COLOR ALTERADO"
	refBorder.Color = if phase == "PREVIEW" then C.Mint else C.Lilac
	redrawWorld(); refreshSpectator(); adaptScreen()
	local signatureProfile = profileSignature(p)
	if currentPage and currentPage ~= "Álbum" then
		if currentPage == "Regalos" or currentPage == "Clasificación" or signatureProfile ~= renderedProfile then renderPage() end
	end
	renderedProfile = signatureProfile
	local windows = { Shop = "Tienda", Gifts = "Regalos", Wardrobe = "Armario", Leaderboards = "Clasificación", Album = "Álbum" }
	if windows[payload.OpenWindow] then showPage(windows[payload.OpenWindow]) end
end
stateEvent.OnClientEvent:Connect(applyState)
workspace:GetAttributeChangedSignal("ColorChaosBootStatus"):Connect(function()
	if workspace:GetAttribute("ColorChaosBootStatus") == "ERROR" then
		showToast("La partida se interrumpió. El lobby sigue disponible; vuelve a entrar para buscar otro servidor.")
	end
end)
watchCamera()
send("Sync", nil, 0)
task.spawn(function()
	while gui.Parent do
		task.wait(2)
		if not gui:GetAttribute("Ready") then send("Sync", nil, 1) else redrawWorld() end
	end
end)
