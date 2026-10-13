local Config = {}
Config.Version = "1.0.0"
Config.Title = "Color Rush: Corre y Recuerda"
Config.MinimumPlayers = 2
Config.MaxParticipants = 20
Config.Intermission = 18
Config.PreviewSeconds = 2
Config.RunSeconds = 12
Config.FinalSeconds = 18
Config.RevealSeconds = 4
Config.ResultSeconds = 9
Config.MaxNormalRounds = 7
Config.MaxAllWrongRepeats = 1
Config.MaxRevivesPerMatch = 1
Config.MaxCoins = 100000000
Config.MaxReviveCredits = 1000
Config.MaxReceipts = 10000
Config.DataStoreName = "ColorRush_Player_v1"
Config.SaveInterval = 75
Config.ParticipationCoins = 10
Config.CorrectCoins = 8
Config.WinnerCoins = 60
Config.XPPerRound = 15
Config.XPPerWin = 35
Config.GateDistance = 14
Config.MinimumTravelSeconds = 3.5
Config.LaneX = { -28, -14, 0, 14, 28 }
Config.DailyMissions = {
	{ Key = "run3", Name = "Participa en 3 carreras", Metric = "Rounds", Target = 3, Reward = 30 },
	{ Key = "correct8", Name = "Acierta 8 puertas", Metric = "Actions", Target = 8, Reward = 45 },
	{ Key = "win1", Name = "Gana una carrera", Metric = "Wins", Target = 1, Reward = 60 },
}
Config.Trails = {
	{ Name = "SIN ESTELA", Cost = 0, ColorRGB = { 90, 160, 255 }, Style = "none" },
	{ Name = "MENTA", Cost = 60, ColorRGB = { 82, 232, 167 }, Style = "ribbon" },
	{ Name = "SOLAR", Cost = 160, ColorRGB = { 255, 213, 68 }, Style = "ribbon" },
	{ Name = "NEBULOSA", Cost = 350, ColorRGB = { 186, 127, 255 }, Style = "double" },
	{ Name = "PRISMA VIP", Cost = 0, Access = "VIP", ColorRGB = { 214, 172, 255 }, Style = "prisma" },
	{ Name = "COMETA", Cost = 650, ColorRGB = { 255, 141, 66 }, Style = "double" },
	{ Name = "DIAMANTE", Cost = 1000, ColorRGB = { 115, 225, 255 }, Style = "double" },
}
-- Starting price recommendations only. Actual prices are set in Creator Hub.
-- Configure FIVE ProductIds and ONE PassId belonging to this new experience.
Config.Commerce = {
	Products = {
		{ Key = "revive1", Name = "1 crédito de reentrada", ProductId = 0, Coins = 0, Credits = 1, SuggestedPrice = 9, Description = "Un crédito guardado. Una reentrada por partida; no revoca una victoria." },
		{ Key = "revive3", Name = "3 créditos de reentrada", ProductId = 0, Coins = 0, Credits = 3, SuggestedPrice = 25, Description = "Tres créditos para distintas partidas. El límite sigue siendo uno por partida." },
		{ Key = "coins200", Name = "200 monedas", ProductId = 0, Coins = 200, Credits = 0, SuggestedPrice = 19, Description = "200 monedas para estelas cosméticas de resultado conocido." },
		{ Key = "coins800", Name = "800 monedas", ProductId = 0, Coins = 800, Credits = 0, SuggestedPrice = 59, Description = "800 monedas para estelas cosméticas de resultado conocido." },
		{ Key = "coins2000", Name = "2000 monedas", ProductId = 0, Coins = 2000, Credits = 0, SuggestedPrice = 99, Description = "2000 monedas para estelas cosméticas de resultado conocido." },
	},
	VIP = { Key = "vip", PassId = 0, Name = "VIP Prisma", SuggestedPrice = 79, Description = "Estela Prisma exclusiva y título VIP. No revela respuestas ni incluye reentradas ilimitadas." },
}
return Config
