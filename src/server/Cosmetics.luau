-- Accessories never replace the user's avatar, collision groups or movement settings.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.ColorChaos.Config)
local Catalog = require(ReplicatedStorage.ColorChaos.Catalog)
local Cosmetics = {}
local activeEmotes = setmetatable({}, { __mode = "k" })
local lastEmote, lastReaction = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
local INK = Color3.fromRGB(36, 48, 73)
local WHITE = Color3.fromRGB(246, 241, 222)
local function rgb(value) return Color3.fromRGB(value[1], value[2], value[3]) end
local function itemFor(data, kind, vip)
	local id = type(data.Equipped) == "table" and data.Equipped[kind] or Catalog.Defaults[kind]
	local item = Catalog.ById[id]
	if not item or item.Kind ~= kind then return Catalog.ById[Catalog.Defaults[kind]] end
	local owned = type(data.CosmeticsOwned) == "table" and data.CosmeticsOwned[item.Id] == true
	if item.Access == "VIP" then owned = vip == true end
	if item.Id == Catalog.Defaults[kind] then owned = true end
	return if owned then item else Catalog.ById[Catalog.Defaults[kind]]
end
local function stopEmote(player)
	local state = activeEmotes[player]
	if not state then return end
	activeEmotes[player] = nil
	for _, connection in ipairs(state.Connections) do connection:Disconnect() end
	for _, tween in ipairs(state.Tweens) do tween:Cancel() end
	for motor, original in pairs(state.Originals) do
		if motor.Parent then motor.C0 = original end
	end
	if state.Effect then state.Effect:Destroy() end
end
function Cosmetics.stopEmote(player) stopEmote(player) end

local function attach(folder, body, name, size, offset, color, shape)
	local part = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
	part.Name, part.Size = name, size
	part.CFrame = body.CFrame * offset
	part.Color, part.Material = color, Enum.Material.SmoothPlastic
	part.Anchored, part.Massless = false, true
	part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false, false, false, false
	if shape == "Ball" then part.Shape = Enum.PartType.Ball end
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part:SetAttribute("ColorChaosCosmetic", true)
	part.Parent = folder
	local weld = Instance.new("WeldConstraint")
	weld.Name, weld.Part0, weld.Part1, weld.Parent = "CosmeticWeld", body, part, part
	return part
end
local function addSuit(folder, character, item)
	if item.Style == "None" then return end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if not torso or not torso:IsA("BasePart") then return end
	local color, accent = rgb(item.Color), rgb(item.Accent)
	local w, h, d = torso.Size.X, torso.Size.Y, torso.Size.Z
	local function panel(name, x, y, z, sx, sy, sz, shade, shape, angle)
		return attach(folder, torso, name, Vector3.new(sx, sy, sz), CFrame.new(x, y, z) * (angle or CFrame.identity), shade or color, shape)
	end
	panel("ChestPlate", 0, 0, -d / 2 - 0.085, w * 0.87, h * 0.83, 0.18, color, "Ball")
	panel("PrismaBadge", -w * 0.23, h * 0.17, -d / 2 - 0.19, 0.24, 0.29, 0.08, accent, "Wedge")
	panel("UtilityBelt", 0, -h * 0.37, -d / 2 - 0.17, w * 0.85, 0.12, 0.11, INK)
	for _, side in ipairs({ -1, 1 }) do
		panel("ShoulderTrim", side * w * 0.46, h * 0.37, 0, w * 0.34, 0.22, d * 1.13, accent, "Ball")
	end
	if item.Style == "Garden" then
		for _, side in ipairs({ -1, 1 }) do
			panel("GardenPocket", side * w * 0.25, -h * 0.10, -d / 2 - 0.20, w * 0.28, h * 0.23, 0.16, accent, "Ball")
		end
		panel("LeafCape", 0, 0, d / 2 + 0.14, w * 0.95, h * 1.21, 0.13, color, "Wedge")
	elseif item.Style == "Astronaut" then
		panel("LifeSupport", 0, 0, d / 2 + 0.25, w * 0.77, h * 0.85, 0.46, WHITE, "Ball")
		panel("FlightConsole", 0, h * 0.06, -d / 2 - 0.22, w * 0.45, h * 0.33, 0.12, WHITE)
		for lamp = -1, 1 do panel("ConsoleLight", lamp * w * 0.11, h * 0.07, -d / 2 - 0.30, 0.11, 0.11, 0.03, accent, "Ball") end
	elseif item.Style == "Pilot" then
		for _, side in ipairs({ -1, 1 }) do panel("Harness", side * w * 0.19, 0, -d / 2 - 0.21, 0.12, h * 0.78, 0.06, accent) end
		panel("Buckle", 0, -h * 0.22, -d / 2 - 0.26, 0.30, 0.20, 0.06, WHITE)
	elseif item.Style == "Explorer" then
		panel("ExplorerPack", 0, 0, d / 2 + 0.27, w * 0.70, h * 0.94, 0.45, color, "Ball")
		panel("BlanketRoll", 0, h * 0.47, d / 2 + 0.30, w * 0.81, 0.27, 0.33, accent, "Ball")
		panel("ScarfTail", -w * 0.26, -h * 0.12, -d / 2 - 0.23, 0.25, h * 0.77, 0.07, accent)
	elseif item.Style == "Knight" or item.Style == "Prism" then
		panel("Cape", 0, -h * 0.10, d / 2 + 0.20, w * 1.09, h * 1.45, 0.11, accent)
		for _, side in ipairs({ -1, 1 }) do
			panel("CrystalPauldron", side * w * 0.49, h * 0.45, 0, w * 0.40, 0.38, d * 1.2, color, "Wedge", CFrame.Angles(0, 0, side * 0.12))
		end
		panel("ChestCrystal", 0, h * 0.14, -d / 2 - 0.24, w * 0.24, h * 0.41, 0.12, accent, "Wedge")
	end
	if head and head:IsA("BasePart") then
		local hw, hh, hd = head.Size.X, head.Size.Y, head.Size.Z
		if item.Style == "Astronaut" then
			-- Open face guard: no opaque sphere hides the player's face or accessories.
			for _, side in ipairs({ -1, 1 }) do
				attach(folder, head, "HelmetSide", Vector3.new(0.16, hh * 1.1, hd * 0.95), CFrame.new(side * (hw / 2 + 0.08), 0, 0), WHITE, "Ball")
			end
			attach(folder, head, "HelmetCrown", Vector3.new(hw * 1.12, 0.15, hd), CFrame.new(0, hh / 2 + 0.10, 0), WHITE, "Ball")
		elseif item.Style == "Garden" then
			attach(folder, head, "SunhatBrim", Vector3.new(hw * 1.42, 0.13, hd * 1.36), CFrame.new(0, hh / 2 + 0.10, 0), accent, "Ball")
			attach(folder, head, "SunhatCrown", Vector3.new(hw * 0.90, 0.36, hd), CFrame.new(0, hh / 2 + 0.28, 0), color, "Ball")
		elseif item.Style == "Prism" then
			for spike = -1, 1 do
				attach(folder, head, "PrismCrown", Vector3.new(hw * 0.23, 0.38 + (if spike == 0 then 0.12 else 0), 0.18), CFrame.new(spike * hw * 0.29, hh / 2 + 0.25, -hd * 0.39), accent, "Wedge")
			end
		end
	end
end

local function addTrail(folder, root, item)
	if item.Style == "None" then return end
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Name, b.Name = "ColorChaosTrailA", "ColorChaosTrailB"
	a.Position, b.Position = Vector3.new(-0.66, 0.2, 0.5), Vector3.new(0.66, 0.2, 0.5)
	a.Parent, b.Parent = root, root
	local trail = Instance.new("Trail")
	trail.Name, trail.Attachment0, trail.Attachment1 = "EquippedTrail", a, b
	trail.FaceCamera, trail.LightEmission = true, 0.55
	trail.Lifetime, trail.MinLength = if item.Style == "Comet" then 0.48 else 0.30, 0.10
	trail.Color = ColorSequence.new(rgb(item.Color), rgb(item.Accent))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.08) })
	trail.Parent = folder
	if item.Style == "Prism" then
		trail.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 144, 188)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(174, 155, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(108, 242, 220)) })
	end
end

function Cosmetics.apply(player, data, vip)
	local character = player.Character
	if not character or type(data) ~= "table" then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return false end
	stopEmote(player)
	local previous = character:FindFirstChild("ColorChaosCosmetics")
	if previous then previous:Destroy() end
	for _, name in ipairs({ "ColorChaosTrailA", "ColorChaosTrailB" }) do
		local attachment = root:FindFirstChild(name)
		if attachment then attachment:Destroy() end
	end
	local folder = Instance.new("Model")
	folder.Name, folder.Parent = "ColorChaosCosmetics", character
	addSuit(folder, character, itemFor(data, "Suit", vip))
	local trailItem = itemFor(data, "Trail", vip)
	-- Legacy aura purchases remain visible, including their original trail benefit.
	local index = type(data.Selected) == "number" and data.Selected or 1
	local palette = Config.Palettes and Config.Palettes[index]
	if palette and ((palette.Access == "VIP" and vip) or (palette.Access ~= "VIP" and (index == 1 or type(data.Owned) == "table" and data.Owned[tostring(index)]))) then
		local aura = Instance.new("Highlight")
		aura.Name, aura.Adornee = "LegacyAura", character
		aura.FillColor, aura.OutlineColor = palette.Color, palette.Color
		aura.FillTransparency, aura.OutlineTransparency = 0.92, 0.42
		aura.DepthMode, aura.Parent = Enum.HighlightDepthMode.Occluded, folder
		if trailItem.Style == "None" and palette.Trail then
			trailItem = { Style = "Ribbon", Color = { palette.Color.R * 255, palette.Color.G * 255, palette.Color.B * 255 }, Accent = { 246, 241, 222 } }
		end
	end
	addTrail(folder, root, trailItem)
	local head = character:FindFirstChild("Head")
	if vip and head then
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Adornee, gui.Size = "VIPTitle", head, UDim2.fromOffset(120, 24)
		gui.StudsOffset, gui.MaxDistance, gui.AlwaysOnTop = Vector3.new(0, 2.3, 0), 75, false
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		text.Text, text.Font, text.TextSize = "✦ VIP PRISMA", Enum.Font.GothamBold, 14
		text.TextColor3, text.TextStrokeTransparency = Color3.fromRGB(222, 196, 255), 0.65
		text.Parent, gui.Parent = gui, folder
	end
	return true
end

local validEmotes = { Wave = true, Cheer = true, Dance = true, Spin = true, Bow = true, Float = true }
function Cosmetics.playEmote(player, style)
	local item = Catalog.ById[style]
	if item then style = if item.Kind == "Emote" then item.Style else nil end
	if not validEmotes[style] then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.MoveDirection.Magnitude > 0.05 then return false end
	local now = os.clock()
	if lastEmote[player] and now - lastEmote[player] < 2 then return false end
	lastEmote[player] = now
	stopEmote(player)
	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local name = string.gsub(descendant.Name, " ", "")
			if name == "RightShoulder" or name == "LeftShoulder" or name == "Waist" or name == "Neck" then motors[name] = descendant end
		end
	end
	if not motors.RightShoulder and not motors.LeftShoulder then return false end
	local state = { Originals = {}, Connections = {}, Tweens = {} }
	for _, motor in pairs(motors) do state.Originals[motor] = motor.C0 end
	activeEmotes[player] = state
	local function cancelIfMoving(speed) if speed > 0.1 and activeEmotes[player] == state then stopEmote(player) end end
	table.insert(state.Connections, humanoid.Running:Connect(cancelIfMoving))
	table.insert(state.Connections, humanoid.Jumping:Connect(function(jumping) if jumping and activeEmotes[player] == state then stopEmote(player) end end))
	table.insert(state.Connections, humanoid.Died:Connect(function() if activeEmotes[player] == state then stopEmote(player) end end))
	local function pose(name, x, y, z, seconds)
		local motor = motors[name]
		if not motor or not motor.Parent then return end
		local tween = TweenService:Create(motor, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { C0 = state.Originals[motor] * CFrame.Angles(x, y, z) })
		table.insert(state.Tweens, tween)
		tween:Play()
	end
	task.spawn(function()
		for beat = 1, 6 do
			if activeEmotes[player] ~= state or player.Character ~= character or not character.Parent then break end
			local swing = if beat % 2 == 0 then 1 else -1
			if style == "Wave" then
				pose("RightShoulder", 0.1, 0.2, -1.55 + swing * 0.27, 0.23)
				pose("Neck", 0, 0, swing * 0.04, 0.23)
			elseif style == "Cheer" then
				pose("RightShoulder", -0.1, 0, -1.85 + swing * 0.18, 0.23)
				pose("LeftShoulder", -0.1, 0, 1.85 - swing * 0.18, 0.23)
			elseif style == "Dance" then
				pose("RightShoulder", swing * 0.35, 0, -0.65, 0.23)
				pose("LeftShoulder", -swing * 0.35, 0, 0.65, 0.23)
				pose("Waist", 0, swing * 0.28, swing * 0.10, 0.23)
			elseif style == "Spin" then
				-- Torso twist, not character rotation: root position and controls never change.
				pose("RightShoulder", 0, swing * 0.32, -1.08, 0.23)
				pose("LeftShoulder", 0, -swing * 0.32, 1.08, 0.23)
				pose("Waist", 0, swing * 0.52, 0, 0.23)
			elseif style == "Bow" then
				pose("Waist", if beat < 5 then 0.44 else 0, 0, 0, 0.25)
				pose("Neck", if beat < 5 then 0.24 else 0, 0, 0, 0.25)
				pose("RightShoulder", -0.25, 0, -0.25, 0.25)
			else
				pose("RightShoulder", 0.12, 0, -0.95 + swing * 0.10, 0.23)
				pose("LeftShoulder", 0.12, 0, 0.95 - swing * 0.10, 0.23)
				pose("Neck", -0.12, swing * 0.12, 0, 0.23)
			end
			task.wait(0.27)
		end
		if activeEmotes[player] == state then stopEmote(player) end
	end)
	return true
end

function Cosmetics.playReaction(player, input)
	local item = if type(input) == "table" then Catalog.ById[input.Id] else Catalog.ById[input]
	if not item or item.Kind ~= "Reaction" then
		for _, entry in ipairs(Catalog.Items) do if entry.Kind == "Reaction" and entry.Style == input then item = entry; break end end
	end
	if not item or item.Kind ~= "Reaction" then return false end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid or humanoid.Health <= 0 then return false end
	local now = os.clock()
	if lastReaction[player] and now - lastReaction[player] < 2 then return false end
	lastReaction[player] = now
	local prior = character:FindFirstChild("ColorChaosReaction")
	if prior then prior:Destroy() end
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee, gui.Size = "ColorChaosReaction", head, UDim2.fromOffset(150, 72)
	gui.AlwaysOnTop, gui.MaxDistance, gui.StudsOffset = false, 90, Vector3.new(0, 3.1, 0)
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.BackgroundTransparency = "Bubble", UDim2.fromScale(1, 1), 1
	label.Text, label.Font, label.TextScaled = item.Glyph, Enum.Font.GothamBlack, true
	label.TextColor3, label.TextStrokeColor3, label.TextStrokeTransparency = rgb(item.Color), INK, 0.35
	label.Parent, gui.Parent = gui, character
	TweenService:Create(gui, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 4.2, 0) }):Play()
	task.delay(1.6, function()
		if label.Parent then TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end
	end)
	Debris:AddItem(gui, 2.6)
	return true
end
Cosmetics.react = Cosmetics.playReaction
function Cosmetics.cleanup(player)
	stopEmote(player)
	lastEmote[player], lastReaction[player] = nil, nil
end
return Cosmetics
