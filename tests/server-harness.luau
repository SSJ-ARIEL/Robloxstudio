-- Minimal orchestration mocks, not a Roblox engine or physics replacement.
-- @SCENARIO@
local now = 1
local jobs = {}
local warnings = {}
local function warn(message) table.insert(warnings, tostring(message)) end
local os = { clock = function() return now end, time = function() return 1700000000 + math.floor(now) end }
local function enqueue(thread, due)
	table.insert(jobs, { Thread = thread, Due = due })
end
local task = {}
function task.spawn(callback, ...)
	local args = table.pack(...)
	enqueue(coroutine.create(function() callback(table.unpack(args, 1, args.n)) end), now)
end
function task.delay(seconds, callback) enqueue(coroutine.create(callback), now + seconds) end
function task.wait(seconds) return coroutine.yield(seconds or 0.03) end
local function nextJob()
	local best = 1
	for i = 2, #jobs do if jobs[i].Due < jobs[best].Due then best = i end end
	return best
end
local function runUntil(predicate, timeout)
	local deadline, iterations = now + timeout, 0
	while not predicate() do
		assert(#jobs > 0, "Scheduler stopped before expected state")
		local index = nextJob()
		local job = table.remove(jobs, index)
		assert(job.Due <= deadline, "Timed out waiting for simulated server state")
		now = job.Due
		local ok, delay = coroutine.resume(job.Thread)
		assert(ok, tostring(delay))
		if coroutine.status(job.Thread) ~= "dead" then enqueue(job.Thread, now + (delay or 0.03)) end
		iterations += 1
		assert(iterations < 10000, "Scheduler runaway")
	end
end
local function advance(seconds)
	local target = now + seconds
	while #jobs > 0 and jobs[nextJob()].Due <= target do
		local job = table.remove(jobs, nextJob())
		now = job.Due
		local ok, delay = coroutine.resume(job.Thread)
		assert(ok, tostring(delay))
		if coroutine.status(job.Thread) ~= "dead" then enqueue(job.Thread, now + (delay or 0.03)) end
	end
	now = target
end

local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback) table.insert(callbacks, callback); return { Disconnect = function() end } end,
		Fire = function(_, ...) for _, callback in ipairs(callbacks) do callback(...) end end,
	}
end
local Vector3 = {}
local vectorMeta = {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta) end
vectorMeta.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMeta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end
vectorMeta.__index = function(v, key) if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end end
Vector3.zero = Vector3.new()
local Vector2 = { new = function(...) return { ... } end, zero = {} }
local frameMeta = {}
local CFrame = {}
function CFrame.new(position, y, z)
	return setmetatable({ Position = type(position) == "number" and Vector3.new(position, y, z) or position or Vector3.zero }, frameMeta)
end
frameMeta.__add = function(frame, offset) return CFrame.new(frame.Position + offset) end
local Color3 = { fromRGB = function(...) return { ... } end, new = function(...) return { ... } end }
local UDim = { new = function(...) return { ... } end }
local UDim2 = { new = function(...) return { ... } end, fromOffset = function(...) return { ... } end, fromScale = function(...) return { ... } end }
local Enum = setmetatable({}, { __index = function(_, category) return setmetatable({}, { __index = function(_, value) return category .. "." .. value end }) end })
local Random = { new = function() return { NextInteger = function(_, minimum) return minimum end } end }

local function clone(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in pairs(value) do copy[key] = clone(child) end
	return copy
end
local instanceMeta = {}
local methods = {}
local Instance = {}
instanceMeta.__index = function(object, key)
	if methods[key] then return methods[key] end
	if object._properties[key] ~= nil then return object._properties[key] end
	for _, child in ipairs(object._children) do if child.Name == key then return child end end
	return nil
end
instanceMeta.__newindex = function(object, key, value)
	if key == "Parent" then
		local old = object._properties.Parent
		if old then
			for i, child in ipairs(old._children) do if child == object then table.remove(old._children, i); break end end
		end
		if value then table.insert(value._children, object) end
	end
	object._properties[key] = value
	if key == "Position" then object._properties.CFrame = CFrame.new(value) end
	if key == "CFrame" then object._properties.Position = value.Position end
end
function Instance.new(className)
	local object = setmetatable({ _properties = { ClassName = className, Name = className }, _children = {} }, instanceMeta)
	if className == "ProximityPrompt" then object.Triggered = signal(); object.Enabled = true end
	if className == "Humanoid" then object.Died = signal(); object.Health = 100; object.HipHeight = 2 end
	if className == "RemoteEvent" then object.OnServerEvent = signal() end
	if className == "Part" or className == "SpawnLocation" or className == "WedgePart" then
		object.Size, object.Position = Vector3.new(2, 2, 2), Vector3.zero
		object.Anchored, object.CanCollide, object.Transparency, object.Touched = false, true, 0, signal()
	end
	return object
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(self._children) do if child.Name == name then return child end end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = child:FindFirstChild(name, true)
			if found then return found end
		end
	end
	return nil
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result = {}
	for _, child in ipairs(self._children) do
		table.insert(result, child)
		for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end
	end
	return result
end
function methods:IsA(className)
	return self.ClassName == className or (className == "BasePart"
		and (self.ClassName == "Part" or self.ClassName == "SpawnLocation" or self.ClassName == "WedgePart"))
end
function methods:SetAttribute(name, value)
	self._attributes = self._attributes or {}
	self._attributes[name] = value
end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:FindFirstChildOfClass(className)
	for _, child in ipairs(self._children) do if child.ClassName == className then return child end end
	return nil
end
function methods:WaitForChild(name, timeout)
	local child = self:FindFirstChild(name)
	if timeout and not child then return nil end
	assert(child, "Harness missing expected child: " .. name)
	return child
end
function methods:Destroy()
	for i = #self._children, 1, -1 do self._children[i]:Destroy() end
	self.Parent = nil
	self.Destroyed = true
end
function methods:PivotTo(frame) self.HumanoidRootPart.Position = frame.Position end
function methods:FireClient(player, payload)
	if self.Name == "State" then player.Latest = clone(payload); table.insert(player.States, clone(payload)) end
end

local players = Instance.new("Players")
players.PlayerAdded, players.PlayerRemoving = signal(), signal()
players.List = {}
function players:GetPlayers() return table.clone(self.List) end
function players:GetPlayerByUserId(id)
	for _, player in ipairs(self.List) do
		if player.UserId == id and player.Parent == self then return player end
	end
	return nil
end
local replicated = Instance.new("ReplicatedStorage")
local shared = Instance.new("Folder")
shared.Name, shared.Parent = "ColorChaos", replicated
local workspace = Instance.new("Workspace")
-- @STATIC_WORLD@
local saved = {}
local commitThenThrow = false
local storeUpdates = 0
local store = {
	UpdateAsync = function(_, key, callback)
		storeUpdates += 1
		local result = callback(clone(saved[key]))
		if result then saved[key] = clone(result) end
		if commitThenThrow then
			commitThenThrow = false
			error("Simulated lost acknowledgement after committed UpdateAsync")
		end
		return result
	end,
}
local vipOwnership, ownershipQueries = false, 0
local purchasePrompts = {}
local marketplace = {
	PromptProductPurchaseFinished = signal(),
	PromptGamePassPurchaseFinished = signal(),
	UserOwnsGamePassAsync = function(_, userId, passId)
		assert(type(userId) == "number" and passId == 201, "Unexpected pass ownership lookup")
		ownershipQueries += 1
		return vipOwnership
	end,
	PromptProductPurchase = function(_, player, productId)
		table.insert(purchasePrompts, { Player = player, Kind = "Product", Id = productId })
	end,
	PromptGamePassPurchase = function(_, player, passId)
		table.insert(purchasePrompts, { Player = player, Kind = "Pass", Id = passId })
	end,
}
local services = {
	Players = players, ReplicatedStorage = replicated,
	DataStoreService = { GetDataStore = function()
		if scenario == "datastore-unavailable" then error("Simulated GetDataStore unavailable during boot") end
		return store
	end },
	RunService = { IsStudio = function() return false end },
	HttpService = { GenerateGUID = function() return "mock-guid" end },
	Debris = { AddItem = function(_, object) object:Destroy() end },
	MarketplaceService = marketplace,
}
local game = { JobId = "mock-job", GetService = function(_, name) return assert(services[name], name) end, BindToClose = function() end }
local function attachCharacter(player)
	local character = Instance.new("Model")
	character.Name = player.Name
	character.Parent = workspace
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local root = Instance.new("Part")
	root.Name, root.Position, root.Parent = "HumanoidRootPart", Vector3.new(0, 11, 153), character
	player.Character = character
	return character
end
local function addPlayer(id)
	local player = Instance.new("Player")
	player.Name, player.DisplayName, player.UserId = "Tester" .. id, "Tester" .. id, id
	player.States = {}
	player.CharacterAdded = signal()
	player.Parent = players
	attachCharacter(player)
	table.insert(players.List, player)
	return player
end
local first = addPlayer(1)
local preparationTeammate = (scenario == "preparation-fall" or scenario == "lava-contact" or scenario == "r6-lava-contact") and addPlayer(2) or nil

-- The Python runner inserts unmodified module bodies and the actual server here.
-- @MODULES_AND_SERVER@

-- Synthetic IDs exist only in this simulation; actual Config retains zero IDs
-- until the owner creates the products and pass for their Roblox experience.
for index, product in ipairs(Config.Commerce.Products) do product.ProductId = 100 + index end
Config.Commerce.VIP.PassId = 201
if scenario == "legacy-config" then Config.Lava = nil end
local function active(mode)
	return first.Latest and first.Latest.Phase == "JUEGO" and first.Latest.Mode == Config.Modes[mode].Name
end
local checks = 0
local function check(name, condition)
	assert(condition, name)
	checks += 1
	print("PASS mock-server: " .. name)
end
local function near(actual, expected) return type(actual) == "number" and math.abs(actual - expected) < 0.000001 end
local serializedWorld = workspace:FindFirstChild("ColorChaosWorld")
if scenario ~= "fallback-world" then
	check("lobby and neutral spawn exist before any game script starts", serializedWorld ~= nil
		and serializedWorld:FindFirstChild("Plaza del reactor") ~= nil
		and serializedWorld:FindFirstChild("LobbySpawn") ~= nil)
	local floor, safeSpawn = serializedWorld["Plaza del reactor"], serializedWorld.LobbySpawn
	check("serialized spawn stands over an anchored collidable lobby floor", floor.Anchored and floor.CanCollide
		and safeSpawn:IsA("SpawnLocation") and safeSpawn.Anchored and safeSpawn.Neutral
		and math.abs(safeSpawn.Position.X - floor.Position.X) + safeSpawn.Size.X / 2 <= floor.Size.X / 2
		and math.abs(safeSpawn.Position.Z - floor.Position.Z) + safeSpawn.Size.Z / 2 <= floor.Size.Z / 2
		and safeSpawn.Position.Y - safeSpawn.Size.Y / 2 >= floor.Position.Y + floor.Size.Y / 2 - 0.1)
	local surface = serializedWorld:FindFirstChild("LavaSurface")
	local lookout = serializedWorld:FindFirstChild("Mirador")
	local safeWalkways, inspected = true, 0
	for _, object in ipairs(lookout:GetDescendants()) do
		if object:IsA("BasePart") and object.CanCollide then
			inspected += 1
			local overlapsX = math.abs(object.Position.X - surface.Position.X) < (object.Size.X + surface.Size.X) / 2
			local overlapsZ = math.abs(object.Position.Z - surface.Position.Z) < (object.Size.Z + surface.Size.Z) / 2
			if overlapsX and overlapsZ then safeWalkways = false end
		end
	end
	check("saved lava footprint cannot submerge spectator walkways even at maximum height", inspected > 0
		and safeWalkways and surface.Position.Z + surface.Size.Z / 2 <= 66)
end
check("published configuration can start with one player", Config.MinimumPlayers == 1)
task.spawn(serverMain)
local function arenaPart(name)
	return workspace.ColorChaosWorld.Ronda:WaitForChild(name)
end
local function trigger(player, target)
	advance(0.35)
	player.Character.HumanoidRootPart.Position = target.Position
	local prompt = target:FindFirstChildOfClass("ProximityPrompt")
	assert(prompt and prompt.Enabled, "Expected enabled prompt on " .. target.Name)
	prompt.Triggered:Fire(player)
end

if scenario == "datastore-unavailable" or scenario == "fallback-world" or scenario == "legacy-config" then
	runUntil(function() return active(1) end, 60)
	local world = workspace.ColorChaosWorld
	check("initialization still creates a playable round", first.Latest.Participating and first.Latest.Alive
		and world.Ronda ~= nil and world.LobbySpawn ~= nil and world["Plaza del reactor"] ~= nil)
	if scenario == "datastore-unavailable" then
		check("world boot reuses the serialized lobby even when persistence is unavailable", world == serializedWorld)
		check("failed datastore acquisition reports session-only progress", first.Latest.Persistence == "PROGRESO DE ESTA SESIÓN"
			and storeUpdates == 0 and #warnings > 0)
		local paidAvailable = false
		for _, item in ipairs(first.Latest.Commerce) do
			if item.Kind == "Product" and item.Available then paidAvailable = true end
		end
		check("coin product catalog is disabled without reliable persistence", not paidAvailable)
		advance(0.35)
		shared.Remotes.Action.OnServerEvent:Fire(first, "Purchase", { Kind = "Product", Key = "coins100" })
		check("unavailable datastore never opens a coin purchase dialog", #purchasePrompts == 0)
		check("receipts stay unresolved instead of granting unpersisted purchases", marketplace.ProcessReceipt({
			PlayerId = 1, ProductId = 101, PurchaseId = "unavailable-store-receipt",
		}) == Enum.ProductPurchaseDecision.NotProcessedYet and first.Latest.Profile.Coins == 0)
	elseif scenario == "fallback-world" then
		check("runtime fallback builds a safe lobby when serialized world is absent", world.LobbySpawn.Anchored
			and world["Plaza del reactor"].Anchored and world["Plaza del reactor"].CanCollide)
	else
		check("existing commerce config works without the new optional lava settings", Config.Lava == nil
			and first.Latest.Persistence == "GUARDADO ACTIVO" and near(first.Latest.LavaHeight, 10)
			and Config.DataStoreName == "ColorChaos_Player_v1")
	end
	for _ = 1, 5 do trigger(first, arenaPart("AZUL")) end
	if scenario == "legacy-config" then
		check("legacy configuration uses safe default lift without altering saved products", near(first.Latest.PlatformLift, 10)
			and near(arenaPart("Puente 5").Position.Y, 30.5) and first.Latest.Commerce[1].Id == 101)
	end
	trigger(first, arenaPart("Reactor de llegada"))
	runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
	check("free game objectives continue despite unavailable persistence or missing saved scenery", first.Latest.Profile.Coins == 35
		and first.Latest.Profile.Wins == 1)
	print(string.format("All %d mock-server %s checks passed; no Roblox physics or real services were run.", checks, scenario))
	return
end

if scenario == "lava-contact" then
	runUntil(function() return active(1) end, 60)
	local topAtStart = workspace.ColorChaosWorld.LavaSurface.Position.Y + workspace.ColorChaosWorld.LavaSurface.Size.Y / 2
	local startY = first.Character.HumanoidRootPart.Position.Y
	advance(5.1)
	local topAfterPlay = workspace.ColorChaosWorld.LavaSurface.Position.Y + workspace.ColorChaosWorld.LavaSurface.Size.Y / 2
	check("lava surface physically rises while the game timer runs", near(topAtStart, Config.Lava.StartHeight)
		and topAfterPlay > topAtStart and first.Latest.LavaHeight > Config.Lava.StartHeight
		and near(first.Character.HumanoidRootPart.Position.Y, startY))
	local lateJoiner = addPlayer(3)
	players.PlayerAdded:Fire(lateJoiner)
	advance(0.1)
	first.Character.HumanoidRootPart.Position = Vector3.new(0, topAfterPlay + 2.5, 34)
	check("forced lava contact is still well above the old void-death threshold", first.Character.HumanoidRootPart.Position.Y > 5)
	advance(0.2)
	check("touching lava with the feet eliminates promptly without killing the humanoid", not first.Latest.Alive
		and first.Character.Humanoid.Health == 100 and first.Character.HumanoidRootPart.Position.Z == 153)
	check("late joiner remains safe while the lava eliminates an arena participant", lateJoiner.Character.HumanoidRootPart.Position.Z == 153
		and lateJoiner.Character.Humanoid.Health == 100 and not lateJoiner.Latest.Participating)
	lateJoiner.Character.HumanoidRootPart.Position = Vector3.new(0, -1, 153)
	advance(0.2)
	check("an unenrolled lobby visitor is recovered from a void fall without death", lateJoiner.Character.HumanoidRootPart.Position.Z == 153
		and lateJoiner.Character.HumanoidRootPart.Position.Y == 11 and lateJoiner.Character.Humanoid.Health == 100)
	advance(1.1)
	check("spectator list removes the fallen player and keeps the surviving teammate", #lateJoiner.Latest.SpectatorIds == 1
		and lateJoiner.Latest.SpectatorIds[1] == preparationTeammate.UserId and lateJoiner.Latest.AlivePlayers == 1)
	for _ = 1, 5 do trigger(preparationTeammate, arenaPart("AZUL")) end
	trigger(preparationTeammate, arenaPart("Reactor de llegada"))
	runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
	check("ending a match resets the lava and restores every participant to the lobby", near(first.Latest.LavaHeight, Config.Lava.StartHeight)
		and first.Character.HumanoidRootPart.Position.Z == 153
		and preparationTeammate.Character.HumanoidRootPart.Position.Z == 153)
	print(string.format("All %d mock-server lava contact checks passed; no Roblox physics or real services were run.", checks))
	return
end

if scenario == "r6-lava-contact" then
	runUntil(function() return first.Latest and first.Latest.Phase == "PREPARACIÓN" end, 30)
	local humanoid = first.Character.Humanoid
	humanoid.RigType, humanoid.HipHeight = Enum.HumanoidRigType.R6, 0
	local leftLeg = Instance.new("Part")
	leftLeg.Name, leftLeg.Size, leftLeg.Parent = "Left Leg", Vector3.new(1, 2, 1), first.Character
	first.Character.HumanoidRootPart.Position = Vector3.new(0, 13.1, 34)
	advance(0.2)
	check("R6 feet just above the lava remain alive during the frozen preview", first.Latest.Alive
		and near(first.Latest.LavaHeight, 10))
	first.Character.HumanoidRootPart.Position = Vector3.new(0, 13, 34)
	check("R6 lava contact occurs with root above the R15-only cutoff and void threshold", humanoid.HipHeight == 0
		and first.Character.HumanoidRootPart.Position.Y > 11 and first.Character.HumanoidRootPart.Position.Y > 5)
	advance(0.2)
	check("R6 leg height is counted so feet touching lava promptly eliminate", not first.Latest.Alive
		and first.Character.HumanoidRootPart.Position.Z == 153 and humanoid.Health == 100)
	check("R6 recovery unfreezes the avatar and leaves the teammate playable", not first.Character.HumanoidRootPart.Anchored
		and preparationTeammate.Latest.Alive)
	print(string.format("All %d mock-server R6 lava checks passed; no Roblox physics or real services were run.", checks))
	return
end

if scenario == "preparation-fall" then
	runUntil(function() return first.Latest and first.Latest.Phase == "PREPARACIÓN" end, 30)
	check("two prepared players begin alive above the lava", first.Latest.Alive and preparationTeammate.Latest.Alive)
	check("memory preparation temporarily freezes both avatars for the preview", first.Character.HumanoidRootPart.Anchored
		and preparationTeammate.Character.HumanoidRootPart.Anchored)
	first.Character.HumanoidRootPart.Position = Vector3.new(0, 8, 34)
	advance(1.1)
	check("falling during preparation eliminates before the memory preview completes", not first.Latest.Alive
		and first.Character.HumanoidRootPart.Position.Z == 153 and first.Latest.Phase == "PREPARACIÓN")
	check("preparation elimination releases the avatar for lobby movement", not first.Character.HumanoidRootPart.Anchored)
	local replacement = attachCharacter(first)
	first.CharacterAdded:Fire(replacement)
	advance(0.1)
	check("respawn returns to the lobby without re-enrolling into the ongoing match", not first.Latest.Alive
		and first.Character.HumanoidRootPart.Position.Z == 153)
	runUntil(function() return active(1) end, 15)
	trigger(first, arenaPart("AZUL"))
	check("eliminated participant cannot trigger arena objectives with a new character", first.Latest.Progress == 0)
	for _ = 1, 5 do trigger(preparationTeammate, arenaPart("AZUL")) end
	trigger(preparationTeammate, arenaPart("Reactor de llegada"))
	runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
	check("remaining teammate can complete the same match after a preparation fall", preparationTeammate.Latest.Profile.Wins == 1
		and first.Latest.Profile.Wins == 0 and first.Latest.Profile.Coins == 0)
	print(string.format("All %d mock-server preparation checks passed; no Roblox physics or real services were run.", checks))
	return
end

runUntil(function() return active(1) end, 60)
check("server starts and enrolled player receives playable state", first.Latest.Participating and first.Latest.Alive)
local worlds, spawns = 0, 0
for _, child in ipairs(workspace:GetChildren()) do if child.Name == "ColorChaosWorld" then worlds += 1 end end
for _, descendant in ipairs(workspace:GetDescendants()) do if descendant:IsA("SpawnLocation") then spawns += 1 end end
check("runtime reuses one serialized world and one lobby spawn", workspace.ColorChaosWorld == serializedWorld
	and worlds == 1 and spawns == 1 and first.RespawnLocation == serializedWorld.LobbySpawn)
local lobbyState, preparationState
for _, payload in ipairs(first.States) do
	if payload.Phase == "LOBBY" and payload.Profile then lobbyState = payload end
	if payload.Phase == "PREPARACIÓN" then preparationState = payload end
end
check("lobby exposes one ready player and no active combatants", lobbyState and lobbyState.ReadyPlayers == 1
	and lobbyState.AlivePlayers == 0 and #lobbyState.SpectatorIds == 0)
check("lava stays at its starting height throughout the memory preparation", preparationState
	and near(preparationState.LavaHeight, Config.Lava.StartHeight)
	and near(first.Latest.LavaHeight, Config.Lava.StartHeight))
check("a playable participant is unfrozen after the preview", first.Character.HumanoidRootPart.Anchored == false)
local ordinals = {}
for _, state in ipairs(first.States) do if state.DemoCode == 1 and state.DemoStep then ordinals[state.DemoStep] = true end end
check("five repeated symbols remain individually identified", ordinals[1] and ordinals[2] and ordinals[3] and ordinals[4] and ordinals[5])
local late = addPlayer(2)
players.PlayerAdded:Fire(late)
advance(0.1)
check("late joiner waits outside the active team", late.Latest and not late.Latest.Participating)
check("late joiner receives the live teammate's spectator id and remains at the safe spawn", late.Latest.AlivePlayers == 1
	and late.Latest.ReadyPlayers == 2 and late.Latest.SpectatorIds[1] == first.UserId
	and late.Character.HumanoidRootPart.Position.Z == 153)
first.Character.HumanoidRootPart.Position = Vector3.new(0, 11, 153)
advance(0.35)
arenaPart("AZUL"):FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(first)
check("firing a prompt from the lobby cannot advance an objective", first.Latest.Progress == 0 and workspace.ColorChaosWorld.Ronda:FindFirstChild("Puente 1") == nil)
local memoryBaseY, firstButtonY = arenaPart("Inicio").Position.Y, arenaPart("AZUL").Position.Y
trigger(first, arenaPart("AZUL"))
assert(first.Latest.Progress == 1, "Setup for wrong-input replay must create one bridge")
local memoryStepLift = Config.Lava.MaxLift / first.Latest.Total
local prefixBridgeY = arenaPart("Puente 1").Position.Y
check("a memory success raises its floor and bridges while carrying the living player", near(first.Latest.PlatformLift, memoryStepLift)
	and near(arenaPart("Inicio").Position.Y, memoryBaseY + memoryStepLift)
	and near(first.Character.HumanoidRootPart.Position.Y, firstButtonY + memoryStepLift)
	and near(prefixBridgeY, 20.5 + memoryStepLift))
local replayStart = #first.States
trigger(first, arenaPart("AMARILLO"))
advance(0.05)
check("wrong memory input destroys existing bridges and resets progress", first.Latest.Progress == 0 and workspace.ColorChaosWorld.Ronda:FindFirstChild("Puente 1") == nil)
check("wrong memory input preserves gained altitude and resets onto the raised start", near(first.Latest.PlatformLift, memoryStepLift)
	and near(arenaPart("Inicio").Position.Y, memoryBaseY + memoryStepLift)
	and near(first.Character.HumanoidRootPart.Position.Y, 25 + memoryStepLift))
runUntil(function()
	return first.Latest.Message == "Activa la secuencia en orden. Después cruza al reactor." and first.Latest.DemoCode == nil
end, 10)
local replayOrdinals = {}
for i = replayStart + 1, #first.States do
	local state = first.States[i]
	if state.DemoCode == 1 and state.DemoStep then replayOrdinals[state.DemoStep] = true end
end
check("replay shows all five symbols and restores the input phase", replayOrdinals[1] and replayOrdinals[2] and replayOrdinals[3] and replayOrdinals[4] and replayOrdinals[5] and first.Latest.DemoStep == nil and first.Latest.Phase == "JUEGO")
trigger(first, arenaPart("AZUL"))
check("replaying a previously solved memory prefix cannot farm platform elevation", near(first.Latest.PlatformLift, memoryStepLift)
	and near(arenaPart("Puente 1").Position.Y, prefixBridgeY))
for _ = 2, 5 do trigger(first, arenaPart("AZUL")) end
check("all five bridges complete without prematurely finishing the round", first.Latest.Progress == 5 and first.Latest.Total == 6 and first.Latest.Phase == "JUEGO")
local bridgesAligned = true
for i = 1, 5 do bridgesAligned = bridgesAligned and near(arenaPart("Puente " .. i).Position.Y, 20.5 + first.Latest.PlatformLift) end
check("late-created memory bridges stay level with every existing raised bridge", bridgesAligned
	and near(first.Latest.PlatformLift, Config.Lava.MaxLift * 5 / 6))
trigger(first, arenaPart("Reactor de llegada"))
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("reactor completes memory and rewards exactly one victory", first.Latest.Profile.Coins == 35 and first.Latest.Profile.Wins == 1)
check("late joiner cannot receive someone else's victory rewards", late.Latest.Profile.Coins == 0 and late.Latest.Profile.Wins == 0)

runUntil(function() return active(2) end, 50)
check("late joiner is enrolled at the next round", late.Latest.Participating and late.Latest.Alive)
check("new relay round resets the lava and platform lift", near(first.Latest.PlatformLift, 0)
	and near(first.Latest.LavaHeight, Config.Lava.StartHeight))
local relayBaseY = arenaPart("Arena").Position.Y
for index = 1, 8 do
	local target = first.Latest.Target
	local teammateY = late.Character.HumanoidRootPart.Position.Y
	trigger(first, arenaPart(Config.Colors[target].Name))
	if index == 1 then
		check("relay repair raises the complete arena and both live teammates together", near(first.Latest.PlatformLift, Config.Lava.MaxLift / 8)
			and near(arenaPart("Arena").Position.Y, relayBaseY + Config.Lava.MaxLift / 8)
			and near(late.Character.HumanoidRootPart.Position.Y, teammateY + Config.Lava.MaxLift / 8))
	end
	advance(1.3)
end
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("all relay stations produce a single second victory", first.Latest.Profile.Coins == 70 and first.Latest.Profile.Wins == 2)
check("idle enrolled player receives no currency", late.Latest.Profile.Coins == 0 and late.Latest.Profile.Wins == 0)
check("both teammates are returned to the safe lobby after the lava round", first.Character.HumanoidRootPart.Position.Z == 153
	and late.Character.HumanoidRootPart.Position.Z == 153 and near(first.Latest.LavaHeight, Config.Lava.StartHeight))

runUntil(function() return active(3) end, 50)
local target = first.Latest.Target
trigger(first, arenaPart("Panel " .. Config.Colors[target].Name))
local spark = arenaPart("Chispa " .. Config.Colors[target].Name)
trigger(first, spark)
check("picking up a spark marks it as carried", spark.Transparency == 1 and first.Character.HumanoidRootPart:FindFirstChild("CarriedSpark") ~= nil)
first.Character.Humanoid.Health = 0
first.Character.Humanoid.Died:Fire()
check("carrier death restores the spark and removes carried indicator", spark.Transparency == 0 and first.Character.HumanoidRootPart:FindFirstChild("CarriedSpark") == nil and not first.Latest.Alive)
trigger(late, spark)
trigger(late, arenaPart("Reactor receptor"))
check("teammate can recover and deliver a dropped spark", late.Latest.Progress == 1)
check("rescue delivery raises the island, floor and surviving teammate together", near(late.Latest.PlatformLift, Config.Lava.MaxLift / 4)
	and near(arenaPart("Arena").Position.Y, 20 + Config.Lava.MaxLift / 4)
	and near(arenaPart("Isla AZUL").Position.Y, 20 + Config.Lava.MaxLift / 4)
	and near(late.Character.HumanoidRootPart.Position.Y, 25 + Config.Lava.MaxLift / 4))
for _ = 2, 4 do
	local nextTarget = late.Latest.Target
	trigger(late, arenaPart("Panel " .. Config.Colors[nextTarget].Name))
	if _ == 2 then
		check("new rescue bridge is created at the already-raised platform altitude", near(arenaPart("Puente de rescate").Position.Y,
			20.5 + late.Latest.PlatformLift))
	end
	trigger(late, arenaPart("Chispa " .. Config.Colors[nextTarget].Name))
	trigger(late, arenaPart("Reactor receptor"))
end
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("surviving rescuer receives the team victory", late.Latest.Profile.Coins == 35 and late.Latest.Profile.Wins == 1)
check("eliminated contributor receives only participation", first.Latest.Profile.Coins == 80 and first.Latest.Profile.Wins == 2)

local action = shared.Remotes.Action
local function sendAction(player, kind, value)
	advance(0.35)
	action.OnServerEvent:Fire(player, kind, value)
end
local function receipt(playerId, productId, purchaseId)
	return marketplace.ProcessReceipt({ PlayerId = playerId, ProductId = productId, PurchaseId = purchaseId })
end
local granted, retry = Enum.ProductPurchaseDecision.PurchaseGranted, Enum.ProductPurchaseDecision.NotProcessedYet
check("first paid product commits coins and receipt together", receipt(1, 101, "real-server-receipt-100") == granted
	and first.Latest.Profile.Coins == 180 and saved.Player_1.Data.Coins == 180
	and saved.Player_1.Data.Receipts["real-server-receipt-100"] == 100)
check("actual server receipt replay cannot double-credit currency", receipt(1, 101, "real-server-receipt-100") == granted
	and first.Latest.Profile.Coins == 180 and saved.Player_1.Data.Coins == 180)
commitThenThrow = true
check("lost acknowledgement leaves receipt unresolved despite stored commit", receipt(1, 102, "real-server-receipt-400") == retry
	and first.Latest.Profile.Coins == 180 and saved.Player_1.Data.Coins == 580
	and saved.Player_1.Data.Receipts["real-server-receipt-400"] == 400)
advance(2.1)
check("scheduled recovery merges paid coins instead of overwriting committed grant", first.Latest.Profile.Coins == 580
	and saved.Player_1.Data.Coins == 580 and saved.Player_1.Data.Receipts["real-server-receipt-400"] == 400)
check("receipt replay after recovery acknowledges once without another credit", receipt(1, 102, "real-server-receipt-400") == granted
	and first.Latest.Profile.Coins == 580 and saved.Player_1.Data.Coins == 580)
local updatesBefore = storeUpdates
advance(Config.SaveInterval)
check("later periodic saves preserve purchased coins and receipt history", storeUpdates > updatesBefore
	and saved.Player_1.Data.Coins == 580 and saved.Player_1.Data.Receipts["real-server-receipt-100"] == 100
	and saved.Player_1.Data.Receipts["real-server-receipt-400"] == 400)
first.Parent = nil
check("disconnected receipt cannot be acknowledged", receipt(1, 101, "offline-receipt") == retry)
first.Parent = players
check("unconfigured product receipt cannot be acknowledged", receipt(1, 999999, "unknown-product-receipt") == retry
	and saved.Player_1.Data.Coins == 580)
local beforeQueries = ownershipQueries
marketplace.PromptGamePassPurchaseFinished:Fire(first, 201, true)
check("pass prompt success without ownership grants no VIP", first.Latest.Profile.VIP == false and ownershipQueries == beforeQueries + 1)
vipOwnership = true
marketplace.PromptGamePassPurchaseFinished:Fire(first, 201, true)
check("verified ownership gives VIP title without gameplay advantages", first.Latest.Profile.VIP == true
	and first.Character.HumanoidRootPart:FindFirstChild("VIPTitle") ~= nil and first.Latest.Profile.Coins == 580)
sendAction(first, "Palette", 5)
check("verified VIP can equip exclusive Prisma aura without spending", first.Latest.Profile.Selected == 5 and first.Latest.Profile.Coins == 580)
sendAction(late, "Palette", 5)
check("player without verified entitlement cannot equip VIP aura", late.Latest.Profile.Selected == 1)
check("participating rounds and victories complete daily missions", first.Latest.Progression.Missions[1].Complete
	and first.Latest.Progression.Missions[3].Complete and first.Latest.Progression.XP == 95)
sendAction(first, "ClaimMission", "play3")
check("server grants completed daily mission exactly once", first.Latest.Profile.Coins == 610
	and first.Latest.Progression.Missions[1].Claimed)
sendAction(first, "ClaimMission", "play3")
check("daily mission replay cannot duplicate reward", first.Latest.Profile.Coins == 610)
sendAction(first, "ClaimMission", "win2")
check("second legitimate mission pays only its configured reward", first.Latest.Profile.Coins == 660)
sendAction(late, "ClaimMission", "play3")
check("idle and late arrivals cannot claim another player's mission", late.Latest.Profile.Coins == 35 and not late.Latest.Progression.Missions[1].Claimed)
sendAction(first, "ClaimMission", "invented")
check("unknown mission requests cannot increase currency", first.Latest.Profile.Coins == 660)

print(string.format("All %d mock-server checks passed. These mocks do not run Roblox physics, network, real DataStores or billing.", checks))
