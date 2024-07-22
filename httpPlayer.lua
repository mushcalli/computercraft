local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()

local httpPlayer = {}

httpPlayer.chunkSize = 16 * 1024


local function playChunk(chunk, interruptEvent)
    local buf = decoder(chunk)
    while not speaker.playAudio(buf) do
        local event, data = os.pullEvent()

        if (interruptEvent) then
            if (event == interruptEvent) then
                speaker.stop()
                return true
            end
        end
    end

    return false
end

local function streamFromUrl(audioUrl, audioByteLength, interruptEvent)
    --- stream audio chunks from url
    local startTimestamp = os.date("!%a, %d %b %Y %T GMT")

    
    local i
    local maxByteOffset = httpPlayer.chunkSize * math.floor(audioByteLength / httpPlayer.chunkSize)

    local rangeEnd = math.min(httpPlayer.chunkSize, audioByteLength)
    local chunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=0-" .. rangeEnd})
    if (audioByteLength >= httpPlayer.chunkSize) then
        i = httpPlayer.chunkSize
        rangeEnd = math.min(i + httpPlayer.chunkSize, audioByteLength)
        local nextChunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        while (i <= maxByteOffset) do
            -- return if get error
            if (chunkHandle.getResponseCode() == 412 or nextChunkHandle.getResponseCode() == 412) then
                print("get failed: file modified :(")
                chunkHandle.close()
                return
            elseif (chunkHandle.getResponseCode ~= 200 or nextChunkHandle.getResponseCode() ~= 200) then
                print("get request failed :(")
                chunkHandle.close()
                return
            end

            -- start playback of chunk (~2.7s for default chunkSize of 16kb)
            local chunk = chunkHandle.readAll()
            local buf = decoder(chunk)
            speaker.playAudio(buf)

            -- increment, get next chunk while current is playing
            -- (smooth playback relies on being able to http get the next fixed-size chunk during the current one's run time, adjust chunkSize as needed)
            chunkHandle.close()
            chunkHandle = nextChunkHandle
            i = i + httpPlayer.chunkSize
            rangeEnd = math.min(i + httpPlayer.chunkSize, audioByteLength)
            nextChunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})

            -- wait through remainder of chunk run time, receive interrupts
            while not speaker.playAudio(buf) do
                local event, data = os.pullEvent()
        
                if (interruptEvent) then
                    if (event == interruptEvent) then
                        speaker.stop()
                        chunkHandle.close()
                        nextChunkHandle.close()
                        return
                    end
                end
            end
        end
    end

    -- play last chunk
    local chunk = chunkHandle.readAll()
    playChunk(chunk, interruptEvent)
    chunkHandle.close()
end

function httpPlayer.playFromUrl(audioUrl, interruptEvent)
    -- check url
    local success, err = http.checkURL(audioUrl)
    if (not success) then
        print(err or "invalid url")
    end


    
    --- head request
    http.request({url = audioUrl, method = "HEAD"})

    local event, _url, handle
    repeat
        event, _url, handle = os.pullEvent("http_success")
    until _url == audioUrl

    -- get content length and partial request support
    local headers = handle.getResponseHeaders()
    --local audioByteLength = headers["Content-Length"]
    ---- BROKEN FOR GITHUB RAW LINKS ^^ idk why github isnt properly implementing the Content-Length headers in their HEAD request responses :(((
    local usePartialRequests = (headers["Accept-Ranges"] and headers["Accept-Ranges"] ~= "none")


    --- playback
    if (usePartialRequests) then
        -- get request the first byte to scrape the full file's Content-Length from lmfao
        local byteHandle = http.get(audioUrl, {["Range"] = "bytes=0-0"})
        local _, __, audioByteLength = string.find(byteHandle.getResponseHeaders()["Content-Range"], "([^%/]+)$")
        audioByteLength = tonumber(audioByteLength)

        streamFromUrl(audioUrl, audioByteLength, interruptEvent)
    else
        --- play from single get request
        local response = http.get(audioUrl)
        if (not response) then
            print("get request failed :(")
            return
        end

        local chunk = response.read(httpPlayer.chunkSize)
        while (chunk) do
            local interrupt = playChunk(chunk, interruptEvent)
            if (interrupt) then
                -- close response handle and exit early
                response.close()
                return
            end

            chunk = response.read(httpPlayer.chunkSize)
        end

        -- close response handle when done
        response.close()
    end
end


return httpPlayer