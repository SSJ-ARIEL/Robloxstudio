-- The actual client is inserted below. Mocks implement Roblox APIs only;
-- they do not reimplement client behavior or execute the renderer/physics.
local objects, sent, childWaits, mounts, priceCalls = {}, {}, {}, {}, {}
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
	if table.find({ "Activated", "Died", "CharacterAdded", "MouseEnter", "MouseLeave" }, key) then
		local value = signal()
		rawset(self, key, value)
		return value
	end
	local property = rawget(self, key)
	if property ~= nil then return property end
	for _, child in ipairs(rawget(self, "children") or {}) do if child.Name == key then return child end end
	return nil
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
		and table.find({ "Frame", "TextLabel", "TextButton", "ImageLabel", "ImageButton", "ViewportFrame", "ScrollingFrame" }, self.ClassName) ~= nil
end
function Node:GetChildren() return table.clone(self.children) end
function Node:GetDescendants()
	local result = {}
	for _, child in ipairs(self.children) do
		table.insert(result, child)
		for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end
	end
	return result
end
function Node:ClearAllChildren() for _, child in ipairs(self:GetChildren()) do child:Destroy() end end
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
function Node:SetAttribute(name, value)
	self.attributes[name] = value
	if self.propertySignals["Attribute:" .. name] then self.propertySignals["Attribute:" .. name]:fire() end
end
function Node:GetAttributeChangedSignal(name) return self:GetPropertyChangedSignal("Attribute:" .. name) end
local function node(className, name, parent)
	local value = setmetatable({ ClassName = className, Name = name or className, children = {},
		propertySignals = {}, attributes = {}, ZIndex = 1, Visible = true, Active = className == "TextButton",
		AbsoluteSize = { X = 900, Y = 700 } }, Node)
	value.Parent = parent
	table.insert(objects, value)
	return value
end
local Instance = { new = function(className) return node(className) end }
local function vector(x, y) return { X = x, Y = y } end
local Vector2 = { new = vector, zero = vector(0, 0) }
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
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
local ColorSequence = { new = function(...) return { ... } end }
local NumberSequence = { new = function(...) return { ... } end }
local ColorSequenceKeypoint = { new = function(...) return { ... } end }
local NumberSequenceKeypoint = { new = function(...) return { ... } end }
local delayed, scheduled, mockClock = {}, {}, 10
local os = { clock = function() return mockClock end }
local function resumeTask(thread, ...)
	local ok, pause = coroutine.resume(thread, ...)
	assert(ok, pause)
	if coroutine.status(thread) == "suspended" then table.insert(scheduled, { Due = mockClock + (pause or 0), Thread = thread }) end
end
local task = {
	spawn = function(callback, ...) local thread = coroutine.create(callback); resumeTask(thread, ...); return thread end,
	defer = function(callback) table.insert(delayed, { Due = mockClock, Callback = callback }) end,
	delay = function(seconds, callback) table.insert(delayed, { Due = mockClock + seconds, Callback = callback }) end,
	wait = function(seconds) return coroutine.yield(seconds or 0) end,
}
local function advanceTime(seconds)
	mockClock += seconds
	for index = #delayed, 1, -1 do
		if delayed[index].Due <= mockClock then table.remove(delayed, index).Callback() end
	end
	for index = #scheduled, 1, -1 do
		if scheduled[index].Due <= mockClock then resumeTask(table.remove(scheduled, index).Thread) end
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
function players:GetPlayers() local list = {}; for _, member in pairs(roster) do table.insert(list, member) end; return list end
local storage = node("ReplicatedStorage")
local shared = node("Folder", "ColorChaos", storage)
for _, name in ipairs({ "Config", "Catalog", "GameSettings", "Characters", "Portrait", "Progression", "ProfileLedger", "Economy", "GameRules" }) do
	node("ModuleScript", name, shared)
end
local world = node("Folder", "ColorChaosWorld", workspace)
local stages = node("Folder", "Stages", world)
for stageIndex = 1, 8 do
	local stage = node("Model", string.format("Stage%02d", stageIndex), stages)
	local startZ = -40 - (stageIndex - 1) * 112
	local anchor = node("Part", "ReferenceAnchor", stage)
	anchor.Position = Vector3.new(0, 31, startZ - 25)
	local gates = node("Folder", "Gates", stage)
	for index = 1, 5 do
		local gate = node("Model", "Gate" .. index, gates)
		local portrait = node("Part", "PortraitAnchor", gate)
		portrait.Position = Vector3.new(-60 + index * 20, 24, startZ - 48)
	end
end
local remotes = node("Folder", "Remotes", shared)
local state = node("RemoteEvent", "State", remotes)
state.OnClientEvent = signal()
local action = node("RemoteEvent", "Action", remotes)
function action:FireServer(kind, value) table.insert(sent, { kind, value }) end
local input = { TouchEnabled = false, InputBegan = signal() }
local priceFailures = {}
local function getProductInfo(_, id, kind)
	table.insert(priceCalls, { Id = id, Kind = kind })
	if priceFailures[id] then error("Native price unavailable") end
	return { PriceInRobux = 7, IsForSale = true }
end
local services = {
	Players = players, ReplicatedStorage = storage, UserInputService = input,
	MarketplaceService = { GetProductInfoAsync = getProductInfo, GetProductInfo = getProductInfo },
	TweenService = { Create = function(_, target, _, properties)
		return { Play = function() for key, value in pairs(properties) do target[key] = value end end, Cancel = function() end }
	end },
}
local game = { GetService = function(_, name) return assert(services[name], name) end }
-- @CLIENT_MOCKS_END@
-- @CLIENT_MODULES@
local function clientMain()
-- @CLIENT_SOURCE@
end
clientMain()


local checks=0
local function check(ok,message) checks+=1;assert(ok,message) end
local ui=playerGui:FindFirstChild("ColorChaosUI")
local function named(name,parent) return assert((parent or ui):FindFirstChild(name,true),"Missing: "..name) end
local function click(name,parent) named(name,parent).Activated:fire() end
local function contains(text)
 for _,o in ipairs(objects)do if not o.destroyed and type(o.Text)=="string"and string.find(o.Text,text,1,true)then return true end end;return false
end
local function row(title)
 for _,o in ipairs(objects)do if not o.destroyed and o.Name=="Row" and o:FindFirstChild("Title") and o.Title.Text==title then return o end end
 error("Missing row "..title)
end
local function act(title) row(title).Action.Activated:fire() end
local function gift(key)
 for _,o in ipairs(objects)do if not o.destroyed and o:GetAttribute("TimeGiftId")==key then return o end end
 error("Missing gift "..key)
end
local NOW=2000000000
local data=Economy.clean({Coins=500,Gems=75,Wins=2,CurrentStreak=5,BestStreak=7,FreeGifts=1},NOW,Config)
data.Timers.Seconds=120;data.CosmeticsOwned.suit_mint=true
local p=Economy.view(data,NOW);p.VIP=false
local offers={}
for _,v in ipairs(Config.Commerce.Products)do table.insert(offers,{Key=v.Key,Kind="Product",Id=0,Available=false,Name=v.Name,Description=v.Description})end
table.insert(offers,{Key=Config.Commerce.VIP.Key,Kind="Pass",Id=0,Available=false,Name=Config.Commerce.VIP.Name})
local base={Phase="LOBBY",Mode="LOBBY",Stage=0,StageCount=8,Seconds=18,ReadyCount=1,Profile=p,Commerce=offers}
local function snapshot(changes)local value=table.clone(base);for k,v in pairs(changes or{})do value[k]=v end;state.OnClientEvent:fire(value)end
check(ui and not ui:GetAttribute("Ready"),"main remains unready before server state")
check(#sent==1 and sent[1][1]=="Sync","initial sync requested after subscription")
for _,v in ipairs(childWaits)do if v.Name~="PlayerGui"then check(v.Timeout~=nil and v.Timeout<=20,"dependencies have finite waits")end end
state.OnClientEvent:fire("invalid");state.OnClientEvent:fire({Toast="Espera"})
state.OnClientEvent:fire({Phase="READY",Profile={}});state.OnClientEvent:fire({Phase="LOBBY"})
check(not ui:GetAttribute("Ready"),"invalid and toast-only messages cannot dismiss welcome")
advanceTime(2);check(#sent==2 and sent[2][1]=="Sync","late server triggers nonblocking sync retry")
snapshot();check(ui:GetAttribute("Ready") and contains("500 monedas · 75 diamantes"),"valid snapshot presents both balances")
check(not named("SpectatorControls").Visible,"lobby hides match observation")
snapshot({OpenWindow="Shop"});local n=#sent
act("Astronauta Nova");check(sent[#sent][1]=="BuyCosmetic" and sent[#sent][2]=="suit_nova","direct purchase sends only cosmetic ID")
act("Astronauta Nova");act("Explorador Menta")
check(#sent==n+1 and p.Coins==500 and not p.CosmeticsOwned.suit_nova,"double click and owned item cannot mint or spend locally")
click("Robux");n=#sent
for _,v in ipairs(offers)do check(row(v.Name).Action.Text=="No disponible","zero ID offer unavailable");act(v.Name)end
check(#sent==n and #priceCalls==0,"unconfigured products never prompt or fetch prices")
local configured={};for i,v in ipairs(offers)do configured[i]=table.clone(v)end
configured[1].Id,configured[1].Available=101,true
snapshot({Commerce=configured})
check(row(configured[1].Name).Action.Text=="R$ 7" and #priceCalls==1,"shop uses native price quote")
act(configured[1].Name);n=#sent;act(configured[1].Name)
check(#sent==n and sent[n][1]=="Purchase" and sent[n][2].Key=="coins100" and sent[n][2].Kind=="Product" and sent[n][2].Amount==nil,"purchase uses kind/key with click rate limit and no award")
snapshot({Commerce=configured,Seconds=17});check(#priceCalls==1,"clock snapshots reuse price quotes")
configured[2].Id,configured[2].Available=102,true;priceFailures[102]=true
snapshot({Commerce=configured,OpenWindow="Shop"});click("Robux")
check(row(configured[2].Name).Action.Text=="Ver precio","native pricing failure never invents a Robux price")
snapshot({OpenWindow="Wardrobe"});act("Explorador Menta")
check(sent[#sent][1]=="EquipCosmetic" and sent[#sent][2].Id=="suit_mint","owned suit requests server equip")
n=#sent;act("Caballero Meteoro");act("Centinela Prisma VIP")
check(#sent==n,"unowned and unverified VIP equipment cannot submit")
click("Emote");act("Saludo · puesto");check(sent[#sent][1]=="Emote"and sent[#sent][2]=="emote_wave","free emote submits actual owned ID")
click("Reaction");act("Estrella · puesto");check(sent[#sent][1]=="Reaction"and sent[#sent][2]=="reaction_star","free reaction submits actual owned ID")
click("Aura");act("MENTA");check(sent[#sent][1]=="Palette"and sent[#sent][2]==2,"legacy aura uses original numeric index")
snapshot({OpenWindow="Gifts"})
check(gift("time2").Text=="Reclamar" and gift("time5").Text=="3:00","gift eligibility and countdown follow server time")
n=#sent;gift("time5").Activated:fire();check(#sent==n,"locked time gift cannot claim")
gift("time2").Activated:fire();n=#sent;gift("time2").Activated:fire()
check(#sent==n and sent[n][1]=="ClaimTimeGift" and sent[n][2]=="time2" and p.Gems==75,"time claim sends milestone once without local diamonds")
data.Timers.Claimed.time2=true
snapshot({Profile=Economy.view(data,NOW)});gift("time2").Activated:fire()
check(gift("time2").Text=="Reclamado" and #sent==n,"confirmed time reward becomes inert")
click("Racha");act("Racha actual: 5")
check(sent[#sent][1]=="OpenGift"and sent[#sent][2]==nil,"earned gift sends no outcome or price")
data.FreeGifts=0;snapshot({Profile=Economy.view(data,NOW)});n=#sent;act("Racha actual: 5")
check(#sent==n and contains("Sin regalos"),"no gift balance cannot open a reward")
click("Premios")
check(contains("45%")and contains("30%")and contains("15%")and contains("6%")and contains("4%"),"all reward category probabilities visible")
check(contains("6 opciones · 2.50% cada una")and contains("15 diamantes"),"item-level odds and duplicate compensation disclosed")
snapshot({GiftResult={Kind="Gems",Amount=15}})
check(named("GiftReveal").Visible and named("Name",named("GiftReveal")).Text=="15 diamantes","server reward opens the actual reveal panel")
snapshot({GiftResult={Kind="Suit",Name="Explorador Menta"}})
check(named("Name",named("GiftReveal")).Text=="Explorador Menta","new confirmed gift replaces earlier reveal safely")
click("CloseGift");check(not named("GiftReveal").Visible,"gift panel closes without submitting a purchase")
click("Close")
local ch=Characters.get(1)
local colors={{255,60,100},{80,180,255},ch.TargetRGB,{255,210,70},{90,225,130}}
local function challenge(changes)
 local value={Phase="CHOOSE",Mode="ALIVE",Stage=1,CharacterId=1,ReferenceRGB=colors[1],Choices=colors,AliveCount=3,Seconds=12}
 for k,v in pairs(changes or{})do value[k]=v end;snapshot(value)
end
challenge({Phase="PREVIEW",ReferenceRGB=ch.TargetRGB,Choices={},Seconds=2})
check(named("ReferenceCard").Visible and named("ReferenceCard").AnchorPoint.X==0.5,"original reference is central during two-second preview")
check(ui:FindFirstChild("WorldReference")and not ui:FindFirstChild("WorldChoice1"),"preview reveals no alternatives")
check(table.concat(mounts[#mounts].RGB,",")==table.concat(ch.TargetRGB,","),"preview uses original catalog color")
challenge()
check(ui:FindFirstChild("WorldChoice1")and ui:FindFirstChild("WorldChoice5"),"choosing mounts all five gate portraits")
check(ui.WorldChoice5.Size.X.Scale==14 and ui.WorldChoice5.Size.X.Offset==0,"portraits use world-size bounds fitting lane spacing")
local ref
for _,m in ipairs(mounts)do if m.Viewport.Parent and m.Viewport.Parent.Parent and m.Viewport.Parent.Parent.Name=="WorldReference"then ref=m end end
check(ref and table.concat(ref.RGB,",")==table.concat(colors[1],","),"central choosing portrait has server-altered color")
local before=#mounts;n=#sent;challenge({Seconds=11})
check(#mounts==before and #sent==n,"timer ticks rebuild no portraits and request no answer")
challenge({MyChoice=3});check(contains("Elegiste el camino 3"),"physical choice confirmation uses server state")
challenge({Phase="REVEAL",CorrectLane=3,ReferenceRGB=ch.TargetRGB})
check(ui.WorldChoice3.Card.BackgroundColor3.G>ui.WorldChoice3.Card.BackgroundColor3.R,"resolved correct gate is highlighted")
challenge({Phase="PREVIEW",Stage=2,CharacterId=2,ReferenceRGB=Characters.get(2).TargetRGB,Choices={}})
check(not ui:FindFirstChild("WorldChoice3"),"next stage clears prior revealed answer")
local lateStage=stages:FindFirstChild("Stage08");lateStage.Parent=nil
challenge({Phase="PREVIEW",Stage=8,ReferenceRGB=ch.TargetRGB,Choices={}})
check(not ui:FindFirstChild("WorldReference"),"missing streamed stage defers its world portrait safely")
lateStage.Parent=stages;advanceTime(2)
check(ui:FindFirstChild("WorldReference")~=nil,"background retry draws sector after its geometry arrives")
snapshot({OpenWindow="Album"});check(named("Character1")and named("Character10"),"gallery loads ten actual originals")
click("Next");check(named("Character11")and mounts[#mounts].Id==20,"album pagination reaches next characters")
for _=1,23 do click("Next")end
check(named("Character250")and mounts[#mounts].Id==250,"all 250 original citizens reachable")
before=#mounts;snapshot({Seconds=17});check(#mounts==before,"timer updates do not reconstruct album")
challenge({Phase="PREVIEW",ReferenceRGB=ch.TargetRGB,Choices={}})
check(not named("Overlay").Visible and not ui:FindFirstChild("Character250",true),"live preview closes answer gallery")
challenge({OpenWindow="Album"});check(not named("Overlay").Visible and contains("álbum vuelve"),"competitor cannot reopen catalog during choice")
local function rival(id,name)local r=node("Player",name);r.UserId,r.DisplayName=id,name;roster[id]=r;return r,makeCharacter(r)end
local blue,blueH=rival(20,"Azul");local green,greenH=rival(30,"Verde")
challenge({Mode="LOBBY",SpectatorIds={20,30}})
check(named("SpectatorControls").Visible and workspace.CurrentCamera.CameraSubject==ownHumanoid,"late arrival gets voluntary observation")
n=#sent;click("Observe");check(workspace.CurrentCamera.CameraSubject==blueH,"observe follows competitor")
click("NextObserved");check(workspace.CurrentCamera.CameraSubject==greenH,"next cycles camera")
click("Observe");check(workspace.CurrentCamera.CameraSubject==ownHumanoid and #sent==n,"observation submits no game or purchase action")
click("Observe");snapshot({Phase="RESULTS",Mode="LOBBY",SpectatorIds={30}})
check(workspace.CurrentCamera.CameraSubject==ownHumanoid and not named("SpectatorControls").Visible,"results restore lobby camera")
challenge({Mode="LOBBY",SpectatorIds={20,30}});click("Ghost")
check(sent[#sent][1]=="EnterGhost"and sent[#sent][2]==nil,"ghost entry asks authoritative server")
challenge({Mode="GHOST",SpectatorIds={20,30}})
check(contains("FANTASMA · sin premios")and not named("Observe").Visible and workspace.CurrentCamera.CameraSubject==ownHumanoid,"ghost role discloses no round rewards and keeps own camera")
click("Ghost");check(sent[#sent][1]=="LeaveGhost","ghost can explicitly leave")
challenge({Mode="ALIVE",SpectatorIds={20,30}});check(not named("SpectatorControls").Visible,"competitor cannot spectate")
snapshot();local previous=ownHumanoid;ownHumanoid=makeCharacter(player);player.CharacterAdded:fire(player.Character);advanceTime(0)
check(workspace.CurrentCamera.CameraSubject==ownHumanoid and previous~=ownHumanoid,"respawn restores camera to replacement avatar")
snapshot({OpenWindow="Leaderboards",RoomBoard={{Place=1,UserId=10,DisplayName="Ariel",CorrectThisMatch=4,Alive=true}},
 GlobalBoards={Wins={{Rank=1,UserId=20,Name="Azul",Value=75}},Streak={{Rank=1,UserId=30,Name="Verde",Value=25}},Level={{Rank=1,UserId=20,Name="Azul",Value=12}}}})
check(contains("4 aciertos")and contains("Esta partida"),"room board represents this match")
click("Wins");check(named("Rank1").Score.Text=="75","global wins display authoritative score")
click("Streak");check(named("Rank1").Score.Text=="25","global streak displays authoritative score")
click("Level",named("Tabs"));check(named("Rank1").Score.Text=="12","global level displays authoritative score")
input.TouchEnabled=true;workspace.CurrentCamera.ViewportSize=vector(850,390);workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):fire()
check(not named("Wallet").Visible and named("Menu").Position.X.Scale==0.5,"compact touch layout protects thumb corners")
input.TouchEnabled=false;workspace.CurrentCamera.ViewportSize=vector(1200,700);workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):fire()
check(named("Wallet").Visible,"desktop restores wallet")
workspace:SetAttribute("ColorChaosBootStatus","ERROR")
check(contains("servidor"),"server startup failure shows client status")
ui:Destroy();advanceTime(2);check(#scheduled==0,"background sync polling stops after GUI removal")
print("Color Chaos UI smoke checks: "..checks.." passed (API mocks; no Roblox engine).")
