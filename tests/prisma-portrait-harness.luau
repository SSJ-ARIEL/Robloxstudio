-- Executes the real art constructors, not Roblox rendering, lighting, projection or physics.
local checks = 0
local function check(condition, message)
	checks += 1
	assert(condition, message)
end
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local Vector3 = {}
function Vector3.new(x, y, z)
	assert(finite(x) and finite(y) and finite(z), "Vector3 components must be finite")
	return { X = x, Y = y, Z = z, _type = "Vector3" }
end
local Color = {}
Color.__index = Color
local Color3 = {}
function Color3.new(r, g, b)
	assert(finite(r) and finite(g) and finite(b), "Color3 channels must be finite")
	assert(r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1, "Color3 channels out of range")
	return setmetatable({ R = r, G = g, B = b, _type = "Color3" }, Color)
end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
function Color:Lerp(other, alpha)
	assert(other._type == "Color3" and finite(alpha), "Lerp requires a color and finite factor")
	return Color3.new(self.R + (other.R - self.R) * alpha, self.G + (other.G - self.G) * alpha, self.B + (other.B - self.B) * alpha)
end
local function sameColor(left, right)
	return math.abs(left.R - right.R) < 1e-9 and math.abs(left.G - right.G) < 1e-9 and math.abs(left.B - right.B) < 1e-9
end

-- Matrix composition catches nonfinite transforms and records actual geometry invariants.
local CF = {}
CF.__index = CF
local function frame(position, rotation)
	return setmetatable({ Position = position, Rotation = rotation, _type = "CFrame" }, CF)
end
local IDENTITY = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local CFrame = {}
function CFrame.new(x, y, z)
	local position = if type(x) == "table" then x else Vector3.new(x or 0, y or 0, z or 0)
	assert(position._type == "Vector3", "CFrame.new requires a position")
	return frame(position, table.clone(IDENTITY))
end
function CF.__mul(left, right)
	assert(left._type == "CFrame" and right._type == "CFrame", "CFrame composition requires frames")
	local a, b, rotation = left.Rotation, right.Rotation, {}
	for row = 0, 2 do
		for column = 0, 2 do
			rotation[row * 3 + column + 1] = a[row * 3 + 1] * b[column + 1] + a[row * 3 + 2] * b[column + 4] + a[row * 3 + 3] * b[column + 7]
		end
	end
	local p, q = left.Position, right.Position
	return frame(Vector3.new(p.X + a[1] * q.X + a[2] * q.Y + a[3] * q.Z, p.Y + a[4] * q.X + a[5] * q.Y + a[6] * q.Z, p.Z + a[7] * q.X + a[8] * q.Y + a[9] * q.Z), rotation)
end
function CFrame.Angles(x, y, z)
	assert(finite(x) and finite(y) and finite(z), "Angles must be finite")
	local sx, cx, sy, cy, sz, cz = math.sin(x), math.cos(x), math.sin(y), math.cos(y), math.sin(z), math.cos(z)
	local origin = Vector3.new(0, 0, 0)
	return frame(origin, { 1, 0, 0, 0, cx, -sx, 0, sx, cx }) * frame(origin, { cy, 0, sy, 0, 1, 0, -sy, 0, cy }) * frame(origin, { cz, -sz, 0, sz, cz, 0, 0, 0, 1 })
end
function CFrame.lookAt(position, target)
	assert(position._type == "Vector3" and target._type == "Vector3", "Camera lookAt requires vectors")
	assert(position.X ~= target.X or position.Y ~= target.Y or position.Z ~= target.Z, "Camera cannot aim at itself")
	local result = frame(position, table.clone(IDENTITY))
	result.LookTarget = target -- Projection and renderer behavior deliberately are not simulated.
	return result
end
CFrame.identity = CFrame.new()

local nodes = {}
local Node = {}
Node.__index = function(self, key)
	if key == "Parent" then return rawget(self, "_parent") end
	return Node[key] or rawget(self, key)
end
Node.__newindex = function(self, key, value)
	if key == "Parent" then
		assert(not self.destroyed or value == nil, "Destroyed instances cannot be reparented")
		local prior = rawget(self, "_parent")
		if prior then
			for index, child in ipairs(prior.children) do
				if child == self then table.remove(prior.children, index); break end
			end
		end
		rawset(self, "_parent", value)
		if value then table.insert(value.children, self) end
	else
		rawset(self, key, value)
	end
end
function Node:GetChildren() return table.clone(self.children) end
function Node:GetDescendants()
	local result = {}
	for _, child in ipairs(self.children) do
		table.insert(result, child)
		for _, nested in ipairs(child:GetDescendants()) do table.insert(result, nested) end
	end
	return result
end
function Node:FindFirstChild(name)
	for _, child in ipairs(self.children) do if child.Name == name then return child end end
	return nil
end
function Node:SetAttribute(name, value) self.attributes[name] = value end
function Node:GetAttribute(name) return self.attributes[name] end
function Node:Destroy()
	for _, child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent = nil
	self.destroyed = true
end
local Instance = {}
local allowedClasses = { Model = true, Part = true, WedgePart = true, WorldModel = true, Camera = true, ViewportFrame = true, Frame = true }
function Instance.new(className)
	assert(allowedClasses[className], "Portrait uses an unexpected instance class: " .. tostring(className))
	local object = setmetatable({ ClassName = className, Name = className, children = {}, attributes = {} }, Node)
	table.insert(nodes, object)
	return object
end
local Enum = {
	Material = { SmoothPlastic = "SmoothPlastic" }, PartType = { Ball = "Ball", Cylinder = "Cylinder" },
	SurfaceType = { Smooth = "Smooth" },
}
local catalogModule = (function()
-- @CHARACTERS_SOURCE@
end)()
local Portrait = (function()
-- @PORTRAIT_SOURCE@
end)()

local function partGeometry(part)
	local components = { part.Name, part.ClassName, part.Shape or "Block", part.Material, part.Size.X, part.Size.Y, part.Size.Z, part.CFrame.Position.X, part.CFrame.Position.Y, part.CFrame.Position.Z }
	for _, element in ipairs(part.CFrame.Rotation) do table.insert(components, element) end
	for index, component in ipairs(components) do components[index] = tostring(component) end
	return table.concat(components, "/")
end
local function modelGeometry(model)
	local components = {}
	for _, part in ipairs(model:GetChildren()) do table.insert(components, partGeometry(part)) end
	return table.concat(components, ";")
end
local function legacyTargetNames(character)
	if character.TargetPart == "Coat" then return { TargetCoat = true, Sleeve = true } end
	local familyNames = {
		robot = { Head = true }, mushroom = { TargetCap = true },
		knight = { TargetHelmet = true, NoseGuard = true },
		diver = { TargetDiveHelmet = true }, racer = { TargetRaceHelmet = true },
	}
	return assert(familyNames[character.Archetype], "Missing target region contract")
end
local overrideRGB = { 17, 99, 231 }
local override = Color3.fromRGB(17, 99, 231)
local hidden = Color3.fromRGB(139, 150, 169)
local familySignatures, variantSignatures = {}, {}
for _, character in ipairs(catalogModule.All) do
	local normal = Portrait.build(character)
	local recolored = Portrait.build(character, overrideRGB)
	local masked = Portrait.build(character, overrideRGB, true)
	check(normal.ClassName == "Model" and normal:GetAttribute("CharacterId") == character.Id and normal:GetAttribute("CharacterName") == character.Name, "Constructor metadata " .. character.Id)
	local originalParts, recoloredParts, maskedParts = normal:GetChildren(), recolored:GetChildren(), masked:GetChildren()
	check(#originalParts >= 25 and #originalParts == #recoloredParts and #originalParts == #maskedParts, "Color change must not remove geometry " .. character.Id)
	check(modelGeometry(normal) == modelGeometry(recolored) and modelGeometry(normal) == modelGeometry(masked), "Answer and masked variants must preserve exact geometry " .. character.Id)
	-- All target areas are explicitly tagged by the real art constructor.
	local targetCount, nonTargetCount = 0, 0
	local targetColor = Color3.fromRGB(character.TargetRGB[1], character.TargetRGB[2], character.TargetRGB[3])
	local allPhysicsSafe, allSizesValid, allColorsValid, allChangesIsolated = true, true, true, true
	for index, part in ipairs(originalParts) do
		local answer, gray = recoloredParts[index], maskedParts[index]
		allPhysicsSafe = allPhysicsSafe and part.Anchored == true and part.CanCollide == false and part.CanTouch == false and part.CanQuery == false and part.CastShadow == false
		allSizesValid = allSizesValid and part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0 and part.CFrame._type == "CFrame"
		allColorsValid = allColorsValid and part.Color._type == "Color3"
		if part:GetAttribute("ColorTarget") == true then
			targetCount += 1
			allChangesIsolated = allChangesIsolated and sameColor(part.Color, targetColor) and sameColor(answer.Color, override) and sameColor(gray.Color, hidden)
		else
			nonTargetCount += 1
			allChangesIsolated = allChangesIsolated and sameColor(part.Color, answer.Color) and sameColor(part.Color, gray.Color)
		end
	end
	check(allPhysicsSafe, "Every portrait part is anchored and excluded from collision/touch/query " .. character.Id)
	check(allSizesValid and allColorsValid, "Every portrait transform, size and color is usable " .. character.Id)
	check(targetCount >= 1 and nonTargetCount > targetCount and allChangesIsolated, "Override and masking change only the intended region " .. character.Id)
	local signature = modelGeometry(normal)
	variantSignatures[character.Archetype] = variantSignatures[character.Archetype] or {}
	check(not variantSignatures[character.Archetype][signature], "Every family variant needs distinct geometry " .. character.Id)
	variantSignatures[character.Archetype][signature] = true
	if character.Variant == 1 then
		check(not familySignatures[signature], "Archetype silhouettes must be distinct " .. character.Id)
		familySignatures[signature] = true
	end
	normal:Destroy(); recolored:Destroy(); masked:Destroy()
end
local countFamilies = 0
for _ in pairs(familySignatures) do countFamilies += 1 end
check(countFamilies == 25, "All 25 archetypes have distinct geometric silhouettes")

local viewport = Instance.new("ViewportFrame")
local decoration = Instance.new("Frame")
decoration.Name, decoration.Parent = "KeepUI", viewport
local priorModel, priorWorld, priorCamera = nil, nil, nil
for _, character in ipairs(catalogModule.All) do
	local model = Portrait.mount(viewport, character.Id, overrideRGB, character.Id % 2 == 0)
	if priorModel then
		check(priorModel.destroyed and priorWorld.destroyed and priorCamera.destroyed, "Replacing a portrait destroys all prior model resources " .. character.Id)
	end
	local world, camera = viewport:FindFirstChild("PortraitWorld"), viewport:FindFirstChild("PortraitCamera")
	check(#viewport:GetChildren() == 3 and world.ClassName == "WorldModel" and camera.ClassName == "Camera", "Repeated mounts keep one world, one camera and existing decoration " .. character.Id)
	check(model.Parent == world and #world:GetChildren() == 1 and viewport.CurrentCamera == camera, "Mounted model and active camera ownership " .. character.Id)
	local expectedColor = if character.Id % 2 == 0 then hidden else override
	local mountedColorsValid, mountedTargets = true, 0
	for _, part in ipairs(model:GetChildren()) do
		if part:GetAttribute("ColorTarget") == true then
			mountedTargets += 1
			mountedColorsValid = mountedColorsValid and sameColor(part.Color, expectedColor)
		end
	end
	check(mountedTargets > 0 and mountedColorsValid, "Mount forwards both override and target-mask arguments " .. character.Id)
	check(decoration.Parent == viewport and not decoration.destroyed, "Mount preserves unrelated UI children " .. character.Id)
	check(camera.CFrame.Position.Z > 0 and camera.CFrame.LookTarget.Z == 0 and camera.FieldOfView > 0 and camera.FieldOfView < 90, "Camera configuration aims toward a usable frontal portrait " .. character.Id)
	check(viewport.Ambient._type == "Color3" and viewport.LightColor._type == "Color3" and viewport.LightDirection._type == "Vector3", "Lighting values are fixed and well formed " .. character.Id)
	priorModel, priorWorld, priorCamera = model, world, camera
end
local liveBefore = #viewport:GetDescendants()
local invalidOK = pcall(function() Portrait.mount(viewport, 251) end)
check(not invalidOK and #viewport:GetDescendants() == liveBefore and viewport.CurrentCamera == priorCamera, "Invalid character IDs fail before destroying a working portrait")
viewport:Destroy()
local liveNodes = 0
for _, node in ipairs(nodes) do if not node.destroyed then liveNodes += 1 end end
check(liveNodes == 0, "All constructed and mounted objects can be destroyed without instance leaks")

check(catalogModule.count() == 250 and catalogModule.all() == catalogModule.All, "Stable catalog collection APIs")
local names = {}
for _, citizen in ipairs(catalogModule.All) do
	check(not names[citizen.Name] and #citizen.Family > 0 and citizen.ColorRGB == citizen.TargetRGB, "Citizen name, family and target aliases " .. citizen.Id)
	names[citizen.Name] = true
end
local objectModel = Portrait.mount(viewport, { Id = 1 }, { 17, 99, 231 }, { Framing = "bust" })
check(objectModel:GetAttribute("CharacterId") == 1, "Mount accepts a minimal character payload")
check(viewport.CurrentCamera.CFrame.Position.Z == 9.2, "Bust framing uses a closer lens")
local hiddenModel = Portrait.mount(viewport, catalogModule.get(10), nil, { HideTarget = true })
for _, part in ipairs(hiddenModel:GetChildren()) do
	if part:GetAttribute("ColorTarget") then check(sameColor(part.Color, hidden), "Options table masks the answer target") end
end
check(not pcall(function() Portrait.build(0) end), "Unknown character fails clearly")
check(catalogModule.get("1") == nil and catalogModule.get(1.5) == nil and catalogModule.get(0/0) == nil, "Untrusted IDs cannot select arbitrary catalog objects")
local portraitChecks = checks
-- Real accessory constructors and gesture code; no rendering/animation blending/replication.
for _, class in ipairs({ "Attachment", "WeldConstraint", "Highlight", "BillboardGui", "TextLabel", "Trail", "Humanoid", "Motor6D" }) do allowedClasses[class] = true end
function Node:IsA(class) return self.ClassName == class or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "WedgePart")) end
function Node:FindFirstChildOfClass(class)
	for _, child in ipairs(self.children) do if child:IsA(class) then return child end end
	return nil
end
Enum.HighlightDepthMode = { Occluded = "Occluded" }
Enum.Font = { GothamBold = "GothamBold", GothamBlack = "GothamBlack" }
Enum.EasingStyle, Enum.EasingDirection = { Sine = "Sine" }, { InOut = "InOut", Out = "Out" }
local UDim2 = { fromOffset = function(x, y) return { x, y } end, fromScale = function(x, y) return { x, y } end }
local NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
local ColorSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
local NumberSequence = { new = function(value) return { Keypoints = value } end }
local ColorSequence = { new = function(a, b) return { A = a, B = b } end }
local TweenInfo = { new = function(seconds) return { Time = seconds } end }
local function signal()
	local listeners = {}
	return {
		Connect = function(_, callback)
			local entry = { Callback = callback, Connected = true }
			function entry:Disconnect() self.Connected = false end
			table.insert(listeners, entry)
			return entry
		end,
		Fire = function(_, ...) for _, entry in ipairs(table.clone(listeners)) do if entry.Connected then entry.Callback(...) end end end,
	}
end
local queue, playedTweens, disposed = {}, {}, {}
local task = { spawn = function(f) table.insert(queue, f) end, delay = function(_, f) table.insert(queue, f) end, wait = function(_) return 0.27 end }
local function drain() while #queue > 0 do table.remove(queue, 1)() end end
local tweenService = {}
function tweenService:Create(instance, info, goal)
	local tween = { Instance = instance, Goal = goal, Info = info }
	function tween:Play() table.insert(playedTweens, self); for key, value in pairs(self.Goal) do self.Instance[key] = value end end
	function tween:Cancel() self.Cancelled = true end
	return tween
end
local services = { ReplicatedStorage = {}, TweenService = tweenService, Debris = { AddItem = function(_, instance, seconds) table.insert(disposed, { Instance = instance, Seconds = seconds }) end } }
local game = { GetService = function(_, name) return assert(services[name], "Unknown cosmetic service") end }
local cosmeticsCatalog = (function()
-- @CATALOG_SOURCE@
end)()
local configModule = (function()
-- @CONFIG_SOURCE@
end)()
local Cosmetics = (function()
-- @COSMETICS_SOURCE@
end)()
local scene = Instance.new("Model")
local function playerRig(r15)
	local character = Instance.new("Model")
	character.Name, character.Parent = "TestAvatar", scene
	local root, torso, head = Instance.new("Part"), Instance.new("Part"), Instance.new("Part")
	root.Name, torso.Name, head.Name = "HumanoidRootPart", if r15 then "UpperTorso" else "Torso", "Head"
	root.Size, torso.Size, head.Size = Vector3.new(2, 2, 1), Vector3.new(2, if r15 then 1.6 else 2, 1), Vector3.new(2, 1, 1)
	root.CFrame, torso.CFrame, head.CFrame = CFrame.new(0, 10, 0), CFrame.new(0, 10.5, 0), CFrame.new(0, 12, 0)
	root.Anchored, root.CanCollide, root.CollisionGroup = false, true, "Players"
	root.Parent, torso.Parent, head.Parent = character, character, character
	local humanoid = Instance.new("Humanoid")
	humanoid.Name, humanoid.Health, humanoid.WalkSpeed = "Humanoid", 100, 16
	humanoid.MoveDirection = { Magnitude = 0 }
	humanoid.Running, humanoid.Jumping, humanoid.Died = signal(), signal(), signal()
	humanoid.Parent = character
	for _, name in ipairs(if r15 then { "RightShoulder", "LeftShoulder", "Waist", "Neck" } else { "Right Shoulder", "Left Shoulder", "Neck" }) do
		local motor = Instance.new("Motor6D")
		motor.Name, motor.C0, motor.Parent = name, CFrame.new(0.2, 0.3, 0.4), torso
	end
	return { Character = character }, root, humanoid
end
local function ownedData()
	local data = { Equipped = table.clone(cosmeticsCatalog.Defaults), CosmeticsOwned = {}, Owned = { ["1"] = true }, Selected = 1 }
	for _, item in ipairs(cosmeticsCatalog.Items) do if item.Access ~= "VIP" then data.CosmeticsOwned[item.Id] = true end end
	return data
end
for _, r15 in ipairs({ false, true }) do
	local avatar, root, humanoid = playerRig(r15)
	local rootFrame, previousFolder = root.CFrame, nil
	for _, item in ipairs(cosmeticsCatalog.Items) do
		if item.Kind == "Suit" or item.Kind == "Trail" then
			local data = ownedData()
			data.Equipped[item.Kind] = item.Id
			check(Cosmetics.apply(avatar, data, item.Access == "VIP"), "Applies cosmetic " .. item.Id)
			local folder = avatar.Character:FindFirstChild("ColorChaosCosmetics")
			check(folder and (not previousFolder or previousFolder.destroyed), "Replacement cleans owned folder " .. item.Id)
			previousFolder = folder
			local partCount = 0
			for _, accessory in ipairs(folder:GetChildren()) do
				if accessory:IsA("BasePart") then
					partCount += 1
					local weld = accessory:FindFirstChild("CosmeticWeld")
					check(accessory.Anchored == false and accessory.Massless == true and accessory.CanCollide == false and accessory.CanTouch == false and accessory.CanQuery == false and weld and weld.Part1 == accessory and weld.Part0.Parent == avatar.Character, "Safe welded cosmetic " .. item.Id)
				end
			end
			if item.Kind == "Suit" then check((item.Style == "None" and partCount == 0) or (item.Style ~= "None" and partCount >= 8), "Advertised suit has visible geometry " .. item.Id) end
			if item.Kind == "Trail" and item.Style ~= "None" then
				local trail = folder:FindFirstChild("EquippedTrail")
				check(trail and trail.Attachment0.Parent == root and trail.Attachment1.Parent == root and trail.Lifetime > 0, "Trail follows moving avatar " .. item.Id)
			end
			check(root.CFrame == rootFrame and root.Anchored == false and root.CollisionGroup == "Players" and humanoid.Health == 100 and humanoid.WalkSpeed == 16, "Preserves movement/health " .. item.Id)
		end
	end
	local data = ownedData()
	data.Equipped.Suit, data.Equipped.Trail = "suit_prism", "trail_rainbow"
	data.CosmeticsOwned.suit_prism, data.CosmeticsOwned.trail_rainbow = true, true
	Cosmetics.apply(avatar, data, false)
	local folder = avatar.Character:FindFirstChild("ColorChaosCosmetics")
	check(not folder:FindFirstChild("ChestPlate") and not folder:FindFirstChild("EquippedTrail") and not folder:FindFirstChild("VIPTitle"), "Ownership cannot bypass live VIP entitlement")
	data.Equipped.Suit, data.CosmeticsOwned.suit_nova = "suit_nova", nil
	Cosmetics.apply(avatar, data, false)
	check(not avatar.Character:FindFirstChild("ColorChaosCosmetics"):FindFirstChild("ChestPlate"), "Unearned suit rejected")
	data.Equipped = table.clone(cosmeticsCatalog.Defaults)
	data.Selected, data.Owned["7"] = 7, true
	Cosmetics.apply(avatar, data, false)
	check(avatar.Character:FindFirstChild("ColorChaosCosmetics"):FindFirstChild("EquippedTrail") ~= nil, "Legacy purchased trail retained")
	data.Selected = 1
	Cosmetics.apply(avatar, data, false)
	check(root:FindFirstChild("ColorChaosTrailA") == nil and root:FindFirstChild("ColorChaosTrailB") == nil, "Unequipped trail attachments cleaned")
end
for _, style in ipairs({ "Wave", "Cheer", "Dance", "Spin", "Bow", "Float" }) do
	for _, r15 in ipairs({ false, true }) do
		local avatar, root, humanoid = playerRig(r15)
		local originals = {}
		for _, node in ipairs(avatar.Character:GetDescendants()) do if node:IsA("Motor6D") then originals[node] = node.C0 end end
		local tweenCount, rootFrame = #playedTweens, root.CFrame
		check(Cosmetics.playEmote(avatar, style), "R6/R15 gesture starts " .. style)
		check(not Cosmetics.playEmote(avatar, style), "Gesture throttled " .. style)
		drain()
		check(#playedTweens > tweenCount, "Gesture animates motors " .. style)
		for motor, original in pairs(originals) do check(motor.C0 == original, "Gesture restores joint " .. style) end
		check(root.CFrame == rootFrame and humanoid.WalkSpeed == 16 and root.CollisionGroup == "Players", "Gesture preserves controls " .. style)
	end
end
local cancelAvatar, _, cancelHumanoid = playerRig(true)
check(Cosmetics.playEmote(cancelAvatar, "emote_wave"), "Gesture accepts catalog ID")
cancelHumanoid.Running:Fire(2)
local beforeCancelled = #playedTweens
drain()
check(#playedTweens == beforeCancelled, "Walking cancels queued gesture")
local movingAvatar, _, movingHumanoid = playerRig(true)
movingHumanoid.MoveDirection.Magnitude = 1
check(not Cosmetics.playEmote(movingAvatar, "Wave") and not Cosmetics.playEmote(movingAvatar, "Unknown"), "Moving avatars/unknown gestures rejected")
for _, item in ipairs(cosmeticsCatalog.Items) do
	if item.Kind == "Reaction" then
		local avatar = playerRig(true)
		check(Cosmetics.playReaction(avatar, item), "Reaction displays " .. item.Id)
		local gui = avatar.Character:FindFirstChild("ColorChaosReaction")
		check(gui and gui:FindFirstChild("Bubble").Text == item.Glyph and gui.Adornee == avatar.Character:FindFirstChild("Head"), "Reaction uses authored glyph " .. item.Id)
		check(not Cosmetics.playReaction(avatar, item.Id), "Reaction throttled " .. item.Id)
		check(disposed[#disposed].Instance == gui and disposed[#disposed].Seconds == 2.6, "Reaction expires " .. item.Id)
		Cosmetics.cleanup(avatar)
		drain()
	end
end
print("Ciudad Prisma portraits: " .. portraitChecks .. " assertions; cosmetics: " .. (checks - portraitChecks) .. " assertions passed (constructor/event mocks; no renderer)")
