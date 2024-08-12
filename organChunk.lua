peripheral.find("modem", rednet.open)

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end

local noteLength = 0.2 -- about the length of a noteblock note, may increase later
local protocol = "organChunk"
local offsetPath = "offset.txt"
local UIDeviceOrientation = {
    [0] = "top",
    [1] = "bottom",
    [2] = "left",
    [3] = "right"
}
local offset

-- get offset from file
if (not fs.exists(offsetPath)) then
    error("offset.txt not found")
else
    local file = fs.open(offsetPath, "r")
    local line = file.readLine()
    offset = tonumber(line)
end

-- generate table of valid rednet messages
local validMessages = {}
local messagePrefix = ":3 organChunks can u play "
for i = 0, 3 do
    validMessages[i] = messagePrefix .. ((offset * 4) + i)
end


--- main
while true do
    local id, message = rednet.receive(protocol)

    if (validMessages[message]) then
        local mod = math.fmod(tonumber(string.sub(message, string.len(messagePrefix) + 1)), 4)
        redstone.setOutput(UIDeviceOrientation[mod], true)
        os.sleep(noteLength)
    end
end