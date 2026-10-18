-- Original cosmetic descriptions; prices buy this exact item, never a random box.
local Catalog = {}
Catalog.Defaults = { Suit = "suit_base", Emote = "emote_wave", Reaction = "reaction_star", Trail = "trail_none" }
Catalog.Items = {
	{ Id = "suit_base", Kind = "Suit", Name = "Tu avatar", Style = "None", Color = { 241, 245, 255 }, Accent = { 92, 177, 255 }, Currency = "Coins", Cost = 0 },
	{ Id = "suit_mint", Kind = "Suit", Name = "Explorador Menta", Style = "Garden", Color = { 74, 219, 169 }, Accent = { 255, 236, 139 }, Currency = "Gems", Cost = 40 },
	{ Id = "suit_nova", Kind = "Suit", Name = "Astronauta Nova", Style = "Astronaut", Color = { 106, 136, 255 }, Accent = { 255, 240, 180 }, Currency = "Coins", Cost = 180 },
	{ Id = "suit_coral", Kind = "Suit", Name = "Piloto Coral", Style = "Pilot", Color = { 255, 133, 140 }, Accent = { 255, 232, 176 }, Currency = "Coins", Cost = 240 },
	{ Id = "suit_glacier", Kind = "Suit", Name = "Explorador Glaciar", Style = "Explorer", Color = { 139, 222, 255 }, Accent = { 232, 246, 255 }, Currency = "Gems", Cost = 75 },
	{ Id = "suit_garden", Kind = "Suit", Name = "Guardián Jardín", Style = "Garden", Color = { 160, 213, 106 }, Accent = { 237, 159, 255 }, Currency = "Coins", Cost = 400 },
	{ Id = "suit_meteor", Kind = "Suit", Name = "Caballero Meteoro", Style = "Knight", Color = { 255, 171, 84 }, Accent = { 114, 100, 220 }, Currency = "Gems", Cost = 120 },
	{ Id = "suit_prism", Kind = "Suit", Name = "Centinela Prisma VIP", Style = "Prism", Color = { 191, 147, 255 }, Accent = { 89, 239, 231 }, Currency = "Coins", Cost = 0, Access = "VIP" },
	{ Id = "emote_wave", Kind = "Emote", Name = "Saludo", Style = "Wave", Color = { 122, 209, 255 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 0 },
	{ Id = "emote_cheer", Kind = "Emote", Name = "¡Lo logramos!", Style = "Cheer", Color = { 255, 219, 111 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 80 },
	{ Id = "emote_dance", Kind = "Emote", Name = "Baile Prisma", Style = "Dance", Color = { 210, 142, 255 }, Accent = { 255, 195, 230 }, Currency = "Coins", Cost = 140 },
	{ Id = "emote_spark", Kind = "Emote", Name = "Vuelta Estelar", Style = "Spin", Color = { 116, 230, 217 }, Accent = { 255, 235, 123 }, Currency = "Gems", Cost = 35 },
	{ Id = "emote_bow", Kind = "Emote", Name = "Reverencia", Style = "Bow", Color = { 255, 166, 204 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 200 },
	{ Id = "emote_float", Kind = "Emote", Name = "Órbita", Style = "Float", Color = { 150, 186, 255 }, Accent = { 223, 235, 255 }, Currency = "Gems", Cost = 65 },
	{ Id = "reaction_star", Kind = "Reaction", Name = "Estrella", Style = "Star", Glyph = "★", Color = { 255, 223, 111 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 0 },
	{ Id = "reaction_heart", Kind = "Reaction", Name = "Corazón", Style = "Heart", Glyph = "♥", Color = { 255, 141, 181 }, Accent = { 255, 225, 237 }, Currency = "Gems", Cost = 25 },
	{ Id = "reaction_wow", Kind = "Reaction", Name = "¡Wow!", Style = "Wow", Glyph = "¡WOW!", Color = { 129, 216, 255 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 60 },
	{ Id = "reaction_gg", Kind = "Reaction", Name = "Buena partida", Style = "GG", Glyph = "GG", Color = { 144, 239, 174 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 90 },
	{ Id = "reaction_laugh", Kind = "Reaction", Name = "¡Jajaja!", Style = "Laugh", Glyph = "JAJA", Color = { 255, 217, 121 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 110 },
	{ Id = "reaction_spark", Kind = "Reaction", Name = "Destello", Style = "Spark", Glyph = "✦", Color = { 189, 153, 255 }, Accent = { 245, 229, 255 }, Currency = "Gems", Cost = 30 },
	{ Id = "reaction_fire", Kind = "Reaction", Name = "¡En racha!", Style = "Fire", Glyph = "¡RACHA!", Color = { 255, 153, 83 }, Accent = { 255, 230, 117 }, Currency = "Coins", Cost = 180 },
	{ Id = "reaction_rainbow", Kind = "Reaction", Name = "Prisma", Style = "Rainbow", Glyph = "PRISMA", Color = { 125, 235, 226 }, Accent = { 255, 161, 220 }, Currency = "Gems", Cost = 45 },
	{ Id = "trail_none", Kind = "Trail", Name = "Sin estela", Style = "None", Color = { 255, 255, 255 }, Accent = { 255, 255, 255 }, Currency = "Coins", Cost = 0 },
	{ Id = "trail_mint", Kind = "Trail", Name = "Brisa Menta", Style = "Ribbon", Color = { 96, 232, 185 }, Accent = { 201, 255, 228 }, Currency = "Coins", Cost = 100 },
	{ Id = "trail_comet", Kind = "Trail", Name = "Cometa", Style = "Comet", Color = { 255, 163, 86 }, Accent = { 255, 234, 155 }, Currency = "Coins", Cost = 300 },
	{ Id = "trail_ocean", Kind = "Trail", Name = "Marea Celeste", Style = "Ribbon", Color = { 97, 208, 255 }, Accent = { 178, 177, 255 }, Currency = "Gems", Cost = 55 },
	{ Id = "trail_solar", Kind = "Trail", Name = "Polvo Solar", Style = "Comet", Color = { 255, 221, 104 }, Accent = { 255, 153, 167 }, Currency = "Gems", Cost = 80 },
	{ Id = "trail_rainbow", Kind = "Trail", Name = "Estela Prisma VIP", Style = "Prism", Color = { 191, 147, 255 }, Accent = { 89, 239, 231 }, Currency = "Coins", Cost = 0, Access = "VIP" },
}
Catalog.ById = {}
Catalog.RewardPools = { Suit = {}, Emote = {}, Reaction = {} }
for _, item in ipairs(Catalog.Items) do
	assert(Catalog.ById[item.Id] == nil, "Duplicate cosmetic ID")
	Catalog.ById[item.Id] = item
	local pool = Catalog.RewardPools[item.Kind]
	if pool and item.Cost > 0 and item.Access ~= "VIP" then table.insert(pool, item.Id) end
	table.freeze(item.Color)
	table.freeze(item.Accent)
	table.freeze(item)
end
for _, pool in pairs(Catalog.RewardPools) do table.freeze(pool) end
table.freeze(Catalog.RewardPools)
table.freeze(Catalog.ById)
table.freeze(Catalog.Defaults)
table.freeze(Catalog.Items)
return table.freeze(Catalog)
