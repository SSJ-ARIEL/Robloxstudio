-- Original procedural portrait art. Models are local, anchored and never enter physics.
-- Every answer renders the exact same geometry, lighting and camera; only the target changes.
local Characters = require(script.Parent.Characters)
local Portrait = {}
local WHITE = Color3.fromRGB(243, 244, 235)
local DARK = Color3.fromRGB(35, 43, 64)
local GRAY = Color3.fromRGB(123, 137, 157)
local GOLD = Color3.fromRGB(245, 210, 132)
local function rgb(value)
	return Color3.fromRGB(value[1], value[2], value[3])
end

function Portrait.build(character, overrideRGB, hideTarget)
	assert(type(character) == "table" and character.Id, "A catalog character is required")
	local model = Instance.new("Model")
	model.Name = "Portrait_" .. character.Id
	model:SetAttribute("CharacterId", character.Id)
	model:SetAttribute("CharacterName", character.Name)
	local skin, accent = rgb(character.SkinRGB), rgb(character.AccentRGB)
	local target = if hideTarget then GRAY else rgb(overrideRGB or character.TargetRGB)
	local coat = if character.TargetPart == "Coat" then target else accent
	local helmet = if character.TargetPart == "Helmet" then target else accent
	local archetype, variant = character.Archetype, character.Variant
	local bodyWidth = ({ 1.7, 1.85, 1.6 })[character.BodyStyle]
	local function make(name, size, position, color, shape, rotation)
		local object = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
		object.Name = name
		object.Size = size
		object.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
		object.Color = color
		object.Material = Enum.Material.SmoothPlastic
		object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		object.CastShadow = false
		object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape == "Ball" then object.Shape = Enum.PartType.Ball end
		if shape == "Cylinder" then object.Shape = Enum.PartType.Cylinder end
		object.Parent = model
		return object
	end
	local function ball(name, x, y, z, sx, sy, sz, color, rotation)
		return make(name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, "Ball", rotation)
	end
	local function block(name, x, y, z, sx, sy, sz, color, rotation)
		return make(name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, nil, rotation)
	end
	local function wedge(name, x, y, z, sx, sy, sz, color, rotation)
		return make(name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, "Wedge", rotation)
	end
	local function disk(name, x, y, z, radius, depth, color)
		return make(name, Vector3.new(depth, radius, radius), Vector3.new(x, y, z), color, "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
	end
	local angle = math.rad(({ 9, -8, 18, -16 })[character.PoseStyle])
	for _, side in ipairs({ -1, 1 }) do
		ball("Boot", side * 0.46, 0.44, 0.14, 0.68, 0.43, 0.97, DARK)
		block("Trouser", side * 0.43, 0.94, 0, 0.55, 0.91, 0.66, DARK)
		ball("BootTrim", side * 0.46, 0.60, 0.12, 0.64, 0.15, 0.85, accent)
		ball("Sleeve", side * (bodyWidth / 2 + 0.23), 2.23, 0, 0.57, 1.25, 0.67, coat, CFrame.Angles(0, 0, side * angle))
		ball("Glove", side * (bodyWidth / 2 + 0.31), 1.65, 0.10, 0.53, 0.52, 0.56, skin)
	end
	ball("TargetCoat", 0, 2.20, 0, bodyWidth, 1.84, 1.02, coat)
	block("Hem", 0, 1.49, 0.06, bodyWidth - 0.12, 0.18, 0.82, DARK)
	ball("Collar", 0, 2.98, 0.09, 0.86, 0.25, 0.96, WHITE)
	block("Zip", 0, 2.16, 0.523, 0.05, 1.19, 0.035, DARK)
	disk("Badge", -0.48, 2.53, 0.53, 0.25, 0.045, GOLD)
	local outfit = character.OutfitStyle
	if outfit == 1 then
		for _, side in ipairs({ -1, 1 }) do block("Pocket", side * 0.48, 1.99, 0.50, 0.43, 0.29, 0.08, accent) end
	elseif outfit == 2 then
		block("Sash", 0, 2.30, 0.53, 0.17, 1.45, 0.06, accent, CFrame.Angles(0, 0, math.rad(28)))
	elseif outfit == 3 then
		for _, side in ipairs({ -1, 1 }) do block("ShoulderPanel", side * 0.6, 2.74, 0.40, 0.43, 0.18, 0.25, accent) end
		block("Belt", 0, 1.82, 0.52, bodyWidth - 0.15, 0.11, 0.07, DARK)
	elseif outfit == 4 then
		for _, side in ipairs({ -1, 1 }) do block("Harness", side * 0.35, 2.19, 0.53, 0.10, 1.2, 0.055, accent) end
		disk("Fastener", 0, 2.30, 0.56, 0.25, 0.04, WHITE)
	else
		block("Scarf", 0, 2.92, 0.48, 0.86, 0.23, 0.19, accent)
		block("ScarfTail", 0.43, 2.52, 0.55, 0.22, 0.66, 0.07, accent, CFrame.Angles(0, 0, math.rad(-10)))
	end
	local headColor = if archetype == "robot" then helmet else skin
	local headWidth = if archetype == "alien" or archetype == "frog" then 1.97 else 1.68
	local headShape = if archetype == "robot" or archetype == "golem" then nil else "Ball"
	make("Head", Vector3.new(headWidth, 1.5, 1.38), Vector3.new(0, 3.80, 0), headColor, headShape)
	local faceZ = 0.68
	if archetype == "robot" then
		block("Display", 0, 3.89, 0.71, 1.36, 0.68, 0.08, DARK)
		for _, side in ipairs({ -1, 1 }) do disk("AudioRing", side * 0.87, 3.81, 0, 0.52, 0.12, GOLD) end
	elseif archetype == "penguin" then
		ball("FaceMask", 0, 3.72, 0.53, 1.41, 1.11, 0.39, WHITE)
		ball("Belly", 0, 2.08, 0.51, 0.81, 0.97, 0.13, WHITE)
	elseif archetype == "panda" then
		for _, side in ipairs({ -1, 1 }) do ball("EyePatch", side * 0.36, 3.92, 0.67, 0.55, 0.63, 0.17, DARK, CFrame.Angles(0, 0, side * 0.18)) end
	end
	local eyeY = if archetype == "frog" then 4.18 else 3.94
	for _, side in ipairs({ -1, 1 }) do
		local x = side * (if archetype == "alien" then 0.44 else 0.34)
		local style = character.EyeStyle
		if archetype == "frog" then ball("EyeSocket", x, eyeY, 0.54, 0.68, 0.66, 0.55, skin) end
		if style == 4 then
			block("Eye", x, eyeY, faceZ + 0.095, 0.28, 0.075, 0.07, if archetype == "robot" then WHITE else DARK, CFrame.Angles(0, 0, side * 0.12))
		else
			local eyeWidth = if style == 2 then 0.29 else 0.35
			local eyeHeight = if style == 3 then 0.43 else 0.35
			ball("EyeWhite", x, eyeY, faceZ, eyeWidth, eyeHeight, 0.15, WHITE)
			ball("Pupil", x + (if style == 5 then 0.04 else 0), eyeY, faceZ + 0.074, 0.16, 0.21, 0.07, DARK)
			ball("EyeSpark", x - 0.03, eyeY + 0.055, faceZ + 0.107, 0.055, 0.055, 0.018, WHITE)
		end
		block("Brow", x, eyeY + 0.26, faceZ - 0.018, 0.32, 0.065, 0.06, DARK, CFrame.Angles(0, 0, side * (0.07 + style * 0.035)))
	end
	local muzzleOffset = if ({ bear = true, panda = true, fox = true, cat = true, shark = true })[archetype] then 0.18 else 0
	ball("Nose", 0, 3.70, faceZ + 0.043 + muzzleOffset, 0.19, 0.14, 0.13, if archetype == "robot" then GOLD else DARK)
	ball("Smile", 0, 3.49, faceZ - 0.002 + muzzleOffset, 0.31, 0.075, 0.06, DARK)
	for _, side in ipairs({ -1, 1 }) do
		if archetype == "fox" or archetype == "cat" then
			local height = if archetype == "fox" then 0.9 else 0.65
			wedge("Ear", side * 0.62, 4.58, 0.01, 0.62, height, 0.54, skin, CFrame.Angles(0, 0, side * math.rad(-12)))
			wedge("InnerEar", side * 0.62, 4.58, 0.31, 0.34, height * 0.65, 0.07, accent)
			ball("Muzzle", side * 0.18, 3.59, 0.64, 0.42, 0.31, 0.30, WHITE)
			for line = 1, 2 do block("Whisker", side * 0.60, 3.62 - line * 0.08, 0.66, 0.37, 0.025, 0.035, DARK, CFrame.Angles(0, 0, side * line * 0.09)) end
		elseif archetype == "bear" or archetype == "panda" then
			ball("Ear", side * 0.73, 4.46, -0.01, 0.64, 0.66, 0.45, if archetype == "panda" then DARK else skin)
			ball("InnerEar", side * 0.73, 4.46, 0.20, 0.32, 0.33, 0.06, accent)
			ball("Muzzle", 0, 3.53, 0.63, 0.77, 0.51, 0.36, WHITE)
		elseif archetype == "rabbit" then
			ball("Ear", side * 0.48, 4.95, -0.10, 0.43, 1.70, 0.42, skin, CFrame.Angles(0, 0, side * (0.08 + variant * 0.016)))
			ball("InnerEar", side * 0.48, 4.99, 0.10, 0.20, 1.15, 0.045, accent, CFrame.Angles(0, 0, side * 0.1))
		elseif archetype == "owl" then
			wedge("Tuft", side * 0.62, 4.51, 0.0, 0.56, 0.59, 0.57, skin)
			disk("FacialDisk", side * 0.36, 3.93, 0.61, 0.70, 0.03, GOLD)
		elseif archetype == "axolotl" then
			for branch = 1, 3 do
				local rotation = CFrame.Angles(0, 0, side * math.rad((branch - 2) * 32))
				ball("Gill", side * (0.93 + branch * 0.04), 3.61 + branch * 0.20, 0.03, 0.79, 0.18, 0.29, accent, rotation)
			end
		elseif archetype == "dragon" then
			wedge("Horn", side * 0.58, 4.57, -0.09, 0.34, 0.76, 0.40, GOLD, CFrame.Angles(0, 0, side * 0.21))
			wedge("Wing", side * 1.17, 2.40, -0.35, 1.09, 1.54, 0.12, accent, CFrame.Angles(0, 0, side * 0.32))
		elseif archetype == "golem" then
			block("StoneBrow", side * 0.38, 4.26, 0.68, 0.63, 0.20, 0.22, skin, CFrame.Angles(0, 0, side * 0.12))
			wedge("Crystal", side * 0.9, 2.92, 0.04, 0.44, 0.70, 0.48, accent)
		end
	end
	if archetype == "owl" or archetype == "penguin" then
		wedge("Beak", 0, 3.65, 0.83, 0.35, 0.32, 0.42, GOLD, CFrame.Angles(math.pi, 0, 0))
	elseif archetype == "alien" then
		for _, side in ipairs({ -1, 1 }) do
			block("Antenna", side * 0.54, 4.65, 0, 0.075, 0.51 + variant * 0.015, 0.075, skin, CFrame.Angles(0, 0, side * 0.28))
			ball("AntennaTip", side * 0.62, 4.94 + variant * 0.008, 0, 0.23, 0.23, 0.23, accent)
		end
	elseif archetype == "shark" then
		wedge("DorsalFin", 0, 4.60, -0.23, 0.38, 0.9, 0.83, skin)
		ball("Snout", 0, 3.66, 0.65, 1.01, 0.54, 0.41, WHITE)
		for tooth = -1, 1 do wedge("Tooth", tooth * 0.15, 3.47, 0.81, 0.11, 0.15, 0.05, WHITE, CFrame.Angles(0, 0, math.pi)) end
	elseif archetype == "mushroom" then
		ball("TargetCap", 0, 4.52, -0.05, 2.64, 1.06, 1.94, helmet)
		ball("CapRim", 0, 4.17, -0.05, 2.59, 0.18, 1.86, WHITE)
		for spot = -2, 2 do ball("CapSpot", spot * 0.40, 4.65 + (2 - math.abs(spot)) * 0.11, 0.63, 0.24, 0.15, 0.10, WHITE) end
	end
	local human = ({ astronaut = true, knight = true, wizard = true, chef = true, diver = true, racer = true, gardener = true, inventor = true, pirate = true, explorer = true })[archetype]
	if human and character.TargetPart ~= "Helmet" then
		local hair = skin:Lerp(DARK, 0.72)
		for lock = -2, 2 do
			local long = if character.Hairstyle == 2 or character.Hairstyle == 5 then 0.49 else 0.25
			ball("HairLock", lock * 0.25, 4.42 - (math.abs(lock) * 0.03), 0.13 + character.Hairstyle * 0.025, 0.58, long, 0.70, hair, CFrame.Angles(0, 0, lock * 0.10))
		end
	end
	if archetype == "astronaut" then
		ball("SpaceHelmet", 0, 3.86, -0.11, 2.13, 1.98, 1.71, WHITE)
		ball("Visor", 0, 3.85, 0.62, 1.69, 1.29, 0.17, DARK)
		block("ChestConsole", 0, 2.19, 0.57, 0.72, 0.43, 0.12, WHITE)
		for light = -1, 1 do disk("ConsoleLight", light * 0.20, 2.21, 0.65, 0.11, 0.025, accent) end
	elseif archetype == "knight" then
		ball("TargetHelmet", 0, 3.91, -0.06, 1.98, 1.83, 1.61, helmet)
		block("VisorSlit", 0, 3.96, 0.74, 1.33, 0.23, 0.08, DARK)
		block("NoseGuard", 0, 3.76, 0.80, 0.15, 0.61, 0.10, helmet)
		ball("Plume", 0, 4.84, -0.13, 0.40, 0.60 + variant * 0.016, 0.85, accent)
		for _, side in ipairs({ -1, 1 }) do ball("Pauldron", side * 1.02, 2.82, 0, 0.70, 0.53, 0.94, GOLD) end
	elseif archetype == "wizard" then
		ball("HatBrim", 0, 4.39, 0, 2.34, 0.17, 1.79, accent)
		wedge("HatCrown", 0, 4.97, -0.16, 1.23, 1.17, 1.03, accent, CFrame.Angles(0, 0, math.rad((variant - 5) * 2)))
		disk("HatRune", 0, 4.81, 0.41, 0.27, 0.03, GOLD)
	elseif archetype == "chef" then
		block("HatBand", 0, 4.53, 0, 1.65, 0.28, 1.25, WHITE)
		for cloud = -1, 1 do ball("Toque", cloud * 0.46, 4.91 + (cloud == 0 and 0.18 or 0), 0, 0.93, 0.79, 1.19, WHITE) end
		block("Apron", 0, 1.94, 0.55, 0.88, 0.87, 0.07, WHITE)
	elseif archetype == "diver" then
		ball("TargetDiveHelmet", 0, 3.86, -0.07, 2.09, 1.99, 1.73, helmet)
		disk("WindowRing", 0, 3.88, 0.81, 1.16, 0.08, GOLD)
		disk("Window", 0, 3.88, 0.865, 0.96, 0.04, DARK)
		for _, side in ipairs({ -1, 1 }) do disk("Valve", side * 0.82, 3.62, 0.63, 0.22, 0.04, WHITE) end
		ball("AirTank", 0, 2.32, -0.58, 1.36, 1.74, 0.57, GOLD)
	elseif archetype == "racer" then
		ball("TargetRaceHelmet", 0, 3.91, -0.06, 1.97, 1.83, 1.57, helmet)
		ball("RaceVisor", 0, 3.97, 0.75, 1.53, 0.69, 0.11, DARK)
		block("VisorShine", -0.33, 4.10, 0.81, 0.42, 0.04, 0.025, WHITE, CFrame.Angles(0, 0, 0.12))
	elseif archetype == "gardener" then
		ball("HatBrim", 0, 4.42, 0, 2.38, 0.20, 1.85, GOLD)
		ball("HatCrown", 0, 4.66, -0.05, 1.64, 0.64, 1.31, GOLD)
		block("HatBand", 0, 4.58, 0.62, 1.36, 0.13, 0.10, accent)
	elseif archetype == "explorer" then
		ball("SafariBrim", 0, 4.43, 0.05, 2.06, 0.20, 1.62, GOLD)
		ball("SafariCrown", 0, 4.70, -0.06, 1.51, 0.77, 1.38, GOLD)
		block("SafariRidge", 0, 4.91, 0.05, 0.15, 0.22, 1.15, WHITE)
		disk("Compass", 0.44, 2.74, 0.60, 0.31, 0.06, DARK)
		wedge("CompassNeedle", 0.44, 2.78, 0.64, 0.10, 0.14, 0.02, WHITE)
	elseif archetype == "inventor" then
		for _, side in ipairs({ -1, 1 }) do
			disk("GoggleRim", side * 0.34, 4.05, 0.81, 0.52, 0.07, GOLD)
			disk("GoggleGlass", side * 0.34, 4.05, 0.855, 0.36, 0.04, DARK)
		end
		block("GoggleBridge", 0, 4.05, 0.84, 0.15, 0.06, 0.05, GOLD)
	elseif archetype == "pirate" then
		ball("HatBrim", 0, 4.42, -0.04, 2.38, 0.24, 1.71, DARK)
		wedge("Tricorn", 0, 4.74, -0.15, 1.87, 0.64, 1.03, DARK)
		disk("CompassEmblem", 0, 4.68, 0.43, 0.26, 0.04, GOLD)
	end
	-- Ten visibly different kit combinations for every archetype. Palette alone is never a variant.
	local kit = character.HeadgearStyle
	if kit == 1 then
		ball("SideRibbon", 0.85, 4.12, 0.26, 0.49, 0.18, 0.20, accent, CFrame.Angles(0, 0, 0.3))
	elseif kit == 2 then
		block("EarComms", -0.88, 3.87, 0.24, 0.22, 0.57, 0.41, GOLD)
		block("CommsMic", -0.69, 3.50, 0.75, 0.38, 0.08, 0.08, DARK)
	elseif kit == 3 then
		for _, side in ipairs({ -1, 1 }) do ball("Mantle", side * 1.0, 2.88, -0.14, 0.57, 0.28, 0.75, accent) end
	elseif kit == 4 then
		block("Notebook", -0.86, 1.66, 0.54, 0.47, 0.68, 0.15, accent, CFrame.Angles(0, 0, -0.16))
		block("BookSpine", -1.05, 1.66, 0.62, 0.08, 0.68, 0.05, GOLD)
	elseif kit == 5 then
		for _, side in ipairs({ -1, 1 }) do ball("Cuff", side * (bodyWidth / 2 + 0.31), 1.84, 0.12, 0.56, 0.17, 0.64, GOLD) end
		ball("Charm", 0.42, 2.72, 0.61, 0.19, 0.24, 0.08, WHITE)
	elseif kit == 6 then
		block("SatchelStrap", -0.50, 2.17, 0.56, 0.14, 1.39, 0.05, GOLD, CFrame.Angles(0, 0, -0.23))
		block("Satchel", -0.76, 1.70, 0.64, 0.66, 0.59, 0.27, accent)
	elseif kit == 7 then
		ball("Brooch", 0.43, 2.80, 0.55, 0.41, 0.31, 0.10, WHITE)
		ball("BroochCore", 0.43, 2.80, 0.61, 0.19, 0.19, 0.04, accent)
	elseif kit == 8 then
		block("FlagPole", 1.20, 2.37, -0.25, 0.055, 2.75, 0.055, GOLD)
		wedge("Pennant", 1.45, 3.59, -0.25, 0.52, 0.65, 0.08, accent)
	elseif kit == 9 then
		ball("Gadget", 0.98, 1.64, 0.41, 0.52, 0.51, 0.26, DARK)
		disk("GadgetDial", 0.98, 1.64, 0.57, 0.26, 0.03, GOLD)
	else
		block("Cape", 0, 2.19, -0.57, 1.54, 1.72, 0.10, accent)
		for _, side in ipairs({ -1, 1 }) do ball("CapeClasp", side * 0.57, 2.87, 0.46, 0.22, 0.22, 0.12, GOLD) end
	end
	return model
end

function Portrait.mount(viewport, characterId, overrideRGB, hideTarget)
	local character = Characters.get(characterId)
	assert(character, "Unknown character ID")
	local previous = viewport:FindFirstChild("PortraitWorld")
	if previous then previous:Destroy() end
	local oldCamera = viewport:FindFirstChild("PortraitCamera")
	if oldCamera then oldCamera:Destroy() end
	local world = Instance.new("WorldModel")
	world.Name, world.Parent = "PortraitWorld", viewport
	local model = Portrait.build(character, overrideRGB, hideTarget)
	model.Parent = world
	local camera = Instance.new("Camera")
	camera.Name = "PortraitCamera"
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 3.10, 10.4), Vector3.new(0, 2.95, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Ambient = Color3.fromRGB(185, 190, 206)
	viewport.LightColor = Color3.fromRGB(255, 248, 235)
	viewport.LightDirection = Vector3.new(-0.5, -0.8, -1)
	return model
end

return Portrait
