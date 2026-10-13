-- Client presentation. Gate choices, eliminations, currency and receipts belong to the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("ColorRush")
local Config = require(shared:WaitForChild("Config"))
local Characters = require(shared:WaitForChild("Characters"))
local Portrait = require(shared:WaitForChild("Portrait"))
local Rules = require(shared:WaitForChild("Rules"))
local remotes = shared:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local actionEvent = remotes:WaitForChild("Action")

local latest = {}
local currentPage = "Estelas"
local pages, tabs, trailButtons, offerRows = {}, {}, {}, {}
local quoteGeneration = 0
local catalogSignature, missionSignature, worldSignature = "", "", ""
local previewSignature = ""
local lastPurchaseRequest, lastReviveRequest = 0, 0
local toastSerial = 0
local albumPage = 1
local openPage
local showToast
local cancelPractice = function() end
local practiceGeneration = 0
local practiceRandom = Random.new()
local ink = Color3.fromRGB(243, 247, 255)
local muted = Color3.fromRGB(164, 180, 211)
local violet = Color3.fromRGB(133, 90, 255)
local cyan = Color3.fromRGB(56, 225, 228)
local dark = Color3.fromRGB(14, 19, 34)

local gui = Instance.new("ScreenGui")
gui.Name = "ColorRushUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corners(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = object
end

local function stroke(object, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color, s.Transparency, s.Thickness = color or violet, transparency or 0.65, 1
	s.Parent = object
end

local function label(parent, content, size, position, dimensions)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text, t.TextSize, t.TextColor3 = content, size or 16, ink
	t.Font = Enum.Font.GothamBold
	t.TextWrapped, t.TextXAlignment = true, Enum.TextXAlignment.Left
	t.Position, t.Size = position or UDim2.new(), dimensions or UDim2.new(1, 0, 0, 30)
	t.ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 1 or 2
	t.Parent = parent
	return t
end

local function fitText(object, minSize, maxSize)
	object.TextScaled = true
	local c = Instance.new("UITextSizeConstraint")
	c.MinTextSize, c.MaxTextSize = minSize or 10, maxSize or 18
	c.Parent = object
end

local function button(parent, content, position, dimensions, callback)
	local b = Instance.new("TextButton")
	b.Text, b.TextSize, b.TextColor3 = content, 14, ink
	b.Font, b.TextWrapped = Enum.Font.GothamBold, true
	b.BackgroundColor3 = Color3.fromRGB(45, 54, 81)
	b.Position, b.Size = position, dimensions
	b.ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 1 or 2
	b.Parent = parent
	corners(b, 10)
	if callback then b.Activated:Connect(callback) end
	return b
end

local function card(parent, height)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(24, 31, 51)
	f.Size = UDim2.new(1, 0, 0, height or 90)
	f.ZIndex = parent.ZIndex + 1
	f.Parent = parent
	corners(f)
	stroke(f, Color3.fromRGB(115, 140, 190), 0.85)
	return f
end

local function viewport(parent, position, dimensions)
	local v = Instance.new("ViewportFrame")
	v.BackgroundTransparency = 1
	v.Position, v.Size = position, dimensions
	v.ZIndex = parent.ZIndex + 1
	v.Parent = parent
	return v
end

local function mount(v, characterId, color, hidden)
	-- Portrait owns the camera, model and lighting; never use user-provided image URLs.
	for _, child in ipairs(v:GetChildren()) do child:Destroy() end
	local ok, err = pcall(Portrait.mount, v, characterId, color, hidden)
	if not ok then warn("Color Rush: portrait unavailable", err) end
end

local hud = Instance.new("Frame")
hud.AnchorPoint = Vector2.new(0.5, 0)
hud.Position, hud.Size = UDim2.new(0.5, 0, 0, 8), UDim2.new(0.96, 0, 0, 118)
hud.BackgroundColor3, hud.BackgroundTransparency = dark, 0.07
hud.Parent = gui
corners(hud, 16)
stroke(hud)
local hudLimit = Instance.new("UISizeConstraint")
hudLimit.MaxSize = Vector2.new(800, 118)
hudLimit.Parent = hud
local title = label(hud, "COLOR RUSH", 22, UDim2.fromOffset(15, 8), UDim2.new(0.55, 0, 0, 27))
fitText(title, 13, 22)
local timer = label(hud, "--", 25, UDim2.new(1, -86, 0, 8), UDim2.fromOffset(70, 30))
timer.TextXAlignment, timer.TextColor3 = Enum.TextXAlignment.Right, cyan
local instructions = label(hud, "Preparando la carrera...", 14, UDim2.fromOffset(15, 39), UDim2.new(1, -30, 0, 34))
fitText(instructions, 11, 16)
local stats = label(hud, "0 monedas  ·  0 victorias  ·  Nv. 1", 12, UDim2.fromOffset(15, 79), UDim2.new(1, -145, 0, 22))
fitText(stats, 9, 12)
local menuButton = button(hud, "TIENDA", UDim2.new(1, -126, 0, 78), UDim2.fromOffset(110, 28), function()
	openPage((latest.Phase == "LOBBY" or latest.Eliminated) and "Entrenar" or "Estelas")
end)
menuButton.BackgroundColor3 = violet
fitText(menuButton, 10, 13)

local status = label(gui, "", 12, UDim2.new(0.5, 0, 0, 131), UDim2.new(0.92, 0, 0, 26))
status.AnchorPoint, status.TextXAlignment, status.TextColor3 = Vector2.new(0.5, 0), Enum.TextXAlignment.Center, muted
status.BackgroundColor3, status.BackgroundTransparency = dark, 0.2
corners(status, 9)
local statusLimit = Instance.new("UISizeConstraint")
statusLimit.MaxSize = Vector2.new(770, 26)
statusLimit.Parent = status

local preview = Instance.new("Frame")
preview.AnchorPoint = Vector2.new(0.5, 0.5)
preview.Position, preview.Size = UDim2.fromScale(0.5, 0.58), UDim2.fromOffset(390, 355)
preview.BackgroundColor3, preview.BackgroundTransparency = dark, 0.03
preview.Visible, preview.ZIndex = false, 5
preview.Parent = gui
corners(preview, 22)
stroke(preview, cyan, 0.25)
local previewScale = Instance.new("UIScale")
previewScale.Parent = preview
local previewHeading = label(preview, "MEMORIZA EL COLOR", 20, UDim2.fromOffset(15, 11), UDim2.new(1, -30, 0, 27))
previewHeading.TextXAlignment, previewHeading.TextColor3 = Enum.TextXAlignment.Center, cyan
local previewViewport = viewport(preview, UDim2.fromOffset(20, 44), UDim2.new(1, -40, 1, -94))
local previewCaption = label(preview, "", 14, UDim2.new(0, 15, 1, -43), UDim2.new(1, -30, 0, 30))
previewCaption.TextXAlignment = Enum.TextXAlignment.Center

local reviveBox = Instance.new("Frame")
reviveBox.AnchorPoint = Vector2.new(0.5, 1)
reviveBox.Position, reviveBox.Size = UDim2.new(0.5, 0, 1, -12), UDim2.new(0.72, 0, 0, 126)
reviveBox.BackgroundColor3, reviveBox.BackgroundTransparency = dark, 0.06
reviveBox.Visible, reviveBox.ZIndex = false, 6
reviveBox.Parent = gui
corners(reviveBox)
stroke(reviveBox)
local reviveLimit = Instance.new("UISizeConstraint")
reviveLimit.MaxSize = Vector2.new(500, 126)
reviveLimit.Parent = reviveBox
local reviveMessage = label(reviveBox, "", 13, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 52))
reviveMessage.TextXAlignment = Enum.TextXAlignment.Center
local reviveButton = button(reviveBox, "", UDim2.fromOffset(12, 66), UDim2.new(0.6, -18, 0, 43), function()
	if os.clock() - lastReviveRequest < 1 then return end
	lastReviveRequest = os.clock()
	if (latest.Profile and latest.Profile.ReviveCredits or 0) > 0 then
		actionEvent:FireServer("UseRevive", true)
	else
		openPage("Robux")
	end
end)
reviveButton.BackgroundColor3 = violet
fitText(reviveButton, 10, 14)
local waitButton = button(reviveBox, "ESPERAR GRATIS", UDim2.new(0.6, 0, 0, 66), UDim2.new(0.4, -12, 0, 43), function() reviveBox.Visible = false end)
fitText(waitButton, 9, 13)

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3, overlay.BackgroundTransparency = Color3.new(0, 0, 0), 0.28
overlay.Visible, overlay.ZIndex = false, 20
overlay.Parent = gui
local panel = Instance.new("Frame")
panel.AnchorPoint, panel.Position, panel.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.94, 0.88)
panel.BackgroundColor3, panel.ZIndex = dark, 21
panel.Parent = overlay
corners(panel, 20)
stroke(panel)
local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize = Vector2.new(700, 640)
panelLimit.Parent = panel
local heading = label(panel, "PERSONALIZA TU CARRERA", 21, UDim2.fromOffset(16, 12), UDim2.new(1, -80, 0, 32))
fitText(heading, 12, 21)
button(panel, "X", UDim2.new(1, -52, 0, 10), UDim2.fromOffset(36, 34), function() cancelPractice(); overlay.Visible = false end)
local scroll = Instance.new("ScrollingFrame")
scroll.Position, scroll.Size = UDim2.fromOffset(14, 100), UDim2.new(1, -28, 1, -115)
scroll.BackgroundTransparency, scroll.BorderSizePixel, scroll.ScrollBarThickness = 1, 0, 5
scroll.AutomaticCanvasSize, scroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
scroll.ZIndex, scroll.Parent = 22, panel

local function makePage(name)
	local p = Instance.new("Frame")
	p.Name, p.BackgroundTransparency, p.Size = name, 1, UDim2.new(1, -8, 0, 0)
	p.AutomaticSize, p.ZIndex, p.Visible = Enum.AutomaticSize.Y, 23, false
	p.Parent = scroll
	local l = Instance.new("UIListLayout")
	l.Padding, l.SortOrder, l.Parent = UDim.new(0, 10), Enum.SortOrder.LayoutOrder, p
	pages[name] = p
	return p
end

local function paragraph(parent, content, size)
	local t = label(parent, content, size or 14, UDim2.new(), UDim2.new(1, 0, 0, 0))
	t.AutomaticSize, t.TextYAlignment, t.Font = Enum.AutomaticSize.Y, Enum.TextYAlignment.Top, Enum.Font.Gotham
	t.TextColor3 = muted
	return t
end

local function clearPage(p)
	for _, child in ipairs(p:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
end

local trailPage = makePage("Estelas")
paragraph(trailPage, "Tu estilo, tus colores. Las estelas son cosméticas: no cambian la velocidad ni las respuestas. Gana monedas jugando o compra un paquete opcional.")
for i, trail in ipairs(Config.Trails or {}) do
	local key = tostring(trail.Key or trail.Id or i)
	local b = button(trailPage, trail.Name or key, UDim2.new(), UDim2.new(1, 0, 0, 64), function()
		if (trail.Access == "VIP" or trail.VIP) and not (latest.Profile and latest.Profile.VIP) then
			openPage("Robux")
		else actionEvent:FireServer("Trail", tonumber(key) or key) end
	end)
	b.LayoutOrder = i
	b.BackgroundColor3 = Color3.fromRGB(33, 43, 66)
	local accent = Instance.new("Frame")
	accent.Position, accent.Size = UDim2.fromOffset(8, 8), UDim2.new(0, 5, 1, -16)
	local rgb = trail.ColorRGB
	accent.BackgroundColor3 = typeof(trail.Color) == "Color3" and trail.Color or (rgb and Color3.fromRGB(rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b)) or violet
	accent.BorderSizePixel, accent.ZIndex, accent.Parent = 0, b.ZIndex + 1, b
	corners(accent, 3)
	trailButtons[key] = { Button = b, Trail = trail }
end
local robuxPage = makePage("Robux")
local missionsPage = makePage("Misiones")
local album = makePage("Álbum")
local practicePage = makePage("Entrenar")
local help = makePage("Ayuda")
paragraph(help,
	"CINCO CAMINOS. UN COLOR CORRECTO.\n\n"
	.. "1. Mira el personaje original durante dos segundos. Recuerda el color de la parte destacada.\n"
	.. "2. Corre a una de las cinco imágenes. Colócate detrás de la puerta que conserva el color original.\n"
	.. "3. Puedes cambiar de dirección hasta cruzar una puerta. Cruzarla confirma tu elección: si es correcta sigues; si es incorrecta quedas eliminado.\n"
	.. "4. Si aciertas, sigues. Si fallas, esperas gratis en el vestíbulo o usas un crédito de reentrada válido.\n\n"
	.. "FINAL\nCon dos corredores, gana el primero que llega al camino correcto. Elegir un camino incorrecto te elimina. "
	.. "Cada finalista puede usar como máximo una reentrada en la final si todavía no ha usado su reentrada de esa partida. "
	.. "Activa la reentrada automática antes de competir si quieres usar un crédito que ya tienes al fallar. Nunca se inicia una compra automática. Una victoria anunciada no se revoca.\n\n"
	.. "CRÉDITOS DE REENTRADA\nUna reentrada por jugador y partida, incluida la final. La reentrada vuelve a una etapa válida; no compra una respuesta ni una victoria. "
	.. "Si compras un crédito y la partida ya terminó, lo conservas para otra. Si todos fallan, la etapa se repite sin consumir créditos.\n\n"
	.. "CONTROLES\nComputadora: WASD o flechas para correr, espacio para saltar. Celular: joystick y botón de salto. "
	.. "Corre físicamente a las puertas; tocar imágenes en la pantalla no elige un camino.\n\n"
	.. "ENTRENAMIENTO GRATUITO\nMientras esperas puedes practicar en la pestaña Entrenar. Mira dos segundos y toca una de cinco imágenes. "
	.. "Es una práctica local: no entrega monedas, XP ni créditos, y no cuenta como una carrera. Cuando empiece tu partida se cierra automáticamente.\n\n"
	.. "MONEDAS Y VIP\nMonedas, estelas, XP y misiones se obtienen jugando. El VIP es un pase permanente con cosméticos exclusivos. "
	.. "Roblox Premium es otra suscripción y no sustituye el VIP. Las monedas y los créditos no se canjean por Robux ni dinero. "
	.. "Los precios y la confirmación de pago aparecen en la ventana oficial de Roblox.\n\n"
	.. "GUARDADO\nEl progreso se guarda en la experiencia publicada. Studio utiliza datos temporales. Si el estado de guardado indica un problema, espera a que se recupere.", 15)

local autoRevive = button(help, "", UDim2.new(), UDim2.new(1, 0, 0, 68), function()
	actionEvent:FireServer("AutoRevive", not (latest.Profile and latest.Profile.AutoRevive))
end)
autoRevive.LayoutOrder = 10
autoRevive.BackgroundColor3 = Color3.fromRGB(41, 48, 75)

local function getCatalog()
	local c = latest.Catalog or latest.Commerce or {}
	return type(c.Catalog) == "table" and c.Catalog or c
end

local function catalogKey()
	local values = {}
	for _, offer in ipairs(getCatalog()) do
		values[#values + 1] = table.concat({ tostring(offer.Key), tostring(offer.Kind), tostring(offer.Id), tostring(offer.Available), tostring(offer.Name), tostring(offer.Description) }, "|")
	end
	return table.concat(values, ";")
end

local function updateOffer(row)
	local e, b, quote = row.Entry, row.Button, row.Quote
	local enabled = e.Available == true and type(e.Id) == "number" and e.Id > 0 and not e.Owned
	if e.Owned then b.Text = "ADQUIRIDO"
	elseif not enabled then b.Text = "NO DISPONIBLE"
	elseif quote and quote.ForSale == false then b.Text, enabled = "NO DISPONIBLE", false
	elseif row.Loading then b.Text, enabled = "CONSULTANDO PRECIO...", false
	elseif quote and quote.Price then b.Text = "COMPRAR  ·  R$ " .. tostring(quote.Price)
	else b.Text = "VER PRECIO EN ROBLOX" end
	b.Active, b.Selectable, b.AutoButtonColor = enabled, enabled, enabled
	b.BackgroundColor3 = enabled and violet or Color3.fromRGB(43, 51, 72)
end

local function productInfo(id, kind)
	local infoType = kind == "Pass" and Enum.InfoType.GamePass or Enum.InfoType.Product
	local present, method = pcall(function() return MarketplaceService.GetProductInfoAsync end)
	if present and type(method) == "function" then return method(MarketplaceService, id, infoType) end
	return MarketplaceService:GetProductInfo(id, infoType)
end

local function rebuildCommerce()
	quoteGeneration += 1
	local generation = quoteGeneration
	catalogSignature = catalogKey()
	clearPage(robuxPage)
	offerRows = {}
	paragraph(robuxPage, "Compras opcionales con resultado conocido. Puedes esperar la siguiente partida sin pagar. Las estelas y el VIP no aumentan tu velocidad. El precio final se confirma en el diálogo oficial de Roblox.")
	for i, offer in ipairs(getCatalog()) do
		local c = card(robuxPage, 155)
		c.LayoutOrder = i
		label(c, offer.Name or "Oferta", 19, UDim2.fromOffset(13, 9), UDim2.new(1, -26, 0, 25))
		local description = label(c, offer.Description or "", 13, UDim2.fromOffset(13, 37), UDim2.new(1, -26, 0, 60))
		description.Font, description.TextColor3 = Enum.Font.Gotham, muted
		local row = { Entry = offer }
		row.Button = button(c, "", UDim2.fromOffset(12, 104), UDim2.new(1, -24, 0, 39), function()
			local e = row.Entry
			if not e.Available or e.Owned or row.Loading or (row.Quote and row.Quote.ForSale == false) then return end
			if os.clock() - lastPurchaseRequest < 1 then return end
			lastPurchaseRequest = os.clock()
			actionEvent:FireServer("ShopBuy", { Kind = e.Kind, Key = e.Key })
		end)
		offerRows[i] = row
		if offer.Available and type(offer.Id) == "number" and offer.Id > 0 and not offer.Owned then
			row.Loading = true
			task.spawn(function()
				local ok, info = pcall(productInfo, offer.Id, offer.Kind)
				if generation ~= quoteGeneration or not row.Button.Parent then return end
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
	local notice = paragraph(robuxPage, "Los paquetes se pueden comprar varias veces. El VIP se compra una vez. Los créditos permanecen guardados hasta usarlos; solo se consume un crédito cuando la reentrada es válida. Las monedas no son Robux.", 13)
	notice.LayoutOrder = 100
end

local function missionsKey()
	local p = latest.Progression or {}
	local values = { tostring(p.Level), tostring(p.LevelProgress) }
	for _, m in ipairs(p.Missions or {}) do values[#values + 1] = table.concat({ tostring(m.Key), tostring(m.Count), tostring(m.Claimed), tostring(m.Complete) }, "|") end
	return table.concat(values, ";")
end

local function rebuildMissions()
	missionSignature = missionsKey()
	clearPage(missionsPage)
	local p = latest.Progression or {}
	paragraph(missionsPage, "NIVEL " .. tostring(p.Level or latest.Profile and latest.Profile.Level or 1) .. "  ·  " .. tostring(p.LevelProgress or 0) .. " / " .. tostring(p.NextLevelXP or 100) .. " XP", 20)
	local intro = paragraph(missionsPage, "Las misiones diarias son gratuitas. Juega, acierta y reclama sus monedas cuando completes el objetivo.")
	intro.LayoutOrder = 1
	if #(p.Missions or {}) == 0 then paragraph(missionsPage, "Esperando tus misiones...").LayoutOrder = 2 end
	for i, m in ipairs(p.Missions or {}) do
		local canClaim = m.Complete == true and not m.Claimed
		local b = button(missionsPage, (m.Name or "Misión") .. "\n" .. tostring(m.Count or 0) .. " / " .. tostring(m.Target or 0) .. "  ·  " .. tostring(m.Reward or 0) .. " monedas\n" .. (m.Claimed and "RECLAMADA" or canClaim and "RECLAMAR" or "EN PROGRESO"), UDim2.new(), UDim2.new(1, 0, 0, 99), function()
			if canClaim then actionEvent:FireServer("ClaimMission", m.Key) end
		end)
		b.LayoutOrder, b.Active, b.Selectable, b.AutoButtonColor = i + 1, canClaim, canClaim, canClaim
		b.BackgroundColor3 = canClaim and Color3.fromRGB(20, 111, 100) or Color3.fromRGB(36, 45, 68)
	end
end

local function rebuildAlbum()
	clearPage(album)
	paragraph(album, "250 personajes originales. Este álbum es gratuito: no vende personajes ni ofrece recompensas aleatorias.")
	local nav = card(album, 44)
	nav.LayoutOrder = 1
	label(nav, "PÁGINA " .. tostring(albumPage) .. " / 25", 13, UDim2.new(0.25, 0, 0, 0), UDim2.new(0.5, 0, 1, 0)).TextXAlignment = Enum.TextXAlignment.Center
	button(nav, "<", UDim2.fromOffset(6, 6), UDim2.new(0.2, 0, 1, -12), function() albumPage = albumPage == 1 and 25 or albumPage - 1; rebuildAlbum() end)
	button(nav, ">", UDim2.new(0.8, -6, 0, 6), UDim2.new(0.2, 0, 1, -12), function() albumPage = albumPage == 25 and 1 or albumPage + 1; rebuildAlbum() end)
	for i = 1, 5 do
		local row = Instance.new("Frame")
		row.BackgroundTransparency, row.Size, row.LayoutOrder, row.ZIndex, row.Parent = 1, UDim2.new(1, 0, 0, 180), i + 1, 24, album
		for j = 1, 2 do
			local id = (albumPage - 1) * 10 + (i - 1) * 2 + j
			local character = Characters.get(id)
			local c = card(row, 180)
			c.Size, c.Position = UDim2.new(0.5, -5, 1, 0), UDim2.new((j - 1) * 0.5, (j - 1) * 10, 0, 0)
			local v = viewport(c, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -40))
			mount(v, id)
			local name = label(c, string.format("%03d  %s", id, character and character.Name or "Personaje"), 12, UDim2.new(0, 7, 1, -35), UDim2.new(1, -14, 0, 30))
			name.TextXAlignment = Enum.TextXAlignment.Center
			fitText(name, 9, 12)
		end
	end
end

local function rebuildPractice()
	cancelPractice()
	clearPage(practicePage)
	paragraph(practicePage, "ENTRENAMIENTO GRATUITO. Practica mientras esperas. No entrega monedas, XP ni créditos; no cambia tu posición ni tus partidas.")
	if latest.Alive == true and (latest.Phase == "RUN" or latest.Phase == "PREVIEW") then
		paragraph(practicePage, "Estás participando en una carrera. Puedes entrenar cuando termine o después de quedar eliminado.")
		return
	end
	local reference = card(practicePage, 220)
	reference.LayoutOrder = 1
	local hint = label(reference, "Pulsa Empezar para memorizar una imagen.", 14, UDim2.fromOffset(10, 8), UDim2.new(1, -20, 0, 28))
	hint.TextXAlignment = Enum.TextXAlignment.Center
	local original = viewport(reference, UDim2.fromScale(0.15, 0.16), UDim2.fromScale(0.7, 0.75))
	local alternatives = Instance.new("Frame")
	alternatives.Size, alternatives.BackgroundTransparency, alternatives.LayoutOrder = UDim2.new(1, 0, 0, 145), 1, 2
	alternatives.ZIndex, alternatives.Parent = practicePage.ZIndex + 1, practicePage
	local options = {}
	local characterId, choices, correct, ready = nil, nil, nil, false
	local startButton
	local function setEnabled(enabled)
		for _, entry in ipairs(options) do
			entry.Button.Active, entry.Button.Selectable, entry.Button.AutoButtonColor = enabled, enabled, enabled
		end
	end
	cancelPractice = function()
		practiceGeneration += 1
		ready = false
		setEnabled(false)
	end
	for i = 1, 5 do
		local b = button(alternatives, "", UDim2.new((i - 1) / 5, 3, 0, 0), UDim2.new(0.2, -6, 1, 0), function()
			if not ready then return end
			ready = false
			setEnabled(false)
			local success = Rules.classify(i, correct) == "correct"
			hint.Text = success and "¡Correcto! Puedes practicar otra imagen." or "El correcto era el camino " .. tostring(correct) .. ". Intenta otra imagen."
			hint.TextColor3 = success and cyan or Color3.fromRGB(255, 133, 155)
			mount(original, characterId)
			for index, entry in ipairs(options) do entry.Button.BackgroundColor3 = index == correct and Color3.fromRGB(22, 119, 100) or Color3.fromRGB(45, 54, 81) end
			startButton.Text, startButton.Active, startButton.Selectable, startButton.AutoButtonColor = "OTRA IMAGEN", true, true, true
			showToast(success and "¡Correcto! Práctica completada." or "Era el camino " .. tostring(correct) .. ". Puedes intentarlo otra vez gratis.")
		end)
		b.Name = "PracticeChoice" .. tostring(i)
		local v = viewport(b, UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.92, 0.77))
		local number = label(b, tostring(i), 12, UDim2.fromScale(0.04, 0.82), UDim2.fromScale(0.92, 0.15))
		number.TextXAlignment = Enum.TextXAlignment.Center
		options[i] = { Button = b, Viewport = v }
	end
	setEnabled(false)
	startButton = button(practicePage, "EMPEZAR", UDim2.new(), UDim2.new(1, 0, 0, 43), function()
		if not startButton.Active then return end
		practiceGeneration += 1
		local generation = practiceGeneration
		ready = false
		setEnabled(false)
		characterId = practiceRandom:NextInteger(1, #Characters.All)
		local character = Characters.get(characterId)
		choices, correct = Rules.options(character.TargetRGB, Characters.Palette, 1, function(low, high) return practiceRandom:NextInteger(low, high) end)
		mount(original, characterId)
		hint.Text, hint.TextColor3 = "MEMORIZA " .. (character.TargetPart == "Helmet" and "EL CASCO" or "EL TRAJE") .. "  ·  2 segundos", cyan
		startButton.Text, startButton.Active, startButton.Selectable, startButton.AutoButtonColor = "MEMORIZANDO...", false, false, false
		for _, entry in ipairs(options) do
			entry.Viewport.Visible = false
			entry.Button.BackgroundColor3 = Color3.fromRGB(45, 54, 81)
		end
		task.delay(2, function()
			if generation ~= practiceGeneration or currentPage ~= "Entrenar" or not overlay.Visible then return end
			mount(original, characterId, nil, true)
			for index, entry in ipairs(options) do mount(entry.Viewport, characterId, choices[index]); entry.Viewport.Visible = true end
			hint.Text = "Toca la imagen que conserva el color original."
			startButton.Text = "ELIGE UNA IMAGEN"
			ready = true
			setEnabled(true)
		end)
	end)
	startButton.Name, startButton.LayoutOrder, startButton.BackgroundColor3 = "PracticeStart", 3, violet
end

openPage = function(name)
	cancelPractice()
	currentPage = name
	for key, p in pairs(pages) do p.Visible = key == name; p.Parent = key == name and scroll or nil end
	for key, b in pairs(tabs) do b.BackgroundColor3 = key == name and violet or Color3.fromRGB(38, 47, 70) end
	heading.Text = name == "Entrenar" and "ENTRENA GRATIS" or name == "Ayuda" and "REGLAS Y REENTRADAS" or name == "Álbum" and "GALERÍA DE PERSONAJES" or "PERSONALIZA TU CARRERA"
	if name == "Robux" then rebuildCommerce()
	elseif name == "Misiones" then rebuildMissions()
	elseif name == "Álbum" then rebuildAlbum()
	elseif name == "Entrenar" then rebuildPractice() end
	scroll.CanvasPosition, overlay.Visible = Vector2.zero, true
end

for i, name in ipairs({ "Estelas", "Robux", "Misiones", "Álbum", "Entrenar", "Ayuda" }) do
	local b = button(panel, string.upper(name), UDim2.new((i - 1) / 6, 6, 0, 56), UDim2.new(1 / 6, -12, 0, 34), function() openPage(name) end)
	fitText(b, 8, 12)
	tabs[name] = b
end

local toast = label(gui, "", 16, UDim2.fromScale(0.5, 0.73), UDim2.new(0.86, 0, 0, 65))
toast.AnchorPoint, toast.TextXAlignment, toast.BackgroundColor3 = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center, dark
toast.BackgroundTransparency, toast.Visible, toast.ZIndex = 0.03, false, 40
corners(toast)
stroke(toast, cyan)
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize, toastLimit.Parent = Vector2.new(590, 65), toast
showToast = function(message)
	toastSerial += 1
	local serial = toastSerial
	toast.Text, toast.Visible = tostring(message), true
	task.delay(4, function() if toastSerial == serial then toast.Visible = false end end)
end

local function worldPortrait(board, id, color, hidden, name, width, height)
	local old = board:FindFirstChild("ColorRushPortrait")
	if old then old:Destroy() end
	local billboard = Instance.new("BillboardGui")
	billboard.Name, billboard.Adornee = "ColorRushPortrait", board
	-- Scale here is measured in world studs. Fixed pixel widths overlap when
	-- viewed from the starting line, especially on a small screen.
	billboard.Size = UDim2.fromScale(width or 10.5, height or 12.4)
	billboard.AlwaysOnTop, billboard.MaxDistance = false, 220
	billboard.Parent = board
	local background = Instance.new("Frame")
	background.Size, background.BackgroundColor3, background.BackgroundTransparency = UDim2.fromScale(1, 1), dark, 0.04
	background.Parent = billboard
	corners(background, 12)
	stroke(background, hidden and muted or cyan, 0.4)
	local v = viewport(background, UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.92, 0.79))
	mount(v, id, color, hidden)
	local caption = label(background, name, 12, UDim2.fromScale(0.03, 0.83), UDim2.fromScale(0.94, 0.15))
	caption.TextXAlignment = Enum.TextXAlignment.Center
	fitText(caption, 11, 16)
	return billboard
end

local function renderWorld(payload)
	local world = workspace:FindFirstChild("ColorRushWorld")
	if not world then return end
	local parts = { tostring(payload.CharacterId), tostring(payload.Phase), tostring(payload.CorrectChoice) }
	for _, rgb in ipairs(payload.Colors or {}) do parts[#parts + 1] = table.concat({ tostring(rgb[1] or rgb.r), tostring(rgb[2] or rgb.g), tostring(rgb[3] or rgb.b) }, ",") end
	local signature = table.concat(parts, "|")
	if signature == worldSignature then return end
	worldSignature = signature
	local show = payload.CharacterId and (payload.Phase == "RUN" or payload.Phase == "REVEAL")
	for i = 1, 5 do
		local board = world:FindFirstChild("Board" .. tostring(i), true)
		if board then
			local old = board:FindFirstChild("ColorRushPortrait")
			if old then old:Destroy() end
			if show and payload.Colors and payload.Colors[i] then
				local caption = "CAMINO " .. tostring(i)
				if payload.Phase == "REVEAL" and payload.CorrectChoice == i then caption = "CORRECTO  ·  " .. tostring(i) end
				worldPortrait(board, payload.CharacterId, payload.Colors[i], false, caption)
			end
		end
	end
	local reference = world:FindFirstChild("ReferenceBoard", true)
	if reference then
		local old = reference:FindFirstChild("ColorRushPortrait")
		if old then old:Destroy() end
		if payload.CharacterId and (show or payload.Phase == "PREVIEW") then
			worldPortrait(reference, payload.CharacterId, nil, payload.Phase == "RUN", payload.Phase == "RUN" and "RECUERDA EL COLOR" or "COLOR ORIGINAL", 23, 17)
		end
	end
end

local dismissedMatch = nil
waitButton.Activated:Connect(function() dismissedMatch = latest.MatchId end)
stateEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.Phase == "PREVIEW" and payload.Alive == true then
		cancelPractice()
		overlay.Visible = false
		toastSerial += 1
		toast.Visible = false
	end
	latest = payload
	local phase = payload.Phase
	title.Text = phase == "LOBBY" and "COLOR RUSH" or payload.Final and "FINAL  ·  COLOR RUSH" or "COLOR RUSH  ·  ETAPA " .. tostring(payload.Round or 0)
	timer.Text = tostring(payload.Seconds or 0) .. "s"
	timer.TextColor3 = phase == "RUN" and (payload.Seconds or 0) <= 3 and Color3.fromRGB(255, 119, 143) or cyan
	instructions.Text = payload.Message or "Corre a la imagen correcta."
	menuButton.Text = (phase == "LOBBY" or payload.Eliminated) and "ENTRENAR" or "TIENDA"
	local profile = payload.Profile or {}
	stats.Text = tostring(profile.Coins or 0) .. " monedas  ·  " .. tostring(profile.Wins or 0) .. " victorias  ·  Nv. " .. tostring(profile.Level or payload.Progression and payload.Progression.Level or 1)
	local selected = payload.SelectedChoice or payload.Selected
	local selection = selected and ("  ·  Camino " .. tostring(selected)) or ""
	status.Text = tostring(payload.RunnerCount or 0) .. " corredores" .. selection .. "  ·  " .. (payload.Persistence or "Cargando progreso")
	preview.Visible = phase == "PREVIEW" and payload.CharacterId ~= nil
	if preview.Visible then
		local signature = tostring(payload.MatchId) .. "/" .. tostring(payload.Round) .. "/" .. tostring(payload.CharacterId)
		if previewSignature ~= signature then
			previewSignature = signature
			mount(previewViewport, payload.CharacterId)
			local character = Characters.get(payload.CharacterId)
			previewCaption.Text = character and character.Name or "Recuerda el color destacado"
			previewHeading.Text = character and character.TargetPart == "Helmet" and "MEMORIZA EL CASCO" or "MEMORIZA EL TRAJE"
		end
	end
	for key, row in pairs(trailButtons) do
		local t = row.Trail
		local owned = profile.OwnedTrails and profile.OwnedTrails[key] or false
		local vip = t.Access == "VIP" or t.VIP == true
		if vip then owned = profile.VIP == true end
		local suffix = tostring(profile.SelectedTrail) == key and "EQUIPADA" or owned and "EQUIPAR" or vip and "VER VIP" or tostring(t.Cost or 0) .. " monedas"
		row.Button.Text = (t.Name or key) .. "  ·  " .. suffix
	end
	autoRevive.Text = "REENTRADA AUTOMÁTICA: " .. (profile.AutoRevive and "ACTIVADA" or "DESACTIVADA") .. "\nUsa solo créditos que ya tienes. Nunca compra automáticamente."
	local credits = profile.ReviveCredits or 0
	local eligible = payload.CanRevive == true and payload.QueuedRevive ~= true
	-- The server supplies eligibility; the client never infers a safe reentry from a loss alone.
	reviveBox.Visible = eligible and payload.MatchId ~= dismissedMatch and not overlay.Visible
	reviveMessage.Text = "Quedaste eliminado. " .. tostring(credits) .. " crédito(s) disponibles.\nPuedes esperar gratis la siguiente partida."
	if payload.QueuedRevive then status.Text = "REENTRADA CONFIRMADA: entrarás en la siguiente etapa." end
	reviveButton.Text = credits > 0 and "USAR 1 CRÉDITO" or "VER CRÉDITO DE REENTRADA"
	if overlay.Visible and currentPage == "Robux" then
		if catalogSignature ~= catalogKey() then rebuildCommerce()
		else for i, offer in ipairs(getCatalog()) do if offerRows[i] then offerRows[i].Entry = offer; updateOffer(offerRows[i]) end end end
	elseif overlay.Visible and currentPage == "Misiones" and missionSignature ~= missionsKey() then rebuildMissions() end
	renderWorld(payload)
	if payload.Toast then showToast(payload.Toast) end
	if payload.OpenShop then openPage("Estelas") end
end)

local viewportConnection
local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local size = camera.ViewportSize
	previewScale.Scale = math.min(1, math.max(0.5, math.min((size.X - 25) / 390, (size.Y - 175) / 355)))
	if UserInputService.TouchEnabled then
		reviveBox.AnchorPoint, reviveBox.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 161)
	else reviveBox.AnchorPoint, reviveBox.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12) end
end
local function watchCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	if workspace.CurrentCamera then viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt) end
	adapt()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H then if overlay.Visible then cancelPractice(); overlay.Visible = false else openPage("Ayuda") end
	elseif input.KeyCode == Enum.KeyCode.Escape then cancelPractice(); overlay.Visible = false end
end)
actionEvent:FireServer("Sync")
