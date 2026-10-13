-- Minimal orchestration mocks, not a Roblox engine or physics replacement.
local now = 1
local jobs = {}
local warnings = {}
local function warn(message) table.insert(warnings, tostring(message)) end
local baseOs = os
local os = setmetatable({ clock = function() return now end, time = function() return 1700000000 + math.floor(now) end }, { __index = baseOs })
local function enqueue(thread, due)
	table.insert(jobs, { Thread = thread, Due = due })
end
local task = {}
function task.spawn(callback, ...)
	local args = table.pack(...)
	enqueue(coroutine.create(function() callback(table.unpack(args, 1, args.n)) end), now)
end
function task.delay(seconds, callback) enqueue(coroutine.create(callback), now + seconds) end
function task.defer(callback, ...) task.spawn(callback, ...) end
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
vectorMeta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__mul = function(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
Vector3.zero = Vector3.new()
local Vector2 = { new = function(...) return { ... } end, zero = {} }
local frameMeta = {}
local CFrame = { new = function(x, y, z)
	return setmetatable({ Position = type(x) == "table" and x or Vector3.new(x, y, z) }, frameMeta)
end }
frameMeta.__mul = function(a, b) return CFrame.new(a.Position + b.Position) end
CFrame.identity = CFrame.new()
CFrame.Angles = function() return CFrame.new() end
CFrame.lookAt = function(position) return CFrame.new(position) end
local Color3 = {}
local colorMeta = {}
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, colorMeta) end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
colorMeta.__index = { Lerp = function(a, b, alpha) return Color3.new(a.R + (b.R - a.R) * alpha, a.G + (b.G - a.G) * alpha, a.B + (b.B - a.B) * alpha) end }
local NumberSequence = { new = function(...) return { ... } end }
local NumberSequenceKeypoint = { new = function(...) return { ... } end }
local ColorSequence = { new = function(...) return { ... } end }
local ColorSequenceKeypoint = { new = function(...) return { ... } end }
local TweenInfo = { new = function(...) return { ... } end }
local UDim = { new = function(...) return { ... } end }
local UDim2 = { fromOffset = function(...) return { ... } end, fromScale = function(...) return { ... } end }
local Enum = setmetatable({}, { __index = function(_, category) return setmetatable({}, { __index = function(_, value) return category .. "." .. value end }) end })
local randomSeed = 23
local Random = { new = function() return {
	NextInteger = function(_, minimum, maximum)
		randomSeed = (randomSeed * 48271) % 2147483647
		return minimum + randomSeed % (maximum - minimum + 1)
	end,
	NextNumber = function(_, minimum, maximum) return minimum + (maximum - minimum) * 0.4 end,
} end }

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
	if key == "CFrame" and value and value.Position then object._properties.Position = value.Position end
	if key == "Parent" then
		local old = object._properties.Parent
		if old then
			for i, child in ipairs(old._children) do if child == object then table.remove(old._children, i); break end end
		end
		if value then table.insert(value._children, object) end
	end
	object._properties[key] = value
	if key == "Parent" and value then
		if value.ChildAdded then value.ChildAdded:Fire(object) end
		local ancestor = value
		while ancestor do
			if ancestor.DescendantAdded then ancestor.DescendantAdded:Fire(object) end
			ancestor = ancestor.Parent
		end
	end
end
function Instance.new(className)
	local object = setmetatable({ _properties = { ClassName = className, Name = className }, _children = {}, _attributes = {} }, instanceMeta)
	object.ChildAdded, object.DescendantAdded = signal(), signal()
	if className == "Part" or className == "SpawnLocation" or className == "WedgePart" then
		object.Position, object.Size, object.Touched = Vector3.new(), Vector3.new(1, 1, 1), signal()
	end
	if className == "ProximityPrompt" then object.Triggered = signal(); object.Enabled = true end
	if className == "Humanoid" then object.Died = signal(); object.Health = 100 end
	if className == "RemoteEvent" then object.OnServerEvent = signal() end
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
function methods:Clone()
	local result = Instance.new(self.ClassName)
	for key, value in pairs(self._properties) do
		if key ~= "Parent" and key ~= "ClassName" and key ~= "ChildAdded" and key ~= "DescendantAdded" and key ~= "Touched" then result[key] = value end
	end
	result._attributes = clone(self._attributes)
	for _, child in ipairs(self._children) do child:Clone().Parent = result end
	return result
end
function methods:PivotTo(frame) self.HumanoidRootPart.Position = frame.Position end
function methods:SetAttribute(name, value) self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes[name] end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result = {}
	for _, child in ipairs(self._children) do
		table.insert(result, child)
		for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end
	end
	return result
end
function methods:IsA(className) return self.ClassName == className or (className == "BasePart" and (self.ClassName == "Part" or self.ClassName == "SpawnLocation")) end
function methods:FindFirstAncestorOfClass(className)
	local parent = self.Parent
	while parent do if parent:IsA(className) then return parent end; parent = parent.Parent end
	return nil
end
function methods:FireClient(player, payload)
	if self.Name == "State" then
		player.Latest = clone(payload)
		table.insert(player.States, clone(payload))
		table.insert(player.StateTimes, now)
	end
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
function players:GetPlayerFromCharacter(character)
	for _, player in ipairs(self.List) do if player.Character == character and player.Parent == self then return player end end
	return nil
end
local replicated = Instance.new("ReplicatedStorage")
local shared = Instance.new("Folder")
shared.Name, shared.Parent = "ColorRush", replicated
local serverFolder = Instance.new("Folder")
serverFolder.Name = "ColorRushServer"
local workspace = Instance.new("Workspace")
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
		return clone(result)
	end,
}
local vipOwnership, ownershipQueries = {}, 0
local purchasePrompts = {}
local marketplace = {
	PromptProductPurchaseFinished = signal(),
	PromptGamePassPurchaseFinished = signal(),
	UserOwnsGamePassAsync = function(_, userId, passId)
		assert(type(userId) == "number" and type(passId) == "number", "Unexpected pass ownership lookup")
		ownershipQueries += 1
		return vipOwnership[userId] == true
	end,
	PromptProductPurchase = function(_, player, productId)
		table.insert(purchasePrompts, { Player = player, Kind = "Product", Id = productId })
	end,
	PromptGamePassPurchase = function(_, player, passId)
		table.insert(purchasePrompts, { Player = player, Kind = "Pass", Id = passId })
	end,
}
local guidNumber = 0
local services = {
	Players = players, ReplicatedStorage = replicated, Workspace = workspace,
	DataStoreService = { GetDataStore = function(_, name) assert(name == "ColorRush_Player_v1", "New game must not reuse Color Chaos data"); return store end },
	RunService = { IsStudio = function() return false end },
	PhysicsService = { RegisterCollisionGroup = function() end, CollisionGroupSetCollidable = function() end },
	HttpService = { GenerateGUID = function() guidNumber += 1; return "mock-guid-" .. guidNumber end },
	Debris = { AddItem = function() end },
	Lighting = Instance.new("Lighting"),
	TweenService = { Create = function() return { Play = function() end } end },
	MarketplaceService = marketplace,
}
local game = { JobId = "mock-job", GetService = function(_, name) return assert(services[name], name) end, BindToClose = function() end }
local function addPlayer(id)
	local player = Instance.new("Player")
	player.Name, player.DisplayName, player.UserId = "Tester" .. id, "Tester" .. id, id
	player.States, player.StateTimes = {}, {}
	player.CharacterAdded = signal()
	player.Parent = players
	local character = Instance.new("Model")
	character.Name = player.Name
	character.Parent = workspace
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local root = Instance.new("Part")
	root.Name, root.Position, root.Parent = "HumanoidRootPart", Vector3.new(0, 11, 153), character
	local head = Instance.new("Part")
	head.Name, head.Position, head.Parent = "Head", Vector3.new(0, 13, 153), character
	player.Character = character
	table.insert(players.List, player)
	return player
end
local first, second = addPlayer(1), addPlayer(2)


-- Insert unmodified game modules and the real server.
-- @MODULES_AND_SERVER@

local checks = 0
local function check(name, condition)
	assert(condition, name)
	checks += 1
	print("PASS mock-server: " .. name)
end
local productIds = {}
-- These synthetic IDs exist only in the mock runtime. Shipped Config keeps
-- zero IDs until the owner creates this experience's actual products/pass.
for index, product in ipairs(Config.Commerce.Products) do
	product.ProductId = 100 + index
	productIds[product.Key] = product.ProductId
end
Config.Commerce.VIP.PassId = 201
local function grant(player, key, receiptId)
	return marketplace.ProcessReceipt({
		PlayerId = player.UserId,
		ProductId = assert(productIds[key], "Unknown fixture product"),
		PurchaseId = receiptId,
	})
end
local function correctChoice(state)
	local character = assert(Characters.get(state.CharacterId), "Expected catalog character")
	for index, rgb in ipairs(state.Colors or {}) do
		if table.concat(rgb, ",") == table.concat(character.TargetRGB, ",") then return index end
	end
	error("No matching option in the real server's generated state")
end
local function gate(index)
	return workspace.ColorRushWorld.Gates:WaitForChild("Gate" .. index)
end
local function touch(player, index, travelSeconds)
	if travelSeconds then advance(travelSeconds) end
	local target = gate(index)
	player.Character.HumanoidRootPart.Position = target.Position
	target.Touched:Fire(player.Character.HumanoidRootPart)
end
local function action(player, name, value)
	shared.Remotes.Action.OnServerEvent:Fire(player, name, value)
end
local function removePlayer(player)
	players.PlayerRemoving:Fire(player)
	player.Parent = nil
	for index, item in ipairs(players.List) do if item == player then table.remove(players.List, index); break end end
end

-- @SCENARIOS@
local third = addPlayer(3)
task.spawn(serverMain)
runUntil(function() return first.Latest and first.Latest.Phase == "PREVIEW" end, 60)
local previewStarted = now
check("three ready players start the first normal stage", first.Latest.Participating and first.Latest.Alive and first.Latest.RunnerCount == 3 and not first.Latest.Final)
check("all contenders are frozen at the same start during preview", first.Character.HumanoidRootPart.Anchored and second.Character.HumanoidRootPart.Anchored and third.Character.HumanoidRootPart.Anchored and first.Character.HumanoidRootPart.Position.Z == second.Character.HumanoidRootPart.Position.Z)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
check("memorization preview lasts exactly two seconds", now - previewStarted == 2)
check("running state has five options and never publishes the correct lane", #first.Latest.Colors == 5 and first.Latest.CorrectChoice == nil)
local answer = correctChoice(first.Latest)
local wrong = answer % 5 + 1
touch(first, answer)
check("instant teleport to a gate cannot finish the stage", first.Latest.SelectedChoice == nil and first.Latest.Alive)
first.Character.HumanoidRootPart.Position = Vector3.new(0, 8, 50)
advance(Config.MinimumTravelSeconds + 0.1)
local late = addPlayer(4)
players.PlayerAdded:Fire(late)
advance(0.05)
check("late arrival waits without entering the running match", late.Latest and not late.Latest.Participating and not late.Latest.Alive)
first.Character.HumanoidRootPart.Position = Vector3.new(0, 9, 145)
gate(answer).Touched:Fire(first.Character.HumanoidRootPart)
check("gate callback from the lobby cannot select an answer", first.Latest.SelectedChoice == nil and first.Latest.Alive)
action(first, "Choose", answer)
check("client-supplied answer cannot replace a physical gate choice", first.Latest.SelectedChoice == nil)
check("reentry product grants a durable banked credit", grant(third, "revive1", "normal-credit") == Enum.ProductPurchaseDecision.PurchaseGranted and third.Latest.Profile.ReviveCredits == 1)
check("three-credit product deposits exactly three credits", grant(first, "revive3", "final-credit-bank") == Enum.ProductPurchaseDecision.PurchaseGranted and first.Latest.Profile.ReviveCredits == 3)
touch(first, wrong)
touch(second, wrong)
touch(third, wrong)
check("wrong image eliminates immediately and returns player to lobby", not third.Latest.Alive and third.Character.HumanoidRootPart.Position.Z == 145)
action(third, "UseRevive", true)
check("normal reentry reserves intent without immediately spending a credit", third.Latest.QueuedRevive and third.Latest.Profile.ReviveCredits == 1)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.Round == 2 end, 30)
check("all-wrong replay is free and restores the original active roster", first.Latest.Alive and second.Latest.Alive and third.Latest.Alive and not third.Latest.QueuedRevive and third.Latest.Profile.ReviveCredits == 1 and not late.Latest.Participating)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer, wrong = correctChoice(first.Latest), correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(third, wrong)
action(third, "UseRevive", true)
touch(first, answer)
touch(second, answer)
check("correct normal choices lock once while the match continues", first.Latest.Alive and first.Latest.SelectedChoice == answer and second.Latest.SelectedChoice == answer and first.Latest.Phase == "RUN")
local firstCoins = first.Latest.Profile.Coins
touch(first, wrong)
check("second gate contact cannot replace a committed correct choice or reward twice", first.Latest.Alive and first.Latest.SelectedChoice == answer and first.Latest.Profile.Coins == firstCoins)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.Round == 3 end, 30)
check("queued paid reentry joins the next stage and consumes one credit", third.Latest.Alive and third.Latest.Profile.ReviveCredits == 0 and not third.Latest.QueuedRevive and first.Latest.RunnerCount == 3)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer, wrong = correctChoice(first.Latest), correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(third, wrong)
grant(third, "revive1", "extra-bank-credit")
action(third, "UseRevive", true)
check("a second ordinary reentry is refused and its credit remains banked", not third.Latest.Alive and not third.Latest.QueuedRevive and third.Latest.Profile.ReviveCredits == 1)
touch(first, answer)
touch(second, answer)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.Final end, 30)
check("two surviving players enter a first-arrival final", first.Latest.RunnerCount == 2 and first.Latest.Alive and second.Latest.Alive and not third.Latest.Alive)
action(first, "AutoRevive", true)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer, wrong = correctChoice(first.Latest), correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(first, wrong)
check("automatic final reentry uses exactly one of three credits without recursive consumption", first.Latest.Alive and first.Latest.Profile.ReviveCredits == 2 and first.Character.HumanoidRootPart.Position.Z == 50)
touch(first, answer)
check("final reentry must run the distance again before selecting", first.Latest.SelectedChoice == nil)
advance(Config.MinimumTravelSeconds + 0.1)
touch(first, wrong)
check("only one final opportunity is allowed even with more banked credits", not first.Latest.Alive and not first.Latest.CanRevive and first.Latest.Profile.ReviveCredits == 2)
touch(second, answer)
runUntil(function() return first.Latest.Phase == "REVEAL" end, 2)
check("once the rival finishes all reentry offers close", not first.Latest.CanRevive and not third.Latest.CanRevive)
check("a purchase confirmed after the winning finish stays in the credit bank", grant(first, "revive1", "late-final-credit") == Enum.ProductPurchaseDecision.PurchaseGranted and not first.Latest.Alive and first.Latest.Profile.ReviveCredits == 3)
runUntil(function() return first.Latest.Phase == "RESULTS" end, 6)
check("race declares the first correct final finisher and awards one victory", first.Latest.WinnerName == second.DisplayName and second.Latest.Profile.Wins == 1 and first.Latest.Profile.Wins == 0)
check("spectator and eliminated participants cannot receive the winning reward", late.Latest.Profile.Wins == 0 and late.Latest.Profile.Coins == 0 and third.Latest.Profile.Wins == 0)
check("public state excludes persistence receipt history and locking metadata", first.Latest.Profile.Receipts == nil and first.Latest.Profile.Session == nil and first.Latest.Profile.LeaseUntil == nil)

grant(first, "coins200", "cosmetic-coins")
local coinsBeforeTrail = first.Latest.Profile.Coins
advance(0.35)
action(first, "Trail", 2)
check("actual shop action purchases and equips an earned-currency trail", first.Latest.Profile.SelectedTrail == 2 and first.Latest.Profile.OwnedTrails["2"] and first.Latest.Profile.Coins == coinsBeforeTrail - Config.Trails[2].Cost and first.Character.HumanoidRootPart:FindFirstChild("RushTrail") ~= nil)
vipOwnership[first.UserId] = true
marketplace.PromptGamePassPurchaseFinished:Fire(first, 201, true)
advance(0.35)
action(first, "Trail", 5)
check("verified VIP creates its title and exclusive double trail without changing wins", first.Latest.Profile.VIP and first.Latest.Profile.SelectedTrail == 5 and first.Character.HumanoidRootPart:FindFirstChild("RushVIP") ~= nil and first.Character.HumanoidRootPart:FindFirstChild("RushTrail2") ~= nil and first.Latest.Profile.Wins == 0)

removePlayer(third)
removePlayer(late)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.MatchId == "2" end, 40)
check("new match resets entries and two players can start without a full lobby", first.Latest.Final and first.Latest.RunnerCount == 2 and first.Latest.Alive and second.Latest.Alive)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer = correctChoice(first.Latest)
advance(Config.MinimumTravelSeconds + 0.1)
grant(second, "revive1", "second-bank-credit")
local secondCoins = second.Latest.Profile.Coins
touch(first, answer)
touch(second, answer)
check("two correct contacts in the same scheduler instant latch only the first finisher", first.Latest.SelectedChoice == answer and second.Latest.SelectedChoice == nil and second.Latest.Profile.Coins == secondCoins)
action(second, "UseRevive", true)
check("manual reentry after the winning contact cannot consume a banked credit", second.Latest.Profile.ReviveCredits == 1)
runUntil(function() return first.Latest.Phase == "RESULTS" end, 7)
check("same-frame rival contact cannot alter the winner or create another victory", first.Latest.WinnerName == first.DisplayName and first.Latest.Profile.Wins == 1 and second.Latest.Profile.Wins == 1)
local beforeClaim = first.Latest.Profile.Coins
advance(0.35)
action(first, "ClaimMission", "win1")
check("actual mission action grants the configured daily win reward", first.Latest.Profile.Coins == beforeClaim + Config.DailyMissions[3].Reward)
advance(0.35)
action(first, "ClaimMission", "win1")
check("claiming the same mission twice cannot duplicate currency", first.Latest.Profile.Coins == beforeClaim + Config.DailyMissions[3].Reward)

local newcomer = addPlayer(5)
players.PlayerAdded:Fire(newcomer)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.MatchId == "3" end, 40)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer, wrong = correctChoice(first.Latest), correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(first, wrong)
local creditsBeforeDeath = first.Latest.Profile.ReviveCredits
check("opted-in normal reentry stays reserved until the next stage", first.Latest.QueuedRevive and creditsBeforeDeath == 3)
first.Character.Humanoid.Health = 0
first.Character.Humanoid.Died:Fire()
touch(second, answer)
touch(newcomer, answer)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.Round == 2 end, 30)
check("a queued player whose avatar died cannot lose a credit at stage transition", not first.Latest.Alive and not first.Latest.QueuedRevive and first.Latest.Profile.ReviveCredits == creditsBeforeDeath and first.Latest.RunnerCount == 2)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
answer = correctChoice(first.Latest)
advance(Config.MinimumTravelSeconds + 0.1)
touch(second, answer)
runUntil(function() return first.Latest.Phase == "RESULTS" end, 7)

removePlayer(newcomer)
first.Character.Humanoid.Health = 100
first.CharacterAdded:Fire(first.Character)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.MatchId == "4" end, 40)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
advance(Config.MinimumTravelSeconds + 0.1)
local bankBeforeFinalDeath = first.Latest.Profile.ReviveCredits
first.Character.Humanoid.Health = 0
first.Character.Humanoid.Died:Fire()
check("final avatar death does not automatically consume a credit on an unusable character", not first.Latest.Alive and first.Latest.Profile.ReviveCredits == bankBeforeFinalDeath)
runUntil(function() return first.Latest.Phase == "REVEAL" end, 25)
check("expired final closes reentry before eliminating remaining runners", not first.Latest.CanRevive and not second.Latest.CanRevive)
grant(first, "revive1", "expired-final-credit")
check("receipt confirmed after final timeout remains banked", first.Latest.Profile.ReviveCredits == bankBeforeFinalDeath + 1 and not first.Latest.Alive)
runUntil(function() return first.Latest.Phase == "RESULTS" end, 7)
check("final without any correct finish is a draw with no invented winner", first.Latest.WinnerName == nil and first.Latest.Profile.Wins == 1 and second.Latest.Profile.Wins == 2)

first.Character.Humanoid.Health = 100
first.CharacterAdded:Fire(first.Character)
local lastRunner = addPlayer(6)
players.PlayerAdded:Fire(lastRunner)
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.MatchId == "5" end, 40)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
wrong = correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(first, wrong)
touch(second, wrong)
touch(lastRunner, wrong)
local drawBank = first.Latest.Profile.ReviveCredits
runUntil(function() return first.Latest.Phase == "PREVIEW" and first.Latest.Round == 2 end, 30)
check("new match gets one free all-wrong retry without using automatic paid credits", first.Latest.Profile.ReviveCredits == drawBank and first.Latest.Alive)
runUntil(function() return first.Latest.Phase == "RUN" end, 5)
wrong = correctChoice(first.Latest) % 5 + 1
advance(Config.MinimumTravelSeconds + 0.1)
touch(first, wrong)
touch(second, wrong)
touch(lastRunner, wrong)
runUntil(function() return first.Latest.Phase == "RESULTS" end, 30)
check("exhausted all-wrong retry ends as a draw instead of selling a last-player victory", first.Latest.WinnerName == nil and first.Latest.Profile.ReviveCredits == drawBank and not first.Latest.QueuedRevive and first.Latest.Profile.Wins == 1)
assert(checks > 0, "No server orchestration scenario executed")
print(string.format("All %d real-server orchestration checks passed (limited mocks).", checks))
