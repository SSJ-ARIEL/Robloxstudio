-- Server-owned geometry and question rules. Pure data makes them independently testable.
local Characters = if script then require(script.Parent.Characters) else require("./Characters")
local GameRules = {}

local DEFAULT_LANES = { -40, -20, 0, 20, 40 }
local DISTRACTORS = Characters.Palette
local MINIMUM_COLOR_DISTANCE_SQUARED = 70 * 70

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function sameRGB(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

local function distinctColor(a, b)
	local r, g, blue = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return r * r + g * g + blue * blue >= MINIMUM_COLOR_DISTANCE_SQUARED
end

local function copyRGB(rgb)
	assert(type(rgb) == "table", "Character must define a target RGB color")
	local copy = {}
	for index = 1, 3 do
		assert(finite(rgb[index]) and rgb[index] >= 0 and rgb[index] <= 255, "Invalid target RGB channel")
		copy[index] = math.floor(rgb[index])
	end
	return copy
end

function GameRules.stageCoordinates(index, _settings)
	assert(finite(index) and index >= 1 and index % 1 == 0, "Invalid stage number")
	local start = -40 - (index - 1) * 112
	return { StartZ = start, GateZ = start - 48, EndZ = start - 82 }
end

function GameRules.generateQuestion(character, random)
	assert(type(character) == "table" and character.Id ~= nil, "Missing character")
	assert(random and type(random.NextInteger) == "function", "Question requires server randomness")
	local original = copyRGB(character.ColorRGB or character.TargetRGB)
	local available = {}
	for _, color in ipairs(DISTRACTORS) do
		if distinctColor(color, original) then table.insert(available, table.clone(color)) end
	end
	-- Sampling without replacement prevents repeated alternatives, even for adversarial RNG mocks.
	local choices = { table.clone(original) }
	for _ = 1, 4 do
		assert(#available > 0, "Character palette lacks five clearly distinct alternatives")
		local choice = table.remove(available, random:NextInteger(1, #available))
		table.insert(choices, choice)
		for index = #available, 1, -1 do
			if not distinctColor(available[index], choice) then table.remove(available, index) end
		end
	end
	for index = #choices, 2, -1 do
		local other = random:NextInteger(1, index)
		choices[index], choices[other] = choices[other], choices[index]
	end
	local correct, wrongOptions = nil, {}
	for index, color in ipairs(choices) do
		if sameRGB(color, original) then correct = index else table.insert(wrongOptions, color) end
	end
	return {
		CharacterId = character.Id, Choices = choices, CorrectLane = correct,
		WrongRGB = table.clone(wrongOptions[random:NextInteger(1, #wrongOptions)]),
		OriginalRGB = original,
	}
end

function GameRules.validChoice(position, stage, elapsed, settings)
	settings = settings or {}
	local minimum = settings.MinimumChoiceSeconds or 1.5
	if not finite(elapsed) or elapsed < minimum or position == nil then return nil end
	local x, y, z = position.X or position.x, position.Y or position.y, position.Z or position.z
	if not finite(x) or not finite(y) or not finite(z) then return nil end
	local coordinates = type(stage) == "number" and GameRules.stageCoordinates(stage) or stage
	if type(coordinates) ~= "table" or not finite(coordinates.GateZ) then return nil end
	if y < 7 or y > 20 or z < coordinates.GateZ + 4 or z > coordinates.GateZ + 16 then return nil end
	for lane, laneX in ipairs(settings.LaneX or DEFAULT_LANES) do
		if math.abs(x - laneX) <= 8 then return lane end
	end
	return nil
end

function GameRules.rankRoom(entries)
	local rows = {}
	for _, entry in pairs(entries) do
		if type(entry) == "table" and entry.Eligible ~= false and not entry.Ghost
			and finite(entry.UserId) and entry.UserId > 0 and entry.UserId % 1 == 0 then
			local row = table.clone(entry)
			row.CorrectThisMatch = finite(row.CorrectThisMatch) and math.max(0, math.floor(row.CorrectThisMatch)) or 0
			row.LastChoiceAt = finite(row.LastChoiceAt) and row.LastChoiceAt or math.huge
			table.insert(rows, row)
		end
	end
	table.sort(rows, function(a, b)
		if a.CorrectThisMatch ~= b.CorrectThisMatch then return a.CorrectThisMatch > b.CorrectThisMatch end
		if a.LastChoiceAt ~= b.LastChoiceAt then return a.LastChoiceAt < b.LastChoiceAt end
		return a.UserId < b.UserId
	end)
	for position, row in ipairs(rows) do row.Place = position end
	return rows
end

return table.freeze(GameRules)
