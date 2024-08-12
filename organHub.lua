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


local function playNote()

end


--- g
local clipMode = 2
local context = wave.createContext()
context:addOutput(playNote, 1, {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}, wave._defaultThrottle, clipMode)

-- get and check url
local url = read()
local result = httpPlayer.pollUrl(url)
if (result == nil) then
    error("bad url :(")
end

-- get filehandle from url
local response = http.get(audioUrl)
if (not response) then
    print("get request failed :(")
    return
end

local track = wave.loadTrackFromHandle(response)
local instance = context:addInstance(track, volume, true, true)

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