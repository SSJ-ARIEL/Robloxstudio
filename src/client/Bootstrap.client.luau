-- Independent of shared modules and server initialization. A late server must
-- leave a readable welcome message while the serialized lobby keeps players safe.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then return end

local gui = Instance.new("ScreenGui")
gui.Name = "ColorChaosWelcome"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position, panel.Size = UDim2.new(0.5, 0, 0, 12), UDim2.new(0.9, 0, 0, 128)
panel.BackgroundColor3 = Color3.fromRGB(19, 29, 56)
panel.BackgroundTransparency = 0.05
panel.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(650, 128)
limit.Parent = panel
local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 14)
corners.Parent = panel
local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(102, 232, 204)
border.Thickness = 2
border.Parent = panel

local title = Instance.new("TextLabel")
title.Position, title.Size = UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 32)
title.BackgroundTransparency = 1
title.Text = "COLOR CHAOS · CIUDAD PRISMA"
title.TextColor3 = Color3.fromRGB(249, 246, 233)
title.Font, title.TextScaled = Enum.Font.GothamBold, true
title.Parent = panel
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MinTextSize, titleLimit.MaxTextSize = 14, 24
titleLimit.Parent = title

local message = Instance.new("TextLabel")
message.Position, message.Size = UDim2.fromOffset(16, 53), UDim2.new(1, -32, 0, 59)
message.BackgroundTransparency = 1
message.Text = "Estás en el lobby seguro. Preparando la siguiente partida…"
message.TextColor3 = Color3.fromRGB(201, 221, 247)
message.Font, message.TextSize, message.TextWrapped = Enum.Font.Gotham, 16, true
message.Parent = panel

local started = os.clock()
while gui.Parent do
	local mainGui = playerGui:FindFirstChild("ColorChaosUI")
	local status = workspace:GetAttribute("ColorChaosBootStatus")
	-- A snapshot can arrive while server modules are still starting. Both ends
	-- must be ready before dismissing the independent welcome.
	if status == "READY" and mainGui and mainGui:GetAttribute("Ready") == true then
		gui:Destroy()
		break
	end
	if status == "ERROR" then
		message.Text = "La partida no pudo iniciarse. El lobby sigue disponible. Vuelve a entrar para buscar otro servidor."
		border.Color = Color3.fromRGB(255, 145, 169)
	elseif os.clock() - started >= 10 then
		message.Text = "La partida tarda más de lo esperado. Puedes esperar en el lobby seguro."
		border.Color = Color3.fromRGB(255, 188, 97)
	end
	task.wait(0.25)
end
