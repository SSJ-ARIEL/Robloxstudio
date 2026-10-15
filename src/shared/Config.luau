-- Configuration shared by the authoritative server and presentation client.
local Config = {}
Config.Version = "1.1.0"
Config.MaxCoins = 100000000
Config.MaxReceipts = 10000 -- stop NEW sales before receipt history approaches datastore limits
Config.XPPerRound = 15
Config.XPPerWin = 25
Config.DailyMissions = {
	{ Key = "play3", Name = "Colabora en 3 rondas", Metric = "Rounds", Target = 3, Reward = 30 },
	{ Key = "repair8", Name = "Completa 8 acciones de reparación", Metric = "Actions", Target = 8, Reward = 40 },
	{ Key = "win2", Name = "Consigue 2 victorias", Metric = "Wins", Target = 2, Reward = 50 },
}

-- Replace these four zeros with IDs created for THIS experience in Creator Hub.
-- Prices are set in Roblox, retrieved locally and confirmed by the native prompt.
Config.Commerce = {
	Products = {
		{ Key = "coins100", ProductId = 0, Name = "100 monedas", Coins = 100, Description = "100 monedas para comprar auras de resultado conocido." },
		{ Key = "coins400", ProductId = 0, Name = "400 monedas", Coins = 400, Description = "400 monedas para comprar auras de resultado conocido." },
		{ Key = "coins1000", ProductId = 0, Name = "1000 monedas", Coins = 1000, Description = "1000 monedas para comprar auras de resultado conocido." },
	},
	VIP = { Key = "vip", PassId = 0, Name = "VIP Prisma", Description = "Aura Prisma exclusiva y título VIP. Sin ventajas en los desafíos." },
}

Config.Intermission = 16
Config.RoundSeconds = 100
Config.ResultSeconds = 9
Config.MinimumPlayers = 1
Config.MaxParticipants = 12
Config.DataStoreName = "ColorChaos_Player_v1"
Config.SaveInterval = 75
Config.WinCoins = 35
Config.ParticipationCoins = 10
Config.InteractionDistance = 13
Config.Lava = { StartHeight = 10, EndHeight = 31, MaxLift = 12, HalfWidth = 80, MinZ = -110, MaxZ = 66 }
Config.Colors = {
	{ Name = "AZUL", Symbol = "A", Color = Color3.fromRGB(55, 155, 255) },
	{ Name = "AMARILLO", Symbol = "B", Color = Color3.fromRGB(255, 214, 66) },
	{ Name = "VERDE", Symbol = "C", Color = Color3.fromRGB(79, 224, 145) },
	{ Name = "ROJO", Symbol = "D", Color = Color3.fromRGB(255, 96, 106) },
}
Config.Palettes = {
	{ Name = "CLÁSICA", Cost = 0, Color = Color3.fromRGB(55, 155, 255) },
	{ Name = "MENTA", Cost = 80, Color = Color3.fromRGB(79, 224, 145) },
	{ Name = "SOLAR", Cost = 150, Color = Color3.fromRGB(255, 214, 66) },
	{ Name = "ROSADA", Cost = 220, Color = Color3.fromRGB(255, 115, 205) },
	{ Name = "PRISMA VIP", Cost = 0, Access = "VIP", Color = Color3.fromRGB(203, 148, 255) },
	{ Name = "LAVANDA", Cost = 350, Color = Color3.fromRGB(190, 125, 255) },
	{ Name = "OCÉANO + ESTELA", Cost = 500, Trail = true, Color = Color3.fromRGB(55, 222, 245) },
	{ Name = "COMETA + ESTELA", Cost = 1000, Trail = true, Color = Color3.fromRGB(255, 160, 70) },
}
Config.Modes = {
	{ Id = "memory", Name = "PUENTES DE MEMORIA", Hint = "Mira la secuencia y activa sus letras en orden. Cada acierto crea un puente." },
	{ Id = "relay", Name = "REPARACIÓN EN EQUIPO", Hint = "Busca el color indicado y repara su estación. Todos comparten el objetivo." },
	{ Id = "rescue", Name = "RESCATE CROMÁTICO", Hint = "Activa el color indicado para crear un camino. Recoge su chispa y llévala al reactor." },
}

return Config
