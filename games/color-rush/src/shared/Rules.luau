-- Pure selection and race rules; clients never determine eliminations or wins.
local Rules = {}
local function validRGB(rgb)
	if type(rgb) ~= "table" then return false end
	for i = 1, 3 do
		if type(rgb[i]) ~= "number" or rgb[i] ~= rgb[i] or rgb[i] % 1 ~= 0 or rgb[i] < 0 or rgb[i] > 255 then return false end
	end
	return true
end
local function key(rgb) return table.concat(rgb, ",") end
local function distance(a, b)
	return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end

function Rules.options(target, palette, difficulty, randomIndex)
	assert(validRGB(target), "Invalid target color")
	local candidates, seen = {}, { [key(target)] = true }
	for _, rgb in ipairs(palette) do
		if validRGB(rgb) and not seen[key(rgb)] then
			seen[key(rgb)] = true
			table.insert(candidates, table.clone(rgb))
		end
	end
	assert(#candidates >= 4, "At least four unique distractors required")
	table.sort(candidates, function(a, b)
		local da, db = distance(target, a), distance(target, b)
		if da == db then return key(a) < key(b) end
		return da > db
	end)
	local choices = { table.clone(target) }
	local pool = {}
	-- Later rounds include a nearby shade, while preserving exactly one match.
	if difficulty >= 4 then table.insert(choices, table.clone(candidates[#candidates])); table.remove(candidates) end
	for i = 1, math.max(4, math.ceil(#candidates * 0.75)) do
		if candidates[i] then table.insert(pool, candidates[i]) end
	end
	while #choices < 5 do
		local index = randomIndex(1, #pool)
		table.insert(choices, table.remove(pool, index))
	end
	for i = #choices, 2, -1 do
		local j = randomIndex(1, i)
		choices[i], choices[j] = choices[j], choices[i]
	end
	local correct = nil
	for i, rgb in ipairs(choices) do if key(rgb) == key(target) then correct = i end end
	return choices, correct
end

function Rules.classify(choice, correct)
	if type(choice) ~= "number" or choice % 1 ~= 0 or choice < 1 or choice > 5 then return "ignored" end
	return choice == correct and "correct" or "wrong"
end

function Rules.eligibleRevive(entry, phase, winnerDeclared, maxRevives)
	return entry ~= nil and entry.Alive == false and entry.QueuedRevive ~= true
		and (entry.RevivesUsed or 0) < maxRevives and winnerDeclared ~= true
		and (phase == "RUN" or phase == "REVEAL")
end

function Rules.count(entries)
	local alive, queued = 0, 0
	for _, entry in pairs(entries) do
		if entry.Alive then alive += 1 elseif entry.QueuedRevive then queued += 1 end
	end
	return alive, queued
end

function Rules.isFinal(alive, round, maxNormalRounds)
	return alive == 2 or round > maxNormalRounds
end

return Rules
