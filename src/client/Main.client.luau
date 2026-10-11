-- Presentation only. The server decides objectives, currency and ownership.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("ColorChaos")
local Config = require(shared:WaitForChild("Config"))
local remotes = shared:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local actionEvent = remotes:WaitForChild("Action")
local latest = {}
local paletteButtons = {}
local toastSerial = 0

local gui = Instance.new("ScreenGui")
gui.Name = "ColorChaosUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

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
top.Position, top.Size = UDim2.new(0.5, 0, 0, 8), UDim2.new(0.92, 0, 0, 156)
top.BackgroundColor3 = Color3.fromRGB(17, 24, 42)
top.BackgroundTransparency = 0.08
top.Parent = gui
roundCorners(top)
local topConstraint = Instance.new("UISizeConstraint")
topConstraint.MaxSize = Vector2.new(760, 156)
topConstraint.Parent = top
local title = text(top, "COLOR CHAOS", 23, UDim2.fromOffset(14, 9), UDim2.new(1, -100, 0, 29))
local timer = text(top, "--", 24, UDim2.new(1, -78, 0, 9), UDim2.fromOffset(64, 29))
timer.TextXAlignment = Enum.TextXAlignment.Right
local message = text(top, "Conectando con el reactor...", 15, UDim2.fromOffset(14, 44), UDim2.new(1, -28, 0, 44))
local target = text(top, "", 20, UDim2.fromOffset(14, 91), UDim2.new(1, -28, 0, 28))
local bar = Instance.new("Frame")
bar.Position, bar.Size = UDim2.fromOffset(14, 127), UDim2.new(1, -28, 0, 12)
bar.BackgroundColor3 = Color3.fromRGB(49, 60, 82)
bar.Parent = top
roundCorners(bar, 6)
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Config.Colors[3].Color
fill.Parent = bar
roundCorners(fill, 6)

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
local function adaptToScreen()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local touch = UserInputService.TouchEnabled
	local compact = touch and camera.ViewportSize.Y < 500
	local factor = compact and 0.72 or 1
	topScale.Scale, footerScale.Scale = factor, factor
	-- Touch controls occupy the bottom corners; place the HUD above them.
	if touch then
		footer.AnchorPoint = Vector2.new(0.5, 0)
		footer.Position = UDim2.new(0.5, 0, 0, math.floor(156 * factor) + 18)
	else
		footer.AnchorPoint = Vector2.new(0.5, 1)
		footer.Position = UDim2.new(0.5, 0, 1, -12)
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
local balance = text(footer, "0 monedas · 0 victorias", 15, UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 23))
local persistence = text(footer, "Cargando progreso", 11, UDim2.fromOffset(12, 31), UDim2.new(0.6, 0, 0, 19))
local participation = text(footer, "", 11, UDim2.fromOffset(12, 53), UDim2.new(0.58, 0, 0, 24))

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
local heading = text(panel, "AURAS", 25, UDim2.fromOffset(16, 12), UDim2.new(1, -85, 0, 34))
heading.ZIndex = 12
local close = button(panel, "X", UDim2.new(1, -54, 0, 10), UDim2.fromOffset(40, 38), function() overlay.Visible = false end)
close.ZIndex = 12
local scroll = Instance.new("ScrollingFrame")
scroll.Position, scroll.Size = UDim2.fromOffset(16, 57), UDim2.new(1, -32, 1, -73)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ZIndex = 12
scroll.Parent = panel
local shopContent = Instance.new("Frame")
shopContent.Size = UDim2.new(1, -8, 0, 390)
shopContent.BackgroundTransparency = 1
shopContent.ZIndex = 12
shopContent.Parent = scroll
local shopInfo = text(shopContent, "Auras visibles para tu personaje.\nSe compran con monedas del juego. No se usan Robux.", 15, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 58))
shopInfo.ZIndex = 13
for i, palette in ipairs(Config.Palettes) do
	local b = button(shopContent, palette.Name, UDim2.fromOffset(0, 65 + (i - 1) * 70), UDim2.new(1, 0, 0, 59), function()
		actionEvent:FireServer("Palette", i)
	end)
	b.BackgroundColor3 = palette.Color
	b.TextColor3 = Color3.fromRGB(16, 24, 39)
	b.ZIndex = 13
	paletteButtons[i] = b
end
local helpContent = Instance.new("TextLabel")
helpContent.Size = UDim2.new(1, -8, 0, 0)
helpContent.AutomaticSize = Enum.AutomaticSize.Y
helpContent.BackgroundTransparency = 1
helpContent.TextSize = 17
helpContent.TextWrapped = true
helpContent.TextColor3 = Color3.fromRGB(240, 245, 255)
helpContent.Font = Enum.Font.Gotham
helpContent.TextXAlignment, helpContent.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
helpContent.Text = "LA MISIÓN\nUna máquina borró los colores de la ciudad. Coopera para reparar su reactor.\n\nCONTROLES\nAcércate a un panel y mantén E en PC, toca su botón en móvil o usa el botón indicado en consola.\n\nPUENTES DE MEMORIA\nObserva cinco letras. Actívalas en ese orden y cruza al reactor. Un error reinicia los puentes.\n\nREPARACIÓN EN EQUIPO\nVe a la estación de la letra indicada y repárala. El objetivo es compartido.\n\nRESCATE CROMÁTICO\nActiva el panel indicado, cruza a la isla, recoge su chispa y entrégala al reactor. Si el portador cae, la chispa regresa a la isla.\n\nRECOMPENSAS\nColaborar y sobrevivir a una victoria da 35 monedas y una victoria. Colaborar sin lograrlo da 10 monedas. Las auras son cosméticas.\n\nSI CAES O ENTRAS TARDE\nEspera en la plaza hasta la siguiente ronda.\n\nACCESIBILIDAD\nAzul = A · Amarillo = B · Verde = C · Rojo = D. Todas las indicaciones incluyen letras.\n\nGUARDADO\nStudio usa progreso temporal. Una experiencia publicada intenta guardar automáticamente. Si el guardado falla, la interfaz lo avisa."
helpContent.ZIndex = 13
helpContent.Visible = false
helpContent.Parent = scroll

local function openShop()
	heading.Text = "AURAS"
	shopContent.Visible, helpContent.Visible = true, false
	scroll.CanvasPosition = Vector2.zero
	overlay.Visible = true
end
local function openHelp()
	heading.Text = "CÓMO JUGAR"
	shopContent.Visible, helpContent.Visible = false, true
	scroll.CanvasPosition = Vector2.zero
	overlay.Visible = true
end
button(footer, "AURAS", UDim2.new(0.62, 0, 0, 37), UDim2.new(0.18, -6, 0, 36), openShop)
button(footer, "AYUDA", UDim2.new(0.8, 0, 0, 37), UDim2.new(0.2, -12, 0, 36), openHelp)

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

stateEvent.OnClientEvent:Connect(function(payload)
	latest = payload
	title.Text = payload.Mode or "COLOR CHAOS"
	title.TextSize = payload.Mode and 18 or 23
	timer.Text = tostring(payload.Seconds or 0) .. "s"
	message.Text = payload.Message or ""
	local colorIndex = payload.DemoCode or payload.Target
	local color = colorIndex and Config.Colors[colorIndex]
	if color then
		target.Text = (payload.DemoCode and ("PASO " .. tostring(payload.DemoStep or "") .. ": ") or "OBJETIVO: ") .. color.Symbol .. " · " .. color.Name
		target.TextColor3 = color.Color
	else
		target.Text = (payload.Progress or 0) .. " / " .. (payload.Total or 0) .. " objetivos · " .. (payload.Phase or "")
		target.TextColor3 = Color3.fromRGB(230, 235, 255)
	end
	local ratio = payload.Total and payload.Total > 0 and (payload.Progress or 0) / payload.Total or 0
	TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }):Play()
	if payload.Profile then
		balance.Text = payload.Profile.Coins .. " monedas · " .. payload.Profile.Wins .. " victorias"
		for i, b in ipairs(paletteButtons) do
			local owned = payload.Profile.Owned[tostring(i)]
			local status = payload.Profile.Selected == i and "EQUIPADA" or (owned and "EQUIPAR" or Config.Palettes[i].Cost .. " monedas")
			b.Text = Config.Palettes[i].Name .. " · " .. status
		end
	end
	persistence.Text = payload.Persistence or "Cargando progreso"
	if payload.Phase == "JUEGO" or payload.Phase == "PREPARACIÓN" then
		participation.Text = payload.Participating and payload.Alive and "EN EL EQUIPO" or "SIGUIENTE RONDA EN LA PLAZA"
	else participation.Text = "COOPERA · EXPLORA · REPARA" end
	if payload.Toast then showToast(payload.Toast) end
	if payload.OpenShop then openShop() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H then
		if overlay.Visible then overlay.Visible = false else openHelp() end
	elseif input.KeyCode == Enum.KeyCode.Escape then overlay.Visible = false end
end)

-- Request a snapshot after subscribing, since earlier broadcasts may be missed.
actionEvent:FireServer("Sync")
