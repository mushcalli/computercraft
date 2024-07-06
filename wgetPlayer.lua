local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()

local wgetPlayer = {}

function wgetPlayer.play(path)
    for chunk in io.lines(path, 16 * 1024) do
        local buf = decoder(chunk)
        while not speaker.playAudio(buf) do
            local event, data = os.pullEvent()

            --[[if (event == "key_up" and data == keys.enter) then
                return
            end]]
        end
    end
end

function wgetPlayer.wget_play(url, filename)
    shell.run("wget " .. url .. '"' .. filename .. '"')
    if (fs.exists(filename)) then
        print("(press enter to stop)")
        play(filename)
        fs.delete(filename)
    else
        print("wget failed :(")
    end
    os.sleep(2)
end


return wgetPlayer