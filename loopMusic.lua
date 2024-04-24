if (not fs.exists("wave-2.lua")) then
    shell.run("wget https://drive.google.com/uc?export=download&id=1Co34X9x-GX-WxL_WUbYzvRZ_QlgxClnb wave-2.lua")
end
local wave = dofile("wave-2.lua")

local args = {...}
if (#args ~= 1) then
    error("usage: loopMusic [volume (0.0-1.0)]")
end
if (not tonumber(args[1])) then
    error("usage: loopMusic [volume (0.0-1.0)]")
end
local volume = tonumber(args[1])

local speaker = peripheral.find("speaker")
local drive = peripheral.find("drive")
if (not drive.hasData()) then
    error("no disk found")
end

if (not fs.exists(fs.combine(drive.getMountPath(), "song"))) then
    error("song directory not found, insert an audio disk/phone")
end

local song = fs.list(drive.getMountPath() .. "/song")[1]

local context = wave.createContext()
context:addOutput(peripheral.getName(speaker))
local track = wave.loadTrack("/disk/song/" .. song)
local instance = context:addInstance(track, volume, true, true)

--[[while instance.playing do -- While the instance hasn't finished playing
    context:update() -- Updates the context which in turn plays the notes
    os.sleep(0.05) -- Sleeps for 0.05s
end]]

local timer = os.startTimer(0.05)
while instance.playing do
    local e = {os.pullEventRaw()}
    if e[1] == "timer" and e[2] == timer then
        timer = os.startTimer(0)
        local prevtick = instance.tick
        context:update()
    end
end