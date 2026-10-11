-- Minimal orchestration mocks, not a Roblox engine or physics replacement.
local now = 1
local jobs = {}
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
vectorMeta.__index = function(v, key) if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end end
Vector3.zero = Vector3.new()
local Vector2 = { new = function(...) return { ... } end, zero = {} }
local CFrame = { new = function(position) return { Position = position } end }
local Color3 = { fromRGB = function(...) return { ... } end, new = function(...) return { ... } end }
local UDim = { new = function(...) return { ... } end }
local UDim2 = { fromOffset = function(...) return { ... } end, fromScale = function(...) return { ... } end }
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
end
function Instance.new(className)
	local object = setmetatable({ _properties = { ClassName = className, Name = className }, _children = {} }, instanceMeta)
	if className == "ProximityPrompt" then object.Triggered = signal(); object.Enabled = true end
	if className == "Humanoid" then object.Died = signal(); object.Health = 100 end
	if className == "RemoteEvent" then object.OnServerEvent = signal() end
	return object
end
function methods:FindFirstChild(name)
	for _, child in ipairs(self._children) do if child.Name == name then return child end end
	return nil
end
function methods:FindFirstChildOfClass(className)
	for _, child in ipairs(self._children) do if child.ClassName == className then return child end end
	return nil
end
function methods:WaitForChild(name)
	local child = self:FindFirstChild(name)
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
local replicated = Instance.new("ReplicatedStorage")
local shared = Instance.new("Folder")
shared.Name, shared.Parent = "ColorChaos", replicated
local workspace = Instance.new("Workspace")
local saved = {}
local store = {
	UpdateAsync = function(_, key, callback)
		local result = callback(clone(saved[key]))
		if result then saved[key] = clone(result) end
		return result
	end,
}
local services = {
	Players = players, ReplicatedStorage = replicated,
	DataStoreService = { GetDataStore = function() return store end },
	RunService = { IsStudio = function() return false end },
	HttpService = { GenerateGUID = function() return "mock-guid" end },
	Debris = { AddItem = function(_, object) object:Destroy() end },
}
local game = { JobId = "mock-job", GetService = function(_, name) return assert(services[name], name) end, BindToClose = function() end }
local function addPlayer(id)
	local player = Instance.new("Player")
	player.Name, player.DisplayName, player.UserId = "Tester" .. id, "Tester" .. id, id
	player.States = {}
	player.CharacterAdded = signal()
	player.Parent = players
	local character = Instance.new("Model")
	character.Name = player.Name
	character.Parent = workspace
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local root = Instance.new("Part")
	root.Name, root.Position, root.Parent = "HumanoidRootPart", Vector3.new(0, 11, 153), character
	player.Character = character
	table.insert(players.List, player)
	return player
end
local first = addPlayer(1)

-- The Python runner inserts unmodified module bodies and the actual server here.
-- @MODULES_AND_SERVER@

task.spawn(serverMain)
local function active(mode)
	return first.Latest and first.Latest.Phase == "JUEGO" and first.Latest.Mode == Config.Modes[mode].Name
end
local checks = 0
local function check(name, condition)
	assert(condition, name)
	checks += 1
	print("PASS mock-server: " .. name)
end
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

runUntil(function() return active(1) end, 60)
check("server starts and enrolled player receives playable state", first.Latest.Participating and first.Latest.Alive)
local ordinals = {}
for _, state in ipairs(first.States) do if state.DemoCode == 1 and state.DemoStep then ordinals[state.DemoStep] = true end end
check("five repeated symbols remain individually identified", ordinals[1] and ordinals[2] and ordinals[3] and ordinals[4] and ordinals[5])
local late = addPlayer(2)
players.PlayerAdded:Fire(late)
advance(0.1)
check("late joiner waits outside the active team", late.Latest and not late.Latest.Participating)
first.Character.HumanoidRootPart.Position = Vector3.new(0, 11, 153)
advance(0.35)
arenaPart("AZUL"):FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(first)
check("firing a prompt from the lobby cannot advance an objective", first.Latest.Progress == 0 and workspace.ColorChaosWorld.Ronda:FindFirstChild("Puente 1") == nil)
trigger(first, arenaPart("AZUL"))
assert(first.Latest.Progress == 1, "Setup for wrong-input replay must create one bridge")
local replayStart = #first.States
trigger(first, arenaPart("AMARILLO"))
advance(0.05)
check("wrong memory input destroys existing bridges and resets progress", first.Latest.Progress == 0 and workspace.ColorChaosWorld.Ronda:FindFirstChild("Puente 1") == nil)
runUntil(function()
	return first.Latest.Message == "Activa la secuencia en orden. Después cruza al reactor." and first.Latest.DemoCode == nil
end, 10)
local replayOrdinals = {}
for i = replayStart + 1, #first.States do
	local state = first.States[i]
	if state.DemoCode == 1 and state.DemoStep then replayOrdinals[state.DemoStep] = true end
end
check("replay shows all five symbols and restores the input phase", replayOrdinals[1] and replayOrdinals[2] and replayOrdinals[3] and replayOrdinals[4] and replayOrdinals[5] and first.Latest.DemoStep == nil and first.Latest.Phase == "JUEGO")
for _ = 1, 5 do trigger(first, arenaPart("AZUL")) end
check("all five bridges complete without prematurely finishing the round", first.Latest.Progress == 5 and first.Latest.Total == 6 and first.Latest.Phase == "JUEGO")
trigger(first, arenaPart("Reactor de llegada"))
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("reactor completes memory and rewards exactly one victory", first.Latest.Profile.Coins == 35 and first.Latest.Profile.Wins == 1)
check("late joiner cannot receive someone else's victory rewards", late.Latest.Profile.Coins == 0 and late.Latest.Profile.Wins == 0)

runUntil(function() return active(2) end, 50)
check("late joiner is enrolled at the next round", late.Latest.Participating and late.Latest.Alive)
for _ = 1, 8 do
	local target = first.Latest.Target
	trigger(first, arenaPart(Config.Colors[target].Name))
	advance(1.3)
end
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("all relay stations produce a single second victory", first.Latest.Profile.Coins == 70 and first.Latest.Profile.Wins == 2)
check("idle enrolled player receives no currency", late.Latest.Profile.Coins == 0 and late.Latest.Profile.Wins == 0)

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
for _ = 2, 4 do
	local nextTarget = late.Latest.Target
	trigger(late, arenaPart("Panel " .. Config.Colors[nextTarget].Name))
	trigger(late, arenaPart("Chispa " .. Config.Colors[nextTarget].Name))
	trigger(late, arenaPart("Reactor receptor"))
end
runUntil(function() return first.Latest.Phase == "RESULTADOS" end, 3)
check("surviving rescuer receives the team victory", late.Latest.Profile.Coins == 35 and late.Latest.Profile.Wins == 1)
check("eliminated contributor receives only participation", first.Latest.Profile.Coins == 80 and first.Latest.Profile.Wins == 2)
print(string.format("All %d mock-server checks passed. Physics and real Roblox services still require Studio.", checks))
