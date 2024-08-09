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
local function streamFromUrl(audioUrl, startOffset, audioByteLength, interruptEvent, chunkQueuedEvent)
    -- chunkQueuedEvent optional; see playFromUrl()

    --local startTimestamp = os.date("!%a, %d %b %Y %T GMT")

    local i = startOffset
    local maxByteOffset = httpPlayer.chunkSize * math.floor(audioByteLength / httpPlayer.chunkSize)

    local rangeEnd = math.min(i + httpPlayer.chunkSize - 1, audioByteLength - 1)
    --local chunkHandle, chunkErr = http.get(audioUrl, {["If-Unmodified-Since"] = startTimestamp, ["Range"] = "bytes=0-" .. rangeEnd})
    local chunkHandle, chunkErr = http.get(audioUrl, {["Range"] = "bytes=" .. i .. "-" .. rangeEnd})
    if (audioByteLength - startOffset > httpPlayer.chunkSize) then
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

            --[[local chunk = chunkHandle.readAll()
            local buf = decoder(chunk)
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
            end]]

            -- play chunk once speaker can receieve it, catch interrupts
            -- (chunk run time ~2.7s for default chunkSize of 16kb)
            local chunk = chunkHandle.readAll()

            if (chunkQueuedEvent) then
                os.queueEvent(chunkQueuedEvent, i, os.clock())
            end

            playChunk(chunk, interruptEvent)
            chunkHandle.close()
            nextChunkHandle.close()


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

function httpPlayer.playFromUrl(audioUrl, interruptEvent, chunkQueuedEvent, startOffset, usePartialRequests, audioByteLength)
    -- chunkQueuedEvent optional, if given will send that event just before playing each chunk, along with { chunk byte offset, chunk queued time (based on os.clock()) }
    -- last 2 args optional, only to be used if url has been polled externally

    -- startOffset will be ignored if partial requests aren't supported, the song will just be played from the beginning
    startOffset = startOffset or 0

    if (startOffset < 0 or startOffset > audioByteLength - 1) then
        print("invalid startOffset (" .. startOffset .. ")")
        return
    end

    -- if not provided, poll url for usePartialRequests, audioByteLength
    if (usePartialRequests == nil or audioByteLength == nil) then
        local pollResponse, polledLength = httpPlayer.pollUrl(audioUrl)

        if (pollResponse == nil) then -- if pollUrl returned error, exit
            return
        end

        usePartialRequests = pollResponse
        audioByteLength = polledLength
    end


    --- playback
    if (usePartialRequests) then
        streamFromUrl(audioUrl, startOffset, audioByteLength, interruptEvent, chunkQueuedEvent)
    else
        --- play from single get request
        local response = http.get(audioUrl)
        if (not response) then
            print("get request failed :(")
            return
        end

        local chunk = response.read(httpPlayer.chunkSize)
        local i = 0
        while (chunk) do
            if (chunkQueuedEvent) then
                os.queueEvent(chunkQueuedEvent, i, os.clock())
            end

            local interrupt = playChunk(chunk, interruptEvent)
            if (interrupt) then
                -- close response handle and exit early
                response.close()
                return
            end

            chunk = response.read(httpPlayer.chunkSize)
            i = i + httpPlayer.chunkSize
        end

        -- close response handle when done
        response.close()
    end
end

--- returns { supportsPartialRequests, audioByteLength }
-- { false, nil } if partial requests not supported
-- { nil, err } if error (invalid url/get failed)
function httpPlayer.pollUrl(audioUrl)
    -- head request
    http.request({url = audioUrl, method = "HEAD"})
    local event, _url, response
    repeat
        event, _url, response = os.pullEvent()
    until (event == "http_success" or event == "http_failure") and _url == audioUrl
    if (event == "http_failure") then
        print(response)
        return nil
    end


    local headers = response.getResponseHeaders()
    --local audioByteLength = headers["Content-Length"]
    ---- BROKEN FOR GITHUB RAW LINKS ^^ idk why github isnt properly implementing the Content-Length headers in their HEAD request responses :(((
    local supportsPartialRequests = (headers["Accept-Ranges"] and headers["Accept-Ranges"] ~= "none")
    if (not supportsPartialRequests) then
        return false, nil
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


    return true, audioByteLength
end


return httpPlayer