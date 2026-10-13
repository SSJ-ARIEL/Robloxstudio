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
local function targetNames(character)
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
local hidden = Color3.fromRGB(123, 137, 157)
local familySignatures, variantSignatures = {}, {}
for _, character in ipairs(catalogModule.All) do
	local normal = Portrait.build(character)
	local recolored = Portrait.build(character, overrideRGB)
	local masked = Portrait.build(character, overrideRGB, true)
	check(normal.ClassName == "Model" and normal:GetAttribute("CharacterId") == character.Id and normal:GetAttribute("CharacterName") == character.Name, "Constructor metadata " .. character.Id)
	local originalParts, recoloredParts, maskedParts = normal:GetChildren(), recolored:GetChildren(), masked:GetChildren()
	check(#originalParts >= 25 and #originalParts == #recoloredParts and #originalParts == #maskedParts, "Color change must not remove geometry " .. character.Id)
	check(modelGeometry(normal) == modelGeometry(recolored) and modelGeometry(normal) == modelGeometry(masked), "Answer and masked variants must preserve exact geometry " .. character.Id)
	local allowed = targetNames(character)
	local targetCount, nonTargetCount = 0, 0
	local targetColor = Color3.fromRGB(character.TargetRGB[1], character.TargetRGB[2], character.TargetRGB[3])
	local allPhysicsSafe, allSizesValid, allColorsValid, allChangesIsolated = true, true, true, true
	for index, part in ipairs(originalParts) do
		local answer, gray = recoloredParts[index], maskedParts[index]
		allPhysicsSafe = allPhysicsSafe and part.Anchored == true and part.CanCollide == false and part.CanTouch == false and part.CanQuery == false and part.CastShadow == false
		allSizesValid = allSizesValid and part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0 and part.CFrame._type == "CFrame"
		allColorsValid = allColorsValid and part.Color._type == "Color3"
		if allowed[part.Name] then
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
		if targetNames(character)[part.Name] then
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
print("Color Rush portrait construction: " .. checks .. " checks passed across 250 characters (simulated values, not engine rendering).")
