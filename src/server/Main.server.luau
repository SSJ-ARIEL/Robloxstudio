-- Color Chaos: all objectives, purchases and rewards are server-authoritative.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(ReplicatedStorage.ColorChaos.Config)
local Rules = require(ReplicatedStorage.ColorChaos.Rules)
local Progression = require(ReplicatedStorage.ColorChaos.Progression)
local Ledger = require(ReplicatedStorage.ColorChaos.ProfileLedger)
local Commerce = require(script.Parent.Commerce)

local events = Instance.new("Folder")
events.Name = "Remotes"
events.Parent = ReplicatedStorage.ColorChaos
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = events
local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = events

local profiles = {}
local participants = {}
local lastActions = {}
local initializing = {}
local currentRound = nil
local state = { Phase = "LOBBY", Message = "Preparando el reactor...", Seconds = 0, Progress = 0, Total = 0 }
-- A storage outage must never prevent the lobby or rounds from starting.
local store
local storageOK, storageResult = pcall(function() return DataStoreService:GetDataStore(Config.DataStoreName) end)
if storageOK then store = storageResult else warn("Color Chaos: guardado no disponible; la partida continuará sin ventas de monedas.") end
local sessionId = game.JobId .. HttpService:GenerateGUID(false)
local closing = false
local savingEnabled = store ~= nil and not RunService:IsStudio()
local random = Random.new()
local commerce
-- Defaults also support updating an installed game while retaining its entire Config.
local lavaSettings = Config.Lava or { StartHeight = 10, EndHeight = 31, MaxLift = 12, HalfWidth = 80, MinZ = -110, MaxZ = 66 }

local function cleanProfile(raw)
	local data = Rules.cleanProfile(raw, #Config.Palettes)
	data.Receipts = Ledger.cleanReceipts(type(raw) == "table" and raw.Receipts or nil)
	data.Progress = Progression.clean(type(raw) == "table" and raw.Progress or nil, os.time(), Config)
	return data
end

local function personal(player, extra)
	local record = profiles[player]
	local payload = table.clone(state)
	payload.Participating = participants[player] ~= nil
	payload.Alive = participants[player] ~= nil and participants[player].Alive
	payload.ReadyPlayers, payload.AlivePlayers, payload.ParticipantCount = 0, 0, 0
	payload.MinimumPlayers = Config.MinimumPlayers
	payload.SpectatorIds = {}
	for _, online in ipairs(Players:GetPlayers()) do
		local humanoid = online.Character and online.Character:FindFirstChildOfClass("Humanoid")
		if profiles[online] and humanoid and humanoid.Health > 0 and online.Character:FindFirstChild("HumanoidRootPart") then
			payload.ReadyPlayers += 1
		end
		local entry = participants[online]
		if entry then
			payload.ParticipantCount += 1
			if entry.Alive then
				payload.AlivePlayers += 1
				table.insert(payload.SpectatorIds, online.UserId)
			end
		end
	end
	table.sort(payload.SpectatorIds)
	payload.PlatformLift = currentRound and currentRound.Elevation or 0
	if record then
		payload.Profile = { Coins = record.Data.Coins, Wins = record.Data.Wins,
			Selected = record.Data.Selected, Owned = record.Data.Owned, VIP = record.VIP == true }
		payload.Progression = Progression.view(record.Data.Progress, os.time(), Config)
		payload.Persistence = record.Writable and (record.LastSaveFailed and "ERROR DE GUARDADO: REINTENTANDO" or "GUARDADO ACTIVO") or "PROGRESO DE ESTA SESIÓN"
	else
		payload.Persistence = "CARGANDO PROGRESO"
	end
	payload.Commerce = commerce and commerce.getCatalog(player) or {}
	if extra then
		for key, value in pairs(extra) do payload[key] = value end
	end
	stateEvent:FireClient(player, payload)
end

local function broadcast()
	for _, player in ipairs(Players:GetPlayers()) do personal(player) end
end

local function snapshot(data)
	return { Coins = data.Coins, Wins = data.Wins, Selected = data.Selected, Owned = table.clone(data.Owned),
		Receipts = table.clone(data.Receipts), Progress = Progression.clean(data.Progress, os.time(), Config) }
end

local function save(player, release)
	local record = profiles[player]
	if not record or not record.Writable then return end
	-- Serialize saves, including departure saves, to preserve the most recent state.
	while record.Saving do task.wait(0.1) end
	if not record.Writable then return end
	record.Saving = true
	local data = snapshot(record.Data)
	local updatedRevision = record.Revision
	local ownsLock, committed = false, nil
	local ok = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function(old)
			ownsLock, committed = false, nil
			if type(old) ~= "table" or old.Session ~= sessionId then return nil end
			local merged = Ledger.merge(data, old.Data, Config.MaxCoins)
			if not merged then return nil end
			ownsLock = true
			committed = merged
			local envelope = { Data = merged, Session = sessionId, LeaseUntil = os.time() + 240 }
			if release then envelope.Session = nil; envelope.LeaseUntil = nil end
			return envelope
		end)
	end)
	if ok and ownsLock then
		local recovered = Ledger.reconcile(record.Data, committed, Config.MaxCoins)
		if recovered == nil then
			record.LastSaveFailed = true
			record.Saving = false
			return
		end
		if recovered and recovered > 0 then record.Revision += 1 end
		record.PendingPaid = nil
		record.UncertainReceipt = nil
		record.SavedRevision = updatedRevision
		record.LastSaveFailed = false
	else
		record.LastSaveFailed = true
		if ok then record.Writable = false end
		warn("Color Chaos: no se pudo guardar el progreso de " .. player.UserId)
		if player.Parent then personal(player, { Toast = "No se pudo confirmar el guardado. Conserva esta sesión abierta." }) end
	end
	record.Saving = false
end

local function stats(player)
	local record = profiles[player]
	local folder = player:FindFirstChild("leaderstats")
	if folder and record then
		folder.Monedas.Value = record.Data.Coins
		folder.Victorias.Value = record.Data.Wins
	end
end

local function cosmetic(player)
	local record, character = profiles[player], player.Character
	if not record or not character then return end
	local old = character:FindFirstChild("ChromaticAura")
	if old then old:Destroy() end
	local effect = Instance.new("Highlight")
	effect.Name = "ChromaticAura"
	effect.FillTransparency = 1
	local palette = Config.Palettes[record.Data.Selected]
	if palette.Access == "VIP" and record.VIP ~= true then palette = Config.Palettes[1] end
	effect.OutlineColor = palette.Color
	effect.OutlineTransparency = 0.2
	effect.DepthMode = Enum.HighlightDepthMode.Occluded
	effect.Parent = character
	local r = character:FindFirstChild("HumanoidRootPart")
	if r then
		for _, name in ipairs({ "ChromaticTrail", "TrailStart", "TrailEnd" }) do
			local oldTrail = r:FindFirstChild(name)
			if oldTrail then oldTrail:Destroy() end
		end
		if palette.Trail then
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			a.Name, a.Position, a.Parent = "TrailStart", Vector3.new(-0.9, -0.8, 0), r
			b.Name, b.Position, b.Parent = "TrailEnd", Vector3.new(0.9, -0.8, 0), r
			local trail = Instance.new("Trail")
			trail.Name, trail.Attachment0, trail.Attachment1 = "ChromaticTrail", a, b
			trail.Color, trail.Lifetime = ColorSequence.new(palette.Color), 0.45
			trail.FaceCamera, trail.LightEmission, trail.MinLength = true, 0.8, 0.1
			trail.Parent = r
		end
	end
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if head then
		local oldTitle = head:FindFirstChild("VIPTitle")
		if oldTitle then oldTitle:Destroy() end
		if record.VIP == true then
			local tag = Instance.new("BillboardGui")
			tag.Name, tag.Size = "VIPTitle", UDim2.fromOffset(130, 32)
			tag.StudsOffset, tag.MaxDistance = Vector3.new(0, 3.5, 0), 80
			tag.Parent = head
			local t = Instance.new("TextLabel")
			t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
			t.Text, t.TextColor3, t.TextScaled = "VIP PRISMA", Config.Palettes[5].Color, true
			t.Font, t.Parent = Enum.Font.GothamBold, tag
		end
	end
	if palette.Access == "VIP" and record.VIP == true then
		task.spawn(function()
			local index = 1
			while effect.Parent and character.Parent do
				effect.OutlineColor = Config.Colors[index].Color
				index = index % #Config.Colors + 1
				task.wait(1.5)
			end
		end)
	end
end

local function persistentGrant(player, receipt, product)
	local record = profiles[player]
	if not record or not record.Writable or record.Leaving then return false end
	while record.Saving do task.wait(0.1) end
	if profiles[player] ~= record or not record.Writable or record.Leaving then return false end
	if record.UncertainReceipt and record.UncertainReceipt ~= receipt.PurchaseId then return false end
	record.Saving = true
	record.PendingPaid = product.Coins
	local base = snapshot(record.Data)
	local committed, newlyGranted, lockLost = nil, false, false
	local ok = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function(old)
			committed, newlyGranted, lockLost = nil, false, false
			if type(old) ~= "table" or old.Session ~= sessionId then lockLost = true; return nil end
			local receipts = Ledger.cleanReceipts(type(old.Data) == "table" and old.Data.Receipts or nil)
			if not receipts[receipt.PurchaseId] then
				local count = 0
				for _ in pairs(receipts) do count += 1 end
				if count >= Config.MaxReceipts then return nil end
			end
			local updated, isNew = Ledger.grant(base, old.Data, receipt.PurchaseId, product.Coins, Config.MaxCoins)
			if not updated then return nil end
			committed, newlyGranted = updated, isNew
			return { Data = updated, Session = sessionId, LeaseUntil = os.time() + 240 }
		end)
	end)
	local acknowledged = false
	if ok and committed then
		local recovered = Ledger.reconcile(record.Data, committed, Config.MaxCoins)
		if recovered ~= nil then
			record.Revision += 1
			record.LastSaveFailed = false
			record.UncertainReceipt, record.PendingPaid = nil, nil
			acknowledged = true
		end
	else
		record.LastSaveFailed = true
		record.UncertainReceipt = receipt.PurchaseId
		if lockLost then record.Writable = false end
	end
	record.Saving = false
	if not acknowledged then
		record.LastSaveFailed = true
		record.UncertainReceipt = receipt.PurchaseId
		task.delay(2, function()
			if profiles[player] == record and record.Writable and not record.Leaving then
				save(player, false)
				stats(player)
				if player.Parent then personal(player) end
			end
		end)
		return false
	end
	return true, newlyGranted and ("Compra entregada: +" .. product.Coins .. " monedas.") or ""
end

commerce = Commerce.new({
	Config = Config, Players = Players, MarketplaceService = MarketplaceService,
	PersistentGrant = persistentGrant, GetProfile = function(player) return profiles[player] end,
	Notify = function(player, message) if player.Parent then personal(player, { Toast = message }) end end,
	Refresh = function(player) stats(player); cosmetic(player); if player.Parent then personal(player) end end,
})
commerce.start()

-- The release already contains this world, its floor and its neutral spawn.
-- Fallbacks keep source-only installs playable as well.
local world = workspace:FindFirstChild("ColorChaosWorld")
if not world then
	world = Instance.new("Folder")
	world.Name, world.Parent = "ColorChaosWorld", workspace
end
local function part(parent, name, size, position, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color or Color3.fromRGB(35, 42, 67)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(parent, text, offset, compact)
	local old = parent:FindFirstChild("Caption")
	if old then old:Destroy() end
	local static = parent:FindFirstChild("StaticSign")
	local panel = static and static:FindFirstChild("Panel")
	local heading = panel and panel:FindFirstChild("Heading")
	if heading then return heading end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Caption"
	gui.Size = compact and UDim2.fromOffset(110, 36) or UDim2.fromOffset(270, 75)
	gui.StudsOffset = offset or Vector3.new(0, 4, 0)
	gui.MaxDistance = 170
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.fromRGB(16, 22, 39)
	t.BackgroundTransparency = 0.15
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled, t.TextWrapped = true, true
	t.Text = text
	t.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = t
	return t
end

local lobby = world:FindFirstChild("Plaza del reactor") or part(world, "Plaza del reactor", Vector3.new(110, 3, 80), Vector3.new(0, 5, 145))
lobby.Anchored, lobby.CanCollide = true, true
local spawn = world:FindFirstChild("LobbySpawn")
if not spawn then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size, spawn.Position = Vector3.new(10, 1, 10), Vector3.new(0, 7, 153)
	spawn.Parent = world
end
spawn.Anchored, spawn.Neutral, spawn.CanCollide = true, true, true
spawn.Color, spawn.Duration = Config.Colors[1].Color, 0
label(world:FindFirstChild("Título") or part(world, "Título", Vector3.new(1, 1, 1), Vector3.new(0, 17, 168)), "COLOR CHAOS\nRepara el reactor antes de que suba la lava")
local instructions = world:FindFirstChild("Instrucciones") or part(world, "Instrucciones", Vector3.new(1, 1, 1), Vector3.new(-27, 9, 144))
label(instructions, "1. Espera aquí, estás a salvo\n2. Repara para elevar al equipo\n3. Evita la lava y gana monedas")
local shop = world:FindFirstChild("Tienda de auras") or part(world, "Tienda de auras", Vector3.new(8, 4, 8), Vector3.new(27, 8, 144), Config.Palettes[4].Color)
label(shop, "TIENDA\nAuras, monedas y VIP")
local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.ActionText, shopPrompt.ObjectText = "Abrir", "Auras"
shopPrompt.RequiresLineOfSight = false
shopPrompt.MaxActivationDistance = Config.InteractionDistance
shopPrompt.Parent = shop
shopPrompt.Triggered:Connect(function(player) personal(player, { OpenShop = true }) end)
local lava = world:FindFirstChild("LavaSurface") or part(world, "LavaSurface", Vector3.new(160, 0.8, 176), Vector3.new(0, 9.6, -22), Color3.fromRGB(255, 91, 30))
lava.Anchored, lava.CanCollide, lava.Material = true, false, Enum.Material.Neon
lava.Size = Vector3.new(lavaSettings.HalfWidth * 2, lava.Size.Y, lavaSettings.MaxZ - lavaSettings.MinZ)
local function setLava(height)
	lava.Position = Vector3.new(0, height - lava.Size.Y / 2, (lavaSettings.MinZ + lavaSettings.MaxZ) / 2)
	state.LavaHeight = height
end
setLava(lavaSettings.StartHeight)
local previewParts = {}
local previewLabels = {}
local preview = world:FindFirstChild("ArenaPreview")
if preview then
	for _, object in ipairs(preview:GetDescendants()) do
		if object:IsA("BasePart") then table.insert(previewParts, { Part = object, Transparency = object.Transparency }) end
		if object:IsA("BillboardGui") then table.insert(previewLabels, object) end
	end
end
local function showPreview(visible)
	for _, item in ipairs(previewParts) do item.Part.Transparency = visible and item.Transparency or 1 end
	for _, gui in ipairs(previewLabels) do gui.Enabled = visible end
end
workspace.FallenPartsDestroyHeight = -60

local function root(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function teleport(player, position)
	local r = root(player)
	if r then
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		player.Character:PivotTo(CFrame.new(position))
	end
end

local function arenaPosition(round, position)
	return Vector3.new(position.X, position.Y + round.Elevation, position.Z)
end

local function liftArena(round)
	-- Only new high-water progress raises the arena. Replaying an already solved
	-- memory prefix cannot farm extra height, and a mistake cannot drop teammates.
	round.HighestProgress = math.max(round.HighestProgress, round.Progress)
	local elevation = lavaSettings.MaxLift * math.min(1, round.HighestProgress / round.Total)
	local delta = elevation - round.Elevation
	if delta <= 0 then return end
	round.Elevation = elevation
	for _, object in ipairs(round.Model:GetDescendants()) do
		if object:IsA("BasePart") then
			local p = object.Position
			object.Position = Vector3.new(p.X, p.Y + delta, p.Z)
		end
	end
	for player, entry in pairs(participants) do
		local r = root(player)
		if entry.Alive and r then
			local p = r.Position
			teleport(player, Vector3.new(p.X, p.Y + delta, p.Z))
		end
	end
	state.PlatformLift = elevation
end

local function valid(player, target, round)
	local entry, r = participants[player], root(player)
	if currentRound ~= round or round.Success or state.Phase ~= "JUEGO" or not entry or not entry.Alive or not r then return false end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or (r.Position - target.Position).Magnitude > Config.InteractionDistance + 2 then return false end
	local now = os.clock()
	if now - entry.LastInteraction < 0.25 then return false end
	entry.LastInteraction = now
	return true
end

local function prompt(target, text, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText = text, target.Name
	p.HoldDuration = 0.25
	p.MaxActivationDistance = Config.InteractionDistance
	p.RequiresLineOfSight = false
	p.Parent = target
	p.Triggered:Connect(callback)
	return p
end

local function progress(round, amount)
	round.Progress += amount
	liftArena(round)
	state.Progress = round.Progress
	if round.Progress >= round.Total then round.Success = true end
	broadcast()
end

local function contribute(player)
	local entry = participants[player]
	entry.Contributed = true
	entry.Actions = (entry.Actions or 0) + 1
end

local function freeCoins(record, amount)
	-- A pending paid grant reserves capacity; never reduce an existing balance.
	local room = math.max(0, Config.MaxCoins - (record.PendingPaid or 0) - record.Data.Coins)
	local granted = math.min(amount, room)
	record.Data.Coins += granted
	return granted
end

local function newArena(mode)
	local model = Instance.new("Model")
	model.Name = "Ronda"
	model.Parent = world
	local round = { Model = model, Mode = mode.Id, Progress = 0, Total = 6, Success = false, Elevation = 0, HighestProgress = 0 }
	currentRound = round
	if mode.Id == "memory" then
		part(model, "Inicio", Vector3.new(38, 3, 26), Vector3.new(0, 20, 37))
	else
		part(model, "Arena", Vector3.new(92, 3, 92), Vector3.new(0, 20, 0))
		for _, pos in ipairs({ Vector3.new(0, 23, 46), Vector3.new(0, 23, -46) }) do
			part(model, "Baranda", Vector3.new(94, 3, 1), pos)
		end
		for _, pos in ipairs({ Vector3.new(46, 23, 0), Vector3.new(-46, 23, 0) }) do
			part(model, "Baranda", Vector3.new(1, 3, 92), pos)
		end
	end
	return round
end

local function outlinePlatform(parent, platform, color)
	-- Mark the actual walkable edges above the lava; all trim rises with the arena.
	local p, s = platform.Position, platform.Size
	for i, edge in ipairs({
		{ Size = Vector3.new(s.X, 0.16, 0.2), Position = Vector3.new(p.X, p.Y + s.Y / 2 + 0.1, p.Z - s.Z / 2 + 0.15) },
		{ Size = Vector3.new(s.X, 0.16, 0.2), Position = Vector3.new(p.X, p.Y + s.Y / 2 + 0.1, p.Z + s.Z / 2 - 0.15) },
		{ Size = Vector3.new(0.2, 0.16, s.Z), Position = Vector3.new(p.X - s.X / 2 + 0.15, p.Y + s.Y / 2 + 0.1, p.Z) },
		{ Size = Vector3.new(0.2, 0.16, s.Z), Position = Vector3.new(p.X + s.X / 2 - 0.15, p.Y + s.Y / 2 + 0.1, p.Z) },
	}) do
		local trim = part(parent, platform.Name .. " · borde " .. i, edge.Size, edge.Position, color)
		trim.Material, trim.CanCollide, trim.CanTouch, trim.CanQuery = Enum.Material.Neon, false, false, false
	end
end

local function memory(round)
	round.Total = 5
	round.Sequence, round.Bridges = {}, {}
	for i = 1, round.Total do round.Sequence[i] = random:NextInteger(1, 4) end
	local goal = part(round.Model, "Reactor de llegada", Vector3.new(28, 3, 16), Vector3.new(0, 20, -47), Config.Colors[3].Color)
	outlinePlatform(round.Model, round.Model:FindFirstChild("Inicio"), Config.Colors[1].Color)
	outlinePlatform(round.Model, goal, Config.Colors[3].Color)
	label(goal, "ACTIVA LOS PUENTES\nLuego llega aquí")
	local goalPrompt = prompt(goal, "Reparar reactor", function(player)
		if not valid(player, goal, round) then return end
		if round.Step == #round.Sequence then
			contribute(player)
			progress(round, 1)
		end
	end)
	goalPrompt.Enabled = false
	round.Step = 0
	for i, color in ipairs(Config.Colors) do
		local button = part(round.Model, color.Name, Vector3.new(5, 2, 5), Vector3.new(-13.5 + (i - 1) * 9, 23, 41), color.Color)
		label(button, color.Symbol .. " · " .. color.Name, Vector3.new(0, 3, 0), true)
		prompt(button, "Activar", function(player)
			if not valid(player, button, round) or round.Replaying or round.Step >= #round.Sequence then return end
			if round.Sequence[round.Step + 1] ~= i then
				round.Replaying = true
				state.Message = "Secuencia incorrecta. ¡Vuelve a observar!"
				for _, bridge in ipairs(round.Bridges) do bridge:Destroy() end
				round.Bridges = {}
				round.Step, round.Progress, state.Progress = 0, 0, 0
				goalPrompt.Enabled = false
				for teammate, entry in pairs(participants) do
					if entry.Alive then teleport(teammate, arenaPosition(round, Vector3.new(random:NextInteger(-10, 10), 25, 34))) end
				end
				task.spawn(function()
					for step, code in ipairs(round.Sequence) do
						if currentRound ~= round or state.Phase ~= "JUEGO" then return end
						state.DemoCode, state.DemoStep = code, step; broadcast(); task.wait(1)
						if currentRound ~= round or state.Phase ~= "JUEGO" then return end
						state.DemoCode = nil; broadcast(); task.wait(0.2)
					end
					if currentRound ~= round or state.Phase ~= "JUEGO" then return end
					state.DemoCode = nil
					state.DemoStep = nil
					state.Message = "Activa la secuencia en orden. Después cruza al reactor."
					round.Replaying = false; broadcast()
				end)
			else
				contribute(player)
				round.Step += 1
				local bridge = part(round.Model, "Puente " .. round.Step, Vector3.new(18, 2, 12), arenaPosition(round, Vector3.new(0, 20.5, 23 - (round.Step - 1) * 13)), color.Color)
				-- Keep trim under the bridge so replay destroys both together.
				outlinePlatform(bridge, bridge, Color3.fromRGB(235, 246, 255))
				table.insert(round.Bridges, bridge)
				progress(round, 1)
				goalPrompt.Enabled = round.Step == #round.Sequence
			end
		end)
	end
	-- Five bridges plus activating the reactor completes this objective.
	round.Total += 1
end

local function relay(round)
	round.Total = 8
	round.Target = random:NextInteger(1, 4)
	state.Target = round.Target
	outlinePlatform(round.Model, round.Model:FindFirstChild("Arena"), Config.Colors[1].Color)
	local positions = { Vector3.new(-30, 24, -28), Vector3.new(30, 24, -28), Vector3.new(-30, 24, 24), Vector3.new(30, 24, 24) }
	local core = part(round.Model, "Reactor", Vector3.new(8, 10, 8), Vector3.new(0, 27, 0), Config.Colors[1].Color)
	core.Material = Enum.Material.Neon
	label(core, "REPARACIÓN COOPERATIVA\nActiva la estación indicada")
	for i, color in ipairs(Config.Colors) do
		local node = part(round.Model, color.Name, Vector3.new(8, 5, 8), positions[i], color.Color)
		label(node, color.Symbol .. " · " .. color.Name, Vector3.new(0, 5, 0), true)
		prompt(node, "Reparar", function(player)
			if not valid(player, node, round) or round.Cooldown then return end
			if i ~= round.Target then
				personal(player, { Toast = "Busca la letra indicada en la parte superior." })
				return
			end
			round.Cooldown = true
			contribute(player)
			core.Color = color.Color
			progress(round, 1)
			local nextTarget = random:NextInteger(1, 3)
			if nextTarget >= round.Target then nextTarget += 1 end
			round.Target, state.Target = nextTarget, nextTarget
			broadcast()
			task.delay(1.2, function() if currentRound == round then round.Cooldown = false end end)
		end)
	end
end

local function rescue(round)
	round.Total = 4
	round.Target = random:NextInteger(1, 4)
	round.Carrier, round.Active = nil, false
	state.Target = round.Target
	outlinePlatform(round.Model, round.Model:FindFirstChild("Arena"), Config.Colors[3].Color)
	-- The central floor stops at z=-46. Islands sit across the gap.
	local core = part(round.Model, "Reactor receptor", Vector3.new(9, 5, 9), Vector3.new(0, 24, 12), Color3.fromRGB(230, 235, 255))
	label(core, "ENTREGA LA CHISPA AQUÍ")
	local islands = {}
	for i, color in ipairs(Config.Colors) do
		local x = -33 + (i - 1) * 22
		local island = part(round.Model, "Isla " .. color.Name, Vector3.new(16, 3, 16), Vector3.new(x, 20, -75), color.Color)
		outlinePlatform(round.Model, island, color.Color)
		label(island, color.Symbol .. " · " .. color.Name, Vector3.new(0, 4, 0), true)
		local spark = part(round.Model, "Chispa " .. color.Name, Vector3.new(3, 3, 3), Vector3.new(x, 25, -75), color.Color)
		spark.Shape, spark.Material = Enum.PartType.Ball, Enum.Material.Neon
		spark.CanCollide = false
		islands[i] = { Spark = spark }
		prompt(spark, "Recoger chispa", function(player)
			if not valid(player, spark, round) or not round.Active or round.Target ~= i or round.Carrier then return end
			round.Carrier = player
			contribute(player)
			spark.Transparency = 1
			local indicator = Instance.new("BillboardGui")
			indicator.Name, indicator.Size = "CarriedSpark", UDim2.fromOffset(120, 40)
			indicator.StudsOffset = Vector3.new(0, 5, 0)
			indicator.AlwaysOnTop = true
			indicator.Parent = root(player)
			local text = Instance.new("TextLabel")
			text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
			text.Text, text.TextColor3 = "✦ CHISPA", color.Color
			text.TextScaled, text.Font = true, Enum.Font.GothamBold
			text.Parent = indicator
			state.Message = player.DisplayName .. " lleva la chispa. ¡Debe volver al reactor!"
			broadcast()
		end)
		local node = part(round.Model, "Panel " .. color.Name, Vector3.new(5, 3, 5), Vector3.new(x, 23, -32), color.Color)
		label(node, color.Symbol .. " · " .. color.Name, Vector3.new(0, 3, 0), true)
		prompt(node, "Crear puente", function(player)
			if not valid(player, node, round) or round.Active or round.Target ~= i then return end
			contribute(player)
			round.Active = true
			round.Bridge = part(round.Model, "Puente de rescate", Vector3.new(12, 2, 31), arenaPosition(round, Vector3.new(x, 20.5, -55)), color.Color)
			outlinePlatform(round.Bridge, round.Bridge, Color3.fromRGB(235, 246, 255))
			state.Message = "Puente listo. Recoge la chispa " .. color.Symbol .. " y vuelve al reactor."
			broadcast()
		end)
	end
	round.ResetCarrier = function()
		if round.Carrier then
			local r = root(round.Carrier)
			local indicator = r and r:FindFirstChild("CarriedSpark")
			if indicator then indicator:Destroy() end
		end
		round.Carrier = nil
		islands[round.Target].Spark.Transparency = 0
	end
	prompt(core, "Entregar chispa", function(player)
		if not valid(player, core, round) or round.Carrier ~= player then return end
		contribute(player)
		round.ResetCarrier()
		progress(round, 1)
		if round.Bridge then round.Bridge:Destroy() end
		round.Active = false
		local nextTarget = random:NextInteger(1, 3)
		if nextTarget >= round.Target then nextTarget += 1 end
		round.Target, state.Target = nextTarget, nextTarget
		-- Bring teammates off the old island before removing their route.
		for teammate, entry in pairs(participants) do
			if entry.Alive then teleport(teammate, arenaPosition(round, Vector3.new(random:NextInteger(-10, 10), 25, 28))) end
		end
		state.Message = "¡Chispa entregada! Activa el siguiente puente."
		broadcast()
	end)
end

local function eliminate(player)
	local entry = participants[player]
	if entry and entry.Alive then
		entry.Alive = false
		local r = root(player)
		if r then r.Anchored = false end
		if currentRound and currentRound.Carrier == player then
			currentRound.ResetCarrier()
			state.Message = "La chispa volvió a su isla. Otro jugador puede recogerla."
		end
		personal(player, { Toast = "Vuelve a la plaza. Entrarás en la siguiente ronda." })
	end
end

local function onCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local r = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not r then return end
	-- A new character always starts in the lobby; never re-enter an active round.
	eliminate(player)
	teleport(player, Vector3.new(random:NextInteger(-8, 8), 11, 153))
	cosmetic(player)
	humanoid.Died:Connect(function() eliminate(player) end)
end

local function onPlayer(player)
	if initializing[player] or profiles[player] then return end
	initializing[player] = true
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	local data = cleanProfile(nil)
	local writable = false
	if savingEnabled then
		local acquired, loaded = false, nil
		for attempt = 1, 3 do
			local ok = pcall(function()
				store:UpdateAsync("Player_" .. player.UserId, function(old)
					acquired, loaded = false, nil
					if type(old) == "table" and old.Session and old.Session ~= sessionId and (tonumber(old.LeaseUntil) or 0) > os.time() then return nil end
					loaded = cleanProfile(type(old) == "table" and (old.Data or old) or nil)
					acquired = true
					return { Data = snapshot(loaded), Session = sessionId, LeaseUntil = os.time() + 240 }
				end)
			end)
			if ok and acquired then data, writable = loaded, true; break end
			if attempt < 3 then task.wait(attempt * 2) end
		end
	end
	profiles[player] = { Data = data, Writable = writable, Saving = false, Revision = 0, SavedRevision = 0 }
	initializing[player] = nil
	if not player.Parent then save(player, true); profiles[player] = nil; return end
	local leaderboard = Instance.new("Folder")
	leaderboard.Name, leaderboard.Parent = "leaderstats", player
	for _, name in ipairs({ "Monedas", "Victorias" }) do
		local value = Instance.new("IntValue")
		value.Name, value.Parent = name, leaderboard
	end
	stats(player); cosmetic(player); personal(player)
	task.spawn(function() commerce.refreshPasses(player); if player.Parent then personal(player) end end)
end

-- Monitor preparation as well as play. Recover falls by returning to the safe
-- lobby rather than leaving an avatar falling until Roblox destroys it.
task.spawn(function()
	while not closing do
		task.wait(0.1)
		local round = currentRound
		if round and state.Phase == "JUEGO" and not round.Success then
			local fraction = math.clamp((os.clock() - round.StartedAt) / Config.RoundSeconds, 0, 1)
			setLava(lavaSettings.StartHeight + (lavaSettings.EndHeight - lavaSettings.StartHeight) * fraction)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local r = root(player)
			local entry = participants[player]
			if entry and entry.Alive and round and (state.Phase == "PREPARACIÓN" or state.Phase == "JUEGO") then
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				local inLava = r and math.abs(r.Position.X) <= lavaSettings.HalfWidth and r.Position.Z >= lavaSettings.MinZ and r.Position.Z <= lavaSettings.MaxZ
				local footOffset = humanoid and ((humanoid.HipHeight or 2) + (r and r.Size and r.Size.Y or 2) / 2) or 3
				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
					local leg = player.Character:FindFirstChild("Left Leg")
					footOffset += leg and leg.Size.Y or 2
				end
				if not r or not humanoid or humanoid.Health <= 0 or r.Position.Y < 5 or (inLava and r.Position.Y - footOffset <= (state.LavaHeight or lavaSettings.StartHeight)) then
					eliminate(player)
					teleport(player, Vector3.new(0, 11, 153))
				end
			elseif r and r.Position.Y < 0 then
				-- Lobby visitors and eliminated players are never part of lava checks.
				teleport(player, Vector3.new(0, 11, 153))
			end
		end
	end
end)

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if profiles[player] then profiles[player].Leaving = true end
	eliminate(player)
	participants[player] = nil
	save(player, true)
	profiles[player], lastActions[player] = nil, nil
end)

actionEvent.OnServerEvent:Connect(function(player, action, value)
	local now = os.clock()
	if now - (lastActions[player] or 0) < 0.3 then return end
	lastActions[player] = now
	if action == "Sync" then personal(player); return end
	local record = profiles[player]
	if not record or record.Leaving then return end
	if action == "Purchase" then
		if type(value) == "table" then commerce.requestPurchase(player, value.Kind, value.Key) end
		return
	end
	if record.Saving then personal(player, { Toast = "Un momento: estamos guardando tu progreso." }); return end
	if action == "ClaimMission" then
		for _, mission in ipairs(Config.DailyMissions) do
			if mission.Key == value and record.Data.Coins + (record.PendingPaid or 0) + mission.Reward > Config.MaxCoins then
				personal(player, { Toast = "Gasta algunas monedas antes de reclamar esta recompensa." }); return
			end
		end
		local reward, message = Progression.claim(record.Data.Progress, value, os.time(), Config)
		if reward > 0 then
			freeCoins(record, reward)
			record.Revision += 1
			stats(player)
		end
		personal(player, { Toast = message }); return
	end
	if action ~= "Palette" then return end
	local ok, message = Rules.purchase(record.Data, value, Config.Palettes, record.VIP)
	if ok then
		record.Revision += 1
		stats(player); cosmetic(player)
	end
	personal(player, { Toast = message })
end)

task.spawn(function()
	while not closing do
		task.wait(Config.SaveInterval)
		for player, record in pairs(profiles) do
			if record.Writable then task.spawn(save, player, false) end
		end
	end
end)

game:BindToClose(function()
	closing = true
	local pending = 0
	for player in pairs(profiles) do
		pending += 1
		task.spawn(function() save(player, true); pending -= 1 end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)

local modeIndex = 0
while not closing do
	participants = {}
	state = { Phase = "LOBBY", Message = "Estás a salvo en el lobby. La siguiente ronda comienza pronto.", Progress = 0, Total = 0 }
	setLava(lavaSettings.StartHeight)
	showPreview(true)
	for remaining = Config.Intermission, 1, -1 do
		state.Seconds = remaining; broadcast(); task.wait(1)
	end
	local ready = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if profiles[player] and humanoid and humanoid.Health > 0 and root(player) then table.insert(ready, player) end
	end
	if #ready < Config.MinimumPlayers then
		state.Message = "Esperando jugadores listos..."; broadcast(); task.wait(2)
		continue
	end
	modeIndex = modeIndex % #Config.Modes + 1
	local mode = Config.Modes[modeIndex]
	local round = newArena(mode)
	showPreview(false)
	state = { Phase = "PREPARACIÓN", Mode = mode.Name, Message = mode.Hint, Progress = 0, Total = 0, Seconds = Config.RoundSeconds }
	setLava(lavaSettings.StartHeight)
	if mode.Id == "memory" then memory(round) elseif mode.Id == "relay" then relay(round) else rescue(round) end
	state.Total = round.Total
	for i, player in ipairs(ready) do
		if i <= Config.MaxParticipants then
			participants[player] = { Alive = true, Contributed = false, LastInteraction = 0 }
			teleport(player, Vector3.new(-10 + ((i - 1) % 5) * 5, 25, 34 - math.floor((i - 1) / 5) * 5))
			root(player).Anchored = true
		end
	end
	broadcast(); task.wait(3)
	if mode.Id == "memory" then
		state.Message = "OBSERVA LA SECUENCIA. Después activa las letras."
		for step, code in ipairs(round.Sequence) do
			state.DemoCode, state.DemoStep = code, step; broadcast(); task.wait(1)
			state.DemoCode = nil; broadcast(); task.wait(0.2)
		end
		state.DemoCode, state.DemoStep = nil, nil
		state.Message = "Activa la secuencia en orden y cruza al reactor."
	end
	state.Phase = "JUEGO"
	round.StartedAt = os.clock()
	for player, entry in pairs(participants) do
		local r = root(player)
		if entry.Alive and r then r.Anchored = false end
	end
	for remaining = Config.RoundSeconds, 0, -1 do
		state.Seconds = remaining; broadcast()
		local alive = false
		for player, entry in pairs(participants) do
			if entry.Alive then
				local r = root(player)
				if not r or r.Position.Y < 5 then
					eliminate(player)
					teleport(player, Vector3.new(0, 11, 153))
				else alive = true end
			end
		end
		if round.Success or not alive or remaining == 0 then break end
		task.wait(1)
	end
	state.Phase = "RESULTADOS"
	state.Target, state.DemoCode = nil, nil
	state.Message = round.Success and "¡REACTOR REPARADO! El equipo devolvió el color." or "El reactor sigue apagado. ¡Lo intentaremos en la siguiente ronda!"
	if round.ResetCarrier then round.ResetCarrier() end
	for player, entry in pairs(participants) do
		local record = profiles[player]
		if record then
			local coins, wins = Rules.reward(round.Success, entry.Contributed, entry.Alive, Config.WinCoins, Config.ParticipationCoins)
			coins = freeCoins(record, coins)
			record.Data.Wins += wins; record.Revision += 1
			if entry.Contributed then
				Progression.record(record.Data.Progress, { Rounds = 1, Actions = entry.Actions or 0, Wins = wins }, os.time(), Config)
			end
			stats(player)
			personal(player, { Toast = coins > 0 and ("+" .. coins .. " monedas por colaborar") or "Colabora en un objetivo para ganar monedas." })
		end
		teleport(player, Vector3.new(random:NextInteger(-12, 12), 11, 153))
	end
	currentRound = nil
	Debris:AddItem(round.Model, 0)
	showPreview(true)
	setLava(lavaSettings.StartHeight)
	for remaining = Config.ResultSeconds, 1, -1 do state.Seconds = remaining; broadcast(); task.wait(1) end
end
