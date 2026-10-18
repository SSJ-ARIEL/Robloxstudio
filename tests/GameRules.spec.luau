local Rules = require("../src/shared/GameRules")
local Characters = require("../src/shared/Characters")
local passed = 0
local function check(name, condition) assert(condition, name); passed += 1 end
local function same(a, b) return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] end
local function random(seed)
	return { NextInteger = function(_, minimum, maximum)
		seed = (seed * 48271) % 2147483647
		return minimum + seed % (maximum - minimum + 1)
	end }
end

do
	local first, eighth = Rules.stageCoordinates(1), Rules.stageCoordinates(8)
	check("first stage matches built map", first.StartZ == -40 and first.GateZ == -88 and first.EndZ == -122)
	check("eight stages advance away from lobby", eighth.StartZ == -824 and eighth.GateZ == -872 and eighth.EndZ == -906)
	check("invalid stage cannot silently point outside course", not pcall(Rules.stageCoordinates, 0))
end

do
	local character = { Id = 44, ColorRGB = { 255, 160, 62 } }
	local selected = {}
	for seed = 1, 30 do
		local question = Rules.generateQuestion(character, random(seed))
		local unique, correctCount = {}, 0
		for index, choice in ipairs(question.Choices) do
			local key = table.concat(choice, ",")
			assert(not unique[key], "Duplicate alternative")
			unique[key] = true
			if same(choice, character.ColorRGB) then
				correctCount += 1
				assert(index == question.CorrectLane, "Answer points to another color")
			end
		end
		selected[question.CorrectLane] = true
		check("question has five distinct colors and a single canonical answer " .. seed, #question.Choices == 5 and correctCount == 1)
		check("reference is intentionally recolored after preview " .. seed, not same(question.WrongRGB, question.OriginalRGB))
		check("question retains correct original character " .. seed, question.CharacterId == 44 and same(question.OriginalRGB, character.ColorRGB))
	end
	local count = 0
	for _ in pairs(selected) do count += 1 end
	check("shuffling changes the correct lane", count >= 4)
	local constant = { NextInteger = function(_, minimum) return minimum end }
	local generated = Rules.generateQuestion({ Id = 1, TargetRGB = { 1, 2, 3 } }, constant)
	check("nonpalette target has an exact correct alternative", same(generated.Choices[generated.CorrectLane], { 1, 2, 3 }))
	generated.OriginalRGB[1] = 99
	check("question RGB values do not alias each other", generated.Choices[generated.CorrectLane][1] == 1)
	check("question does not change canonical character catalog", character.ColorRGB[1] == 255)
	check("corrupt catalog fails explicitly", not pcall(Rules.generateQuestion, { Id = 1, ColorRGB = { math.huge, 0, 0 } }, constant))
end

do
	local stage = Rules.stageCoordinates(1)
	local function position(x, y, z) return { X = x, Y = y, Z = z } end
	for index, x in ipairs({ -40, -20, 0, 20, 40 }) do
		check("server position selects lane " .. index, Rules.validChoice(position(x, 10, stage.GateZ + 10), stage, 2) == index)
	end
	check("too-early teleport does not choose", Rules.validChoice(position(0, 10, stage.GateZ + 10), stage, 1) == nil)
	check("configured travel minimum is enforced", Rules.validChoice(position(0, 10, stage.GateZ + 10), stage, 2, { MinimumChoiceSeconds = 3 }) == nil)
	check("gap between lanes is not a choice", Rules.validChoice(position(-30, 10, stage.GateZ + 10), stage, 2) == nil)
	check("lane outer edge is selectable", Rules.validChoice(position(-48, 10, stage.GateZ + 4), stage, 2) == 1)
	check("beyond lane outer edge is not selectable", Rules.validChoice(position(-48.01, 10, stage.GateZ + 4), stage, 2) == nil)
	check("previous stage cannot register for current stage", Rules.validChoice(position(0, 10, stage.GateZ + 10), 2, 2) == nil)
	check("before choice pad is not selectable", Rules.validChoice(position(0, 10, stage.GateZ + 16.1), stage, 2) == nil)
	check("past barrier is not selectable", Rules.validChoice(position(0, 10, stage.GateZ + 3.9), stage, 2) == nil)
	check("below floor does not choose", Rules.validChoice(position(0, 6.9, stage.GateZ + 10), stage, 2) == nil)
	check("above course does not choose", Rules.validChoice(position(0, 20.1, stage.GateZ + 10), stage, 2) == nil)
	check("NaN position cannot choose", Rules.validChoice(position(0/0, 10, stage.GateZ + 10), stage, 2) == nil)
	check("infinite elapsed cannot choose", Rules.validChoice(position(0, 10, stage.GateZ + 10), stage, math.huge) == nil)
	check("missing avatar cannot choose", Rules.validChoice(nil, stage, 2) == nil)
	check("lowercase vector mock is supported", Rules.validChoice({ x = 0, y = 10, z = stage.GateZ + 10 }, stage, 2) == 3)
end

do
	local entries = {
		{ UserId = 5, Name = "Cinco", CorrectThisMatch = 2, LastChoiceAt = 10 },
		{ UserId = 4, Name = "Cuatro", CorrectThisMatch = 2, LastChoiceAt = 8 },
		{ UserId = 3, Name = "Tres", CorrectThisMatch = 2, LastChoiceAt = 8 },
		{ UserId = 2, Name = "Dos", CorrectThisMatch = 3, LastChoiceAt = 12 },
		{ UserId = 1, Name = "Fantasma", CorrectThisMatch = 100, Ghost = true },
		{ UserId = 6, Name = "Tarde", CorrectThisMatch = 99, Eligible = false },
	}
	local ranked = Rules.rankRoom(entries)
	check("room standings exclude ghosts and late joiners", #ranked == 4)
	check("correct choices rank ahead of speed", ranked[1].UserId == 2)
	check("equal accuracy ranks earliest choice then user ID", ranked[2].UserId == 3 and ranked[3].UserId == 4 and ranked[4].UserId == 5)
	check("standings assign contiguous room places", ranked[4].Place == 4)
	check("standings do not mutate caller entries", entries[1].Place == nil and entries[1].UserId == 5)
	local corrupt = Rules.rankRoom({ { UserId = -1 }, { UserId = 1, CorrectThisMatch = math.huge }, { UserId = 2, CorrectThisMatch = 0/0 } })
	check("corrupt scores never outrank real progress", #corrupt == 2 and corrupt[1].CorrectThisMatch == 0)
end

do
	for _, character in ipairs(Characters.All) do
		local good = true
		for seed = 1, 12 do
			local question = Rules.generateQuestion(character, random(seed * character.Id))
			good = good and #question.Choices == 5 and same(question.Choices[question.CorrectLane], character.ColorRGB)
			for i = 1, 5 do
				for j = i + 1, 5 do
					local a, b = question.Choices[i], question.Choices[j]
					local distanceSquared = (a[1]-b[1])^2 + (a[2]-b[2])^2 + (a[3]-b[3])^2
					good = good and distanceSquared >= 4900
				end
			end
		end
		check("citizen " .. character.Id .. " always has five distinct mobile-readable colors", good)
	end
end

print(string.format("GameRules: %d behavioral checks passed", passed))
