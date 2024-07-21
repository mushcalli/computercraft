local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()

local httpPlayer = {}


httpPlayer.chunkSize = 16 * 1024

local function playChunk(chunk, interruptKey)
    local buf = decoder(chunk)
    while not speaker.playAudio(buf) do
        local event, data = os.pullEvent()

        if (interruptKey) then
            if (event == "key_up" and data == interruptKey) then
                return true
            end
        end
    end

    return false
end

function httpPlayer.play_from_url(url, interruptKey)
    -- check url
    local success, err = http.checkURL(url)
    if (not success) then
        print(err or "invalid url")
    end

    -- do get request
    local response = http.get(url)
    if (not response) then
        print("get request failed :(")
        return
    end

    -- play from response handle
    local chunk = response.read(httpPlayer.chunkSize)
    local nextChunk = response.read(httpPlayer.chunkSize)
    while (nextChunk) do
        local interrupt = playChunk(chunk, interruptKey)
        if (interrupt) then
            -- close response handle and exit early
            response.close()
            return
        end
        
        chunk = nextChunk
        nextChunk = response.read(httpPlayer.chunkSize)
    end
    playChunk(chunk, interruptKey)

    -- close response handle when done
    response.close()
end


return httpPlayer