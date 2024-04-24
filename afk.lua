local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")


local path = "music/Please-Hold.dfpwm"
if (not speaker) then error("error: speaker not found") end

local tArgs = {...}
local keepFile = false
if #tArgs > 0 then
    if (tArgs[1] and tArgs[1] ~= 0) then
        keepFile = true
    end
end
print("keepFile = " .. tostring(keepFile))

if (not fs.exists(path)) then 
    print("afk music (" .. path .. ") not found, trying wget,,")
    shell.run("wget https://drive.google.com/uc?id=1e38mQHrPBHj62iCYtclMvdv3XQrORJ-u " .. path)
    if (not fs.exists(path)) then
        error("error: wget failed :(")
    end
end


local decoder = dfpwm.make_decoder()
local ringtone = path
local function main()
    if (multishell) then
        shell.openTab("rom/programs/shell.lua")
        multishell.setTitle(multishell.getCurrent(), "please-hold")
    end

    while true do
        for chunk in io.lines(ringtone, 16 * 1024) do
            local buf = decoder(chunk)
            while not speaker.playAudio(buf) do
                local event, data = os.pullEvent()

                if (event == "key_up" and data == keys.enter) then
                    if (not keepFile) then fs.delete(path) end
                    if (multishell) then shell.exit() end
                    return
                end
            end
        end
    end
end

-- main
main()