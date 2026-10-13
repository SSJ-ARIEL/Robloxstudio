-- CLI checks validate catalog integrity and actual geometric variation, not engine rendering.
local Characters = require("../src/shared/Characters")
local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS " .. name)
end
local function validRGB(color)
	if type(color) ~= "table" or #color ~= 3 then return false end
	for _, channel in ipairs(color) do
		if type(channel) ~= "number" or channel % 1 ~= 0 or channel < 0 or channel > 255 then return false end
	end
	return true
end
check("exactly 250 original character configurations", #Characters.All == 250)
check("exactly 25 archetypes", Characters.ArchetypeCount == 25)
local names, ids, families, hueCounts = {}, {}, {}, {}
for index, character in ipairs(Characters.All) do
	assert(character.Id == index and not ids[character.Id], "IDs must be dense and unique")
	assert(type(character.Name) == "string" and #character.Name > 5 and not names[character.Name], "Names must be meaningful and unique")
	assert(Characters.get(character.Id) == character, "Lookup must preserve frozen catalog identity")
	assert(character.TargetPart == "Coat" or character.TargetPart == "Helmet", "Target area must be renderable")
	assert(validRGB(character.TargetRGB) and validRGB(character.SkinRGB) and validRGB(character.AccentRGB), "Colors must be RGB24")
	assert(table.isfrozen(character) and table.isfrozen(character.TargetRGB), "Catalog data must be immutable")
	assert(character.Variant >= 1 and character.Variant <= 10 and character.Variant % 1 == 0, "Variant range")
	assert(character.Hue >= 1 and character.Hue <= #Characters.Palette, "Hue palette reference")
	assert(character.TargetRGB[1] == Characters.Palette[character.Hue][1] and character.TargetRGB[2] == Characters.Palette[character.Hue][2] and character.TargetRGB[3] == Characters.Palette[character.Hue][3], "Target color agrees with palette")
	names[character.Name], ids[character.Id] = true, true
	if not families[character.Archetype] then families[character.Archetype] = {} end
	local family = families[character.Archetype]
	assert(not family[character.Variant], "Each family variant must be unique")
	family[character.Variant] = character
	hueCounts[character.Hue] = (hueCounts[character.Hue] or 0) + 1
end
check("dense IDs and all names unique", #Characters.All == 250)
check("all target, skin and accent colors are RGB24", true)
check("all entries have a supported target and palette mapping", true)
check("configuration and nested color data cannot be mutated", table.isfrozen(Characters.All))
local familyCount = 0
for _, family in pairs(families) do
	familyCount += 1
	assert(#family == 10, "Every archetype requires ten variants")
	local geometrySignatures = {}
	for _, character in ipairs(family) do
		local signature = table.concat({ character.HeadgearStyle, character.EyeStyle, character.OutfitStyle, character.Hairstyle, character.PoseStyle, character.BodyStyle }, ":")
		assert(not geometrySignatures[signature], "Variants must differ in geometry, not only colors")
		geometrySignatures[signature] = true
	end
	for index = 1, 9 do
		local left, right = family[index], family[index + 1]
		local changed = 0
		for _, field in ipairs({ "HeadgearStyle", "EyeStyle", "OutfitStyle", "Hairstyle", "PoseStyle", "BodyStyle" }) do
			if left[field] ~= right[field] then changed += 1 end
		end
		assert(changed >= 3, "Neighboring variants require three composition changes")
	end
end
check("all 25 families contain exactly ten variants", familyCount == 25)
check("all variants differ geometrically and change at least three composition fields", true)
local low, high = 1000, 0
for hue = 1, #Characters.Palette do
	assert(hueCounts[hue], "Every palette color must be used")
	low, high = math.min(low, hueCounts[hue]), math.max(high, hueCounts[hue])
end
check("target color distribution stays balanced", high - low <= 2)
local invalidIds: { any } = { 0, -1, 251, 1.5, math.huge, "1", false }
for _, invalid in ipairs(invalidIds) do
	assert(Characters.get(invalid) == nil, "Invalid IDs must fail safely")
end
check("invalid IDs do not select characters", Characters.get(0 / 0) == nil and Characters.get(nil) == nil)
local ok = pcall(function() Characters.get(1).TargetRGB[1] = 0 end)
check("a caller cannot recolor the shared catalog", not ok)
print("Characters: " .. passed .. " checks passed")
