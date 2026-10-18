-- Original rounded toy sculptures. Alternatives share geometry, pose, lens and lighting.
local Characters = require(script.Parent.Characters)
local Portrait = {}
local IVORY = Color3.fromRGB(248, 243, 227)
local INK = Color3.fromRGB(37, 46, 68)
local GOLD = Color3.fromRGB(246, 210, 133)
local GRAY = Color3.fromRGB(139, 150, 169)
local function rgb(value) return Color3.fromRGB(value[1], value[2], value[3]) end
local function resolve(character)
	local id = if type(character) == "table" then character.Id else character
	return assert(Characters.get(id), "Unknown Ciudad Prisma character")
end

function Portrait.build(input, overrideRGB, hideTarget)
	local citizen = resolve(input)
	local model = Instance.new("Model")
	model.Name = "Portrait_" .. citizen.Id
	model:SetAttribute("CharacterId", citizen.Id)
	model:SetAttribute("CharacterName", citizen.Name)
	local skin, accent = rgb(citizen.SkinRGB), rgb(citizen.AccentRGB)
	local target = if hideTarget then GRAY else rgb(overrideRGB or citizen.ColorRGB)
	local coatTarget, helmetTarget = citizen.TargetPart == "Coat", citizen.TargetPart == "Helmet"
	local coat, helmet = if coatTarget then target else accent, if helmetTarget then target else accent
	local family, variant = citizen.Archetype, citizen.Variant
	local width = ({ 1.65, 1.83, 1.73 })[citizen.BodyStyle]
	local function piece(name, x, y, z, sx, sy, sz, color, shape, rotation, isTarget)
		local part = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
		part.Name = name
		part.Size = Vector3.new(sx, sy, sz)
		part.CFrame = CFrame.new(x, y, z) * (rotation or CFrame.identity)
		part.Color, part.Material = color, Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.CastShadow = false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape == "Ball" then part.Shape = Enum.PartType.Ball end
		if shape == "Cylinder" then part.Shape = Enum.PartType.Cylinder end
		part:SetAttribute("ColorTarget", isTarget == true)
		part.Parent = model
		return part
	end
	local function ball(name, x, y, z, sx, sy, sz, color, rotation, isTarget)
		return piece(name, x, y, z, sx, sy, sz, color, "Ball", rotation, isTarget)
	end
	local function box(name, x, y, z, sx, sy, sz, color, rotation, isTarget)
		return piece(name, x, y, z, sx, sy, sz, color, nil, rotation, isTarget)
	end
	local function wedge(name, x, y, z, sx, sy, sz, color, rotation)
		return piece(name, x, y, z, sx, sy, sz, color, "Wedge", rotation)
	end
	local function disk(name, x, y, z, diameter, depth, color)
		return piece(name, x, y, z, depth, diameter, diameter, color, "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
	end
	local tilt = math.rad(({ 10, -8, 18, -14 })[citizen.PoseStyle])
	for _, side in ipairs({ -1, 1 }) do
		ball("ShoeSole", side * 0.43, 0.27, 0.20, 0.74, 0.19, 0.98, IVORY)
		ball("Shoe", side * 0.43, 0.45, 0.14, 0.70, 0.47, 0.94, INK)
		box("ShoeStripe", side * 0.43, 0.44, 0.59, 0.39, 0.075, 0.035, accent)
		ball("Trouser", side * 0.42, 0.98, 0, 0.57, 1.04, 0.68, INK)
		ball("Sleeve", side * (width / 2 + 0.18), 2.17, 0, 0.62, 1.29, 0.72, coat, CFrame.Angles(0, 0, side * tilt), coatTarget)
		ball("Cuff", side * (width / 2 + 0.25), 1.64, 0.09, 0.57, 0.21, 0.68, IVORY)
		ball("Hand", side * (width / 2 + 0.28), 1.45, 0.16, 0.52, 0.49, 0.54, skin)
		ball("Thumb", side * (width / 2 + 0.05), 1.51, 0.32, 0.21, 0.26, 0.25, skin)
	end
	ball("TargetJacket", 0, 2.07, 0, width, 1.82, 1.12, coat, nil, coatTarget)
	ball("JacketHem", 0, 1.40, 0.02, width * 0.94, 0.27, 1.02, INK)
	ball("Collar", 0, 2.88, 0, 0.98, 0.31, 1.04, IVORY)
	box("Zipper", 0, 2.06, 0.563, 0.055, 1.18, 0.028, INK)
	disk("ZipperPull", 0.005, 2.59, 0.594, 0.10, 0.035, GOLD)
	disk("PrismaBadge", -0.49, 2.43, 0.50, 0.27, 0.055, IVORY)
	wedge("BadgePrism", -0.49, 2.43, 0.535, 0.14, 0.17, 0.04, accent)
	if citizen.OutfitStyle == 1 then
		for _, side in ipairs({ -1, 1 }) do
			ball("Pocket", side * 0.48, 1.87, 0.48, 0.46, 0.36, 0.19, accent)
			box("PocketStitch", side * 0.48, 1.94, 0.57, 0.29, 0.025, 0.025, IVORY)
		end
	elseif citizen.OutfitStyle == 2 then
		box("Sash", 0.17, 2.13, 0.56, 0.18, 1.32, 0.055, accent, CFrame.Angles(0, 0, 0.40))
	elseif citizen.OutfitStyle == 3 then
		for _, side in ipairs({ -1, 1 }) do ball("ShoulderTrim", side * 0.76, 2.65, 0.10, 0.56, 0.19, 0.73, accent) end
	elseif citizen.OutfitStyle == 4 then
		for _, side in ipairs({ -1, 1 }) do box("Harness", side * 0.34, 2.14, 0.55, 0.12, 1.12, 0.05, accent) end
		disk("Clasp", 0, 2.16, 0.60, 0.23, 0.045, GOLD)
	else
		ball("Scarf", 0, 2.84, 0.30, 1.00, 0.25, 0.65, accent)
		box("ScarfTail", 0.45, 2.43, 0.57, 0.25, 0.69, 0.075, accent, CFrame.Angles(0, 0, -0.12))
	end
	local headWidth = if family == "alien" or family == "frog" then 2.15 else 1.94
	local robot = family == "robot"
	local headColor = if robot then helmet else skin
	if robot or family == "golem" then
		box("Head", 0, 3.86, 0, headWidth * 0.90, 1.51, 1.40, headColor, nil, robot)
		ball("HeadCrown", 0, 4.51, -0.02, headWidth * 0.91, 0.30, 1.39, headColor, nil, robot)
	else
		ball("Head", 0, 3.87, 0, headWidth, 1.83, 1.58, skin)
	end
	local faceZ = 0.76
	if robot then
		ball("FaceScreen", 0, 3.89, 0.74, 1.57, 1.10, 0.14, INK)
		for _, side in ipairs({ -1, 1 }) do ball("EarSpeaker", side * 0.96, 3.88, 0, 0.31, 0.65, 0.74, GOLD) end
	elseif family == "penguin" then
		ball("FaceMask", 0, 3.78, 0.61, 1.63, 1.35, 0.38, IVORY)
		ball("Belly", 0, 1.97, 0.55, 0.82, 1.03, 0.13, IVORY)
	elseif family == "panda" then
		for _, side in ipairs({ -1, 1 }) do ball("EyePatch", side * 0.40, 4.02, 0.72, 0.68, 0.75, 0.20, INK, CFrame.Angles(0, 0, side * 0.20)) end
	elseif family == "owl" then
		for _, side in ipairs({ -1, 1 }) do ball("FacialDisc", side * 0.41, 3.98, 0.65, 0.93, 1.07, 0.30, GOLD) end
	end
	local eyeY = if family == "frog" then 4.23 else 4.04
	for _, side in ipairs({ -1, 1 }) do
		local x = side * (if family == "alien" then 0.47 else 0.39)
		if family == "frog" then ball("EyeSocket", x, eyeY, 0.59, 0.78, 0.85, 0.56, skin) end
		if citizen.EyeStyle == 4 then
			box("JoyEye", x, eyeY, faceZ + 0.08, 0.32, 0.075, 0.07, if robot then IVORY else INK, CFrame.Angles(0, 0, side * 0.15))
		else
			ball("EyeWhite", x, eyeY, faceZ, 0.40, if citizen.EyeStyle == 3 then 0.48 else 0.41, 0.16, IVORY)
			ball("Iris", x + (if citizen.EyeStyle == 5 then 0.025 else 0), eyeY, faceZ + 0.081, 0.235, 0.29, 0.075, INK)
			ball("EyeLight", x - 0.047, eyeY + 0.071, faceZ + 0.122, 0.085, 0.085, 0.024, IVORY)
		end
		box("Brow", x, eyeY + 0.31, faceZ - 0.025, 0.35, 0.065, 0.07, INK, CFrame.Angles(0, 0, side * (0.05 + citizen.EyeStyle * 0.025)))
		if not robot then ball("Cheek", side * 0.62, 3.69, 0.66, 0.28, 0.14, 0.045, skin:Lerp(Color3.fromRGB(241, 146, 151), 0.45)) end
	end
	local muzzle = ({ fox = true, cat = true, bear = true, panda = true, shark = true })[family]
	if muzzle then ball("Muzzle", 0, 3.61, 0.70, 0.88, 0.51, 0.38, IVORY) end
	ball("Nose", 0, 3.78, if muzzle then 0.91 else 0.78, 0.20, 0.145, 0.13, if robot then GOLD else INK)
	ball("Smile", 0, 3.51, if muzzle then 0.88 else 0.73, 0.32, 0.075, 0.055, INK)
	for _, side in ipairs({ -1, 1 }) do
		if family == "fox" or family == "cat" then
			local h = if family == "fox" then 1.04 else 0.72
			wedge("Ear", side * 0.72, 4.70, -0.02, 0.67, h, 0.65, skin, CFrame.Angles(0, 0, -side * 0.12))
			wedge("InnerEar", side * 0.72, 4.70, 0.31, 0.36, h * 0.65, 0.04, accent)
			for line = 1, 2 do box("Whisker", side * 0.67, 3.64 - line * 0.09, 0.70, 0.37, 0.026, 0.035, INK, CFrame.Angles(0, 0, side * line * 0.10)) end
		elseif family == "bear" or family == "panda" then
			ball("Ear", side * 0.80, 4.58, 0, 0.73, 0.74, 0.48, if family == "panda" then INK else skin)
			ball("InnerEar", side * 0.80, 4.58, 0.23, 0.37, 0.37, 0.06, accent)
		elseif family == "rabbit" then
			local angle = CFrame.Angles(0, 0, side * (0.08 + variant * 0.018))
			ball("Ear", side * 0.49, 5.10, -0.11, 0.45, 1.70, 0.45, skin, angle)
			ball("InnerEar", side * 0.49, 5.14, 0.10, 0.21, 1.17, 0.05, accent, angle)
		elseif family == "owl" then
			wedge("EarTuft", side * 0.75, 4.61, -0.10, 0.62, 0.66, 0.61, skin)
		elseif family == "axolotl" then
			for branch = 1, 3 do
				local angle = CFrame.Angles(0, 0, side * math.rad((branch - 2) * 35))
				ball("Gill", side * (1.05 + branch * 0.05), 3.54 + branch * 0.25, 0, 0.86, 0.19, 0.32, accent, angle)
				ball("GillTip", side * (1.41 + branch * 0.05), 3.54 + branch * 0.25, 0, 0.20, 0.28, 0.30, skin:Lerp(accent, 0.65), angle)
			end
		elseif family == "dragon" then
			wedge("Horn", side * 0.62, 4.71, -0.14, 0.35, 0.85, 0.43, GOLD, CFrame.Angles(0, 0, side * 0.20))
			wedge("Wing", side * 1.28, 2.45, -0.40, 1.13, 1.69, 0.15, accent, CFrame.Angles(0, 0, side * 0.31))
		elseif family == "golem" then
			box("StoneBrow", side * 0.42, 4.37, 0.72, 0.67, 0.20, 0.23, skin, CFrame.Angles(0, 0, side * 0.11))
			wedge("ShoulderCrystal", side * 0.95, 2.90, 0, 0.51, 0.78, 0.49, accent)
		end
	end
	if family == "owl" or family == "penguin" then
		wedge("Beak", 0, 3.70, 0.91, 0.40, 0.34, 0.43, GOLD, CFrame.Angles(math.pi, 0, 0))
	elseif family == "alien" then
		for _, side in ipairs({ -1, 1 }) do
			box("Antenna", side * 0.59, 4.78, 0, 0.075, 0.55 + variant * 0.016, 0.075, skin, CFrame.Angles(0, 0, side * 0.25))
			ball("AntennaTip", side * 0.67, 5.08 + variant * 0.008, 0, 0.28, 0.28, 0.28, accent)
		end
	elseif family == "shark" then
		wedge("DorsalFin", 0, 4.73, -0.26, 0.38, 1.01, 0.85, skin)
		for tooth = -1, 1 do wedge("Tooth", tooth * 0.15, 3.49, 0.92, 0.11, 0.15, 0.035, IVORY, CFrame.Angles(0, 0, math.pi)) end
	elseif family == "mushroom" then
		ball("TargetCap", 0, 4.65, -0.07, 2.83, 1.17, 2.03, helmet, nil, true)
		ball("CapRim", 0, 4.26, -0.07, 2.76, 0.18, 1.95, IVORY)
		for spot = -2, 2 do ball("CapSpot", spot * 0.42, 4.77 + (2 - math.abs(spot)) * 0.10, 0.72, 0.26, 0.18, 0.09, IVORY) end
	elseif family == "astronaut" then
		-- Open visor: the citizen's face stays visible instead of being buried by a sphere.
		ball("HelmetBack", 0, 3.97, -0.34, 2.20, 2.10, 1.45, IVORY)
		for _, side in ipairs({ -1, 1 }) do ball("HelmetRim", side * 0.99, 3.88, 0.32, 0.20, 1.60, 0.59, IVORY) end
		box("ChestConsole", 0, 2.07, 0.59, 0.69, 0.44, 0.12, IVORY)
		for lamp = -1, 1 do disk("ConsoleLight", lamp * 0.19, 2.08, 0.66, 0.10, 0.03, accent) end
	elseif family == "knight" then
		ball("TargetHelmet", 0, 3.94, -0.08, 2.11, 2.01, 1.72, helmet, nil, true)
		ball("Visor", 0, 4.02, 0.80, 1.55, 0.46, 0.10, INK)
		box("NoseGuard", 0, 3.90, 0.87, 0.16, 0.76, 0.09, helmet, nil, true)
		ball("Plume", 0, 5.00, -0.14, 0.45, 0.65 + variant * 0.015, 0.91, accent)
	elseif family == "wizard" then
		ball("HatBrim", 0, 4.58, 0, 2.45, 0.19, 1.87, accent)
		wedge("HatCrown", 0, 5.13, -0.13, 1.31, 1.14, 1.12, accent, CFrame.Angles(0, 0, math.rad((variant - 5) * 2)))
		disk("HatRune", 0, 5.00, 0.45, 0.28, 0.04, GOLD)
	elseif family == "chef" then
		box("HatBand", 0, 4.63, 0, 1.84, 0.29, 1.35, IVORY)
		for cloud = -1, 1 do ball("Toque", cloud * 0.51, 5.04 + (if cloud == 0 then 0.17 else 0), 0, 1.01, 0.84, 1.31, IVORY) end
		ball("Apron", 0, 1.83, 0.56, 0.88, 0.81, 0.11, IVORY)
	elseif family == "diver" then
		ball("TargetDiveHelmet", 0, 3.95, -0.06, 2.23, 2.12, 1.81, helmet, nil, true)
		disk("WindowRing", 0, 3.97, 0.88, 1.34, 0.10, GOLD)
		disk("Window", 0, 3.97, 0.945, 1.11, 0.04, INK)
		box("WindowGleam", -0.23, 4.18, 0.975, 0.24, 0.05, 0.02, IVORY, CFrame.Angles(0, 0, 0.28))
	elseif family == "racer" then
		ball("TargetRaceHelmet", 0, 3.96, -0.06, 2.10, 1.98, 1.69, helmet, nil, true)
		ball("Visor", 0, 4.05, 0.81, 1.66, 0.78, 0.12, INK)
		box("VisorGleam", -0.36, 4.21, 0.875, 0.47, 0.05, 0.02, IVORY, CFrame.Angles(0, 0, 0.11))
	elseif family == "gardener" then
		ball("SunhatBrim", 0, 4.59, 0, 2.58, 0.22, 1.99, GOLD)
		ball("SunhatCrown", 0, 4.85, -0.07, 1.76, 0.70, 1.44, GOLD)
		ball("HatFlower", 0.73, 4.70, 0.48, 0.32, 0.32, 0.12, accent)
	elseif family == "explorer" then
		ball("SafariBrim", 0, 4.60, 0.06, 2.23, 0.20, 1.76, GOLD)
		ball("SafariCrown", 0, 4.88, -0.07, 1.64, 0.83, 1.49, GOLD)
		box("SafariRidge", 0, 5.10, 0.05, 0.15, 0.22, 1.24, IVORY)
		disk("Compass", 0.49, 2.55, 0.57, 0.33, 0.07, INK)
	elseif family == "inventor" then
		for _, side in ipairs({ -1, 1 }) do
			disk("GoggleRim", side * 0.39, 4.10, 0.85, 0.61, 0.07, GOLD)
			disk("GoggleGlass", side * 0.39, 4.10, 0.90, 0.43, 0.04, INK)
			ball("GoggleGleam", side * 0.39 - 0.07, 4.19, 0.93, 0.12, 0.06, 0.015, IVORY)
		end
		box("GoggleBridge", 0, 4.10, 0.89, 0.19, 0.07, 0.05, GOLD)
	elseif family == "pirate" then
		ball("HatBrim", 0, 4.59, -0.07, 2.57, 0.25, 1.87, INK)
		wedge("Tricorn", 0, 4.94, -0.16, 2.04, 0.71, 1.13, INK)
		disk("CompassEmblem", 0, 4.86, 0.48, 0.30, 0.04, GOLD)
	end
	-- All ten variants alter their silhouette or accessories, even with color removed.
	if variant == 1 then
		ball("Ribbon", 0.99, 4.16, 0.23, 0.48, 0.19, 0.23, accent, CFrame.Angles(0, 0, 0.30))
	elseif variant == 2 then
		box("Comms", -1.02, 3.90, 0.23, 0.23, 0.57, 0.39, GOLD)
		box("Mic", -0.74, 3.50, 0.78, 0.39, 0.07, 0.07, INK)
	elseif variant == 3 then
		for _, side in ipairs({ -1, 1 }) do ball("Mantle", side * 0.97, 2.85, -0.13, 0.62, 0.28, 0.78, GOLD) end
	elseif variant == 4 then
		box("Notebook", -1.05, 1.50, 0.52, 0.50, 0.70, 0.16, accent, CFrame.Angles(0, 0, -0.15))
		box("BookSpine", -1.26, 1.50, 0.60, 0.07, 0.70, 0.04, GOLD)
	elseif variant == 5 then
		ball("Charm", 0.47, 2.58, 0.59, 0.29, 0.32, 0.08, GOLD)
		for _, side in ipairs({ -1, 1 }) do ball("WristRing", side * (width / 2 + 0.28), 1.52, 0.16, 0.55, 0.12, 0.58, GOLD) end
	elseif variant == 6 then
		box("SatchelStrap", -0.50, 2.05, 0.59, 0.15, 1.40, 0.04, GOLD, CFrame.Angles(0, 0, -0.24))
		ball("Satchel", -0.80, 1.48, 0.55, 0.70, 0.60, 0.33, accent)
	elseif variant == 7 then
		ball("Brooch", 0.48, 2.65, 0.56, 0.43, 0.34, 0.11, IVORY)
		ball("BroochCore", 0.48, 2.65, 0.62, 0.20, 0.20, 0.04, accent)
	elseif variant == 8 then
		box("FlagPole", 1.26, 2.46, -0.33, 0.055, 2.89, 0.055, GOLD)
		wedge("Pennant", 1.51, 3.73, -0.33, 0.55, 0.70, 0.08, accent)
	elseif variant == 9 then
		ball("Gadget", 1.04, 1.49, 0.48, 0.55, 0.54, 0.27, INK)
		disk("GadgetDial", 1.04, 1.49, 0.63, 0.28, 0.04, GOLD)
	else
		box("Cape", 0, 2.13, -0.67, 1.70, 1.87, 0.11, accent)
		for _, side in ipairs({ -1, 1 }) do ball("CapeClasp", side * 0.58, 2.75, 0.49, 0.24, 0.23, 0.13, GOLD) end
	end
	return model
end

function Portrait.mount(viewport, input, overrideRGB, options)
	local citizen = resolve(input)
	local hideTarget = options == true or (type(options) == "table" and options.HideTarget == true)
	local previous = viewport:FindFirstChild("PortraitWorld")
	if previous then previous:Destroy() end
	local previousCamera = viewport:FindFirstChild("PortraitCamera")
	if previousCamera then previousCamera:Destroy() end
	local world = Instance.new("WorldModel")
	world.Name, world.Parent = "PortraitWorld", viewport
	local model = Portrait.build(citizen, overrideRGB, hideTarget)
	model.Parent = world
	local camera = Instance.new("Camera")
	camera.Name, camera.FieldOfView = "PortraitCamera", 34
	local bust = type(options) == "table" and options.Framing == "bust"
	camera.CFrame = if bust then CFrame.lookAt(Vector3.new(0, 3.9, 9.2), Vector3.new(0, 3.65, 0)) else CFrame.lookAt(Vector3.new(0, 3.25, 11.8), Vector3.new(0, 3.10, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Ambient = Color3.fromRGB(188, 198, 215)
	viewport.LightColor = Color3.fromRGB(255, 246, 224)
	viewport.LightDirection = Vector3.new(-0.45, -0.75, -1)
	return model
end

return table.freeze(Portrait)
