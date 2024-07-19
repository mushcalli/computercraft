local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()

local wgetPlayer = {}

function wgetPlayer.play(path, interruptKey)
    for chunk in io.lines(path, 16 * 1024) do
        local buf = decoder(chunk)
        while not speaker.playAudio(buf) do
            local event, data = os.pullEvent()

            if (interruptKey) then
                if (event == "key_up" and data == interruptKey) then
                    return
                end
            end
        end
    end
end

function wgetPlayer.wget_play(url, filename, interruptKey)
    shell.run("wget " .. url .. '"' .. filename .. '"')
    if (fs.exists(filename)) then
        print("(press enter to stop)")
        wgetPlayer.play(filename, interruptKey)
        fs.delete(filename)
    else
        print("wget failed :(")
    end
    os.sleep(2)
end


return wgetPlayer