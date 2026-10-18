-- Limited service/orchestration mocks for the real server and its modules.
-- These are not the Roblox engine: collisions, rendering and networking are not simulated.
-- @SCENARIO@
local now, jobs, warnings = 1, {}, {}
local function warn(message) table.insert(warnings, tostring(message)) end
local baseOs = os
local os = setmetatable({ clock = function() return now end, time = function() return 1700000000 + math.floor(now) end }, { __index = baseOs })
local function enqueue(thread, due) table.insert(jobs, { Thread = thread, Due = due }) end
local task = {}
function task.spawn(callback, ...)
	local args = table.pack(...)
	enqueue(coroutine.create(function() callback(table.unpack(args, 1, args.n)) end), now)
end
function task.delay(seconds, callback, ...)
	local args = table.pack(...)
	enqueue(coroutine.create(function() callback(table.unpack(args, 1, args.n)) end), now + seconds)
end
function task.defer(callback, ...) task.spawn(callback, ...) end
function task.wait(seconds) return coroutine.yield(seconds or 0.03) end
local function nextJob()
	local best = 1
	for index = 2, #jobs do if jobs[index].Due < jobs[best].Due then best = index end end
	return best
end
local function runJob()
	local job = table.remove(jobs, nextJob())
	now = job.Due
	local ok, delay = coroutine.resume(job.Thread)
	assert(ok, tostring(delay) .. "\n" .. debug.traceback(job.Thread))
	if coroutine.status(job.Thread) ~= "dead" then enqueue(job.Thread, now + (delay or 0.03)) end
end
local function runUntil(predicate, timeout)
	local deadline, iterations = now + timeout, 0
	while not predicate() do
		assert(#jobs > 0, "Scheduler stopped before expected server state")
		assert(jobs[nextJob()].Due <= deadline, "Timed out waiting for server; warnings: " .. table.concat(warnings, " / "))
		runJob()
		iterations += 1
		assert(iterations < 50000, "Scheduler runaway")
	end
end
local function advance(seconds)
	local target, iterations = now + seconds, 0
	while #jobs > 0 and jobs[nextJob()].Due <= target do
		runJob()
		iterations += 1
		assert(iterations < 50000, "Scheduler runaway")
	end
	now = target
end
local function signal()
	local connections = {}
	return {
		Connect = function(_, callback)
			local connection = { Active = true, Callback = callback }
			function connection:Disconnect() self.Active = false end
			table.insert(connections, connection)
			return connection
		end,
		Fire = function(_, ...)
			for _, connection in ipairs(table.clone(connections)) do if connection.Active then connection.Callback(...) end end
		end,
	}
end
local Vector3, vectorMeta = {}, {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta) end
vectorMeta.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMeta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end
vectorMeta.__index = function(v, key)
	if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if key == "Unit" then local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z); return Vector3.new(v.X / m, v.Y / m, v.Z / m) end
end
Vector3.zero = Vector3.new()
local Vector2 = { new = function(x, y) return { X = x, Y = y } end, zero = {} }
local CFrame, frameMeta = {}, {}
function CFrame.new(x, y, z) return setmetatable({ Position = type(x) == "table" and x or Vector3.new(x, y, z) }, frameMeta) end
CFrame.Angles = function() return CFrame.new() end
CFrame.lookAt = function(position) return CFrame.new(position) end
CFrame.identity = CFrame.new()
frameMeta.__add = function(frame, offset) return CFrame.new(frame.Position + offset) end
frameMeta.__mul = function(a, b) return CFrame.new(a.Position + b.Position) end
local Color3, colorMeta = {}, {}
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, colorMeta) end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
colorMeta.__index = { Lerp = function(a, b, alpha) return Color3.new(a.R + (b.R - a.R) * alpha, a.G + (b.G - a.G) * alpha, a.B + (b.B - a.B) * alpha) end }
local NumberSequence = { new = function(...) return { ... } end }
local NumberSequenceKeypoint = { new = function(...) return { ... } end }
local ColorSequence = { new = function(...) return { ... } end }
local ColorSequenceKeypoint = { new = function(...) return { ... } end }
local TweenInfo = { new = function(...) return { ... } end }
local UDim = { new = function(...) return { ... } end }
local UDim2 = { new = function(...) return { ... } end, fromOffset = function(...) return { ... } end, fromScale = function(...) return { ... } end }
local Enum = setmetatable({}, { __index = function(_, category) return setmetatable({}, { __index = function(_, value) return category .. "." .. value end }) end })
local randomSeed = 11
local Random = { new = function() return {
	NextInteger = function(_, minimum, maximum) randomSeed = (randomSeed * 48271) % 2147483647; return minimum + randomSeed % (maximum - minimum + 1) end,
	NextNumber = function(_, minimum, maximum) return (minimum or 0) + ((maximum or 1) - (minimum or 0)) * 0.4 end,
} end }
local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end
local instanceMeta, methods, Instance = {}, {}, {}
instanceMeta.__index = function(object, key)
	if methods[key] then return methods[key] end
	if object._properties[key] ~= nil then return object._properties[key] end
	for _, child in ipairs(object._children) do if child.Name == key then return child end end
	return nil
end
instanceMeta.__newindex = function(object, key, value)
	if key == "Parent" then
		local old = object._properties.Parent
		if old then for i, child in ipairs(old._children) do if child == object then table.remove(old._children, i); break end end end
		if value then table.insert(value._children, object) end
	end
	object._properties[key] = value
	if key == "Position" then object._properties.CFrame = CFrame.new(value) end
	if key == "CFrame" and value then object._properties.Position = value.Position end
	if key == "Parent" and value then
		if value.ChildAdded then value.ChildAdded:Fire(object) end
		local ancestor = value
		while ancestor do if ancestor.DescendantAdded then ancestor.DescendantAdded:Fire(object) end; ancestor = ancestor.Parent end
	end
end
function Instance.new(className)
	local object = setmetatable({ _properties = { ClassName = className, Name = className }, _children = {}, _attributes = {} }, instanceMeta)
	object.ChildAdded, object.DescendantAdded = signal(), signal()
	if className == "ProximityPrompt" then object.Triggered = signal(); object.Enabled = true end
	if className == "Humanoid" then object.Died = signal(); object.Health, object.HipHeight, object.WalkSpeed = 100, 2, 16 end
	if className == "RemoteEvent" then object.OnServerEvent = signal() end
	if className == "Part" or className == "SpawnLocation" or className == "WedgePart" or className == "MeshPart" then
		object.Size, object.Position, object.Touched = Vector3.new(2, 2, 2), Vector3.zero, signal()
		object.Anchored, object.CanCollide, object.Transparency = false, true, 0
	end
	return object
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(self._children) do if child.Name == name then return child end end
	if recursive then for _, child in ipairs(self._children) do local found = child:FindFirstChild(name, true); if found then return found end end end
	return nil
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result = {}
	for _, child in ipairs(self._children) do table.insert(result, child); for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end end
	return result
end
function methods:IsA(className)
	return self.ClassName == className or (className == "BasePart" and table.find({ "Part", "SpawnLocation", "WedgePart", "MeshPart" }, self.ClassName) ~= nil)
end
function methods:SetAttribute(name, value) self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes[name] end
function methods:GetAttributes() return table.clone(self._attributes) end
function methods:FindFirstChildOfClass(className) for _, child in ipairs(self._children) do if child.ClassName == className then return child end end; return nil end
function methods:WaitForChild(name, timeout)
	local child = self:FindFirstChild(name)
	if timeout and not child then return nil end
	assert(child, "Harness missing expected child: " .. name)
	return child
end
function methods:Destroy()
	for i = #self._children, 1, -1 do self._children[i]:Destroy() end
	self.Parent, self.Destroyed = nil, true
end
function methods:Clone()
	local result = Instance.new(self.ClassName)
	for key, value in pairs(self._properties) do
		if key ~= "Parent" and key ~= "ClassName" and key ~= "ChildAdded" and key ~= "DescendantAdded" and key ~= "Touched" then result[key] = value end
	end
	result._attributes = clone(self._attributes)
	for _, child in ipairs(self._children) do child:Clone().Parent = result end
	return result
end
function methods:PivotTo(frame) if self.HumanoidRootPart then self.HumanoidRootPart.CFrame = frame else self.WorldPivot = frame end end
function methods:GetPivot() return self.HumanoidRootPart and self.HumanoidRootPart.CFrame or self.WorldPivot or CFrame.new() end
function methods:FindFirstAncestorOfClass(className)
	local parent = self.Parent
	while parent do if parent:IsA(className) then return parent end; parent = parent.Parent end
	return nil
end
function methods:FireClient(player, payload)
	if self.Name == "State" then player.Latest = clone(payload); table.insert(player.States, clone(payload)); table.insert(player.StateTimes, now) end
end
function methods:SetNetworkOwner() end
local players = Instance.new("Players")
players.PlayerAdded, players.PlayerRemoving, players.List = signal(), signal(), {}
function players:GetPlayers()
	local online = {}
	for _, player in ipairs(self.List) do if player.Parent == self then table.insert(online, player) end end
	return online
end
function players:GetPlayerByUserId(id) for _, player in ipairs(self:GetPlayers()) do if player.UserId == id then return player end end; return nil end
function players:GetPlayerFromCharacter(character) for _, player in ipairs(self:GetPlayers()) do if player.Character == character then return player end end; return nil end
function players:GetNameFromUserIdAsync(id) return "Tester" .. tostring(id) end
local replicated, shared = Instance.new("ReplicatedStorage"), Instance.new("Folder")
shared.Name, shared.Parent = "ColorChaos", replicated
local serverFolder = Instance.new("Folder")
serverFolder.Name = "ColorChaosServer"
local workspace = Instance.new("Workspace")
-- @STATIC_WORLD@
local saved, storeUpdates, orderedWrites, orderedReads = {}, 0, 0, 0
local commitThenThrow, dataUnavailable = false, scenario == "datastore-unavailable"
local store = { UpdateAsync = function(_, key, callback)
	storeUpdates += 1
	if dataUnavailable then error("Simulated persistent storage unavailable") end
	local result = callback(clone(saved[key]))
	if result then saved[key] = clone(result) end
	if commitThenThrow then commitThenThrow = false; error("Simulated lost acknowledgement after committed UpdateAsync") end
	return clone(result)
end }
local ordered = {}
local storage = {}
function storage:GetDataStore(name)
	assert(name == "ColorChaos_Player_v1", "Existing published identity and profile store must be retained")
	if dataUnavailable then error("Simulated GetDataStore unavailable") end
	return store
end
function storage:GetOrderedDataStore(name)
	if dataUnavailable then error("Simulated global ranking unavailable") end
	ordered[name] = ordered[name] or {}
	return {
		UpdateAsync = function(_, key, callback) orderedWrites += 1; local value = callback(ordered[name][key]); if value then ordered[name][key] = value end; return value end,
		GetSortedAsync = function()
			orderedReads += 1
			local rows = {}
			for key, value in pairs(ordered[name]) do table.insert(rows, { key = key, value = value }) end
			table.sort(rows, function(a, b) return a.value > b.value end)
			return { GetCurrentPage = function() return rows end }
		end,
	}
end
local vipOwnership, purchasePrompts = {}, {}
local marketplace = {
	PromptProductPurchaseFinished = signal(), PromptGamePassPurchaseFinished = signal(),
	UserOwnsGamePassAsync = function(_, id) return vipOwnership[id] == true end,
	PromptProductPurchase = function(_, player, id) table.insert(purchasePrompts, { Player = player, Kind = "Product", Id = id }) end,
	PromptGamePassPurchase = function(_, player, id) table.insert(purchasePrompts, { Player = player, Kind = "Pass", Id = id }) end,
}
local guid, collisionGroups, collisions = 0, {}, {}
local services = {
	Players = players, ReplicatedStorage = replicated, Workspace = workspace, DataStoreService = storage,
	RunService = { IsStudio = function() return false end, Heartbeat = signal() },
	HttpService = { GenerateGUID = function() guid += 1; return "mock-guid-" .. guid end },
	PhysicsService = {
		IsCollisionGroupRegistered = function(_, group) return collisionGroups[group] == true end,
		RegisterCollisionGroup = function(_, group) collisionGroups[group] = true end,
		CollisionGroupSetCollidable = function(_, a, b, value) collisions[a .. ":" .. b] = value end,
	},
	Debris = { AddItem = function() end }, Lighting = Instance.new("Lighting"),
	TweenService = { Create = function(_, object, _, goals) return { Play = function() for key, value in pairs(goals) do object[key] = value end end, Completed = signal() } end },
	MarketplaceService = marketplace,
}
local closeCallback
local game = { JobId = "mock-job", GetService = function(_, name) return assert(services[name], name) end, BindToClose = function(_, callback) closeCallback = callback end }
local function attachCharacter(player)
	local character = Instance.new("Model")
	character.Name, character.Parent = player.Name, workspace
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local root = Instance.new("Part")
	root.Name, root.Position, root.Parent = "HumanoidRootPart", Vector3.new(0, 11, 110), character
	local head = Instance.new("Part")
	head.Name, head.Position, head.Parent = "Head", Vector3.new(0, 13, 110), character
	player.Character = character
	return character
end
local function addPlayer(id)
	local player = Instance.new("Player")
	player.Name, player.DisplayName, player.UserId = "Tester" .. id, "Tester" .. id, id
	player.States, player.StateTimes, player.CharacterAdded = {}, {}, signal()
	player.Parent = players
	attachCharacter(player)
	table.insert(players.List, player)
	return player
end
local first = addPlayer(1)
local second = scenario ~= "solo" and addPlayer(2) or nil
local third = scenario ~= "solo" and addPlayer(3) or nil

-- @MODULES_AND_SERVER@

for index, product in ipairs(Config.Commerce.Products) do product.ProductId = 100 + index end
Config.Commerce.VIP.PassId = 201
local passed = 0
local function check(name, condition) assert(condition, scenario .. ": " .. name); passed += 1 end
local staticWorld = workspace:FindFirstChild("ColorChaosWorld")
check("world exists before any server module runs", staticWorld ~= nil)
check("spawn is available before storage or commerce initialization", staticWorld:FindFirstChild("LobbySpawn", true) ~= nil)
check("all eight course sectors are serialized", staticWorld.Stages and #staticWorld.Stages:GetChildren() == 8)
check("scene no longer depends on lava for progress", staticWorld:FindFirstChild("Lava", true) == nil)
task.spawn(serverMain)

if scenario == "module-failure" then
	advance(1)
	check("a script startup exception is reported as ERROR", workspace:GetAttribute("ColorChaosBootStatus") == "ERROR")
	check("a failed secondary module never deletes the saved lobby", staticWorld.Parent == workspace and not staticWorld.Destroyed)
	check("a failed module leaves the neutral spawn intact", staticWorld.LobbySpawn.Parent == staticWorld and staticWorld.LobbySpawn.Neutral == true)
	check("a failed module leaves solid floor below spawn", staticWorld["Plaza del reactor"].CanCollide == true)
	print(string.format("Color Chaos server (%s): %d checks passed", scenario, passed))
	return
end

runUntil(function() return first.Latest and first.Latest.Profile end, 15)
check("server boot reaches READY with a safe saved world", workspace:GetAttribute("ColorChaosBootStatus") == "READY")
check("entry stays on the lobby spawn floor", first.Character.HumanoidRootPart.Position.Z == 110)
check("player is bound to saved neutral spawn", first.RespawnLocation == staticWorld.LobbySpawn)
check("players cannot push each other", collisions["ColorChaosPlayers:ColorChaosPlayers"] == false)
check("ghosts pass gates without moving competitors", collisions["ColorChaosGhosts:ColorChaosGates"] == false and collisions["ColorChaosGhosts:ColorChaosPlayers"] == false)
runUntil(function() return first.Latest.Phase == "PREVIEW" end, 25)
check("game starts even with fewer than four people", first.Latest.Stage == 1 and first.Latest.Mode == "ALIVE")
check("preview freezes competitors safely", first.Character.HumanoidRootPart.Anchored == true)
check("preview sends the original color without exposing correct index", first.Latest.ReferenceRGB ~= nil and first.Latest.CorrectLane == nil)
runUntil(function() return first.Latest.Phase == "CHOOSE" end, 4)
check("run releases the avatar", first.Character.HumanoidRootPart.Anchored == false)
check("five visible alternatives use a recolored reference", #first.Latest.Choices == 5 and first.Latest.CorrectLane == nil)

local action = shared.Remotes.Action
local function sync(player)
	advance(0.6)
	action.OnServerEvent:Fire(player, "Sync")
end
local function rgbEqual(a, b) return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] end
local function answer(player)
	local state = player.Latest
	local character = Characters.get(state.CharacterId)
	for lane, color in ipairs(state.Choices) do if rgbEqual(color, character.TargetRGB or character.ColorRGB) then return lane end end
	error("Question has no canonical color")
end
local function placeAt(player, lane)
	local state = first.Latest
	local coordinates = GameRules.stageCoordinates(state.Stage)
	player.Character.HumanoidRootPart.Position = Vector3.new(GameSettings.LaneX[lane], 10, coordinates.GateZ + 10)
	staticWorld.Stages[string.format("Stage%02d", state.Stage)].Gates["Gate" .. lane].ChoicePad.Touched:Fire(player.Character.HumanoidRootPart)
end
local function chooseAll(stage, wrongPlayer)
	runUntil(function() return first.Latest.Phase == "CHOOSE" and first.Latest.Stage == stage end, 28)
	advance(1.6)
	local lane = answer(first)
	for _, player in ipairs({ first, second, third }) do
		if player and player.Latest.Alive then placeAt(player, player == wrongPlayer and lane % 5 + 1 or lane) end
	end
	runUntil(function() return first.Latest.Phase == "REVEAL" or first.Latest.Phase == "RESULTS" end, 14)
	return lane
end

if scenario == "journey" then
	local stageOnePosition = first.Character.HumanoidRootPart.Position.Z
	local startingCoins = first.Latest.Profile.Coins
	action.OnServerEvent:Fire(first, "Choose", { Lane = answer(first), Reward = 99999 })
	check("forged client choices cannot award points", first.Latest.MyChoice == nil and first.Latest.Profile.Coins == startingCoins)
	placeAt(first, answer(first))
	check("instant pretravel teleport cannot answer", first.Latest.MyChoice == nil)
	first.Character.HumanoidRootPart.Position = Vector3.new(0, 10, GameRules.stageCoordinates(1).StartZ)
	local opened = chooseAll(1)
	check("correct physical selection earns a server reward", first.Latest.Profile.Coins == startingCoins + 8)
	check("answered players are released for advancement", not first.Character.HumanoidRootPart.Anchored)
	local gateGroup = staticWorld.Stages.Stage01.Gates
	check("only the correct door opens", not gateGroup["Gate" .. opened].Barrier.CanCollide and gateGroup["Gate" .. (opened % 5 + 1)].Barrier.CanCollide)
	check("answer index appears only after the decision", first.Latest.CorrectLane == opened)
	for stage = 2, 5 do chooseAll(stage) end
	check("five consecutive correct choices grant a free gift", first.Latest.Profile.CurrentStreak == 5 and first.Latest.Profile.FreeGifts == 1)
	check("five-stage advancement moves physically through the map", first.Character.HumanoidRootPart.Position.Z < stageOnePosition - 400)
	check("room board follows current competitors and real accuracy", #first.Latest.RoomBoard == 3 and first.Latest.RoomBoard[1].CorrectThisMatch == 5)
	advance(0.7)
	action.OnServerEvent:Fire(first, "OpenGift", { Kind = "Coins", Amount = 999999, Roll = 1 })
	check("free gift opening consumes exactly one earned gift", first.Latest.Profile.FreeGifts == 0)
	check("caller cannot set random gift value", first.Latest.Profile.Coins < 1000)
	local receipt = { PlayerId = first.UserId, ProductId = 101, PurchaseId = "server-check-001" }
	local beforeReceipt = first.Latest.Profile.Coins
	check("actual receipt callback confirms persisted purchase", marketplace.ProcessReceipt(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
	sync(first)
	check("legacy paid coin quantity is preserved", first.Latest.Profile.Coins == beforeReceipt + Config.Commerce.Products[1].Coins)
	check("paid coins and receipt share the same durable profile", saved.Player_1.Data.Receipts[receipt.PurchaseId] == Config.Commerce.Products[1].Coins and saved.Player_1.Data.Coins == first.Latest.Profile.Coins)
	marketplace.ProcessReceipt(receipt)
	sync(first)
	check("duplicate receipt cannot grant twice", first.Latest.Profile.Coins == beforeReceipt + Config.Commerce.Products[1].Coins)
	check("global board writes only after saved progress", orderedWrites > 0)
elseif scenario == "ghosts" then
	local late = addPlayer(4)
	players.PlayerAdded:Fire(late)
	advance(0.2)
	check("late joining remains in the lobby", late.Latest.Mode == "LOBBY" and not late.Latest.Alive and late.Character.HumanoidRootPart.Position.Z == 110)
	action.OnServerEvent:Fire(late, "EnterGhost")
	check("late joining can voluntarily enter ghost practice", late.Latest.Mode == "GHOST" and not late.Latest.Alive)
	check("ghost avatar receives noncompetitive collision group", late.Character.HumanoidRootPart.CollisionGroup == "ColorChaosGhosts")
	advance(1.6)
	local correct = answer(first)
	placeAt(late, correct)
	local ghostCoins = late.Latest.Profile.Coins
	placeAt(first, correct)
	placeAt(second, correct)
	placeAt(third, correct % 5 + 1)
	runUntil(function() return first.Latest.Phase == "REVEAL" end, 14)
	check("wrong answer eliminates to lobby", third.Latest.Mode == "LOBBY" and not third.Latest.Alive and third.Character.HumanoidRootPart.Position.Z == 110)
	check("late ghost cannot score or earn a streak", late.Latest.Profile.Coins == ghostCoins and late.Latest.Profile.CurrentStreak == 0 and late.Latest.Profile.FreeGifts == 0)
	check("late ghost has no room rank", #late.Latest.RoomBoard == 3)
	advance(0.2)
	action.OnServerEvent:Fire(third, "EnterGhost")
	check("eliminated competitor can practice without rejoining competition", third.Latest.Mode == "GHOST" and not third.Latest.Alive)
	chooseAll(2)
	runUntil(function() return first.Latest.Phase == "CHOOSE" and first.Latest.Stage == 3 end, 25)
	check("two finalists receive a decisive speed round", first.Latest.Final == true and first.Latest.AliveCount == 2)
	check("final starts at equal distance for both rivals", first.Character.HumanoidRootPart.Position.X == second.Character.HumanoidRootPart.Position.X and first.Character.HumanoidRootPart.Position.Z == second.Character.HumanoidRootPart.Position.Z)
	advance(1.6)
	placeAt(second, answer(second))
	placeAt(first, answer(first))
	runUntil(function() return first.Latest.Phase == "RESULTS" end, 15)
	check("first correct final touch wins despite lower userid opponent", second.Latest.Profile.Wins == 1 and first.Latest.Profile.Wins == 0)
	check("ghosts never receive victory awards", third.Latest.Profile.Wins == 0 and late.Latest.Profile.Wins == 0)
	check("result ends ghost practice safely in lobby", late.Latest.Mode == "LOBBY" and third.Latest.Mode == "LOBBY")
	check("eliminated player has no stolen streak gift", third.Latest.Profile.CurrentStreak == 0 and third.Latest.Profile.FreeGifts == 0)
elseif scenario == "solo" then
	check("one player enters explicitly marked practice", first.Latest.Solo == true)
	for stage = 1, 8 do chooseAll(stage) end
	runUntil(function() return first.Latest.Phase == "RESULTS" end, 15)
	check("solo can finish all eight stages without fabricated wins", first.Latest.Profile.Wins == 0)
	check("solo practice still grants free progress and streak gift", first.Latest.Profile.CurrentStreak == 8 and first.Latest.Profile.FreeGifts == 1 and first.Latest.Profile.Coins == 64)
	check("completed practice returns to the safe lobby", first.Character.HumanoidRootPart.Position.Z == 110 and not first.Character.HumanoidRootPart.Anchored)
elseif scenario == "datastore-unavailable" then
	check("unavailable storage does not prevent gameplay", first.Latest.Phase == "CHOOSE" and first.Latest.Mode == "ALIVE")
	check("storage outage keeps paid coin sales closed", first.Latest.Commerce[1].Kind == "Product" and first.Latest.Commerce[1].Available == false)
	chooseAll(1)
	check("free session gameplay remains available during storage failure", first.Latest.Profile.Coins == 8)
	check("outage does not invent global records", orderedWrites == 0 and orderedReads == 0)
	check("pending receipts are retained for later retry", marketplace.ProcessReceipt({ PlayerId = 1, ProductId = 101, PurchaseId = "offline" }) == Enum.ProductPurchaseDecision.NotProcessedYet)
elseif scenario == "recovery" then
	action.OnServerEvent:Fire(first, "ClaimTimeGift", "time2")
	check("time gift cannot be claimed before real session time", first.Latest.Profile.Gems == 0 and not first.Latest.Profile.TimeGifts[1].Claimed)
	first.Character.HumanoidRootPart.Position = Vector3.new(0, -1, -40)
	advance(0.4)
	check("fall is recovered before entering a repeated void death", first.Latest.Mode == "LOBBY" and first.Character.HumanoidRootPart.Position.Y == 11 and first.Character.HumanoidRootPart.Position.Z == 110)
	check("fall removes competitive eligibility", not first.Latest.Alive and first.Latest.Profile.CurrentStreak == 0)
	action.OnServerEvent:Fire(first, "EnterGhost")
	check("recovered player may continue as a ghost", first.Latest.Mode == "GHOST")
	first.Character.HumanoidRootPart.Position = Vector3.new(0, -1, -40)
	advance(0.4)
	check("ghost fall returns to active course without becoming eligible", first.Character.HumanoidRootPart.Position.Y == 10 and first.Latest.Mode == "GHOST" and not first.Latest.Alive)
	advance(121)
	sync(first)
	check("free time rewards count time even without winning", first.Latest.Profile.TimeGifts[1].Ready and first.Latest.Profile.Wins == 0)
	advance(0.2)
	action.OnServerEvent:Fire(first, "ClaimTimeGift", "time2")
	check("two minutes grant exactly twenty free diamonds", first.Latest.Profile.Gems == 20 and first.Latest.Profile.TimeGifts[1].Claimed)
	advance(0.2)
	action.OnServerEvent:Fire(first, "ClaimTimeGift", "time2")
	check("repeated claim cannot duplicate free diamonds", first.Latest.Profile.Gems == 20)
	advance(180)
	action.OnServerEvent:Fire(first, "ClaimTimeGift", "time5")
	check("five minutes grant a usable free suit", first.Latest.Profile.CosmeticsOwned.suit_mint == true and first.Latest.Profile.TimeGifts[2].Claimed)
	advance(0.2)
	action.OnServerEvent:Fire(first, "EquipCosmetic", "suit_mint")
	check("earned suit can be equipped without Robux", first.Latest.Profile.Equipped.Suit == "suit_mint" and #purchasePrompts == 0)
	local before = first.Latest.Profile.Coins
	commitThenThrow = true
	local receipt = { PlayerId = first.UserId, ProductId = 101, PurchaseId = "lost-ack-main" }
	check("lost receipt acknowledgement returns retry", marketplace.ProcessReceipt(receipt) == Enum.ProductPurchaseDecision.NotProcessedYet)
	check("lost acknowledgement still keeps purchase in durable data", saved.Player_1.Data.Receipts[receipt.PurchaseId] == 100)
	advance(2.5)
	sync(first)
	check("scheduled save recovers paid coins exactly once", first.Latest.Profile.Coins == before + 100)
	check("receipt retry acknowledges already recovered award", marketplace.ProcessReceipt(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
	sync(first)
	check("receipt recovery never duplicates credited currency", first.Latest.Profile.Coins == before + 100)
end

print(string.format("Color Chaos server (%s): %d checks passed", scenario, passed))
