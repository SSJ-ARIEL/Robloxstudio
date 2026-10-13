-- Original, deterministic character catalog. No downloaded art or licensed characters.
-- Kept free of engine types so the complete catalog can be checked by the Luau CLI.
local Characters = {}

local palette = {
	{ 247, 77, 107 }, { 255, 160, 62 }, { 248, 213, 73 }, { 122, 218, 90 },
	{ 44, 201, 151 }, { 54, 193, 218 }, { 69, 136, 240 }, { 111, 98, 224 },
	{ 184, 103, 224 }, { 235, 106, 191 }, { 239, 132, 112 }, { 172, 198, 226 },
}
local archetypes = {
	{ "robot", "Autómata", { 172, 192, 214 }, "Helmet", { "Núcleo", "Órbita", "Bisagra", "Tuerca", "Pulso", "Vector", "Bóveda", "Circuito", "Dínamo", "Módulo" } },
	{ "alien", "Visitante", { 145, 218, 198 }, "Coat", { "Nimbo", "Zeta", "Quásar", "Nova", "Cometa", "Púlsar", "Lumen", "Vega", "Cenit", "Cosmo" } },
	{ "fox", "Zorro", { 220, 135, 83 }, "Coat", { "Junco", "Bruma", "Cobre", "Duna", "Castaño", "Sendero", "Brezal", "Pinar", "Otoño", "Mirador" } },
	{ "cat", "Gato", { 188, 179, 202 }, "Coat", { "Tiza", "Nube", "Ópalo", "Miga", "Ovillo", "Trébol", "Bigote", "Lino", "Sombra", "Mosaico" } },
	{ "bear", "Oso", { 158, 119, 88 }, "Coat", { "Avellana", "Roble", "Tronco", "Miel", "Cedro", "Pardo", "Mora", "Bambú", "Musgo", "Bellota" } },
	{ "rabbit", "Conejo", { 225, 215, 207 }, "Coat", { "Algodón", "Salto", "Pétalo", "Nabo", "Trebolín", "Copito", "Zanahoria", "Mimbre", "Nardo", "Alfalfa" } },
	{ "frog", "Rana", { 107, 183, 130 }, "Coat", { "Juncal", "Charco", "Loto", "Rocío", "Nenúfar", "Estanque", "Gota", "Mangle", "Humedal", "Sauce" } },
	{ "owl", "Búho", { 149, 133, 116 }, "Coat", { "Farol", "Vigía", "Noche", "Pluma", "Sabio", "Lucero", "Bosque", "Cálamo", "Estrella", "Campana" } },
	{ "panda", "Panda", { 232, 227, 213 }, "Coat", { "Tallo", "Jade", "Brote", "Nébula", "Ladera", "Cumbre", "Tinta", "Calma", "Papiro", "Bambusal" } },
	{ "penguin", "Pingüino", { 66, 80, 102 }, "Coat", { "Fiordo", "Copo", "Témpano", "Aurora", "Viento", "Escarcha", "Glaciar", "Polo", "Nevado", "Boreal" } },
	{ "axolotl", "Ajolote", { 232, 180, 203 }, "Coat", { "Coral", "Burbuja", "Laguna", "Alga", "Perla", "Acuario", "Rizo", "Arrecife", "Concha", "Nácar" } },
	{ "shark", "Tiburón", { 119, 158, 187 }, "Coat", { "Marea", "Oleaje", "Abisal", "Aleta", "Cresta", "Espuma", "Bahía", "Faro", "Cala", "Atolón" } },
	{ "dragon", "Dragón", { 163, 173, 126 }, "Coat", { "Ascua", "Pedernal", "Ventisca", "Cripta", "Chispa", "Basalto", "Crisol", "Escama", "Cuarzo", "Bramido" } },
	{ "golem", "Gólem", { 160, 160, 151 }, "Coat", { "Granito", "Mármol", "Estrato", "Cantera", "Guijarro", "Runa", "Sílex", "Pizarra", "Cristal", "Cimiento" } },
	{ "mushroom", "Micelio", { 230, 211, 179 }, "Helmet", { "Espora", "Sotobosque", "Sombrilla", "Llovizna", "Honguito", "Helecho", "Madera", "Tierra", "Hojarasca", "Amanecer" } },
	{ "astronaut", "Astronauta", { 185, 139, 112 }, "Coat", { "Horizonte", "Gravedad", "Satélite", "Crater", "Apogeo", "Galaxia", "Eclipse", "Tránsito", "Aster", "Zenit" } },
	{ "knight", "Guardián", { 205, 167, 131 }, "Helmet", { "Escudo", "Almena", "Baluarte", "Lanza", "Fortín", "Emblema", "Bastión", "Torre", "Justa", "Acero" } },
	{ "wizard", "Mago", { 169, 125, 101 }, "Coat", { "Sortilegio", "Pergamino", "Oráculo", "Arcano", "Sigilo", "Amuleto", "Espejo", "Astrolabio", "Runario", "Destello" } },
	{ "chef", "Chef", { 218, 166, 125 }, "Coat", { "Canela", "Tomillo", "Vainilla", "Azafrán", "Pimienta", "Romero", "Cacao", "Comino", "Laurel", "Jengibre" } },
	{ "diver", "Buzo", { 159, 110, 89 }, "Helmet", { "Profundo", "Inmersión", "Nautilo", "Sonda", "Muelle", "Boya", "Bajamar", "Estela", "Salitre", "Exploración" } },
	{ "racer", "Piloto", { 204, 152, 118 }, "Helmet", { "Turbo", "Chicane", "Apex", "Sprint", "Curva", "Ráfaga", "Vértice", "Circuito", "Impulso", "Bandera" } },
	{ "gardener", "Jardinero", { 187, 132, 100 }, "Coat", { "Semilla", "Huerto", "Surco", "Cosecha", "Flor", "Solana", "Raíz", "Abono", "Savia", "Regadera" } },
	{ "inventor", "Inventor", { 212, 175, 145 }, "Coat", { "Engranaje", "Resorte", "Plano", "Bobina", "Palanca", "Probeta", "Telescopio", "Turbina", "Imán", "Fuelle" } },
	{ "pirate", "Navegante", { 170, 123, 94 }, "Coat", { "Velero", "Timón", "Brújula", "Ancla", "Bitácora", "Barlovento", "Islote", "Cabo", "Bergantín", "Sextante" } },
	{ "explorer", "Explorador", { 230, 181, 146 }, "Coat", { "Mapa", "Cañón", "Senda", "Liana", "Derrumbe", "Campamento", "Cordillera", "Travesía", "Expedición", "Oasis" } },
}

local function freezeDeep(value)
	if type(value) ~= "table" then return value end
	for _, child in pairs(value) do freezeDeep(child) end
	return table.freeze(value)
end

Characters.All = {}
for archetypeIndex, definition in ipairs(archetypes) do
	for variant = 1, 10 do
		local id = (archetypeIndex - 1) * 10 + variant
		local hue = ((archetypeIndex * 5 + variant * 7 - 1) % #palette) + 1
		local accent = palette[((hue + 4) % #palette) + 1]
		local skin = definition[3]
		local warmth = ((variant - 1) % 5 - 2) * 5
		local character = {
			Id = id, Name = definition[2] .. " " .. definition[5][variant],
			Archetype = definition[1], Variant = variant, Hue = hue,
			TargetPart = definition[4], TargetRGB = table.clone(palette[hue]),
			SkinRGB = { math.clamp(skin[1] + warmth, 0, 255), math.clamp(skin[2] + warmth, 0, 255), math.clamp(skin[3] + warmth, 0, 255) },
			AccentRGB = table.clone(accent),
			-- Every variant changes silhouette/accessories, face and clothing geometry.
			HeadgearStyle = variant, EyeStyle = ((variant - 1) % 5) + 1,
			OutfitStyle = ((variant - 1) % 5) + 1, Hairstyle = ((variant - 1) % 6) + 1,
			PoseStyle = ((variant - 1) % 4) + 1, DetailStyle = ((variant - 1) % 5) + 1,
			BodyStyle = ((variant - 1) % 3) + 1,
		}
		Characters.All[id] = freezeDeep(character)
	end
end
table.freeze(Characters.All)

function Characters.get(id: any)
	if type(id) ~= "number" or id ~= id or id % 1 ~= 0 then return nil end
	return Characters.All[id]
end

Characters.Palette = freezeDeep(palette)
Characters.ArchetypeCount = #archetypes
return table.freeze(Characters)
