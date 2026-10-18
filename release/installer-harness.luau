-- This exercises the actual installer source; it does not run Roblox Studio.
local checks = 0
local function check(value, message)
	checks += 1
	assert(value, message)
end
local fixture
local failures = {}
local outputs = {}
local function print(message) table.insert(outputs, message) end
local function warn(message) table.insert(outputs, message) end
local Enum = { FinishRecordingOperation = { Commit = "Commit", Cancel = "Cancel" } }
local classes = {
	Part = { BasePart = true }, SpawnLocation = { BasePart = true },
	Script = { BaseScript = true }, LocalScript = { BaseScript = true },
}
local nodeMeta = {}
nodeMeta.__index = function(self, key)
	local methods = rawget(self, "Methods")
	if methods[key] then return methods[key] end
	local props = rawget(self, "Props")
	if props[key] ~= nil then return props[key] end
	for _, child in ipairs(rawget(self, "Children")) do if child.Name == key then return child end end
end
nodeMeta.__newindex = function(self, key, value)
	local props = rawget(self, "Props")
	if key == "Parent" then
		local target = failures[self.Name]
		if target and value == (target == true and fixture.Services.ServerScriptService or target) then
			failures[self.Name] = nil
			error("Injected parent mutation failure")
		end
		local previous = props.Parent
		if previous then
			local siblings = rawget(previous, "Children")
			for index, child in ipairs(siblings) do if child == self then table.remove(siblings, index); break end end
		end
		props.Parent = value
		if value then table.insert(rawget(value, "Children"), self) end
	else
		if key == "Disabled" and value == false and fixture.FailEnable
			and (props.ClassName == "Script" or props.ClassName == "LocalScript")
			and self.Parent and self.Parent.Parent == fixture.Services.ServerScriptService then
			fixture.FailEnable = false
			error("Injected activation failure after moving staged package")
		end
		props[key] = value
	end
end
local Instance = {}
function Instance.new(class)
	local self = setmetatable({ Props = { ClassName = class, Name = class, Archivable = true, Disabled = false }, Children = {}, Methods = {} }, nodeMeta)
	function self.Methods.IsA(_, expected) return class == expected or (classes[class] and classes[class][expected]) == true end
	function self.Methods.FindFirstChild(_, name)
		for _, child in ipairs(self.Children) do if child.Name == name then return child end end
		return nil
	end
	function self.Methods.GetDescendants(_)
		local result = {}
		local function visit(root)
			for _, child in ipairs(root.Children) do table.insert(result, child); visit(child) end
		end
		visit(self)
		return result
	end
	function self.Methods.Clone(_)
		if not self.Archivable then return nil end
		local result = Instance.new(class)
		for key, value in pairs(self.Props) do if key ~= "Parent" then result[key] = value end end
		for _, child in ipairs(self.Children) do local cloned = child:Clone(); if cloned then cloned.Parent = result end end
		return result
	end
	function self.Methods.Destroy(_)
		self.Parent = nil
		self.Destroyed = true
	end
	return self
end
local function node(class, name, parent)
	local value = Instance.new(class)
	value.Name, value.Parent = name, parent
	return value
end
-- @SCENE@
local function sceneNode(spec, name, parent)
	local value = node(spec["$className"], name, parent)
	for property, content in pairs(spec["$properties"] or {}) do
		if property == "Position" or property == "Size" then
			value[property] = { X = content[1], Y = content[2], Z = content[3] }
		elseif property == "CFrame" then
			local position = (content.CFrame or content).position
			value.Position = { X = position[1], Y = position[2], Z = position[3] }
		else
			value[property] = content
		end
	end
	for childName, child in pairs(spec) do
		if string.sub(childName, 1, 1) ~= "$" then sceneNode(child, childName, value) end
	end
	return value
end
local game = {}
function game:GetService(name)
	if name == "DataStoreService" or name == "MarketplaceService" then error("Installer must not access data or sales") end
	assert(fixture.Services[name], "Unexpected service " .. name)
	return fixture.Services[name]
end
local script = node("ModuleScript", "Installer", nil)
local function prepare()
	fixture = { Services = {}, Studio = true, Running = false, Commits = 0, Cancels = 0, RecordingAvailable = true }
	for _, name in ipairs({ "ReplicatedStorage", "ServerScriptService", "StarterPlayer", "ServerStorage", "Workspace" }) do
		fixture.Services[name] = node("Folder", name, nil)
	end
	fixture.Services.RunService = {
		IsStudio = function() return fixture.Studio end,
		IsRunning = function() return fixture.Running end,
	}
	fixture.Services.ChangeHistoryService = {
		TryBeginRecording = function() if not fixture.RecordingAvailable then error("No recording support") end; return "record" end,
		FinishRecording = function(_, token, operation)
			assert(token == "record")
			if operation == "Commit" then fixture.Commits += 1 else fixture.Cancels += 1 end
		end,
		SetWaypoint = function() fixture.Waypoints = (fixture.Waypoints or 0) + 1 end,
	}
	local services = fixture.Services
	local starterScripts = node("Folder", "StarterPlayerScripts", services.StarterPlayer)
	fixture.OriginalShared = node("Folder", "ColorChaos", services.ReplicatedStorage)
	fixture.OriginalConfig = node("ModuleScript", "Config", fixture.OriginalShared)
	fixture.OriginalConfig.Source = "return { Custom = true, Commerce = { ProductIds = { 111, 222, 333 }, PassId = 444 }, DataStoreName = 'keep_me' }"
	fixture.OriginalServer = node("Folder", "ColorChaosServer", services.ServerScriptService)
	fixture.OriginalMain = node("Script", "Main", fixture.OriginalServer)
	fixture.OriginalMain.Disabled = false
	fixture.DisabledHelper = node("Script", "Helper", fixture.OriginalServer)
	fixture.DisabledHelper.Disabled = true
	fixture.OriginalClient = node("Folder", "ColorChaosClient", starterScripts)
	fixture.OriginalUI = node("LocalScript", "Main", fixture.OriginalClient)
	fixture.Other = node("Folder", "Unrelated", services.Workspace)
	fixture.Package = node("Model", "ColorChaosUpdate", services.Workspace)
	local stagedReplicated = node("Folder", "ReplicatedStorage", fixture.Package)
	local shared = node("Folder", "ColorChaos", stagedReplicated)
	node("ModuleScript", "Config", shared).Source = "return { Commerce = { PassId = 0 } }"
	node("ModuleScript", "Rules", shared)
	for _, name in ipairs({ "GameSettings", "Catalog", "Characters", "Portrait", "GameRules", "Economy", "ProfileLedger", "Progression" }) do
		node("ModuleScript", name, shared).Source = "return { NewVersion = true }"
	end
	local stagedServer = node("Folder", "ServerScriptService", fixture.Package)
	local server = node("Folder", "ColorChaosServer", stagedServer)
	node("Script", "Main", server).Disabled = true
	for _, name in ipairs({ "Profiles", "Leaderboards", "Cosmetics", "Commerce" }) do node("ModuleScript", name, server) end
	local stagedStarter = node("Folder", "StarterPlayerScripts", fixture.Package)
	local client = node("Folder", "ColorChaosClient", stagedStarter)
	node("LocalScript", "Main", client).Disabled = true
	node("LocalScript", "Bootstrap", client).Disabled = true
	local stagedWorkspace = node("Folder", "Workspace", fixture.Package)
	local world = sceneNode(sceneSpec, "ColorChaosWorld", stagedWorkspace)
	fixture.StagedWorld = world
	script.Parent = fixture.Package
	failures, outputs = {}, {}
	return fixture
end

-- @INSTALLER@

prepare()
local result = Installer.apply()
check(result.Updated == true, "Update succeeds")
local backup = fixture.Services.ServerStorage:FindFirstChild(result.Backup)
check(backup ~= nil, "Original objects retained in backup")
check(backup.ColorChaos == fixture.OriginalShared, "Original shared object identity retained")
check(backup.ColorChaosServer == fixture.OriginalServer, "Original server identity retained")
check(backup.ColorChaosClient == fixture.OriginalClient, "Original client identity retained")
check(fixture.OriginalMain.Disabled and fixture.OriginalUI.Disabled and fixture.DisabledHelper.Disabled, "Every backup script disabled")
local installed = fixture.Services.ReplicatedStorage.ColorChaos
check(installed.Config ~= fixture.OriginalConfig, "Preserved Config is cloned")
check(installed.Config.Source == fixture.OriginalConfig.Source, "Complete Config including real IDs and store name retained verbatim")
check(installed.Rules ~= nil, "New shared code installed")
check(installed.GameSettings.Source == "return { NewVersion = true }", "New independent gameplay settings installed despite preserving old Config")
check(fixture.Services.ServerScriptService.ColorChaosServer.Main.Disabled == false, "Server enabled after installation")
local client = fixture.Services.StarterPlayer.StarterPlayerScripts.ColorChaosClient
check(not client.Main.Disabled and not client.Bootstrap.Disabled, "All player scripts enabled after installation")
check(fixture.Services.Workspace.ColorChaosWorld.LobbySpawn.Anchored, "Serialized lobby installed")
check(fixture.Services.Workspace.ColorChaosWorld.Stages.Stage08.Gates.Gate5.PortraitAnchor.Anchored,
	"Final sector and fifth portrait are installed from actual scene geometry")
check(fixture.Other.Parent == fixture.Services.Workspace, "Unrelated scene preserved")
check(fixture.Package.Parent == fixture.Services.ServerStorage, "Staged scene removed from the active world")
check(fixture.Services.Workspace:FindFirstChild("ColorChaosUpdate") == nil, "No staged model remains in Workspace")
local spawns = 0
for _, descendant in ipairs(fixture.Services.Workspace:GetDescendants()) do
	if descendant:IsA("SpawnLocation") then spawns += 1 end
end
check(spawns == 1, "Only the installed lobby spawn remains in Workspace")
check(fixture.Package.ServerScriptService.ColorChaosServer.Main.Disabled, "Imported server stays dormant")
check(fixture.Package.StarterPlayerScripts.ColorChaosClient.Main.Disabled
	and fixture.Package.StarterPlayerScripts.ColorChaosClient.Bootstrap.Disabled, "Imported client scripts stay dormant outside Workspace")
check(fixture.Commits == 1 and fixture.Cancels == 0, "History committed on success")
check(#outputs == 1 and not string.find(outputs[1], "111", 1, true) and not string.find(outputs[1], "keep_me", 1, true), "No configured ID or store content logged")

local priorBackup = result.Backup
local second = Installer.apply()
check(second.Backup ~= priorBackup, "Multiple updates retain unique backup names")
check(fixture.Services.ServerStorage:FindFirstChild(priorBackup) == backup, "Earlier backup retained")
check(fixture.Services.ReplicatedStorage.ColorChaos.Config.Source == fixture.OriginalConfig.Source, "Repeated update still preserves configuration")

prepare()
fixture.Studio = false
local ok = pcall(Installer.apply)
check(not ok, "Production invocation rejected")
check(fixture.OriginalShared.Parent == fixture.Services.ReplicatedStorage, "Production rejection has no mutation")
prepare()
fixture.Running = true
ok = pcall(Installer.apply)
check(not ok and not fixture.OriginalMain.Disabled, "Running session rejected before script flags change")

prepare()
fixture.Package.ServerScriptService.ColorChaosServer.Main.Disabled = false
ok = pcall(Installer.apply)
check(not ok, "Active imported script rejected")
check(fixture.Services.Workspace:FindFirstChild("ColorChaosWorld") == nil, "Active script rejection leaves scene untouched")

prepare()
fixture.StagedWorld.LobbySpawn.Position = { X = 999, Y = 7, Z = 153 }
ok = pcall(Installer.apply)
check(not ok, "Spawn outside safe floor rejected")
check(fixture.Services.ServerStorage:GetDescendants()[1] == nil, "Unsafe world creates no backup or partial update")

prepare()
fixture.StagedWorld.LobbySpawn.Enabled = false
ok = pcall(Installer.apply)
check(not ok and not fixture.OriginalMain.Disabled, "Disabled spawn rejected before mutating old game")

prepare()
node("SpawnLocation", "UnexpectedSpawn", fixture.StagedWorld)
ok = pcall(Installer.apply)
check(not ok and fixture.OriginalServer.Parent == fixture.Services.ServerScriptService, "Extra spawn rejected before replacing old game")

prepare()
fixture.StagedWorld.Stages.Stage08.Gates.Gate5.ChoicePad:Destroy()
ok = pcall(Installer.apply)
check(not ok, "Missing final-sector choice pad prevents incomplete installation")
check(fixture.Services.ServerStorage:GetDescendants()[1] == nil, "Incomplete course does not create a partial backup")

prepare()
fixture.Package.ReplicatedStorage.ColorChaos.GameSettings:Destroy()
ok = pcall(Installer.apply)
check(not ok and fixture.OriginalConfig.Parent == fixture.OriginalShared, "Missing new gameplay module leaves original Config intact")

prepare()
fixture.Package.StarterPlayerScripts.ColorChaosClient.Bootstrap:Destroy()
ok = pcall(Installer.apply)
check(not ok and not fixture.OriginalUI.Disabled, "Missing independent welcome blocks incomplete update")

prepare()
fixture.OriginalConfig:Destroy()
ok = pcall(Installer.apply)
check(not ok, "Wrong experience without Config rejected")
check(fixture.OriginalServer.Parent == fixture.Services.ServerScriptService, "Wrong experience preserves original server")

prepare()
fixture.OriginalConfig.Archivable = false
ok = pcall(Installer.apply)
check(not ok and not fixture.OriginalMain.Disabled, "Non-cloneable user Config rejected before mutation")

prepare()
fixture.Package.ServerScriptService.ColorChaosServer.Main.Archivable = false
ok = pcall(Installer.apply)
check(not ok, "Non-cloneable staged server rejected before a silent incomplete clone")
check(fixture.OriginalServer.Parent == fixture.Services.ServerScriptService and not fixture.OriginalMain.Disabled, "Non-cloneable stage preserves installed server")

prepare()
local originalWorld = node("Folder", "ColorChaosWorld", fixture.Services.Workspace)
node("Part", "OldGeometry", originalWorld)
failures.ColorChaosServer = true
ok = pcall(Installer.apply)
check(not ok, "Injected mid-update failure reported")
check(fixture.OriginalShared.Parent == fixture.Services.ReplicatedStorage, "Rollback restores original shared object identity")
check(fixture.OriginalServer.Parent == fixture.Services.ServerScriptService, "Rollback restores original server object identity")
check(fixture.OriginalClient.Parent == fixture.Services.StarterPlayer.StarterPlayerScripts, "Rollback preserves untouched client")
check(originalWorld.Parent == fixture.Services.Workspace, "Rollback preserves previous world")
check(not fixture.OriginalMain.Disabled and fixture.DisabledHelper.Disabled, "Rollback restores every original disabled flag")
check(fixture.OriginalConfig.Source == "return { Custom = true, Commerce = { ProductIds = { 111, 222, 333 }, PassId = 444 }, DataStoreName = 'keep_me' }", "Rollback retains complete configured source")
check(fixture.Cancels == 1 and fixture.Commits == 0, "Failed update cancels history recording")
check(fixture.Other.Parent == fixture.Services.Workspace, "Failed update never touches unrelated objects")
check(fixture.Package.Parent == fixture.Services.Workspace, "Failed update retains imported package in its original parent")

prepare()
failures.ColorChaosUpdate = fixture.Services.ServerStorage
ok = pcall(Installer.apply)
check(not ok, "Failure moving staged package is reported")
check(fixture.Package.Parent == fixture.Services.Workspace, "Failed staged-package move retains its original parent")
check(fixture.OriginalShared.Parent == fixture.Services.ReplicatedStorage and fixture.OriginalServer.Parent == fixture.Services.ServerScriptService,
	"Failed staged-package move rolls back all replaced objects")
check(not fixture.OriginalMain.Disabled, "Failed staged-package move restores original script activation")

prepare()
fixture.FailEnable = true
ok = pcall(Installer.apply)
check(not ok, "Activation failure after moving staged package is reported")
check(fixture.Package.Parent == fixture.Services.Workspace, "Rollback returns already moved staged package to original parent")
check(fixture.OriginalServer.Parent == fixture.Services.ServerScriptService and not fixture.OriginalMain.Disabled,
	"Activation failure restores original server and activation")
check(fixture.Services.Workspace:FindFirstChild("ColorChaosWorld") == nil, "Activation failure removes newly installed scene")

prepare()
fixture.RecordingAvailable = false
result = Installer.apply()
check(result.Updated and fixture.Waypoints == 2, "Backup and legacy waypoints support unavailable modern history")
check(fixture.Services.ServerStorage:FindFirstChild(result.Backup).ColorChaos == fixture.OriginalShared, "Fallback retains original objects")
check(fixture.Services.ReplicatedStorage.ColorChaos.Config.Source == fixture.OriginalConfig.Source, "Fallback retains configured source")

print = _G.print
print("Installer: " .. tostring(checks) .. " checks passed (Studio service mocks; no Roblox engine).")
