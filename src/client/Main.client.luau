-- Presentation only. The server decides objectives, currency and ownership.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local function requiredChild(parent, name)
	local child = parent:WaitForChild(name, 15)
	assert(child, "Color Chaos no inició: falta " .. parent.Name .. "." .. name)
	return child
end
local shared = requiredChild(ReplicatedStorage, "ColorChaos")
local Config = require(requiredChild(shared, "Config"))
local remotes = requiredChild(shared, "Remotes")
local stateEvent = requiredChild(remotes, "State")
local actionEvent = requiredChild(remotes, "Action")
local latest = {}
local paletteButtons = {}
local productRows = {}
local currentPage = "Auras"
local commerceSignature = ""
local missionSignature = ""
local quoteGeneration = 0
local lastPurchaseRequest = 0
local lastMissionRequest = 0
local toastSerial = 0
local spectating = false
local observedId = nil
local spectatorIds = {}
local spectatorPanel, observeButton, nextButton, spectatorName
local refreshSpectator

local gui = Instance.new("ScreenGui")
gui.Name = "ColorChaosUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
gui:SetAttribute("Ready", false)

local function roundCorners(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = object
end

local function text(parent, content, size, position, dimensions)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text, t.TextSize = content, size
	t.TextColor3 = Color3.fromRGB(245, 248, 255)
	t.Font = Enum.Font.GothamBold
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Size, t.Position = dimensions, position
	t.Parent = parent
	return t
end

local function button(parent, content, position, dimensions, callback)
	local b = Instance.new("TextButton")
	b.Text, b.TextSize = content, 16
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.fromRGB(245, 248, 255)
	b.BackgroundColor3 = Color3.fromRGB(48, 64, 93)
	b.Size, b.Position = dimensions, position
	b.Parent = parent
	roundCorners(b, 10)
	b.Activated:Connect(callback)
	return b
end

local top = Instance.new("Frame")
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position, top.Size = UDim2.new(0.5, 0, 0, 8), UDim2.new(0.92, 0, 0, 188)
top.BackgroundColor3 = Color3.fromRGB(17, 24, 42)
top.BackgroundTransparency = 0.08
top.Parent = gui
roundCorners(top)
local topConstraint = Instance.new("UISizeConstraint")
topConstraint.MaxSize = Vector2.new(760, 188)
topConstraint.Parent = top
local title = text(top, "COLOR CHAOS", 23, UDim2.fromOffset(14, 9), UDim2.new(1, -100, 0, 29))
title.TextScaled = true
local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize, titleConstraint.MaxTextSize = 13, 23
titleConstraint.Parent = title
local timer = text(top, "--", 24, UDim2.new(1, -78, 0, 9), UDim2.fromOffset(64, 29))
timer.TextXAlignment = Enum.TextXAlignment.Right
local message = text(top, "Conectando con el reactor...", 15, UDim2.fromOffset(14, 44), UDim2.new(1, -28, 0, 44))
local target = text(top, "", 20, UDim2.fromOffset(14, 91), UDim2.new(1, -28, 0, 28))
target.TextScaled = true
local targetLimit = Instance.new("UITextSizeConstraint")
targetLimit.MinTextSize, targetLimit.MaxTextSize = 11, 20
targetLimit.Parent = target
local roundStatus = text(top, "LOBBY · Preparando la siguiente partida", 12, UDim2.fromOffset(14, 123), UDim2.new(1, -28, 0, 20))
roundStatus.TextScaled = true
local roundStatusLimit = Instance.new("UITextSizeConstraint")
roundStatusLimit.MinTextSize, roundStatusLimit.MaxTextSize = 10, 12
roundStatusLimit.Parent = roundStatus
local bar = Instance.new("Frame")
bar.Position, bar.Size = UDim2.fromOffset(14, 151), UDim2.new(1, -28, 0, 10)
bar.BackgroundColor3 = Color3.fromRGB(49, 60, 82)
bar.Parent = top
roundCorners(bar, 6)
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Config.Colors[3].Color
fill.Parent = bar
roundCorners(fill, 6)
local lavaStatus = text(top, "El lobby siempre es una zona segura", 11, UDim2.fromOffset(14, 167), UDim2.new(1, -28, 0, 16))
lavaStatus.TextScaled = true
local lavaStatusLimit = Instance.new("UITextSizeConstraint")
lavaStatusLimit.MinTextSize, lavaStatusLimit.MaxTextSize = 9, 11
lavaStatusLimit.Parent = lavaStatus

local footer = Instance.new("Frame")
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.Position, footer.Size = UDim2.new(0.5, 0, 1, -12), UDim2.new(0.9, 0, 0, 85)
footer.BackgroundColor3 = Color3.fromRGB(17, 24, 42)
footer.BackgroundTransparency = 0.08
footer.Parent = gui
roundCorners(footer)
local footerConstraint = Instance.new("UISizeConstraint")
footerConstraint.MaxSize = Vector2.new(660, 85)
footerConstraint.Parent = footer
local topScale = Instance.new("UIScale")
topScale.Parent = top
local footerScale = Instance.new("UIScale")
footerScale.Parent = footer
local spectatorScale = Instance.new("UIScale")
local function adaptToScreen()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local touch = UserInputService.TouchEnabled
	local compact = touch and camera.ViewportSize.Y < 500
	local factor = compact and 0.78 or 1
	topScale.Scale, footerScale.Scale, spectatorScale.Scale = factor, factor, factor
	-- Touch controls occupy the bottom corners; place the HUD above them.
	if touch then
		footer.AnchorPoint = Vector2.new(0.5, 0)
		footer.Position = UDim2.new(0.5, 0, 0, math.floor(188 * factor) + 18)
		if spectatorPanel then
			spectatorPanel.AnchorPoint = Vector2.new(0.5, 0)
			spectatorPanel.Position = UDim2.new(0.5, 0, 0, math.floor(273 * factor) + 28)
		end
	else
		footer.AnchorPoint = Vector2.new(0.5, 1)
		footer.Position = UDim2.new(0.5, 0, 1, -12)
		if spectatorPanel then
			spectatorPanel.AnchorPoint = Vector2.new(0.5, 1)
			spectatorPanel.Position = UDim2.new(0.5, 0, 1, -109)
		end
	end
end
local viewportConnection
local function watchCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	if workspace.CurrentCamera then
		viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptToScreen)
	end
	adaptToScreen()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
local balance = text(footer, "0 monedas · 0 victorias · Nivel 1", 15, UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 23))
balance.TextScaled = true
local balanceConstraint = Instance.new("UITextSizeConstraint")
balanceConstraint.MinTextSize, balanceConstraint.MaxTextSize = 10, 15
balanceConstraint.Parent = balance
local persistence = text(footer, "Cargando progreso", 11, UDim2.fromOffset(12, 31), UDim2.new(0.6, 0, 0, 19))
local participation = text(footer, "", 11, UDim2.fromOffset(12, 53), UDim2.new(0.58, 0, 0, 24))
participation.TextScaled = true
local participationLimit = Instance.new("UITextSizeConstraint")
participationLimit.MinTextSize, participationLimit.MaxTextSize = 9, 11
participationLimit.Parent = participation

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.3
overlay.Visible = false
overlay.ZIndex = 10
overlay.Parent = gui
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position, panel.Size = UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.85)
panel.BackgroundColor3 = Color3.fromRGB(21, 30, 49)
panel.ZIndex = 11
panel.Parent = overlay
roundCorners(panel)
local panelConstraint = Instance.new("UISizeConstraint")
panelConstraint.MaxSize = Vector2.new(610, 540)
panelConstraint.Parent = panel
local heading = text(panel, "TIENDA", 25, UDim2.fromOffset(16, 12), UDim2.new(1, -85, 0, 34))
heading.ZIndex = 12
heading.TextScaled = true
local headingConstraint = Instance.new("UITextSizeConstraint")
headingConstraint.MinTextSize, headingConstraint.MaxTextSize = 11, 25
headingConstraint.Parent = heading
local close = button(panel, "X", UDim2.new(1, -54, 0, 10), UDim2.fromOffset(40, 38), function() overlay.Visible = false end)
close.ZIndex = 12
local scroll = Instance.new("ScrollingFrame")
scroll.Position, scroll.Size = UDim2.fromOffset(16, 104), UDim2.new(1, -32, 1, -120)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ZIndex = 12
scroll.Parent = panel
local pages = {}
local tabButtons = {}
local openPage

local function makePage(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, -8, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.ZIndex, frame.Visible = 12, false
	frame.Parent = scroll
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	pages[name] = frame
	return frame
end

local function paragraph(parent, content, size)
	local label = text(parent, content, size or 15, UDim2.new(), UDim2.new(1, 0, 0, 0))
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Gotham
	label.ZIndex = 13
	return label
end

local shopContent = makePage("Auras")
paragraph(shopContent, "Auras cosméticas para tu personaje. Gana monedas jugando o compra un paquete opcional. El pase VIP incluye su propia aura y no aumenta tus victorias.")
for i, palette in ipairs(Config.Palettes) do
	local b = button(shopContent, palette.Name, UDim2.new(), UDim2.new(1, 0, 0, 59), function()
		if palette.Access == "VIP" and not (latest.Profile and latest.Profile.VIP) then
			openPage("Robux")
		else
			actionEvent:FireServer("Palette", i)
		end
	end)
	b.LayoutOrder = i
	b.BackgroundColor3 = palette.Color
	b.TextColor3 = Color3.fromRGB(16, 24, 39)
	b.TextWrapped = true
	b.ZIndex = 13
	paletteButtons[i] = b
end

local commerceContent = makePage("Robux")
local missionContent = makePage("Misiones")
local helpContent = makePage("Ayuda")
paragraph(helpContent,
	"LA MISIÓN\nUna máquina borró los colores de la ciudad. Coopera para reparar su reactor.\n\n"
	.. "CONTROLES\nAcércate a un panel y mantén E en PC, toca su botón en móvil o usa el botón indicado en consola.\n\n"
	.. "PUENTES DE MEMORIA\nObserva cinco letras. Actívalas en ese orden y cruza al reactor. Un error reinicia los puentes.\n\n"
	.. "REPARACIÓN EN EQUIPO\nVe a la estación de la letra indicada y repárala. El objetivo es compartido.\n\n"
	.. "RESCATE CROMÁTICO\nActiva el panel indicado, cruza a la isla, recoge su chispa y entrégala al reactor. Si el portador cae, la chispa regresa a la isla.\n\n"
	.. "LAVA Y PLATAFORMAS\nLa lava sube durante la ronda. Los objetivos completados elevan la arena del equipo. Coopera para mantenerte a salvo y reparar el reactor antes de que se termine el tiempo.\n\n"
	.. "RECOMPENSAS\nColaborar y sobrevivir a una victoria da " .. tostring(Config.WinCoins)
	.. " monedas y una victoria. Colaborar sin lograrlo da " .. tostring(Config.ParticipationCoins)
	.. " monedas. Completa misiones diarias y reclama sus monedas en la pestaña Misiones. La experiencia aumenta tu nivel.\n\n"
	.. "COMPRAS OPCIONALES\nLas monedas compran auras cosméticas. Los paquetes de monedas tienen una cantidad fija. El VIP incluye un aura; no compra victorias. El precio y la confirmación de las compras con Robux aparecen en la ventana oficial de Roblox. Las monedas no se canjean por Robux ni dinero.\n\n"
	.. "LOBBY Y ESPECTADORES\nPuedes jugar desde una sola persona. Si caes o entras tarde, espera en el lobby seguro hasta la siguiente ronda. Pulsa OBSERVAR para seguir a los jugadores; SIGUIENTE cambia de jugador y VOLVER AL LOBBY devuelve la cámara a tu personaje.\n\n"
	.. "ACCESIBILIDAD\nAzul = A · Amarillo = B · Verde = C · Rojo = D. Todas las indicaciones incluyen letras.\n\n"
	.. "GUARDADO\nStudio usa progreso temporal. En una experiencia publicada, el progreso se guarda automáticamente. Consulta el estado de guardado en la pantalla. Si falla, espera a que se recupere antes de salir.", 16)

local function clearPage(page)
	for _, child in ipairs(page:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
end

local function getCatalog()
	local catalog = latest.Commerce
	if type(catalog) ~= "table" then return {} end
	return type(catalog.Catalog) == "table" and catalog.Catalog or catalog
end

local function catalogSignature()
	local fields = {}
	for _, entry in ipairs(getCatalog()) do
		fields[#fields + 1] = table.concat({ tostring(entry.Kind), tostring(entry.Key), tostring(entry.Id),
			tostring(entry.Name), tostring(entry.Description), tostring(entry.Available) }, "|")
	end
	return table.concat(fields, ";")
end

local function updateOffer(row)
	local entry, quote, b = row.Entry, row.Quote, row.Button
	local enabled = entry.Available == true and type(entry.Id) == "number" and entry.Id > 0 and not entry.Owned
	if entry.Owned then
		b.Text = "ADQUIRIDO"
	elseif not enabled then
		b.Text = type(entry.Id) == "number" and entry.Id > 0 and "NO DISPONIBLE" or "PRÓXIMAMENTE"
	elseif quote and quote.ForSale == false then
		b.Text = "NO DISPONIBLE"
		enabled = false
	elseif quote and quote.Price then
		b.Text = "COMPRAR · R$ " .. tostring(quote.Price)
	elseif row.Loading then
		b.Text = "CONSULTANDO PRECIO..."
		enabled = false
	else
		b.Text = "VER PRECIO EN ROBLOX"
	end
	b.Active, b.Selectable, b.AutoButtonColor = enabled, enabled, enabled
	b.BackgroundColor3 = enabled and Color3.fromRGB(43, 94, 137) or Color3.fromRGB(49, 59, 77)
end

local function productInfo(id, kind)
	local infoType = kind == "Pass" and Enum.InfoType.GamePass or Enum.InfoType.Product
	-- Prefer the current API. Fall back only when the method is absent;
	-- a failed network lookup never changes the trust or verification path.
	local present, method = pcall(function() return MarketplaceService.GetProductInfoAsync end)
	if present and type(method) == "function" then return method(MarketplaceService, id, infoType) end
	return MarketplaceService:GetProductInfo(id, infoType)
end

local function rebuildCommerce()
	quoteGeneration += 1
	local generation = quoteGeneration
	commerceSignature = catalogSignature()
	clearPage(commerceContent)
	productRows = {}
	paragraph(commerceContent, "Compras opcionales. Todos pueden completar los desafíos sin pagar. El precio final y la confirmación aparecen en la ventana oficial de Roblox.")
	local catalog = getCatalog()
	if #catalog == 0 then paragraph(commerceContent, "Cargando ofertas...") end
	for i, entry in ipairs(catalog) do
		local card = Instance.new("Frame")
		card.Size, card.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
		card.BackgroundColor3 = Color3.fromRGB(30, 43, 66)
		card.LayoutOrder, card.ZIndex = i, 13
		card.Parent = commerceContent
		roundCorners(card)
		local padding = Instance.new("UIPadding")
		padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12)
		padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
		padding.Parent = card
		local layout = Instance.new("UIListLayout")
		layout.Padding, layout.SortOrder = UDim.new(0, 9), Enum.SortOrder.LayoutOrder
		layout.Parent = card
		local offerTitle = paragraph(card, entry.Name or "Oferta", 18)
		offerTitle.Font = Enum.Font.GothamBold
		local description = paragraph(card, entry.Description or "", 14)
		description.LayoutOrder = 1
		local row = { Entry = entry, Loading = false }
		local b = button(card, "", UDim2.new(), UDim2.new(1, 0, 0, 40), function()
			local offer = row.Entry
			if not offer.Available or offer.Owned or row.Loading or (row.Quote and row.Quote.ForSale == false) then return end
			if os.clock() - lastPurchaseRequest < 1 then return end
			lastPurchaseRequest = os.clock()
			-- Send catalog keys only. The server selects the real product ID;
			-- only its receipt handler awards developer-product purchases.
			actionEvent:FireServer("Purchase", { Kind = offer.Kind, Key = offer.Key })
		end)
		b.LayoutOrder, b.ZIndex, b.TextWrapped = 2, 14, true
		row.Button = b
		productRows[i] = row
		if entry.Available == true and type(entry.Id) == "number" and entry.Id > 0 and not entry.Owned then
			row.Loading = true
			task.spawn(function()
				local ok, info = pcall(productInfo, entry.Id, entry.Kind)
				if generation ~= quoteGeneration or not b.Parent then return end
				row.Loading = false
				if ok and type(info) == "table" then
					local price = info.PriceInRobux
					if type(price) ~= "number" or price < 0 or price ~= price or price == math.huge or price % 1 ~= 0 then price = nil end
					row.Quote = { Price = price, ForSale = info.IsForSale }
				end
				updateOffer(row)
			end)
		end
		updateOffer(row)
	end
	local notice = paragraph(commerceContent, "Las monedas solo sirven en Color Chaos. No se convierten en Robux ni dinero. El VIP es un pase permanente; los paquetes se pueden comprar más de una vez.", 13)
	notice.LayoutOrder = #catalog + 1
end

local function missionsSignature()
	local progression = latest.Progression or {}
	local fields = { tostring(progression.Level), tostring(progression.LevelProgress), tostring(progression.NextLevelXP) }
	for _, mission in ipairs(progression.Missions or {}) do
		fields[#fields + 1] = table.concat({ tostring(mission.Key), tostring(mission.Name), tostring(mission.Count),
			tostring(mission.Target), tostring(mission.Reward), tostring(mission.Claimed), tostring(mission.Complete) }, "|")
	end
	return table.concat(fields, ";")
end

local function rebuildMissions()
	missionSignature = missionsSignature()
	clearPage(missionContent)
	local progression = latest.Progression or {}
	local level = paragraph(missionContent, "NIVEL " .. tostring(progression.Level or 1) .. " · "
		.. tostring(progression.LevelProgress or 0) .. " / " .. tostring(progression.NextLevelXP or 100) .. " XP", 18)
	level.Font = Enum.Font.GothamBold
	local info = paragraph(missionContent, "Gana experiencia colaborando. Las misiones se renuevan cada día. Reclama sus monedas al completar los objetivos.")
	info.LayoutOrder = 1
	local missions = progression.Missions or {}
	if #missions == 0 then
		local loading = paragraph(missionContent, "Cargando misiones...")
		loading.LayoutOrder = 2
	end
	for i, mission in ipairs(missions) do
		local complete = mission.Complete == true and mission.Claimed ~= true
		local status = mission.Claimed and "RECLAMADA" or (complete and "RECLAMAR" or "EN PROGRESO")
		local b = button(missionContent,
			(mission.Name or "Misión") .. "\n" .. tostring(mission.Count or 0) .. " / " .. tostring(mission.Target or 0)
			.. " · " .. tostring(mission.Reward or 0) .. " monedas\n" .. status,
			UDim2.new(), UDim2.new(1, 0, 0, 96), function()
				if not complete or os.clock() - lastMissionRequest < 0.75 then return end
				lastMissionRequest = os.clock()
				actionEvent:FireServer("ClaimMission", mission.Key)
			end)
		b.LayoutOrder, b.ZIndex, b.TextWrapped = i + 1, 13, true
		b.TextSize = 15
		b.Active, b.Selectable, b.AutoButtonColor = complete, complete, complete
		b.BackgroundColor3 = complete and Color3.fromRGB(34, 104, 83) or Color3.fromRGB(48, 64, 93)
	end
end

openPage = function(name)
	currentPage = name
	for key, page in pairs(pages) do
		page.Visible = key == name
		-- Only the current page contributes to the automatic canvas bounds.
		page.Parent = key == name and scroll or nil
	end
	for key, tab in pairs(tabButtons) do
		tab.BackgroundColor3 = key == name and Color3.fromRGB(43, 94, 137) or Color3.fromRGB(48, 64, 93)
	end
	heading.Text = name == "Ayuda" and "CÓMO JUGAR" or "TIENDA Y MISIONES"
	if name == "Robux" then rebuildCommerce() end
	if name == "Misiones" then rebuildMissions() end
	scroll.CanvasPosition = Vector2.zero
	overlay.Visible = true
end

for i, name in ipairs({ "Auras", "Robux", "Misiones", "Ayuda" }) do
	local tab = button(panel, string.upper(name), UDim2.new((i - 1) / 4, 8, 0, 57), UDim2.new(0.25, -16, 0, 36), function() openPage(name) end)
	tab.TextSize, tab.ZIndex, tab.TextScaled = 13, 13, true
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MinTextSize, sizeLimit.MaxTextSize = 9, 13
	sizeLimit.Parent = tab
	tabButtons[name] = tab
end

local function openShop() openPage("Auras") end
local function openHelp() openPage("Ayuda") end
for _, b in ipairs({
	button(footer, "TIENDA", UDim2.new(0.62, 0, 0, 37), UDim2.new(0.2, -6, 0, 36), openShop),
	button(footer, "AYUDA", UDim2.new(0.82, 0, 0, 37), UDim2.new(0.18, -12, 0, 36), openHelp),
}) do
	b.TextScaled = true
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MinTextSize, sizeLimit.MaxTextSize = 9, 16
	sizeLimit.Parent = b
end

local toast = text(gui, "", 17, UDim2.new(0.5, 0, 0.65, 0), UDim2.new(0.85, 0, 0, 70))
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.BackgroundColor3, toast.BackgroundTransparency = Color3.fromRGB(17, 24, 42), 0.05
toast.Visible, toast.ZIndex = false, 20
roundCorners(toast)
local toastConstraint = Instance.new("UISizeConstraint")
toastConstraint.MaxSize = Vector2.new(620, 70)
toastConstraint.Parent = toast

local function showToast(content)
	toastSerial += 1
	local serial = toastSerial
	toast.Text, toast.Visible = content, true
	task.delay(4, function() if toastSerial == serial then toast.Visible = false end end)
end

local observedDeathConnection
local function localHumanoid()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function restoreCamera()
	if observedDeathConnection then observedDeathConnection:Disconnect(); observedDeathConnection = nil end
	observedId = nil
	local camera, humanoid = workspace.CurrentCamera, localHumanoid()
	if camera and humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end
end

local function stopSpectating()
	spectating = false
	restoreCamera()
end

local function livingHumanoid(userId)
	local candidate = Players:GetPlayerByUserId(userId)
	local humanoid = candidate and candidate.Character and candidate.Character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0 and humanoid or nil, candidate
end

refreshSpectator = function()
	local roundActive = latest.Phase == "JUEGO" or latest.Phase == "PREPARACIÓN"
	local mayObserve = roundActive and not (latest.Participating and latest.Alive)
	spectatorIds = {}
	local seen = {}
	if mayObserve and type(latest.SpectatorIds) == "table" then
		for _, userId in ipairs(latest.SpectatorIds) do
			if type(userId) == "number" and userId ~= player.UserId and not seen[userId] and livingHumanoid(userId) then
				seen[userId] = true
				table.insert(spectatorIds, userId)
			end
		end
	end
	if not mayObserve or #spectatorIds == 0 then stopSpectating() end
	spectatorPanel.Visible = mayObserve and #spectatorIds > 0
	observeButton.Text = spectating and "VOLVER AL LOBBY" or "OBSERVAR"
	nextButton.Visible = spectating and #spectatorIds > 1
	spectatorName.Visible = spectating
	if not spectating then return end
	if not table.find(spectatorIds, observedId) then observedId = spectatorIds[1] end
	local humanoid, candidate = livingHumanoid(observedId)
	if not humanoid or not workspace.CurrentCamera then return end
	if workspace.CurrentCamera.CameraSubject ~= humanoid then
		if observedDeathConnection then observedDeathConnection:Disconnect() end
		observedDeathConnection = humanoid.Died:Connect(function() task.spawn(refreshSpectator) end)
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		workspace.CurrentCamera.CameraSubject = humanoid
	end
	spectatorName.Text = "OBSERVANDO A " .. string.upper(candidate.DisplayName or candidate.Name)
end

spectatorPanel = Instance.new("Frame")
spectatorPanel.Name = "SpectatorControls"
spectatorPanel.Size = UDim2.new(0.9, 0, 0, 70)
spectatorPanel.BackgroundColor3 = Color3.fromRGB(17, 24, 42)
spectatorPanel.BackgroundTransparency = 0.08
spectatorPanel.Visible = false
spectatorPanel.Parent = gui
roundCorners(spectatorPanel)
local spectatorConstraint = Instance.new("UISizeConstraint")
spectatorConstraint.MaxSize = Vector2.new(660, 70)
spectatorConstraint.Parent = spectatorPanel
spectatorScale.Parent = spectatorPanel
observeButton = button(spectatorPanel, "OBSERVAR", UDim2.fromOffset(10, 10), UDim2.new(0.57, -15, 0, 32), function()
	if spectating then stopSpectating() else spectating = true end
	refreshSpectator()
end)
nextButton = button(spectatorPanel, "SIGUIENTE", UDim2.new(0.57, 0, 0, 10), UDim2.new(0.43, -10, 0, 32), function()
	if #spectatorIds == 0 then return end
	local index = table.find(spectatorIds, observedId) or 0
	observedId = spectatorIds[index % #spectatorIds + 1]
	refreshSpectator()
end)
for _, control in ipairs({ observeButton, nextButton }) do
	control.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize = 9, 15
	limit.Parent = control
end
spectatorName = text(spectatorPanel, "", 11, UDim2.fromOffset(12, 47), UDim2.new(1, -24, 0, 16))
spectatorName.TextScaled = true
local spectatorNameLimit = Instance.new("UITextSizeConstraint")
spectatorNameLimit.MinTextSize, spectatorNameLimit.MaxTextSize = 9, 11
spectatorNameLimit.Parent = spectatorName
adaptToScreen()

Players.PlayerRemoving:Connect(function(leaving)
	if leaving.UserId == observedId then
		local remaining = {}
		for _, userId in ipairs(latest.SpectatorIds or {}) do
			if userId ~= leaving.UserId then table.insert(remaining, userId) end
		end
		latest.SpectatorIds = remaining
		refreshSpectator()
	end
end)
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	if spectating then refreshSpectator() else restoreCamera() end
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if spectating then refreshSpectator() end
end)

stateEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	latest = payload
	title.Text = payload.Mode or "COLOR CHAOS"
	title.TextSize = payload.Mode and 18 or 23
	timer.Text = (payload.Seconds or 0) > 0 and (tostring(payload.Seconds) .. "s") or "—"
	message.Text = payload.Message or ""
	local colorIndex = payload.DemoCode or payload.Target
	local color = colorIndex and Config.Colors[colorIndex]
	if color then
		target.Text = (payload.DemoCode and ("PASO " .. tostring(payload.DemoStep or "") .. ": ") or "OBJETIVO: ") .. color.Symbol .. " · " .. color.Name
		target.TextColor3 = color.Color
	else
		if payload.Phase == "LOBBY" then
			target.Text = "Juega desde " .. tostring(payload.MinimumPlayers or Config.MinimumPlayers or 1) .. " jugador · coopera para ganar"
		else
			target.Text = (payload.Progress or 0) .. " / " .. (payload.Total or 0) .. " objetivos del equipo"
		end
		target.TextColor3 = Color3.fromRGB(230, 235, 255)
	end
	if payload.Phase == "LOBBY" then
		local ready = payload.ReadyPlayers or 0
		roundStatus.Text = "LOBBY · " .. tostring(ready) .. (ready == 1 and " jugador listo" or " jugadores listos") .. " · próxima ronda"
		lavaStatus.Text = "Explora el lobby. La partida empieza automáticamente."
		lavaStatus.TextColor3 = Color3.fromRGB(188, 213, 240)
	elseif payload.Phase == "JUEGO" or payload.Phase == "PREPARACIÓN" then
		roundStatus.Text = tostring(payload.AlivePlayers or 0) .. " / " .. tostring(payload.ParticipantCount or 0)
			.. " sobrevivientes · " .. tostring(payload.Progress or 0) .. " / " .. tostring(payload.Total or 0) .. " objetivos"
		local height = type(payload.LavaHeight) == "number" and math.floor(payload.LavaHeight * 10) / 10 or 0
		local lift = type(payload.PlatformLift) == "number" and math.floor(payload.PlatformLift * 10) / 10 or 0
		lavaStatus.Text = "LAVA ↑ " .. tostring(height) .. " · ARENA +" .. tostring(lift) .. " · Acertar te eleva"
		lavaStatus.TextColor3 = Color3.fromRGB(255, 185, 125)
	else
		roundStatus.Text = "RESULTADOS · La siguiente ronda empieza desde el lobby"
		lavaStatus.Text = "El lobby siempre es una zona segura"
		lavaStatus.TextColor3 = Color3.fromRGB(188, 213, 240)
	end
	local ratio = payload.Total and payload.Total > 0 and (payload.Progress or 0) / payload.Total or 0
	TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }):Play()
	if payload.Profile then
		balance.Text = tostring(payload.Profile.Coins or 0) .. " monedas · " .. tostring(payload.Profile.Wins or 0)
			.. " victorias · Nivel " .. tostring(payload.Progression and payload.Progression.Level or 1)
		local selected = payload.Profile.Selected
		local selectedPalette = selected and Config.Palettes[selected]
		if selectedPalette and selectedPalette.Access == "VIP" and payload.Profile.VIP ~= true then selected = 1 end
		for i, b in ipairs(paletteButtons) do
			local palette = Config.Palettes[i]
			local owned = payload.Profile.Owned and payload.Profile.Owned[tostring(i)]
			if palette.Access == "VIP" then owned = payload.Profile.VIP == true end
			local status = selected == i and "EQUIPADA" or (owned and "EQUIPAR"
				or (palette.Access == "VIP" and "VER PASE VIP" or tostring(palette.Cost) .. " monedas"))
			b.Text = palette.Name .. " · " .. status
		end
	end
	if overlay.Visible and currentPage == "Robux" then
		if commerceSignature ~= catalogSignature() then
			rebuildCommerce()
		else
			for i, entry in ipairs(getCatalog()) do
				if productRows[i] then
					productRows[i].Entry = entry
					updateOffer(productRows[i])
				end
			end
		end
	elseif overlay.Visible and currentPage == "Misiones" and missionSignature ~= missionsSignature() then
		rebuildMissions()
	end
	persistence.Text = payload.Persistence or "Cargando progreso"
	if payload.Phase == "JUEGO" or payload.Phase == "PREPARACIÓN" then
		participation.Text = payload.Participating and payload.Alive and "EN EL EQUIPO · ¡SUBE Y REPARA!" or "LOBBY SEGURO · SIGUIENTE RONDA"
	else participation.Text = "COOPERA · EXPLORA · REPARA" end
	refreshSpectator()
	if payload.Toast then showToast(payload.Toast) end
	if payload.OpenShop then openShop() end
	gui:SetAttribute("Ready", true)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H then
		if overlay.Visible then overlay.Visible = false else openHelp() end
	elseif input.KeyCode == Enum.KeyCode.Escape then overlay.Visible = false end
end)

-- Request a snapshot after subscribing, since earlier broadcasts may be missed.
actionEvent:FireServer("Sync")
