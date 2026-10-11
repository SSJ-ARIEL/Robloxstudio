-- Configuration shared by the authoritative server and presentation client.
local Config = {}

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
}
Config.Modes = {
	{ Id = "memory", Name = "PUENTES DE MEMORIA", Hint = "Mira la secuencia y activa sus letras en orden. Cada acierto crea un puente." },
	{ Id = "relay", Name = "REPARACIÓN EN EQUIPO", Hint = "Busca el color indicado y repara su estación. Todos comparten el objetivo." },
	{ Id = "rescue", Name = "RESCATE CROMÁTICO", Hint = "Activa el color indicado para crear un camino. Recoge su chispa y llévala al reactor." },
}

return Config
