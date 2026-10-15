-- Tests the actual independent welcome script, without loading Config or server modules.
-- @CLIENT_MOCKS@
storage:Destroy()
services.ReplicatedStorage = nil
services.MarketplaceService = nil
services.TweenService = nil
services.UserInputService = nil
local function require() error("The bootstrap must not require game modules") end
local function bootstrapMain()
-- @BOOTSTRAP_SOURCE@
end

local checks = 0
local function check(value, message) checks += 1; assert(value, message) end
local function resume(thread)
	local ok, interval = coroutine.resume(thread)
	assert(ok, interval)
	return interval
end
local function textWith(fragment)
	for _, object in ipairs(objects) do
		if not object.destroyed and type(object.Text) == "string" and string.find(object.Text, fragment, 1, true) then return object end
	end
	return nil
end

local thread = coroutine.create(bootstrapMain)
local interval = resume(thread)
local welcome = playerGui:FindFirstChild("ColorChaosWelcome")
check(welcome ~= nil and coroutine.status(thread) == "suspended", "welcome renders before the main UI or server exists")
check(welcome.ResetOnSpawn == false, "welcome survives avatar respawns while initialization is pending")
check(welcome.DisplayOrder == 100, "welcome remains readable above the unready HUD")
check(textWith("Estás en el lobby seguro") ~= nil, "waiting players receive a safe-lobby explanation")
check(#sent == 0, "bootstrap never requests purchases, rewards or server actions")
check(#childWaits == 1 and childWaits[1].Name == "PlayerGui" and childWaits[1].Timeout == 15,
	"bootstrap needs only PlayerGui with a finite wait")
check(interval == 0.25, "bootstrap checks readiness without a blocking ten-second wait")
for _ = 1, 39 do
	advanceTime(interval)
	interval = resume(thread)
end
check(mockClock == 19.75 and textWith("tarda más de lo esperado") == nil,
	"the delay warning does not appear before ten seconds")
advanceTime(interval)
interval = resume(thread)
check(mockClock == 20 and textWith("tarda más de lo esperado") ~= nil,
	"a ten-second delay explains that the lobby remains safe")
check(coroutine.status(thread) == "suspended" and welcome.Parent == playerGui,
	"a late server does not remove the independent welcome")
local main = node("ScreenGui", "ColorChaosUI", playerGui)
main:SetAttribute("Ready", false)
advanceTime(interval)
interval = resume(thread)
check(welcome.Parent == playerGui, "creating an unready main UI does not dismiss the welcome")
main:SetAttribute("Ready", true)
advanceTime(interval)
resume(thread)
check(welcome.destroyed and playerGui:FindFirstChild("ColorChaosWelcome") == nil,
	"the first valid server snapshot removes the welcome")
check(coroutine.status(thread) == "dead", "the bootstrap exits after readiness rather than polling forever")
check(#sent == 0, "the welcome never submits game or commerce requests")

-- If the main client wins the startup race there should be no lingering overlay.
thread = coroutine.create(bootstrapMain)
resume(thread)
check(coroutine.status(thread) == "dead" and playerGui:FindFirstChild("ColorChaosWelcome") == nil,
	"an already-ready main UI immediately dismisses the bootstrap overlay")

-- Roblox can time out while waiting for PlayerGui. That case must exit quietly.
main:Destroy()
playerGui.Parent = nil
local before = #objects
thread = coroutine.create(bootstrapMain)
resume(thread)
check(coroutine.status(thread) == "dead" and #objects == before,
	"a PlayerGui timeout creates no orphaned UI and terminates quietly")
print("Color Chaos bootstrap smoke checks: " .. checks .. " passed (API mocks; no Roblox engine).")
