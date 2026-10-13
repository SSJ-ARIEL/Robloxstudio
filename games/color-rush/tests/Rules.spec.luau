-- Pure race rules: authoritative choices, finite elimination and reentry limits.
local Rules = require("../src/shared/Rules")
local passed = 0
local function check(name, condition)
	assert(condition, name)
	passed += 1
	print("PASS rules: " .. name)
end
local function colorKey(rgb) return table.concat(rgb, ",") end
local target = { 110, 170, 240 }
local palette = {
	{ 0, 0, 0 }, { 255, 255, 255 }, { 255, 40, 20 },
	{ 20, 240, 40 }, { 110, 170, 241 }, { 20, 60, 255 },
	{ 230, 70, 210 }, { 255, 180, 0 },
}
local seed = 71
local function randomIndex(lo, hi)
	seed = (seed * 48271) % 2147483647
	return lo + seed % (hi - lo + 1)
end

do
	local everyValid, correctPositions = true, {}
	for difficulty = 1, 10 do
		for _ = 1, 20 do
			local choices, correct = Rules.options(target, palette, difficulty, randomIndex)
			local seen, targetCount = {}, 0
			everyValid = everyValid and #choices == 5 and correct >= 1 and correct <= 5
			for index, rgb in ipairs(choices) do
				local key = colorKey(rgb)
				everyValid = everyValid and seen[key] == nil
				seen[key] = true
				if key == colorKey(target) then targetCount += 1; everyValid = everyValid and index == correct end
			end
			everyValid = everyValid and targetCount == 1
			correctPositions[correct] = true
		end
	end
	check("five distinct options contain exactly one target across 200 randomized rounds", everyValid)
	check("shuffle can place the correct image in every lane", correctPositions[1] and correctPositions[2] and correctPositions[3] and correctPositions[4] and correctPositions[5])
end

do
	local choices = Rules.options(target, palette, 4, randomIndex)
	local nearby = false
	for _, rgb in ipairs(choices) do if colorKey(rgb) == "110,170,241" then nearby = true end end
	check("later rounds include a distinct nearby shade", nearby)
	choices[1][1] = 99
	check("generated choices cannot mutate target or palette", target[1] == 110 and palette[1][1] == 0 and palette[5][1] == 110)
	local duplicates = { target, target, palette[1], palette[1], palette[2], palette[3], palette[4], { "bad", 0, 0 } }
	local distinct = Rules.options(target, duplicates, 1, randomIndex)
	local seen, unique = {}, true
	for _, rgb in ipairs(distinct) do local key = colorKey(rgb); unique = unique and not seen[key]; seen[key] = true end
	check("duplicate and malformed distractors do not create ambiguous answers", unique and #distinct == 5)
	local valid = pcall(Rules.options, target, { palette[1], palette[1] }, 1, randomIndex)
	check("insufficient unique distractors fail rather than display duplicate choices", not valid)
	valid = pcall(Rules.options, { 0 / 0, 50, 255 }, palette, 1, randomIndex)
	check("nonfinite target colors are rejected", not valid)
end

do
	check("matching lane is correct", Rules.classify(3, 3) == "correct")
	check("different valid lane is wrong", Rules.classify(2, 3) == "wrong")
	local rejected = Rules.classify(nil, 3) == "ignored"
	for _, choice in ipairs({ "3", false, {}, -1, 0, 6, 2.5, math.huge, -math.huge, 0 / 0 }) do
		rejected = rejected and Rules.classify(choice, 3) == "ignored"
	end
	check("malformed lane selections are ignored", rejected)
end

do
	local entry = { Alive = false, RevivesUsed = 0 }
	check("eliminated player may use one credit during active or reveal phases", Rules.eligibleRevive(entry, "RUN", false, 1) and Rules.eligibleRevive(entry, "REVEAL", false, 1))
	local inactive = true
	for _, phase in ipairs({ "LOBBY", "PREVIEW", "RESULTS", "unknown" }) do
		inactive = inactive and not Rules.eligibleRevive(entry, phase, false, 1)
	end
	check("credit cannot be consumed outside the active match window", inactive)
	check("announced winner prevents any subsequent reentry", not Rules.eligibleRevive(entry, "RUN", true, 1))
	entry.Alive = true
	check("active participant cannot consume a reentry", not Rules.eligibleRevive(entry, "RUN", false, 1))
	entry.Alive, entry.QueuedRevive = false, true
	check("queued reentry cannot be purchased or used twice", not Rules.eligibleRevive(entry, "REVEAL", false, 1))
	entry.QueuedRevive, entry.RevivesUsed = false, 1
	check("one use per match includes the final", not Rules.eligibleRevive(entry, "RUN", false, 1))
	check("spectator has no reentry entitlement", not Rules.eligibleRevive(nil, "RUN", false, 1))
end

do
	local alive, queued = Rules.count({
		[100] = { Alive = true }, [200] = { Alive = false, QueuedRevive = true },
		[300] = { Alive = false }, [400] = { Alive = true },
	})
	check("survivors and queued reentries remain distinct", alive == 2 and queued == 1)
	alive, queued = Rules.count({})
	check("empty match has no phantom participant", alive == 0 and queued == 0)
	check("two survivors trigger a race final immediately", Rules.isFinal(2, 1, 7))
	check("ordinary multi-player rounds continue before the round limit", not Rules.isFinal(3, 7, 7))
	check("round cap forces a finite multi-player final", Rules.isFinal(12, 8, 7))
end

print(string.format("All %d Color Rush rule checks passed.", passed))
