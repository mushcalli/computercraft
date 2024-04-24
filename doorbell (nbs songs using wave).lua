if (not fs.exists("wave-2.lua")) then
    shell.run("wget https://drive.google.com/uc?export=download&id=13mD4OM_6BjQbSkICZ4moisHuI7O9zgLI wave-2.lua")
end
local wave = dofile("wave-2.lua")

local speaker = peripheral.find("speaker")
local drive = peripheral.find("drive")

local path = "/track1.nbs"
if (not speaker) then error("error: speaker not found")
elseif (not drive) then error("error: drive not found")
elseif (not drive.hasData() or not fs.exists(drive.getMountPath() .. path)) then error("error: ringtone not found") end

local context = wave.createContext()
context:addOutput(peripheral.getName(speaker))
local track = wave.loadTrack(drive.getMountPath() .. path)
local instance = context:addInstance(track)
local play = false

local function waitForRedstone()
    repeat
        local event = os.pullEvent("redstone")
    until redstone.getInput("front")

    play = not play
    os.queueEvent("ring")
end

local function playRingtone()
    local event = os.pullEvent("ring")
    instance.tick = 1

    context.prevClock = os.clock()
    while instance.playing and play do -- While the instance hasn't finished playing
        context:update() -- Updates the context which in turn plays the notes
        os.sleep(0.05) -- Sleeps for 0.05s
    end
end

while (true) do
    parallel.waitForAny(waitForRedstone, playRingtone)
end