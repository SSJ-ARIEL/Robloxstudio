-- Pure rules: no Roblox services, random state or client-provided scores.
local Rules = {}

function Rules.cleanProfile(raw, paletteCount)
	local profile = { Coins = 0, Wins = 0, Selected = 1, Owned = { ["1"] = true } }
	if type(raw) ~= "table" then
		return profile
	end
	for _, key in ipairs({ "Coins", "Wins" }) do
		local value = raw[key]
		if type(value) == "number" and value == value and value > 0 and value < math.huge then
			profile[key] = math.min(math.floor(value), 100000000)
		end
	end
	if type(raw.Owned) == "table" then
		for i = 1, paletteCount do
			if raw.Owned[tostring(i)] == true then
				profile.Owned[tostring(i)] = true
			end
		end
	end
	if type(raw.Selected) == "number" and raw.Selected % 1 == 0 and profile.Owned[tostring(raw.Selected)] then
		profile.Selected = raw.Selected
	end
	return profile
end

function Rules.purchase(profile, index, palettes)
	if type(index) ~= "number" or index % 1 ~= 0 or not palettes[index] then
		return false, "Selección inválida."
	end
	local key = tostring(index)
	if not profile.Owned[key] then
		local cost = palettes[index].Cost
		if profile.Coins < cost then
			return false, "Necesitas más monedas. Se consiguen jugando."
		end
		profile.Coins -= cost
		profile.Owned[key] = true
	end
	profile.Selected = index
	return true, "Color equipado."
end

function Rules.reward(success, contributed, alive, winCoins, participationCoins)
	if not contributed then
		return 0, 0
	end
	if success and alive then
		return winCoins, 1
	end
	return participationCoins, 0
end

return Rules
