-- The actual client is inserted below. Mocks implement Roblox APIs only;
-- they do not reimplement client behavior or execute the renderer/physics.
local objects, sent, childWaits = {}, {}, {}
local function signal()
	local value = { listeners = {} }
	function value:Connect(callback)
		local connection = { Active = true, Callback = callback }
		function connection:Disconnect() self.Active = false end
		table.insert(self.listeners, connection)
		return connection
	end
	function value:fire(...)
		for _, connection in ipairs(table.clone(self.listeners)) do
			if connection.Active then connection.Callback(...) end
		end
	end
	return value
end
local Node = {}
Node.__index = function(self, key)
	if key == "Parent" then return rawget(self, "_parent") end
	if Node[key] then return Node[key] end
	if table.find({ "Activated", "Died", "CharacterAdded" }, key) then
		local value = signal()
		rawset(self, key, value)
		return value
	end
	return rawget(self, key)
end
Node.__newindex = function(self, key, value)
	if key == "Parent" then
		local previous = rawget(self, "_parent")
		if previous then
			for index, child in ipairs(previous.children) do
				if child == self then table.remove(previous.children, index); break end
			end
		end
		rawset(self, "_parent", value)
		if value then table.insert(value.children, self) end
	else rawset(self, key, value) end
end
function Node:IsA(className)
	return className == self.ClassName or className == "GuiObject"
		and table.find({ "Frame", "TextLabel", "TextButton", "ScrollingFrame" }, self.ClassName) ~= nil
end
function Node:GetChildren() return table.clone(self.children) end
function Node:Destroy()
	for _, child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent, self.destroyed = nil, true
end
function Node:FindFirstChild(name, recursive)
	for _, child in ipairs(self.children) do
		if child.Name == name then return child end
		if recursive then
			local match = child:FindFirstChild(name, true)
			if match then return match end
		end
	end
	return nil
end
function Node:FindFirstChildOfClass(className)
	for _, child in ipairs(self.children) do if child.ClassName == className then return child end end
	return nil
end
function Node:WaitForChild(name, timeout)
	table.insert(childWaits, { Parent = self, Name = name, Timeout = timeout })
	return self:FindFirstChild(name)
end
function Node:GetPropertyChangedSignal(name)
	if not self.propertySignals[name] then self.propertySignals[name] = signal() end
	return self.propertySignals[name]
end
function Node:GetAttribute(name) return self.attributes[name] end
function Node:SetAttribute(name, value) self.attributes[name] = value end
local function node(className, name, parent)
	local value = setmetatable({ ClassName = className, Name = name or className, children = {},
		propertySignals = {}, attributes = {}, ZIndex = 1, Active = className == "TextButton" }, Node)
	value.Parent = parent
	table.insert(objects, value)
	return value
end
local Instance = { new = function(className) return node(className) end }
local function vector(x, y) return { X = x, Y = y } end
local Vector2 = { new = vector, zero = vector(0, 0) }
local UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset } end }
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
	return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } }
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
local Color3 = {
	fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255, _type = "Color3" } end,
	new = function(r, g, b) return { R = r, G = g, B = b, _type = "Color3" } end,
}
local function typeof(value) return type(value) == "table" and value._type or type(value) end
local Enum = setmetatable({}, { __index = function(self, group)
	local values = setmetatable({}, { __index = function(options, name)
		rawset(options, name, group .. "." .. name)
		return options[name]
	end })
	rawset(self, group, values)
	return values
end })
local TweenInfo = { new = function(seconds) return { Seconds = seconds } end }
local delayed, mockClock = {}, 10
local os = { clock = function() return mockClock end }
local task = {
	spawn = function(callback) callback() end,
	delay = function(seconds, callback) table.insert(delayed, { Due = mockClock + seconds, Callback = callback }) end,
	wait = function(seconds) return coroutine.yield(seconds or 0) end,
}
local function advanceTime(seconds)
	mockClock += seconds
	for index = #delayed, 1, -1 do
		if delayed[index].Due <= mockClock then table.remove(delayed, index).Callback() end
	end
end
local workspace = node("Workspace")
workspace.CurrentCamera = node("Camera")
workspace.CurrentCamera.ViewportSize = vector(900, 700)
local player = node("Player", "Ariel")
player.UserId, player.DisplayName = 10, "Ariel"
local playerGui = node("PlayerGui", "PlayerGui", player)
local roster = { [player.UserId] = player }
local function makeCharacter(owner, health)
	local character = node("Model", "Character")
	local humanoid = node("Humanoid", "Humanoid", character)
	humanoid.Health = health or 100
	owner.Character = character
	return humanoid
end
local ownHumanoid = makeCharacter(player)
workspace.CurrentCamera.CameraType, workspace.CurrentCamera.CameraSubject = "CameraType.Custom", ownHumanoid
local players = { LocalPlayer = player, PlayerRemoving = signal() }
function players:GetPlayerByUserId(userId) return roster[userId] end
local storage = node("ReplicatedStorage")
local shared = node("Folder", "ColorChaos", storage)
node("ModuleScript", "Config", shared)
local remotes = node("Folder", "Remotes", shared)
local state = node("RemoteEvent", "State", remotes)
state.OnClientEvent = signal()
local action = node("RemoteEvent", "Action", remotes)
function action:FireServer(kind, value) table.insert(sent, { kind, value }) end
local input = { TouchEnabled = false, InputBegan = signal() }
local services = {
	Players = players, ReplicatedStorage = storage, UserInputService = input,
	MarketplaceService = { GetProductInfoAsync = function() return { PriceInRobux = 7, IsForSale = true } end },
	TweenService = { Create = function(_, target, _, properties)
		return { Play = function() for key, value in pairs(properties) do target[key] = value end end }
	end },
}
local game = { GetService = function(_, name) return assert(services[name], name) end }
-- @CLIENT_MOCKS_END@
-- @CLIENT_MODULES@
local function clientMain()
-- @CLIENT_SOURCE@
end
clientMain()

local checks = 0
local function check(value, message) checks += 1; assert(value, message) end
local function buttonWith(text)
	for _, object in ipairs(objects) do
		if not object.destroyed and object.ClassName == "TextButton" and object.Text == text then return object end
	end
	error("Button not found: " .. text)
end
local function containsText(fragment)
	for _, object in ipairs(objects) do
		if not object.destroyed and type(object.Text) == "string" and string.find(object.Text, fragment, 1, true) then return true end
	end
	return false
end
local base = {
	Phase = "LOBBY", Message = "Espera", Seconds = 16, MinimumPlayers = 1, ReadyPlayers = 1,
	Profile = { Coins = 100, Wins = 2, Selected = 1, Owned = { ["1"] = true }, VIP = false },
	Progression = { Level = 3, LevelProgress = 20, NextLevelXP = 100, Missions = {} },
	Persistence = "Guardado activo", Commerce = {},
}
local function snapshot(changes)
	local payload = table.clone(base)
	for key, value in pairs(changes or {}) do payload[key] = value end
	state.OnClientEvent:fire(payload)
end
local ui = playerGui:FindFirstChild("ColorChaosUI")
check(ui and ui:GetAttribute("Ready") == false, "the main UI remains unready until the server responds")
check(#sent == 1 and sent[1][1] == "Sync", "requests the first snapshot after subscribing")
for _, request in ipairs(childWaits) do
	if request.Name ~= "PlayerGui" then check(request.Timeout == 15, "shared dependencies have finite waits") end
end
state.OnClientEvent:fire("bad payload")
check(ui:GetAttribute("Ready") == false, "an invalid snapshot cannot dismiss the independent welcome")
snapshot()
check(ui:GetAttribute("Ready") == true, "the first valid snapshot marks the main UI ready")
check(containsText("1 jugador listo"), "the lobby displays a singular ready-player count")
check(containsText("Juega desde 1 jugador"), "the lobby discloses that one player is sufficient")
check(containsText("La partida empieza automáticamente"), "the lobby explains automatic starts")
local spectatorPanel = ui:FindFirstChild("SpectatorControls")
check(spectatorPanel and not spectatorPanel.Visible, "the lobby does not expose spectator controls")
snapshot({ ReadyPlayers = 4 })
check(containsText("4 jugadores listos"), "plural lobby counts are readable")

local function rival(userId, name, health)
	local owner = node("Player", name)
	owner.UserId, owner.DisplayName = userId, name
	roster[userId] = owner
	return owner, makeCharacter(owner, health)
end
local bluePlayer, blueHumanoid = rival(20, "Azul")
local greenPlayer, greenHumanoid = rival(30, "Verde")
local _, deadHumanoid = rival(40, "Fuera", 0)
snapshot({ Phase = "JUEGO", Participating = false, Alive = false, SpectatorIds = { 10, 20, 20, 30, 40, 999, "invalid" },
	AlivePlayers = 2, ParticipantCount = 3, Progress = 2, Total = 8, LavaHeight = 13.25, PlatformLift = 3.333 })
check(spectatorPanel.Visible, "late arrivals can choose to observe active survivors")
check(workspace.CurrentCamera.CameraSubject == ownHumanoid, "spectating remains voluntary")
check(not buttonWith("SIGUIENTE").Visible, "next-player control is hidden until observing")
check(containsText("2 / 3 sobrevivientes"), "active status reports survivors separately from participants")
check(containsText("LAVA ↑ 13.2 · ARENA +3.3"), "the HUD shows server lava height and platform lift")
local remoteCount = #sent
buttonWith("OBSERVAR").Activated:fire()
check(workspace.CurrentCamera.CameraSubject == blueHumanoid, "observe selects the first living external survivor")
check(buttonWith("SIGUIENTE").Visible, "multiple distinct survivors expose the next-player control")
check(containsText("OBSERVANDO A AZUL"), "the observed survivor is clearly named")
buttonWith("SIGUIENTE").Activated:fire()
check(workspace.CurrentCamera.CameraSubject == greenHumanoid, "next switches to the second survivor")
check(containsText("OBSERVANDO A VERDE"), "the label follows the camera target")
buttonWith("SIGUIENTE").Activated:fire()
check(workspace.CurrentCamera.CameraSubject == blueHumanoid, "next wraps through the deduplicated survivor list")
blueHumanoid.Health = 0
blueHumanoid.Died:fire()
check(workspace.CurrentCamera.CameraSubject == greenHumanoid, "a dead observed avatar immediately yields to a survivor")
check(not buttonWith("SIGUIENTE").Visible, "dead survivors are removed from the camera cycle")
check(workspace.CurrentCamera.CameraSubject ~= deadHumanoid, "preexisting dead avatars are never selected")
buttonWith("VOLVER AL LOBBY").Activated:fire()
check(workspace.CurrentCamera.CameraSubject == ownHumanoid, "return-to-lobby restores the local avatar camera")
check(buttonWith("OBSERVAR") ~= nil, "return-to-lobby leaves observation available without forcing it")
buttonWith("OBSERVAR").Activated:fire()
snapshot({ Phase = "RESULTADOS", Participating = false, Alive = false, SpectatorIds = { 30 } })
check(workspace.CurrentCamera.CameraSubject == ownHumanoid and not spectatorPanel.Visible,
	"results automatically restore the local camera and hide observation")
snapshot({ Phase = "JUEGO", Participating = true, Alive = true, SpectatorIds = { 30 } })
check(not spectatorPanel.Visible and workspace.CurrentCamera.CameraSubject == ownHumanoid,
	"a live participant cannot spectate while playing")
check(containsText("EN EL EQUIPO"), "a live participant sees their active-team status")
snapshot({ Phase = "PREPARACIÓN", Participating = false, Alive = false, SpectatorIds = { 30 } })
check(spectatorPanel.Visible, "late arrivals can observe round preparation")
buttonWith("OBSERVAR").Activated:fire()
players.PlayerRemoving:fire(greenPlayer)
roster[30] = nil
check(workspace.CurrentCamera.CameraSubject == ownHumanoid and not spectatorPanel.Visible,
	"the last observed player's departure restores the lobby camera")
greenHumanoid.Health = 100
roster[30] = greenPlayer
snapshot({ Phase = "JUEGO", Participating = false, Alive = false, SpectatorIds = { 30 } })
buttonWith("OBSERVAR").Activated:fire()
local replacementCamera = node("Camera")
replacementCamera.ViewportSize = vector(1200, 700)
replacementCamera.CameraSubject = ownHumanoid
workspace.CurrentCamera = replacementCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):fire()
check(replacementCamera.CameraSubject == greenHumanoid, "camera replacement preserves voluntary observation")
greenHumanoid.Health = 0
greenHumanoid.Died:fire()
check(replacementCamera.CameraSubject == ownHumanoid and not spectatorPanel.Visible,
	"when all survivors die the local camera is restored")
local previousOwn = ownHumanoid
ownHumanoid = makeCharacter(player)
player.CharacterAdded:fire(player.Character)
check(workspace.CurrentCamera.CameraSubject == ownHumanoid and ownHumanoid ~= previousOwn,
	"respawn restores the camera to the new local humanoid")
check(#sent == remoteCount, "spectator camera controls do not submit game or purchase actions")

snapshot()
local defaultCatalog = {}
for _, product in ipairs(Config.Commerce.Products) do
	table.insert(defaultCatalog, { Key = product.Key, Kind = "Product", Id = 0, Available = false,
		Name = product.Name, Description = product.Description })
end
local vip = Config.Commerce.VIP
table.insert(defaultCatalog, { Key = vip.Key, Kind = "Pass", Id = 0, Available = false, Name = vip.Name, Description = vip.Description })
snapshot({ Commerce = { Catalog = defaultCatalog } })
buttonWith("ROBUX").Activated:fire()
local disabled = 0
for _, object in ipairs(objects) do
	if not object.destroyed and object.ClassName == "TextButton" and object.Text == "PRÓXIMAMENTE" and not object.Active then disabled += 1 end
end
check(disabled == 4, "the actual default catalog disables all four unset product IDs")
local configured = {}
for index, offer in ipairs(defaultCatalog) do configured[index] = table.clone(offer) end
configured[1].Id, configured[1].Available = 101, true
snapshot({ Commerce = configured })
check(buttonWith("COMPRAR · R$ 7").Active, "configured offers show the native current price")
buttonWith("COMPRAR · R$ 7").Activated:fire()
check(sent[#sent][1] == "Purchase" and sent[#sent][2].Key == "coins100" and sent[#sent][2].Kind == "Product",
	"purchase submits only the catalog kind/key to the authoritative server")
buttonWith("AURAS").Activated:fire()
buttonWith("MENTA · 80 monedas").Activated:fire()
check(sent[#sent][1] == "Palette" and sent[#sent][2] == 2, "a cosmetic selection submits its catalog index")
buttonWith("PRISMA VIP · VER PASE VIP").Activated:fire()
check(buttonWith("COMPRAR · R$ 7") ~= nil, "the VIP aura points to optional offers rather than granting ownership")
buttonWith("AYUDA").Activated:fire()
check(containsText("Puedes jugar desde una sola persona"), "help agrees with the server's single-player minimum")
check(containsText("LAVA Y PLATAFORMAS"), "help describes the lava/elevation mechanic")
check(containsText("VOLVER AL LOBBY"), "help explains how to exit voluntary observation")

-- A compact touch display must move controls out of the bottom thumb areas.
input.TouchEnabled = true
workspace.CurrentCamera.ViewportSize = vector(850, 390)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):fire()
local scales = 0
for _, object in ipairs(objects) do
	if not object.destroyed and object.ClassName == "UIScale" then
		check(type(object.Scale) == "number" and object.Scale > 0 and object.Scale < 1,
			"a short touch display scales HUD and spectator controls down")
		scales += 1
	end
end
check(scales == 3, "all three control groups adapt to the compact touch viewport")
check(spectatorPanel.AnchorPoint.Y == 0 and spectatorPanel.Position.Y.Scale == 0 and spectatorPanel.Position.Y.Offset > 0,
	"touch observation controls anchor above the bottom movement buttons")
input.TouchEnabled = false
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):fire()
check(spectatorPanel.AnchorPoint.Y == 1 and spectatorPanel.Position.Y.Scale == 1,
	"desktop observation controls return to their bottom HUD position")
print("Color Chaos UI smoke checks: " .. checks .. " passed (API mocks; no Roblox engine).")
