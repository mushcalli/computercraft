local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()

local httpPlayer = {}

-- (chunkSize can be decreased on faster internet connections for faster initial buffering on song playback, or increased on slower ones for more consistent playback)
-- (max 16 * 1024)
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
    --local startTimestamp = os.date("!%a, %d %b %Y %T GMT")
    
    local i
    local maxByteOffset = httpPlayer.chunkSize * math.floor(audioByteLength / httpPlayer.chunkSize)

    local rangeEnd = math.min(httpPlayer.chunkSize - 1, audioByteLength - 1)
    --local chunkHandle, chunkErr = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=0-" .. rangeEnd})
    local chunkHandle, chunkErr = http.get(audioUrl, {["Range"] = "bytes=0-" .. rangeEnd})
    if (audioByteLength > httpPlayer.chunkSize) then
        i = httpPlayer.chunkSize
        rangeEnd = math.min((2 * httpPlayer.chunkSize) - 1, audioByteLength - 1)
        --local nextChunkHandle, nextErr = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        local nextChunkHandle, nextErr = http.get(audioUrl, {["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        while (i <= maxByteOffset) do
            -- return if get error
            if (not chunkHandle) then
                print("get failed :( \"" .. chunkErr .. "\"")
                if (nextChunkHandle) then
                    nextChunkHandle.close()
                end
                return
            end
            if (not nextChunkHandle) then
                print("get failed :( \"" .. nextErr .. "\"")
                chunkHandle.close()
                return
            end
            --[[if (chunkHandle.getResponseCode() == 412 or nextChunkHandle.getResponseCode() == 412) then
                print("get failed: file modified :(")
                chunkHandle.close()
                nextChunkHandle.close()
                return
            end]]
            if (chunkHandle.getResponseCode() ~= 206 or nextChunkHandle.getResponseCode() ~= 206) then
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
            chunkHandle.close()
            chunkHandle = nextChunkHandle
            i = i + httpPlayer.chunkSize
            rangeEnd = math.min(i + httpPlayer.chunkSize - 1, audioByteLength - 1)
            --nextChunkHandle, nextErr = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
            nextChunkHandle, nextErr = http.get(audioUrl, {["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
        end
    end

    -- play last chunk
    local chunk = chunkHandle.readAll()
    playChunk(chunk, interruptEvent)
    chunkHandle.close()
end

function httpPlayer.playFromUrl(audioUrl, interruptEvent, usePartialRequests, audioByteLength)
    -- check url
    local success, err = http.checkURL(audioUrl)
    if (not success) then
        print(err or "invalid url")
        return
    end


    -- poll url for usePartialRequests, audioByteLength
    if (usePartialRequests == nil) then
        usePartialRequests, audioByteLength = httpPlayer.pollUrl(audioUrl)
    end
    if (usePartialRequests == nil) then -- if pollUrl returned error, exit
        return
    end


    --- playback
    if (usePartialRequests) then
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

--- returns { supportsPartialRequests, audioByteLength }
-- { false, nil } if partial requests not supported
-- nil if error (invalid url/get failed)
function httpPlayer.pollUrl(audioUrl)
    -- check url
    local success, err = http.checkURL(audioUrl)
    if (not success) then
        print(err or "invalid url")
        return nil
    end


    -- head request
    http.request({url = audioUrl, method = "HEAD"})
    local event, _url, handle
    repeat
        event, _url, handle = os.pullEvent("http_success")
    until _url == audioUrl

    local headers = handle.getResponseHeaders()
    --local audioByteLength = headers["Content-Length"]
    ---- BROKEN FOR GITHUB RAW LINKS ^^ idk why github isnt properly implementing the Content-Length headers in their HEAD request responses :(((
    local supportsPartialRequests = (headers["Accept-Ranges"] and headers["Accept-Ranges"] ~= "none")
    if (not supportsPartialRequests) then
        return { false, nil }
    end


    -- request the first byte to scrape the full file's Content-Length from lmfao
    local byteHandle, err = http.get(audioUrl, {["Range"] = "bytes=0-0"})
    if (not byteHandle) then
        print("byte get request failed :( (".. err .. ")")
        return nil
    end
    if (byteHandle.getResponseCode() ~= 206) then
        print("byte get request failed :( (".. byteHandle.getResponseCode() .. ")")
        byteHandle.close()
        return nil
    end
    local _header = byteHandle.getResponseHeaders()["Content-Range"]
    if (not _header) then
        print("byte get request failed :( (no Content-Range)")
        byteHandle.close()
        return nil
    end
    local _, __, audioByteLength = string.find(_header, "([^%/]+)$")
    audioByteLength = tonumber(audioByteLength)


    return { true, audioByteLength }
end


return httpPlayer