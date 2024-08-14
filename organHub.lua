peripheral.find("modem", rednet.open)

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end

local success, wave = pcall(require, "wave-2")
if (not success) then
    shell.run("wget https://github.com/noodle2521/computercraft/raw/main/wave-2.lua wave-2.lua")
    wave = require("wave-2")
end

local httpPlayer
success, httpPlayer = pcall(require, "httpPlayer")
if (not success) then
    shell.run("wget https://github.com/noodle2521/computercraft/raw/main/httpPlayer.lua httpPlayer.lua")
    httpPlayer = require("httpPlayer")
end


local protocol = "organChunk"
local messagePrefix = ":3 organChunks can u play "
local pitchBias = 7

local function playNote(note, pitch, volume)
    -- pitch: F#3 is zero, F#5 is 24

    if (filterOutDrums[note]) then
        rednet.broadcast(messagePrefix .. math.max(math.min(pitch + pitchBias, 35), 0), protocol)
    end
end
--[[local function playNoteLow(note, pitch, volume)
    -- note and volume dont apply here lmao
    -- pitch: F#3 is zero, F#5 is 24

    rednet.broadcast(messagePrefix .. math.max(math.min(pitch - 1, 35), 0), protocol)
end]]


--- g
local clipMode = 0
local context = wave.createContext()
local filterOutDrums = {true, true, false, false, false, true, true, true, true, true, true, false, true, true, true, true}
context:addOutput(playNoteHigh, 1, filterOutDrums, wave._defaultThrottle, clipMode)
context:addOutput(playNoteLow, 1, filterOutDrums, wave._defaultThrottle, clipMode)

-- get and check url
--[[local url = read()
local result = httpPlayer.pollUrl(url)
if (result == nil) then
    error("bad url :(")
end

-- get filehandle from url
local response = http.get(url)
if (not response) then
    print("get request failed :(")
    return
end]]

local path = read()
if (not fs.exists(path)) then
    error("bad path :(")
end

--local track = wave.loadTrackFromHandle(response)
local track = wave.loadTrack(path)
local instance = context:addInstance(track, volume, true, false)

-- playback
local timer = os.startTimer(0.05)
while instance.playing do
    local e = {os.pullEventRaw()}
    if e[1] == "timer" and e[2] == timer then
        timer = os.startTimer(0)
        local prevtick = instance.tick
        context:update()
    end
end