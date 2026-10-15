-- Deliberately a ModuleScript: importing this model never runs the update.
-- apply() only operates in Studio's stopped edit mode. No purchases or stores.
local Installer = {}

local function fail(message)
	error("Color Chaos: " .. message, 0)
end

local function container(parent, name)
	local value = parent:FindFirstChild(name)
	if not value or not (value:IsA("Folder") or value:IsA("Model")) then
		fail("Falta la carpeta " .. name .. ". Importa de nuevo el modelo completo.")
	end
	return value
end

local function scriptsUnder(root)
	local result = {}
	if root:IsA("BaseScript") then table.insert(result, root) end
	for _, value in ipairs(root:GetDescendants()) do
		if value:IsA("BaseScript") then table.insert(result, value) end
	end
	return result
end

local function setDisabled(root, disabled)
	for _, value in ipairs(scriptsUnder(root)) do value.Disabled = disabled end
end

local function assertArchivable(root)
	if not root.Archivable then fail("Activa Archivable en todos los objetos del paquete antes de actualizar.") end
	for _, value in ipairs(root:GetDescendants()) do
		if not value.Archivable then fail("El paquete contiene un objeto que no puede copiarse. Importa de nuevo el modelo.") end
	end
end

local function assertDormant(root)
	for _, value in ipairs(scriptsUnder(root)) do
		if not value.Disabled then
			fail("El paquete contiene un script activo. No se ha cambiado tu juego.")
		end
	end
end

local function validateWorld(world)
	local spawn = world:FindFirstChild("LobbySpawn")
	local floor = world:FindFirstChild("Plaza del reactor")
	if not spawn or not spawn:IsA("SpawnLocation") or not spawn.Anchored or not spawn.Neutral then
		fail("El paquete no tiene el punto de aparición seguro del lobby.")
	end
	if not floor or not floor:IsA("BasePart") or not floor.Anchored or not floor.CanCollide then
		fail("El paquete no tiene el piso seguro del lobby.")
	end
	local top = floor.Position.Y + floor.Size.Y / 2
	if spawn.Position.Y <= top or spawn.Position.Y - top > 8
		or math.abs(spawn.Position.X - floor.Position.X) > floor.Size.X / 2 - spawn.Size.X / 2
		or math.abs(spawn.Position.Z - floor.Position.Z) > floor.Size.Z / 2 - spawn.Size.Z / 2 then
		fail("El punto de aparición está fuera del piso del lobby.")
	end
	if #scriptsUnder(world) > 0 then fail("El escenario contiene scripts inesperados.") end
end

local function backupName(storage)
	local base = "ColorChaosBackup_" .. os.date("!%Y%m%d_%H%M%S")
	local name, index = base, 1
	while storage:FindFirstChild(name) do
		index += 1
		name = base .. "_" .. tostring(index)
	end
	return name
end

function Installer.apply()
	local runService = game:GetService("RunService")
	if not runService:IsStudio() then fail("La actualización solo puede aplicarse en Roblox Studio.") end
	if runService:IsRunning() then fail("Pulsa Detener antes de actualizar. No actualices durante una partida.") end
	local package = script.Parent
	if not package or package.Name ~= "ColorChaosUpdate" then fail("Importa el modelo ColorChaosUpdate completo.") end
	local originalPackageParent = package.Parent
	assertDormant(package)
	assertArchivable(package)

	local replicated = game:GetService("ReplicatedStorage")
	local server = game:GetService("ServerScriptService")
	local starterScripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local storage = game:GetService("ServerStorage")
	local worldService = game:GetService("Workspace")
	local history = game:GetService("ChangeHistoryService")
	if not starterScripts then fail("No existe StarterPlayerScripts en este lugar.") end
	local oldShared = container(replicated, "ColorChaos")
	local oldConfig = oldShared:FindFirstChild("Config")
	if not oldConfig or not oldConfig:IsA("ModuleScript") then
		fail("Este lugar no contiene el Config de Color Chaos. Abre tu experiencia original.")
	end
	-- Never require oldConfig: retain its entire source without evaluating it or
	-- caching its old return value. IDs, store name and user's other settings stay.
	if not oldConfig.Archivable then fail("Activa Archivable en Config antes de actualizar.") end

	local replacements = {
		{ Parent = replicated, Name = "ColorChaos", Source = container(container(package, "ReplicatedStorage"), "ColorChaos") },
		{ Parent = server, Name = "ColorChaosServer", Source = container(container(package, "ServerScriptService"), "ColorChaosServer") },
		{ Parent = starterScripts, Name = "ColorChaosClient", Source = container(container(package, "StarterPlayerScripts"), "ColorChaosClient") },
		{ Parent = worldService, Name = "ColorChaosWorld", Source = container(container(package, "Workspace"), "ColorChaosWorld") },
	}
	validateWorld(replacements[4].Source)
	if #scriptsUnder(replacements[1].Source) > 0 then fail("ReplicatedStorage contiene scripts inesperados.") end
	local stagedConfig = replacements[1].Source:FindFirstChild("Config")
	if not stagedConfig or not stagedConfig:IsA("ModuleScript") then fail("El paquete no contiene un Config válido.") end
	if not replacements[2].Source:FindFirstChild("Main") or not replacements[2].Source.Main:IsA("Script") then
		fail("El paquete no contiene el servidor principal.")
	end
	if not replacements[3].Source:FindFirstChild("Main") or not replacements[3].Source.Main:IsA("LocalScript") then
		fail("El paquete no contiene la interfaz principal.")
	end
	-- Prepare every replacement before touching existing objects. A failed Clone
	-- or missing source cannot leave a partially changed experience.
	for _, entry in ipairs(replacements) do
		entry.Old = entry.Parent:FindFirstChild(entry.Name)
		if entry.Old and not (entry.Old:IsA("Folder") or entry.Old:IsA("Model")) then
			fail("El objeto existente " .. entry.Name .. " tiene una clase inesperada.")
		end
		entry.New = entry.Source:Clone()
		if not entry.New then fail("No se pudo copiar " .. entry.Name .. ".") end
		entry.New.Name = entry.Name
		setDisabled(entry.New, true)
	end
	local preservedConfig = oldConfig:Clone()
	if not preservedConfig then fail("No se pudo conservar tu Config.") end
	local configPlaceholder = replacements[1].New:FindFirstChild("Config")
	configPlaceholder:Destroy()
	preservedConfig.Parent = replacements[1].New
	validateWorld(replacements[4].New)

	local recording
	local began, token = pcall(function()
		return history:TryBeginRecording("ColorChaosLobbyUpdate", "Actualizar lobby de Color Chaos")
	end)
	if began then recording = token end
	if not recording then
		pcall(function() history:SetWaypoint("Antes de actualizar Color Chaos") end)
	end
	local backup = Instance.new("Folder")
	backup.Name = backupName(storage)
	local oldStates = {}
	local applied, reason = pcall(function()
		backup.Parent = storage
		for _, entry in ipairs(replacements) do
			if entry.Old then
				for _, oldScript in ipairs(scriptsUnder(entry.Old)) do
					table.insert(oldStates, { Script = oldScript, Disabled = oldScript.Disabled })
					oldScript.Disabled = true
				end
				entry.Old.Parent = backup
			end
			entry.New.Parent = entry.Parent
		end
		-- The staged scene contains solid parts and a neutral SpawnLocation.
		-- Keeping the dormant model in Workspace would still duplicate geometry
		-- and spawn candidates. Preserve it outside the active world instead.
		package.Parent = storage
		-- Only server and player scripts are enabled. The imported package and
		-- the backup remain dormant permanently until explicitly restored.
		setDisabled(replacements[2].New, false)
		setDisabled(replacements[3].New, false)
	end)
	if not applied then
		-- Restore original object identities, including their disabled flags.
		-- Keep the backup folder as an audit marker; no originals are destroyed.
		local rolledBack, rollbackReason = pcall(function()
			for _, entry in ipairs(replacements) do
				setDisabled(entry.New, true)
				if entry.New.Parent then entry.New.Parent = nil end
				if entry.Old then entry.Old.Parent = entry.Parent end
			end
			for _, oldState in ipairs(oldStates) do oldState.Script.Disabled = oldState.Disabled end
			package.Parent = originalPackageParent
		end)
		if recording then pcall(function() history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end) end
		if not rolledBack then
			fail("La actualización se detuvo y la restauración necesita revisión. Conserva " .. backup.Name
				.. ". No publiques este lugar. " .. tostring(rollbackReason))
		end
		fail("No se pudo aplicar la actualización; se restauraron los objetos originales. " .. tostring(reason))
	end
	if recording then
		local finished = pcall(function() history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end)
		if not finished then warn("Color Chaos: actualización instalada; usa la copia en ServerStorage si necesitas restaurarla.") end
	else
		pcall(function() history:SetWaypoint("Color Chaos actualizado") end)
	end
	-- Retain the package in ServerStorage: destroying an ancestor of this Module
	-- during require may disrupt the call, and a dormant source aids inspection.
	print("Color Chaos actualizado. Config conservado y copia local en ServerStorage: " .. backup.Name .. ". Publica esta misma experiencia.")
	return { Backup = backup.Name, Updated = true }
end

return Installer
