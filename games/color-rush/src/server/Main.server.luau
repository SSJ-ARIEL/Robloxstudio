local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local shared = ReplicatedStorage.ColorRush
local Config = require(shared.Config)
local Characters = require(shared.Characters)
local Rules = require(shared.Rules)
local Ledger = require(shared.Ledger)
local Progression = require(shared.Progression)
local Profiles = require(script.Parent.Profiles)
local Commerce = require(script.Parent.Commerce)

local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "Remotes", shared
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name, stateEvent.Parent = "State", remotes
local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name, actionEvent.Parent = "Action", remotes

local profiles, commerce, requestRevive
local entries, loading, lastActions = {}, {}, {}
local match, round = nil, nil
local closing, matchCounter = false, 0
local rng = Random.new()
local state = { Phase = "LOBBY", Seconds = 0, Message = "Preparando los portales...", Round = 0, RunnerCount = 0 }
local startPosition, lobbyPosition = Vector3.new(0, 8, 50), Vector3.new(0, 9, 145)

pcall(function() PhysicsService:RegisterCollisionGroup("ColorRushRunners") end)
PhysicsService:CollisionGroupSetCollidable("ColorRushRunners", "ColorRushRunners", false)

local function root(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function usableCharacter(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return root(player) ~= nil and humanoid ~= nil and humanoid.Health > 0
end
local function teleport(player, position, freeze)
	local r = root(player)
	if not r then return false end
	r.Anchored = freeze == true
	r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	player.Character:PivotTo(CFrame.new(position))
	return true
end
local function personal(player, extra)
	if not player.Parent then return end
	local payload, entry = table.clone(state), entries[player]
	payload.Participating = entry ~= nil
	payload.Alive = entry ~= nil and entry.Alive == true
	payload.Eliminated = entry ~= nil and not entry.Alive
	payload.QueuedRevive = entry ~= nil and entry.QueuedRevive == true
	payload.SelectedChoice = entry and entry.SelectedChoice or nil
	payload.CanRevive = Rules.eligibleRevive(entry, state.Phase, match ~= nil and match.Winner ~= nil, Config.MaxRevivesPerMatch)
		and not (round and round.Final and round.Closed) and not (entry and entry.ReviveBusy)
	if profiles then
		payload.Profile = profiles.public(player)
		payload.Progression = profiles.progression(player)
		local record = profiles.get(player)
		payload.Persistence = record and record.Writable and (record.LastSaveFailed and "GUARDADO PENDIENTE" or "GUARDADO ACTIVO") or "PROGRESO DE ESTA SESIÓN"
	end
	payload.Catalog = commerce and commerce.getCatalog(player) or {}
	if extra then for key, value in pairs(extra) do payload[key] = value end end
	stateEvent:FireClient(player, payload)
end
local function broadcast()
	local alive, queued = Rules.count(entries)
	state.RunnerCount = alive + queued
	for _, player in ipairs(Players:GetPlayers()) do personal(player) end
end

local function cosmetic(player)
	local record, r = profiles and profiles.get(player), root(player)
	if not record or not r then return end
	for _, name in ipairs({ "RushTrail", "RushTrail2", "RushLeft", "RushRight", "RushHigh", "RushLow", "RushVIP" }) do
		local old = r:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local selected = Config.Trails[record.Data.SelectedTrail] or Config.Trails[1]
	if selected.Access == "VIP" and not record.VIP then selected = Config.Trails[1] end
	if selected.Style ~= "none" then
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Name, a.Position, a.Parent = "RushLeft", Vector3.new(-0.9, -0.8, 0), r
		b.Name, b.Position, b.Parent = "RushRight", Vector3.new(0.9, -0.8, 0), r
		local trail = Instance.new("Trail")
		trail.Name, trail.Attachment0, trail.Attachment1 = "RushTrail", a, b
		trail.Lifetime, trail.FaceCamera, trail.LightEmission = 0.45, true, 0.8
		trail.Color = ColorSequence.new(Color3.fromRGB(table.unpack(selected.ColorRGB)))
		trail.Parent = r
		if selected.Style == "double" or selected.Style == "prisma" then
			local high, low = Instance.new("Attachment"), Instance.new("Attachment")
			high.Name, high.Position, high.Parent = "RushHigh", Vector3.new(0, 0.5, 0), r
			low.Name, low.Position, low.Parent = "RushLow", Vector3.new(0, -1.1, 0), r
			local extra = trail:Clone()
			extra.Name, extra.Attachment0, extra.Attachment1, extra.Parent = "RushTrail2", high, low, r
		end
		if selected.Style == "prisma" then
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 170)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(105, 224, 250)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 145, 255)),
			})
		end
	end
	if record.VIP then
		local tag = Instance.new("BillboardGui")
		tag.Name, tag.Size, tag.StudsOffset = "RushVIP", UDim2.fromOffset(130, 28), Vector3.new(0, 4, 0)
		tag.MaxDistance, tag.Parent = 75, r
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		t.Text, t.TextScaled, t.Font = "VIP PRISMA", true, Enum.Font.GothamBold
		t.TextColor3, t.Parent = Color3.fromRGB(220, 175, 255), tag
	end
end
local function stats(player)
	local record = profiles and profiles.get(player)
	local folder = player:FindFirstChild("leaderstats")
	if record and folder then
		folder.Monedas.Value, folder.Victorias.Value = record.Data.Coins, record.Data.Wins
	end
end
local function refresh(player)
	stats(player)
	cosmetic(player)
	local record, entry = profiles and profiles.get(player), entries[player]
	if requestRevive and record and entry and record.Data.AutoRevive and record.Data.ReviveCredits > 0
		and Rules.eligibleRevive(entry, state.Phase, match ~= nil and match.Winner ~= nil, Config.MaxRevivesPerMatch) then
		requestRevive(player, true)
	end
	personal(player)
end
profiles = Profiles.new({
	Config = Config, Players = Players, DataStoreService = DataStoreService,
	RunService = RunService, HttpService = HttpService, Ledger = Ledger, Progression = Progression,
	Notify = function(player, message) personal(player, { Toast = message }) end,
	Refresh = refresh,
})
commerce = Commerce.new({
	Config = Config, Players = Players, MarketplaceService = MarketplaceService,
	GetProfile = profiles.get, PersistentGrant = profiles.grantReceipt,
	Notify = function(player, message) personal(player, { Toast = message }) end,
	Refresh = refresh,
})
profiles.start()
commerce.start()

local world = Instance.new("Folder")
world.Name, world.Parent = "ColorRushWorld", workspace
local gates = Instance.new("Folder")
gates.Name, gates.Parent = "Gates", world
local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position, p.Anchored = name, size, pos, true
	p.Material, p.Color = material or Enum.Material.SmoothPlastic, color or Color3.fromRGB(24, 32, 55)
	p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return p
end
local function label(target, content, size)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.MaxDistance = size or UDim2.fromOffset(310, 65), Vector3.new(0, 4, 0), 140
	gui.Parent = target
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Font, text.TextScaled, text.TextWrapped = Enum.Font.GothamBold, true, true
	text.TextColor3, text.Text, text.Parent = Color3.new(1, 1, 1), content, gui
end
part(world, "Plaza", Vector3.new(98, 3, 76), Vector3.new(0, 3, 145))
part(world, "Pista", Vector3.new(86, 3, 140), Vector3.new(0, 3, 0))
local spawn = Instance.new("SpawnLocation")
spawn.Name, spawn.Anchored, spawn.Neutral = "LobbySpawn", true, true
spawn.Size, spawn.Position, spawn.Duration = Vector3.new(8, 1, 8), Vector3.new(0, 5, 145), 0
spawn.Color, spawn.Parent = Color3.fromRGB(89, 169, 255), world
workspace.FallenPartsDestroyHeight = -60
label(part(world, "Título", Vector3.new(1, 1, 1), Vector3.new(0, 12, 177)), "COLOR RUSH\nCorre y recuerda")
label(part(world, "Ayuda", Vector3.new(1, 1, 1), Vector3.new(-30, 7, 150)), "2 segundos para memorizar\n5 puertas · 1 respuesta\nFinal: primera llegada correcta")
local shop = part(world, "Tienda", Vector3.new(9, 3, 9), Vector3.new(30, 6, 149), Color3.fromRGB(182, 115, 255), Enum.Material.Neon)
label(shop, "TIENDA\nEstelas · VIP · Créditos")
local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.ActionText, shopPrompt.ObjectText = "Abrir", "Tienda"
shopPrompt.MaxActivationDistance, shopPrompt.RequiresLineOfSight, shopPrompt.Parent = 13, false, shop
shopPrompt.Triggered:Connect(function(player) personal(player, { OpenShop = true }) end)
local reference = part(world, "ReferenceBoard", Vector3.new(26, 16, 1), Vector3.new(0, 32, -66))
reference.CanCollide, reference.Transparency = false, 1
for i, x in ipairs(Config.LaneX) do
	local hue = Color3.fromRGB(table.unpack(Characters.Palette[i]))
	part(world, "Carril" .. i, Vector3.new(11, 0.2, 80), Vector3.new(x, 4.6, 0), hue)
	part(gates, "Gate" .. i, Vector3.new(11, 12, 5), Vector3.new(x, 10, -40), hue, Enum.Material.Neon).Transparency = 0.65
	local gate = gates:FindFirstChild("Gate" .. i)
	gate.CanCollide = false
	local board = part(gates, "Board" .. i, Vector3.new(10, 10, 1), Vector3.new(x, 14, -51))
	board.Transparency, board.CanCollide = 1, false
	label(part(world, "Número" .. i, Vector3.new(1, 1, 1), Vector3.new(x, 6, -35)), tostring(i), UDim2.fromOffset(55, 40))
	for _, dx in ipairs({ -6, 6 }) do
		part(world, "Marco", Vector3.new(0.6, 15, 1), Vector3.new(x + dx, 11, -42), hue, Enum.Material.Neon)
	end
	part(world, "Arco", Vector3.new(12.5, 0.6, 1), Vector3.new(x, 18.5, -42), hue, Enum.Material.Neon)
end
for _, x in ipairs({ -43, 43 }) do
	part(world, "Baranda", Vector3.new(1, 4, 140), Vector3.new(x, 6, 0), Color3.fromRGB(70, 128, 185))
end
for i = 1, 6 do
	local x = i % 2 == 0 and 54 or -54
	local island = part(world, "Isla orbital", Vector3.new(10 + i, 7, 14), Vector3.new(x, -3, -50 + i * 24))
	part(world, "Cristal", Vector3.new(3, 8 + i, 3), island.Position + Vector3.new(0, 8, 0), Color3.fromRGB(88 + i * 18, 130, 235), Enum.Material.Neon)
end

requestRevive = function(player, automatic)
	local entry, record = entries[player], profiles.get(player)
	if not Rules.eligibleRevive(entry, state.Phase, match ~= nil and match.Winner ~= nil, Config.MaxRevivesPerMatch)
		or entry.ReviveBusy or (round and round.Final and (round.Closed or (round.Deadline and os.clock() >= round.Deadline))) then
		if not automatic then personal(player, { Toast = "La reentrada ya no está disponible. Tus créditos se conservan." }) end
		return false
	end
	if not record or record.Data.ReviveCredits < 1 then
		if not automatic then personal(player, { Toast = "Necesitas un crédito. También puedes esperar gratis la siguiente partida.", OpenShop = true }) end
		return false
	end
	if not usableCharacter(player) then
		if not automatic then personal(player, { Toast = "Espera a que reaparezca tu personaje. El crédito se conserva." }) end
		return false
	end
	if record.Saving or record.LastSaveFailed or record.UncertainReceipt then return false end
	if round and round.Final then
		-- No yielding operation can occur between eligibility, credit use and entry.
		entry.ReviveBusy = true
		local ok, message = profiles.consumeRevive(player)
		entry.ReviveBusy = false
		if not ok then if not automatic then personal(player, { Toast = message }) end; return false end
		entry.RevivesUsed += 1
		entry.Alive, entry.SelectedChoice, entry.LastGate = true, nil, os.clock()
		entry.RunBeganAt = os.clock()
		teleport(player, startPosition, false)
		personal(player, { Toast = "Crédito usado. Una nueva oportunidad antes de que haya ganador." })
	else
		-- Reserve intent, not currency: if everyone misses, the free replay
		-- must not consume a paid credit that was unnecessary.
		entry.QueuedRevive = true
		personal(player, { Toast = "Reentrada preparada para la siguiente etapa. El crédito aún no se ha usado." })
	end
	broadcast()
	return true
end
local function eliminate(player, reason, skipAuto)
	local entry = entries[player]
	if not entry or not entry.Alive then return end
	entry.Alive, entry.SelectedChoice = false, nil
	teleport(player, lobbyPosition, false)
	personal(player, { Toast = reason or "Eliminado. Puedes esperar gratis la siguiente partida." })
	local record = profiles.get(player)
	if not skipAuto and record and record.Data.AutoRevive then requestRevive(player, true) end
	broadcast()
end
local function declareWinner(player)
	if not match or match.Winner then return false end
	match.Winner = player -- latch before rewards or any presentation callback
	profiles.reward(player, Config.WinnerCoins, 1, 0, 0)
	stats(player)
	return true
end

for i = 1, 5 do
	local gate = gates:FindFirstChild("Gate" .. i)
	gate.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local entry, r = player and entries[player], player and root(player)
		if state.Phase ~= "RUN" or not round or round.Closed or not match or match.Winner or not entry or not entry.Alive or entry.SelectedChoice or not r then return end
		if round.Deadline and os.clock() >= round.Deadline then return end
		if os.clock() - (entry.RunBeganAt or os.clock()) < Config.MinimumTravelSeconds then return end
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or (r.Position - gate.Position).Magnitude > Config.GateDistance then return end
		if os.clock() - (entry.LastGate or 0) < 0.35 then return end
		entry.LastGate = os.clock()
		if not entry.Contributed then
			entry.Contributed = true
			-- Save participation in the profile immediately, even if the player
			-- disconnects during the reveal/results presentation.
			profiles.reward(player, Config.ParticipationCoins, 0, 1, 0)
		end
		local result = Rules.classify(i, round.Correct)
		if result == "wrong" then
			eliminate(player, "Color incorrecto. Has quedado eliminado de esta etapa.")
		elseif result == "correct" then
			entry.SelectedChoice = i
			if round.Final then declareWinner(player) end
			profiles.reward(player, Config.CorrectCoins, 0, 0, 1)
			teleport(player, Vector3.new(Config.LaneX[i], 8, -43), true)
			personal(player, { Toast = round.Final and "¡Primera llegada correcta!" or "¡Correcto! Espera la siguiente etapa." })
			broadcast()
		end
	end)
end

local function onCharacter(player, character)
	local r = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not r or not humanoid then return end
	local function collision(object)
		if object:IsA("BasePart") then object.CollisionGroup = "ColorRushRunners" end
	end
	for _, object in ipairs(character:GetDescendants()) do collision(object) end
	character.DescendantAdded:Connect(collision)
	humanoid.WalkSpeed, humanoid.JumpPower = 20, 48
	if entries[player] and entries[player].Alive then eliminate(player, "Reaparición: espera o usa una reentrada disponible.", true) end
	teleport(player, lobbyPosition, false)
	refresh(player)
	humanoid.Died:Connect(function() eliminate(player, "Has caído. Tus créditos siguen disponibles si la partida continúa.") end)
end
local function onPlayer(player)
	if loading[player] or profiles.get(player) then return end
	loading[player] = true
	player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	profiles.load(player)
	loading[player] = nil
	if not player.Parent then profiles.remove(player); return end
	local board = Instance.new("Folder")
	board.Name, board.Parent = "leaderstats", player
	for _, name in ipairs({ "Monedas", "Victorias" }) do
		local value = Instance.new("IntValue")
		value.Name, value.Parent = name, board
	end
	refresh(player)
	task.spawn(function() commerce.refreshPasses(player); personal(player) end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	entries[player], loading[player], lastActions[player] = nil, nil, nil
	profiles.remove(player)
end)
actionEvent.OnServerEvent:Connect(function(player, action, value)
	local now = os.clock()
	if now - (lastActions[player] or 0) < 0.3 then return end
	lastActions[player] = now
	if action == "Sync" then personal(player); return end
	if not profiles.get(player) then return end
	local ok, message
	if action == "ShopBuy" and type(value) == "table" then commerce.requestPurchase(player, value.Kind, value.Key); return
	elseif action == "UseRevive" then requestRevive(player, false); return
	elseif action == "Trail" then ok, message = profiles.trail(player, value)
	elseif action == "AutoRevive" then ok, message = profiles.autoRevive(player, value)
	elseif action == "ClaimMission" then ok, message = profiles.claim(player, value)
	else return end
	if ok then refresh(player) end
	personal(player, { Toast = message })
end)
game:BindToClose(function() closing = true; profiles.close() end)

local function waitPhase(seconds)
	for remaining = seconds, 1, -1 do state.Seconds = remaining; broadcast(); task.wait(1); if closing then break end end
end
local function readyPlayers()
	local ready = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if profiles.get(player) and humanoid and humanoid.Health > 0 and root(player) then table.insert(ready, player) end
	end
	return ready
end

while not closing do
	entries, match, round = {}, nil, nil
	state = { Phase = "LOBBY", Message = "Memoriza el color y corre a su imagen. Necesitamos al menos dos jugadores.", Seconds = 0, Round = 0, RunnerCount = 0 }
	while #readyPlayers() < Config.MinimumPlayers and not closing do broadcast(); task.wait(1) end
	if closing then break end
	state.Message = "La carrera está por comenzar. Configura tu estela y tus créditos si quieres."
	waitPhase(Config.Intermission)
	local ready = readyPlayers()
	if #ready < Config.MinimumPlayers then continue end
	matchCounter += 1
	match = { Id = tostring(matchCounter), Winner = nil, SeenCharacters = {}, Repeats = 0 }
	local first = (matchCounter - 1) * Config.MaxParticipants % #ready
	for i = 1, math.min(#ready, Config.MaxParticipants) do
		local player = ready[(first + i - 1) % #ready + 1]
		entries[player] = { Alive = true, QueuedRevive = false, RevivesUsed = 0, Contributed = false, LastGate = 0 }
	end
	local roundNumber = 0
	while not match.Winner and not closing do
		local alive = Rules.count(entries)
		if alive == 0 then break end
		if alive == 1 then
			for player, entry in pairs(entries) do if entry.Alive then declareWinner(player) end end
			break
		end
		roundNumber += 1
		local characterId
		repeat characterId = rng:NextInteger(1, #Characters.All) until not match.SeenCharacters[characterId]
		match.SeenCharacters[characterId] = true
		local colors, correct = Rules.options(Characters.get(characterId).TargetRGB, Characters.Palette, roundNumber, function(a, b) return rng:NextInteger(a, b) end)
		round = { Correct = correct, Final = Rules.isFinal(alive, roundNumber, Config.MaxNormalRounds), Roster = {} }
		state = { Phase = "PREVIEW", Message = "MEMORIZA el color de la ropa o el casco. Tienes dos segundos.", Seconds = Config.PreviewSeconds,
			Round = roundNumber, MatchId = match.Id, Final = round.Final, CharacterId = characterId, Colors = colors, RunnerCount = alive }
		for i = 1, 5 do
			gates:FindFirstChild("Gate" .. i).Color = Color3.fromRGB(125, 135, 155)
			world:FindFirstChild("Carril" .. i).Color = Color3.fromRGB(75, 85, 105)
		end
		for player, entry in pairs(entries) do
			entry.SelectedChoice = nil
			if entry.Alive then
				round.Roster[player] = true
				if not teleport(player, startPosition, true) then entry.Alive = false end
			end
		end
		waitPhase(Config.PreviewSeconds)
		state.Phase = "RUN"
		for i, color in ipairs(colors) do
			gates:FindFirstChild("Gate" .. i).Color = Color3.fromRGB(table.unpack(color))
			world:FindFirstChild("Carril" .. i).Color = Color3.fromRGB(table.unpack(color))
		end
		state.Message = round.Final and "FINAL: gana la primera llegada a la imagen correcta. Una sola reentrada por partida." or "CORRE a la imagen correcta. Una elección por etapa."
		for player, entry in pairs(entries) do
			if entry.Alive and root(player) then root(player).Anchored = false; entry.RunBeganAt = os.clock() end
		end
		local deadline = os.clock() + (round.Final and Config.FinalSeconds or Config.RunSeconds)
		round.Deadline = deadline
		local displayed = -1
		while os.clock() < deadline and not match.Winner and not closing do
			local seconds = math.ceil(deadline - os.clock())
			if seconds ~= displayed then displayed = seconds; state.Seconds = seconds; broadcast() end
			for player, entry in pairs(entries) do
				if entry.Alive and not entry.SelectedChoice then
					local r = root(player)
					if not r or r.Position.Y < 0 then eliminate(player, "Has caído. Espera o usa un crédito disponible.") end
				end
			end
			task.wait(0.15)
		end
		-- After the winner latch, no automatic revival or credit use is eligible.
		round.Closed = true
		if not match.Winner then
			for player, entry in pairs(entries) do
				if entry.Alive and not entry.SelectedChoice then eliminate(player, "Terminó el tiempo para escoger.") end
			end
		end
		state.Phase, state.CorrectChoice, state.Seconds = "REVEAL", correct, Config.RevealSeconds
		state.Message = match.Winner and (match.Winner.DisplayName .. " llegó primero a la imagen correcta.") or "La puerta " .. correct .. " tenía el color original."
		broadcast()
		waitPhase(Config.RevealSeconds)
		if match.Winner then break end
		local survivors = Rules.count(entries)
		if survivors == 0 and not round.Final and match.Repeats < Config.MaxAllWrongRepeats then
			match.Repeats += 1
			for player in pairs(round.Roster) do
				local entry = entries[player]
				if entry and player.Parent and usableCharacter(player) then entry.Alive, entry.QueuedRevive = true, false end
			end
			state.Message = "Todos fallaron. Repetimos una etapa gratis: no se consumen créditos."
			broadcast(); task.wait(2)
		elseif not round.Final and survivors > 0 then
			for player, entry in pairs(entries) do
				if entry.QueuedRevive then
					local ok = usableCharacter(player) and profiles.consumeRevive(player)
					entry.QueuedRevive = false
					if ok then entry.Alive = true; entry.RevivesUsed += 1
					else personal(player, { Toast = "No se pudo activar la reentrada. El crédito se conserva." }) end
				end
			end
		else
			-- A final with no correct finish is a draw; no winner is fabricated.
			for _, entry in pairs(entries) do entry.QueuedRevive = false end
			break
		end
	end
	state.Phase, state.Seconds = "RESULTS", Config.ResultSeconds
	state.WinnerName = match.Winner and match.Winner.DisplayName or nil
	state.Message = match.Winner and ("¡" .. match.Winner.DisplayName .. " gana la carrera!") or "Carrera sin ganador. La próxima partida comienza pronto."
	for player, entry in pairs(entries) do
		teleport(player, lobbyPosition, false)
	end
	broadcast()
	waitPhase(Config.ResultSeconds)
end
