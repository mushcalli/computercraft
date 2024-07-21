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

            local chunk = chunkHandle.readAll()

            -- increment
            chunkHandle = nextChunkHandle
            i = i + httpPlayer.chunkSize
            rangeEnd = math.min(i + httpPlayer.chunkSize, audioByteLength)
            nextChunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        end
    else
        --
    end

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
    local audioByteLength = headers["Content-Length"]
    local usePartialRequests = (headers["Accept-Ranges"] and headers["Accept-Ranges"] ~= "none")


    --- playback
    if (usePartialRequests) then
        streamFromUrl(audioUrl, audioByteLength, interruptKey)
    else
        --- play from single get request
        local response = http.get(audioUrl)
        if (not response) then
            print("get request failed :(")
            return
        end

        local chunk = response.read(httpPlayer.chunkSize)
        while (chunk) do
            local interrupt = playChunk(chunk, interruptKey)
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