-- Ciudad Prisma. The saved world and spawn exist before this script runs.
-- Only the server decides membership, physical choices, rewards and purchases.
local function run()
	workspace:SetAttribute("ColorChaosBootStatus", "STARTING")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DataStoreService = game:GetService("DataStoreService")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local PhysicsService = game:GetService("PhysicsService")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local Config = require(ReplicatedStorage.ColorChaos.Config)
	local Settings = require(ReplicatedStorage.ColorChaos.GameSettings)
	local Catalog = require(ReplicatedStorage.ColorChaos.Catalog)
	local Characters = require(ReplicatedStorage.ColorChaos.Characters)
	local GameRules = require(ReplicatedStorage.ColorChaos.GameRules)
	local Economy = require(ReplicatedStorage.ColorChaos.Economy)
	local Ledger = require(ReplicatedStorage.ColorChaos.ProfileLedger)
	local Rules = require(ReplicatedStorage.ColorChaos.Rules)
	local Profiles = require(script.Parent.Profiles)
	local Leaderboards = require(script.Parent.Leaderboards)
	local Cosmetics = require(script.Parent.Cosmetics)
	local Commerce = require(script.Parent.Commerce)

	local world = assert(workspace:WaitForChild("ColorChaosWorld", 10), "Falta ColorChaosWorld. Importa la entrega completa.")
	local spawn = assert(world:FindFirstChild("LobbySpawn"), "Falta LobbySpawn en el mundo guardado.")
	local stages = assert(world:FindFirstChild("Stages"), "Falta el recorrido Stages.")
	local gates, gatePositions = {}, {}
	for index = 1, Settings.Stages do
		local sector = assert(stages:FindFirstChild(string.format("Stage%02d", index)), "Falta un sector del recorrido.")
		local group = assert(sector:FindFirstChild("Gates"), "Faltan las cinco puertas.")
		gates[index] = {}
		for lane = 1, 5 do
			local gate = assert(group:FindFirstChild("Gate" .. lane), "Falta una puerta.")
			local barrier = assert(gate:FindFirstChild("Barrier"), "Falta Barrier.")
			assert(gate:FindFirstChild("ChoicePad"), "Falta ChoicePad.")
			gates[index][lane], gatePositions[barrier] = gate, barrier.CFrame
		end
	end
	-- Also applied after an in-place update, which preserves the owner's Config.
	Lighting.ClockTime, Lighting.Brightness = 14.4, 2.6
	Lighting.GlobalShadows, Lighting.ExposureCompensation = true, 0.05
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.72, 0.65
	Lighting.Ambient, Lighting.OutdoorAmbient = Color3.new(0.43, 0.49, 0.58), Color3.new(0.66, 0.71, 0.77)
	local function lightingEffect(className, name, properties)
		local effect = Lighting:FindFirstChild(name)
		if effect and not effect:IsA(className) then effect:Destroy(); effect = nil end
		if not effect then effect = Instance.new(className); effect.Name, effect.Parent = name, Lighting end
		for property, value in pairs(properties) do effect[property] = value end
	end
	lightingEffect("Atmosphere", "Atmosfera", { Density = 0.17, Offset = 0.25,
		Color = Color3.new(0.78, 0.88, 0.96), Decay = Color3.new(0.55, 0.64, 0.77), Glare = 0.12, Haze = 0.8 })
	lightingEffect("BloomEffect", "Neon", { Intensity = 0.14, Size = 20, Threshold = 1.35 })
	lightingEffect("ColorCorrectionEffect", "Color", { Brightness = 0, Contrast = 0.04,
		Saturation = 0.06, TintColor = Color3.new(1, 0.99, 0.98) })
	workspace.Gravity, workspace.FallenPartsDestroyHeight = 140, -60
	for _, name in ipairs({ "ColorChaosPlayers", "ColorChaosGhosts", "ColorChaosGates" }) do
		if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
	end
	PhysicsService:CollisionGroupSetCollidable("ColorChaosPlayers", "ColorChaosPlayers", false)
	PhysicsService:CollisionGroupSetCollidable("ColorChaosGhosts", "ColorChaosPlayers", false)
	PhysicsService:CollisionGroupSetCollidable("ColorChaosGhosts", "ColorChaosGhosts", false)
	PhysicsService:CollisionGroupSetCollidable("ColorChaosGhosts", "ColorChaosGates", false)
	for barrier in pairs(gatePositions) do barrier.CollisionGroup = "ColorChaosGates" end

	local shared = ReplicatedStorage.ColorChaos
	local events = shared:FindFirstChild("Remotes") or Instance.new("Folder")
	events.Name, events.Parent = "Remotes", shared
	local stateEvent = events:FindFirstChild("State") or Instance.new("RemoteEvent")
	stateEvent.Name, stateEvent.Parent = "State", events
	local actionEvent = events:FindFirstChild("Action") or Instance.new("RemoteEvent")
	actionEvent.Name, actionEvent.Parent = "Action", events
	local random, closing = Random.new(), false
	local sessions, initializing, lastActions = {}, {}, {}
	local currentRound, commerce, profiles
	local matchCounter, lastRoom = 0, {}
	local state = { Phase = "LOBBY", Seconds = 0, Stage = 0, StageCount = Settings.Stages,
		MatchId = 0, Message = "Bienvenido a Ciudad Prisma", Final = false, Solo = false }
	local store
	if not RunService:IsStudio() then
		local ok, result = pcall(function() return DataStoreService:GetDataStore(Config.DataStoreName) end)
		if ok then store = result else warn("Color Chaos: guardado no disponible; modo de sesión sin ventas de monedas.") end
	end
	local boards = Leaderboards.new({ DataStoreService = DataStoreService, Enabled = store ~= nil,
		Config = Config, NameForUser = function(id) return Players:GetNameFromUserIdAsync(id) end })
	local function online(player) return player.Parent == Players end
	local function body(player)
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
	end
	local function readyPlayers()
		local result = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local root, humanoid = body(player)
			local record = profiles and profiles.get(player)
			if sessions[player] and record and not record.Leaving and root and humanoid and humanoid.Health > 0 then
				table.insert(result, player)
			end
		end
		table.sort(result, function(a, b) return a.UserId < b.UserId end)
		return result
	end
	local function alivePlayers()
		local result = {}
		if currentRound then
			for player, member in pairs(currentRound.Members) do
				if member.Alive and online(player) then table.insert(result, player) end
			end
		end
		table.sort(result, function(a, b) return a.UserId < b.UserId end)
		return result
	end
	local function roomRows()
		if not currentRound then return lastRoom end
		local entries = {}
		for player, member in pairs(currentRound.Members) do
			table.insert(entries, { UserId = player.UserId, Name = player.DisplayName, Alive = member.Alive,
				CorrectThisMatch = member.CorrectThisMatch, LastChoiceAt = member.LastChoiceAt, Eligible = true })
		end
		return GameRules.rankRoom(entries)
	end
	local function personal(player, extra)
		if not online(player) then return end
		local payload = table.clone(state)
		local session = sessions[player]
		local member = currentRound and currentRound.Members[player]
		payload.Mode = session and session.Mode or "LOBBY"
		payload.Alive = member ~= nil and member.Alive == true
		payload.SpectatorIds = {}
		for _, competitor in ipairs(alivePlayers()) do table.insert(payload.SpectatorIds, competitor.UserId) end
		payload.AliveCount, payload.ReadyCount = #payload.SpectatorIds, #readyPlayers()
		payload.MyChoice = if payload.Mode == "GHOST" then session.GhostChoice else member and member.Choice
		local question = currentRound and currentRound.Question
		if question then
			payload.CharacterId, payload.Choices = question.CharacterId, question.Choices
			payload.ReferenceRGB = if state.Phase == "PREVIEW" then question.OriginalRGB else question.WrongRGB
			if state.Phase == "REVEAL" or state.Phase == "TRAVEL" or state.Phase == "RESULTS" then
				payload.CorrectLane = question.CorrectLane
			end
		end
		payload.Profile = profiles and profiles.public(player)
		payload.Commerce = commerce and commerce.getCatalog(player) or {}
		payload.RoomBoard, payload.GlobalBoards = roomRows(), boards.snapshot()
		payload.LeaderboardStatus = payload.GlobalBoards.Status
		if extra then for key, value in pairs(extra) do payload[key] = value end end
		stateEvent:FireClient(player, payload)
	end
	local function broadcast()
		for _, player in ipairs(Players:GetPlayers()) do personal(player) end
	end
	local function notify(player, message) personal(player, { Toast = message }) end
	local function refreshCosmetics(player)
		local record = profiles.get(player)
		if record and player.Character then
			local ok, message = pcall(Cosmetics.apply, player, record.Data, record.VIP)
			if not ok then warn("Color Chaos cosméticos: " .. tostring(message)) end
		end
	end
	profiles = Profiles.new({ Config = Config, Economy = Economy, Ledger = Ledger, Store = store,
		Enabled = store ~= nil, SessionId = game.JobId .. HttpService:GenerateGUID(false),
		Token = function() return HttpService:GenerateGUID(false) end, IsOnline = online, Notify = notify,
		OnSaved = function(player, data) task.spawn(function() boards.publish(player, data) end) end })
	commerce = Commerce.new({ Config = Config, MarketplaceService = MarketplaceService, Players = Players,
		GetProfile = profiles.get, PersistentGrant = profiles.grantReceipt, Notify = notify,
		Refresh = function(player) refreshCosmetics(player); personal(player) end })
	commerce.start()

	local function freeze(player, value)
		local root = body(player)
		if root then root.Anchored = value; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
	end
	local function teleport(player, position)
		local root = body(player)
		if root and player.Character then
			player.Character:PivotTo(CFrame.new(position))
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		end
	end
	local function stylePart(player, part)
		if not part:IsA("BasePart") then return end
		local ghost = sessions[player] and sessions[player].Mode == "GHOST"
		part.CollisionGroup = ghost and "ColorChaosGhosts" or "ColorChaosPlayers"
		local previous = part:GetAttribute("ColorChaosOriginalTransparency")
		if ghost then
			if previous == nil then part:SetAttribute("ColorChaosOriginalTransparency", part.Transparency) end
			part.Transparency = math.max(part.Transparency, 0.55)
		elseif previous ~= nil then
			part.Transparency = previous
			part:SetAttribute("ColorChaosOriginalTransparency", nil)
		end
	end
	local function setMode(player, mode)
		if not sessions[player] then return end
		sessions[player].Mode = mode
		player:SetAttribute("ColorChaosMode", mode)
		if player.Character then for _, part in ipairs(player.Character:GetDescendants()) do stylePart(player, part) end end
	end
	local function toLobby(player)
		freeze(player, false)
		setMode(player, "LOBBY")
		if sessions[player] then sessions[player].GhostChoice = nil end
		teleport(player, Vector3.new(unpack(Settings.LobbyPosition)))
	end
	local function losePlayer(player, message)
		local member = currentRound and currentRound.Members[player]
		if member and member.Alive then
			member.Alive = false
			local record = profiles.get(player)
			if record then Economy.fail(record.Data); profiles.markDirty(player) end
		end
		toLobby(player)
		if message then notify(player, message) end
	end
	local function enterGhost(player)
		local session, member = sessions[player], currentRound and currentRound.Members[player]
		if not session or not currentRound or state.Phase == "RESULTS" or state.Phase == "LOBBY" then
			notify(player, "La próxima partida comienza en el lobby."); return
		end
		if member and member.Alive then notify(player, "Sigues compitiendo. El modo fantasma es para espectadores."); return end
		local root, humanoid = body(player)
		if not root or not humanoid or humanoid.Health <= 0 then return end
		setMode(player, "GHOST")
		session.GhostChoice = nil
		local coordinates = GameRules.stageCoordinates(state.Stage)
		teleport(player, Vector3.new(0, Settings.AvatarY, coordinates.StartZ))
		freeze(player, state.Phase == "PREVIEW")
		notify(player, "Práctica fantasma: puedes elegir y avanzar, sin sumar puntos ni victorias.")
	end
	local function resetGates()
		for barrier, original in pairs(gatePositions) do
			barrier.CFrame, barrier.CanCollide, barrier.Transparency = original, true, 0.22
		end
	end
	local function openGate(index, lane)
		local barrier = gates[index][lane].Barrier
		barrier.CanCollide = false
		TweenService:Create(barrier, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = gatePositions[barrier] + Vector3.new(0, 20, 0), Transparency = 0.68 }):Play()
	end
	local function countdown(phase, seconds, message)
		state.Phase, state.Message = phase, message
		local deadline, displayed = os.clock() + seconds, -1
		repeat
			state.Seconds = math.max(0, math.ceil(deadline - os.clock()))
			if displayed ~= state.Seconds then displayed = state.Seconds; broadcast() end
			task.wait(0.1)
		until closing or os.clock() >= deadline
	end
	local bag = {}
	local function nextCharacter()
		if #bag == 0 then
			for _, character in ipairs(Characters.All) do table.insert(bag, character) end
			for index = #bag, 2, -1 do
				local swap = random:NextInteger(1, index)
				bag[index], bag[swap] = bag[swap], bag[index]
			end
		end
		return table.remove(bag)
	end
	local function processChoice(player)
		local round, session = currentRound, sessions[player]
		if not round or not session or state.Phase ~= "CHOOSE" or round.FinalWinner then return end
		local member = round.Members[player]
		local competing = member and member.Alive
		if not competing and session.Mode ~= "GHOST" then return end
		if (competing and member.Choice) or (not competing and session.GhostChoice) then return end
		local root, humanoid = body(player)
		if not root or not humanoid or humanoid.Health <= 0 then return end
		local chosen = GameRules.validChoice(root.Position, GameRules.stageCoordinates(state.Stage), os.clock() - round.StartedAt, Settings)
		if not chosen then return end
		if competing then
			member.Choice, member.ChoiceAt = chosen, os.clock()
			if state.Final and chosen == round.Question.CorrectLane then round.FinalWinner = player end
		else session.GhostChoice = chosen end
		freeze(player, true)
		personal(player)
	end
	for index, laneGates in ipairs(gates) do
		for _, gate in ipairs(laneGates) do
			gate.ChoicePad.Touched:Connect(function(part)
				if state.Stage ~= index or state.Phase ~= "CHOOSE" then return end
				local model = part:FindFirstAncestorOfClass("Model")
				local player = model and Players:GetPlayerFromCharacter(model)
				if player then processChoice(player) end
			end)
		end
	end
	local function playStage(index)
		local round = currentRound
		state.Stage = index
		state.Final = not round.Solo and ((#alivePlayers() == 2 and index >= Settings.FinalMinStage) or index == Settings.Stages)
		round.Question, round.FinalWinner = GameRules.generateQuestion(nextCharacter(), random), nil
		local coordinates, roster = GameRules.stageCoordinates(index), alivePlayers()
		for slot, player in ipairs(roster) do
			local member = round.Members[player]
			member.Choice, member.ChoiceAt = nil, nil
			Cosmetics.stopEmote(player)
			-- Finalists share one starting point; player collisions are disabled.
			local x = if state.Final then 0 else ((slot - 1) % 5 - 2) * 8
			local z = coordinates.StartZ + (if state.Final then 0 else math.floor((slot - 1) / 5) * 3)
			teleport(player, Vector3.new(x, Settings.AvatarY, z))
			freeze(player, true)
		end
		for player, session in pairs(sessions) do
			if session.Mode == "GHOST" then
				session.GhostChoice = nil
				teleport(player, Vector3.new(0, Settings.AvatarY, coordinates.StartZ))
				freeze(player, true)
			end
		end
		countdown("PREVIEW", Settings.PreviewSeconds, "MEMORIZA · este es el color original")
		if closing then return end
		state.Phase, state.Message = "CHOOSE", state.Final and "FINAL · llega primero a la puerta correcta" or "CORRE · elige un camino y confirma tu respuesta"
		round.StartedAt = os.clock()
		local deadline = round.StartedAt + (state.Final and Settings.FinalSeconds or Settings.RunSeconds)
		for player, session in pairs(sessions) do if session.Mode ~= "LOBBY" then freeze(player, false) end end
		local displayed = -1
		repeat
			local unchosen = 0
			for _, player in ipairs(alivePlayers()) do
				processChoice(player)
				if not round.Members[player].Choice then unchosen += 1 end
			end
			for player, session in pairs(sessions) do if session.Mode == "GHOST" then processChoice(player) end end
			state.Seconds = math.max(0, math.ceil(deadline - os.clock()))
			if displayed ~= state.Seconds then displayed = state.Seconds; broadcast() end
			if round.FinalWinner or unchosen == 0 then break end
			task.wait(0.05)
		until closing or os.clock() >= deadline
		state.Phase = "REVEAL"
		for _, player in ipairs(alivePlayers()) do
			local member, record = round.Members[player], profiles.get(player)
			if member.Choice == round.Question.CorrectLane then
				member.CorrectThisMatch += 1
				member.LastChoiceAt = member.ChoiceAt
				if record then
					local reward = Economy.correct(record.Data, os.time(), Config, record.PendingPaid)
					profiles.markDirty(player)
					notify(player, reward.FreeGifts > 0 and "¡Cinco aciertos seguidos! Tienes un regalo gratis en Regalos." or "¡Correcto! +8 monedas · +10 XP")
				end
				freeze(player, false)
			else losePlayer(player, "Esta vez no acertaste. Puedes observar o practicar como fantasma.") end
		end
		for player, session in pairs(sessions) do
			if session.Mode == "GHOST" then
				freeze(player, false)
				if session.GhostChoice then notify(player, session.GhostChoice == round.Question.CorrectLane
					and "Fantasma: ¡acertaste! Práctica sin puntos." or "Fantasma: prueba de nuevo en el siguiente sector.") end
			end
		end
		openGate(index, round.Question.CorrectLane)
		local survivors = alivePlayers()
		local ending = round.FinalWinner ~= nil or (#survivors == 1 and not round.Solo)
		if ending then for _, player in ipairs(survivors) do freeze(player, true) end end
		countdown("REVEAL", Settings.RevealSeconds, "La puerta " .. round.Question.CorrectLane .. " es la correcta")
		if not ending and #alivePlayers() > 0 then countdown("TRAVEL", Settings.TravelSeconds, "AVANZA · cruza la puerta abierta hacia el siguiente sector") end
	end
	local function runMatch(roster)
		matchCounter += 1
		resetGates()
		currentRound = { Members = {}, Solo = #roster == 1, StartedAt = 0 }
		state.MatchId, state.Solo = matchCounter, currentRound.Solo
		for _, player in ipairs(roster) do
			currentRound.Members[player] = { Alive = true, CorrectThisMatch = 0 }
			setMode(player, "ALIVE")
		end
		local winner
		for index = 1, Settings.Stages do
			if closing then break end
			local survivors = alivePlayers()
			if #survivors == 0 then break end
			if #survivors == 1 and not currentRound.Solo then winner = survivors[1]; break end
			playStage(index)
			if currentRound.FinalWinner then winner = currentRound.FinalWinner; break end
		end
		local survivors = alivePlayers()
		if not winner and not currentRound.Solo and #survivors == 1 then winner = survivors[1] end
		local message = "Ronda terminada · vuelve a intentarlo en la próxima"
		if winner and online(winner) and currentRound.Members[winner].Alive and not closing then
			local record = profiles.get(winner)
			if record then Economy.win(record.Data, os.time(), Config, record.PendingPaid); profiles.markDirty(winner) end
			message = "¡" .. winner.DisplayName .. " gana! +60 monedas · +10 diamantes"
		elseif currentRound.Solo then message = "Práctica terminada · conserva tus premios; las victorias requieren rivales" end
		lastRoom = roomRows()
		for player in pairs(sessions) do toLobby(player) end
		-- Stop eligibility before results; late joins and ghosts never enter this roster.
		for _, member in pairs(currentRound.Members) do member.Alive = false end
		countdown("RESULTS", Settings.ResultSeconds, message)
		currentRound = nil
		state.Stage, state.Final, state.Solo = 0, false, false
	end

	local function limited(player, key, delay)
		local bucket = lastActions[player]
		if not bucket then bucket = {}; lastActions[player] = bucket end
		if bucket[key] and os.clock() - bucket[key] < delay then return true end
		bucket[key] = os.clock()
		return false
	end
	local function validId(value) return type(value) == "string" and #value > 0 and #value <= 80 end
	actionEvent.OnServerEvent:Connect(function(player, action, payload)
		if not online(player) or type(action) ~= "string" or #action > 40 or limited(player, "Any", 0.12) then return end
		if action == "Sync" then if not limited(player, "Sync", 0.5) then personal(player) end; return end
		local record = profiles.get(player)
		if not record or closing then return end
		if action == "EnterGhost" then enterGhost(player); return end
		if action == "LeaveGhost" then
			if sessions[player] and sessions[player].Mode == "GHOST" then toLobby(player); personal(player) end
			return
		end
		if action == "Purchase" then
			if type(payload) == "table" then commerce.requestPurchase(player, payload.Kind, payload.Key) end
			return
		end
		if action == "Emote" or action == "Reaction" then
			local kind = action
			local id = validId(payload) and payload or record.Data.Equipped[kind]
			local item = Catalog.ById[id]
			if not item or item.Kind ~= kind or not (record.Data.CosmeticsOwned[id] or (item.Access == "VIP" and record.VIP)) then return end
			if limited(player, kind, kind == "Emote" and 3 or 2) then return end
			if kind == "Emote" then
				if sessions[player].Mode == "ALIVE" and (state.Phase == "PREVIEW" or state.Phase == "CHOOSE") then
					notify(player, "Los emotes vuelven al terminar la elección."); return
				end
				Cosmetics.playEmote(player, item.Style)
			else Cosmetics.playReaction(player, item.Id) end
			return
		end
		local callback
		if action == "BuyCosmetic" and validId(payload) then
			callback = function(data) return Economy.purchase(data, payload, record.VIP) end
		elseif action == "EquipCosmetic" then
			local id = type(payload) == "table" and payload.Id or payload
			if validId(id) then callback = function(data) return Economy.equip(data, id, record.VIP) end end
		elseif action == "ClaimTimeGift" and validId(payload) then
			callback = function(data) return Economy.claimTimeGift(data, payload, os.time(), Config, record.PendingPaid) end
		elseif action == "OpenGift" and not limited(player, "Gift", 1) then
			local roll, itemRoll, boundary = random:NextInteger(1, 100), 1, 0
			for _, odds in ipairs(Economy.GiftOdds) do
				boundary += odds.Chance
				if roll <= boundary then
					local pool = Catalog.RewardPools[odds.Kind]
					if pool then itemRoll = random:NextInteger(1, #pool) end
					break
				end
			end
			callback = function(data) return Economy.openGift(data, roll, itemRoll, Config, record.PendingPaid) end
		elseif action == "Palette" and type(payload) == "number" and payload == payload and payload % 1 == 0 then
			callback = function(data) return Rules.purchase(data, payload, Config.Palettes, record.VIP) end
		end
		if callback then
			local ok, message, reward = profiles.mutate(player, callback)
			if ok and (action == "BuyCosmetic" or action == "EquipCosmetic" or action == "Palette") then refreshCosmetics(player) end
			personal(player, { Toast = message or (ok and "Listo." or "No se pudo realizar la acción."), GiftResult = reward })
		end
	end)
	local function prompt(name, label, action)
		local anchor = world:FindFirstChild(name)
		if not anchor or not anchor:IsA("BasePart") then return end
		local proximity = Instance.new("ProximityPrompt")
		proximity.Name, proximity.ActionText, proximity.ObjectText = "CiudadPrismaPrompt", label, "Ciudad Prisma"
		proximity.MaxActivationDistance, proximity.HoldDuration, proximity.RequiresLineOfSight = 14, 0, false
		proximity.Parent = anchor
		proximity.Triggered:Connect(function(player)
			if action == "Ghost" then
				if sessions[player] and sessions[player].Mode == "GHOST" then toLobby(player); personal(player) else enterGhost(player) end
			else personal(player, { OpenWindow = action }) end
		end)
	end
	prompt("ShopStand", "Abrir tienda", "Shop")
	prompt("GiftStand", "Ver regalos gratis", "Gifts")
	prompt("GhostPortal", "Practicar como fantasma", "Ghost")
	prompt("GlobalBoard", "Clasificación global", "Leaderboards")
	prompt("RoomBoard", "Clasificación de la sala", "Leaderboards")
	local function updateWorldBoard(name, heading, rows, valueKey, empty)
		local anchor = world:FindFirstChild(name)
		local sign = anchor and anchor:FindFirstChild("StaticSign")
		local panel = sign and sign:FindFirstChild("Panel")
		if not panel then return end
		local title, content = panel:FindFirstChild("Heading"), panel:FindFirstChild("Body")
		if not title or not content then return end
		sign.Size = UDim2.fromScale(34, 22)
		title.Text = heading
		local lines = {}
		for index, row in ipairs(rows) do
			if index > 8 then break end
			table.insert(lines, string.format("%d. %s  ·  %d", index, row.Name or "Jugador", row[valueKey] or 0))
		end
		content.Text = #lines > 0 and table.concat(lines, "\n") or empty
	end
	local function updateBoards()
		local global = boards.snapshot()
		local metric = ({ "Wins", "Streak", "Level" })[math.floor(os.clock() / 10) % 3 + 1]
		local title = ({ Wins = "VICTORIAS", Streak = "MEJOR RACHA", Level = "NIVEL" })[metric]
		updateWorldBoard("GlobalBoard", "GLOBAL · " .. title, global[metric], "Value", global.Status .. "\nAún no hay resultados guardados.")
		updateWorldBoard("RoomBoard", "SALA · ACIERTOS EN ESTA PARTIDA", roomRows(), "CorrectThisMatch", "Tu próxima aventura comienza aquí.")
	end
	local function updatePlayerStats(player)
		local record = profiles.get(player)
		if not record then return end
		local folder = player:FindFirstChild("leaderstats")
		if not folder then folder = Instance.new("Folder"); folder.Name, folder.Parent = "leaderstats", player end
		local values = { Victorias = record.Data.Wins, Racha = record.Data.CurrentStreak,
			Nivel = math.min(1000, math.floor(record.Data.Progress.XP / 100) + 1) }
		for name, value in pairs(values) do
			local stat = folder:FindFirstChild(name)
			if not stat then stat = Instance.new("IntValue"); stat.Name, stat.Parent = name, folder end
			stat.Value = value
		end
	end

	local function characterAdded(player, character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not root or not humanoid or not online(player) or player.Character ~= character then return end
		local member = currentRound and currentRound.Members[player]
		if member and member.Alive then losePlayer(player) else toLobby(player) end
		character.DescendantAdded:Connect(function(part) stylePart(player, part) end)
		humanoid.Died:Connect(function()
			if player.Character == character then losePlayer(player, "Regresa al lobby; podrás practicar como fantasma.") end
		end)
		refreshCosmetics(player)
		personal(player)
	end
	local function playerAdded(player)
		if initializing[player] or sessions[player] then return end
		initializing[player], sessions[player] = true, { Mode = "LOBBY" }
		player.RespawnLocation = spawn
		player:SetAttribute("ColorChaosMode", "LOBBY")
		player.CharacterAdded:Connect(function(character) characterAdded(player, character) end)
		if player.Character then task.spawn(characterAdded, player, player.Character) end
		local record = profiles.load(player)
		initializing[player] = nil
		if not record or not online(player) then return end
		refreshCosmetics(player)
		updatePlayerStats(player)
		personal(player, { Toast = currentRound and "La partida ya empezó. Puedes observar o entrar como fantasma." or "Bienvenido. Memoriza el color, elige tu puerta y avanza." })
		task.spawn(function() commerce.refreshPasses(player) end)
	end
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local member = currentRound and currentRound.Members[player]
		if member and member.Alive then
			member.Alive = false
			local record = profiles.get(player)
			if record then Economy.fail(record.Data); profiles.markDirty(player) end
		end
		sessions[player], initializing[player], lastActions[player] = nil, nil, nil
		Cosmetics.cleanup(player)
		profiles.remove(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(playerAdded, player) end
	game:BindToClose(function() closing = true; profiles.close() end)

	-- A fall can never trap a player in an endless death/void cycle.
	task.spawn(function()
		while not closing do
			for player, session in pairs(sessions) do
				local root, humanoid = body(player)
				if root and humanoid and humanoid.Health > 0 and root.Position.Y < 0 then
					if session.Mode == "ALIVE" then losePlayer(player, "Caíste del recorrido. Puedes seguir como fantasma.")
					elseif session.Mode == "GHOST" and currentRound then
						freeze(player, false)
						teleport(player, Vector3.new(0, Settings.AvatarY, GameRules.stageCoordinates(math.max(1, state.Stage)).StartZ))
					else toLobby(player) end
				end
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		local previous, lastSave, lastBoard = os.clock(), os.clock(), -math.huge
		while not closing do
			task.wait(1)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local record = profiles.get(player)
				if record and Economy.advanceTime(record.Data, now - previous, os.time()) > 0 then profiles.markDirty(player) end
				updatePlayerStats(player)
			end
			updateBoards()
			previous = now
			if now - lastSave >= Settings.SaveInterval then
				lastSave = now
				for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() profiles.save(player, false) end) end
			end
			if now - lastBoard >= Settings.LeaderboardInterval then
				lastBoard = now
				task.spawn(function() boards.refresh() end)
			end
		end
	end)
	workspace:SetAttribute("ColorChaosBootStatus", "READY")
	while not closing do
		state.Phase, state.Message, state.Seconds = "LOBBY", "Esperando jugadores en Ciudad Prisma", 0
		while not closing and #readyPlayers() < Settings.MinimumPlayers do broadcast(); task.wait(1) end
		if closing then break end
		countdown("LOBBY", Settings.Intermission, "La próxima expedición comienza pronto · explora el lobby")
		local roster = readyPlayers()
		-- Rotate overflow fairly instead of always taking the lowest user IDs.
		for index = #roster, 2, -1 do local swap = random:NextInteger(1, index); roster[index], roster[swap] = roster[swap], roster[index] end
		while #roster > Settings.MaxParticipants do table.remove(roster) end
		if #roster >= Settings.MinimumPlayers and not closing then
			local ok, problem = xpcall(function() runMatch(roster) end, debug.traceback)
			if not ok then
				warn("Color Chaos ronda: " .. tostring(problem))
				for player in pairs(sessions) do toLobby(player) end
				currentRound = nil
				state.Stage, state.Final, state.Solo = 0, false, false
				countdown("LOBBY", 8, "La ronda se reinició. Tu lobby sigue disponible.")
			end
		end
	end
end

local ok, problem = xpcall(run, debug.traceback)
if not ok then
	workspace:SetAttribute("ColorChaosBootStatus", "ERROR")
	warn("Color Chaos no pudo iniciar. El lobby guardado permanece disponible.\n" .. tostring(problem))
end
