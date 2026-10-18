-- Ciudad Prisma's original toy citizens. Catalog data is independent of Roblox services.
local Characters = {}
local palette = {
	{ 244, 86, 116 }, { 255, 164, 66 }, { 250, 214, 78 }, { 143, 216, 94 },
	{ 57, 202, 163 }, { 66, 192, 225 }, { 79, 141, 243 }, { 123, 107, 231 },
	{ 188, 115, 230 }, { 237, 119, 195 }, { 232, 141, 108 }, { 155, 195, 229 },
}
-- Family, Spanish label, complexion, variable region, ten original citizen names.
local families = {
	{ "robot", "Autómata", { 173, 192, 214 }, "Helmet", { "Núcleo", "Órbita", "Bisagra", "Tuerca", "Pulso", "Vector", "Bóveda", "Circuito", "Dínamo", "Módulo" } },
	{ "alien", "Visitante", { 149, 218, 198 }, "Coat", { "Nimbo", "Zeta", "Quásar", "Nova", "Cometa", "Púlsar", "Lumen", "Vega", "Cenit", "Cosmo" } },
	{ "fox", "Zorro", { 225, 144, 91 }, "Coat", { "Junco", "Bruma", "Cobre", "Duna", "Castaño", "Sendero", "Brezal", "Pinar", "Otoño", "Mirador" } },
	{ "cat", "Gato", { 195, 188, 214 }, "Coat", { "Tiza", "Nube", "Ópalo", "Miga", "Ovillo", "Trébol", "Bigote", "Lino", "Sombra", "Mosaico" } },
	{ "bear", "Oso", { 167, 128, 96 }, "Coat", { "Avellana", "Roble", "Tronco", "Miel", "Cedro", "Pardo", "Mora", "Bambú", "Musgo", "Bellota" } },
	{ "rabbit", "Conejo", { 230, 221, 213 }, "Coat", { "Algodón", "Salto", "Pétalo", "Nabo", "Trebolín", "Copito", "Zanahoria", "Mimbre", "Nardo", "Alfalfa" } },
	{ "frog", "Rana", { 119, 191, 138 }, "Coat", { "Juncal", "Charco", "Loto", "Rocío", "Nenúfar", "Estanque", "Gota", "Mangle", "Humedal", "Sauce" } },
	{ "owl", "Búho", { 159, 143, 126 }, "Coat", { "Farol", "Vigía", "Noche", "Pluma", "Sabio", "Lucero", "Bosque", "Cálamo", "Estrella", "Campana" } },
	{ "panda", "Panda", { 239, 233, 219 }, "Coat", { "Tallo", "Jade", "Brote", "Nébula", "Ladera", "Cumbre", "Tinta", "Calma", "Papiro", "Bambusal" } },
	{ "penguin", "Pingüino", { 70, 86, 110 }, "Coat", { "Fiordo", "Copo", "Témpano", "Aurora", "Viento", "Escarcha", "Glaciar", "Polo", "Nevado", "Boreal" } },
	{ "axolotl", "Ajolote", { 236, 188, 209 }, "Coat", { "Coral", "Burbuja", "Laguna", "Alga", "Perla", "Acuario", "Rizo", "Arrecife", "Concha", "Nácar" } },
	{ "shark", "Tiburón", { 128, 166, 193 }, "Coat", { "Marea", "Oleaje", "Abisal", "Aleta", "Cresta", "Espuma", "Bahía", "Faro", "Cala", "Atolón" } },
	{ "dragon", "Dragón", { 167, 183, 132 }, "Coat", { "Ascua", "Pedernal", "Ventisca", "Cripta", "Chispa", "Basalto", "Crisol", "Escama", "Cuarzo", "Bramido" } },
	{ "golem", "Gólem", { 168, 172, 165 }, "Coat", { "Granito", "Mármol", "Estrato", "Cantera", "Guijarro", "Runa", "Sílex", "Pizarra", "Cristal", "Cimiento" } },
	{ "mushroom", "Micelio", { 237, 217, 185 }, "Helmet", { "Espora", "Sotobosque", "Sombrilla", "Llovizna", "Honguito", "Helecho", "Madera", "Tierra", "Hojarasca", "Amanecer" } },
	{ "astronaut", "Astronauta", { 192, 147, 120 }, "Coat", { "Horizonte", "Gravedad", "Satélite", "Cráter", "Apogeo", "Galaxia", "Eclipse", "Tránsito", "Aster", "Zenit" } },
	{ "knight", "Guardián", { 213, 175, 139 }, "Helmet", { "Escudo", "Almena", "Baluarte", "Lanza", "Fortín", "Emblema", "Bastión", "Torre", "Justa", "Acero" } },
	{ "wizard", "Mago", { 179, 136, 113 }, "Coat", { "Sortilegio", "Pergamino", "Oráculo", "Arcano", "Sigilo", "Amuleto", "Espejo", "Astrolabio", "Runario", "Destello" } },
	{ "chef", "Chef", { 224, 174, 133 }, "Coat", { "Canela", "Tomillo", "Vainilla", "Azafrán", "Pimienta", "Romero", "Cacao", "Comino", "Laurel", "Jengibre" } },
	{ "diver", "Buzo", { 169, 121, 100 }, "Helmet", { "Profundo", "Inmersión", "Nautilo", "Sonda", "Muelle", "Boya", "Bajamar", "Estela", "Salitre", "Exploración" } },
	{ "racer", "Piloto", { 214, 162, 129 }, "Helmet", { "Turbo", "Chicane", "Apex", "Sprint", "Curva", "Ráfaga", "Vértice", "Circuito", "Impulso", "Bandera" } },
	{ "gardener", "Jardinero", { 197, 143, 111 }, "Coat", { "Semilla", "Huerto", "Surco", "Cosecha", "Flor", "Solana", "Raíz", "Abono", "Savia", "Regadera" } },
	{ "inventor", "Inventor", { 220, 183, 153 }, "Coat", { "Engranaje", "Resorte", "Plano", "Bobina", "Palanca", "Probeta", "Telescopio", "Turbina", "Imán", "Fuelle" } },
	{ "pirate", "Navegante", { 181, 134, 105 }, "Coat", { "Velero", "Timón", "Brújula", "Ancla", "Bitácora", "Barlovento", "Islote", "Cabo", "Bergantín", "Sextante" } },
	{ "explorer", "Explorador", { 237, 189, 154 }, "Coat", { "Mapa", "Cañón", "Senda", "Liana", "Derrumbe", "Campamento", "Cordillera", "Travesía", "Expedición", "Oasis" } },
}
local function frozen(value)
	if type(value) == "table" then
		for _, child in pairs(value) do frozen(child) end
		if not table.isfrozen(value) then table.freeze(value) end
	end
	return value
end
Characters.All = {}
for familyIndex, family in ipairs(families) do
	for variant = 1, 10 do
		local id = (familyIndex - 1) * 10 + variant
		local hue = ((familyIndex * 5 + variant * 7 - 1) % #palette) + 1
		local shift = ((variant - 1) % 5 - 2) * 5
		local target = table.clone(palette[hue])
		Characters.All[id] = frozen({
			Id = id, Name = family[2] .. " " .. family[5][variant], Family = family[2], Archetype = family[1],
			Variant = variant, Hue = hue, TargetPart = family[4], TargetRGB = target, ColorRGB = target,
			ColorArea = if family[4] == "Helmet" then (if family[1] == "mushroom" then "Sombrero" else "Casco") else "Chaqueta",
			SkinRGB = { math.clamp(family[3][1] + shift, 0, 255), math.clamp(family[3][2] + shift, 0, 255), math.clamp(family[3][3] + shift, 0, 255) },
			AccentRGB = table.clone(palette[((hue + 4) % #palette) + 1]),
			EyeStyle = (variant - 1) % 5 + 1, OutfitStyle = (variant - 1) % 5 + 1,
			PoseStyle = (variant - 1) % 4 + 1, BodyStyle = (variant - 1) % 3 + 1,
		})
	end
end
frozen(Characters.All)
Characters.Palette = frozen(palette)
Characters.ArchetypeCount = #families
function Characters.get(id)
	if type(id) ~= "number" or id ~= id or id % 1 ~= 0 then return nil end
	return Characters.All[id]
end
function Characters.all() return Characters.All end
function Characters.count() return #Characters.All end
return table.freeze(Characters)
