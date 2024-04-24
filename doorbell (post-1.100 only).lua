local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
local drive = peripheral.find("drive")

local path = "/track1.dfpwm"
if (not speaker) then error("error: speaker not found")
elseif (not drive) then error("error: drive not found")
elseif (not drive.hasData() or not fs.exists(drive.getMountPath() + path)) then error("error: ringtone not found") end

local decoder = dfpwm.make_decoder()
local ringtone = drive.getMountPath() + path

while (true) do
    local event = os.pullEvent("redstone")

    -- redstone input has changed
    if (redstone.getInput("front")) then
        for chunk in io.lines(ringtone, 16 * 1024) do
            local buf = decoder(chunk)
            while not speaker.playAudio(buf) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
end