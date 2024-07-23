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

--- stream audio chunks from url
local function streamFromUrl(audioUrl, audioByteLength, interruptEvent)
    local startTimestamp = os.date("!%a, %d %b %Y %T GMT")
    
    local i
    local maxByteOffset = httpPlayer.chunkSize * math.floor(audioByteLength / httpPlayer.chunkSize)

    local rangeEnd = math.min(httpPlayer.chunkSize - 1, audioByteLength - 1)
    local chunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=0-" .. rangeEnd})
    if (audioByteLength >= httpPlayer.chunkSize) then
        i = httpPlayer.chunkSize
        rangeEnd = math.min((2 * httpPlayer.chunkSize) - 1, audioByteLength - 1)
        local nextChunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        while (i <= maxByteOffset) do
            -- return if get error
            if (chunkHandle.getResponseCode() == 412 or nextChunkHandle.getResponseCode() == 412) then
                print("get failed: file modified :(")
                chunkHandle.close()
                nextChunkHandle.close()
                return
            elseif (chunkHandle.getResponseCode() ~= 206 or nextChunkHandle.getResponseCode() ~= 206) then
                print("get request failed :( (" .. chunkHandle.getResponseCode() .. ", " .. nextChunkHandle.getResponseCode() .. ")")
                chunkHandle.close()
                nextChunkHandle.close()
                return
            end

            local chunk = chunkHandle.readAll()
            local buf = decoder(chunk)
            -- play chunk once speaker can receieve it, catch interrupts
            -- (chunk run time ~2.7s for default chunkSize of 16kb)
            while (not speaker.playAudio(buf)) do
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

            -- increment, get next chunk while current is playing
            -- (smooth playback relies on being able to http get the next fixed-size chunk during the current one's run time, adjust chunkSize as needed)
            chunkHandle.close()
            chunkHandle = nextChunkHandle
            i = i + httpPlayer.chunkSize
            rangeEnd = math.min(i + httpPlayer.chunkSize - 1, audioByteLength - 1)
            nextChunkHandle = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
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
        if (byteHandle.getResponseCode() ~= 206) then
            print("get request failed :( (".. byteHandle.getResponseCode() .. ")")
            byteHandle.close()
            return
        end
        local _header = byteHandle.getResponseHeaders()["Content-Range"]
        if (not _header) then
            print("get request failed :( (no Content-Range)")
            byteHandle.close()
            return
        end
        local _, __, audioByteLength = string.find(_header, "([^%/]+)$")
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