local messenger = require("calliMessenger")

local chat = peripheral.find("chatBox")
local det = peripheral.find("playerDetector")
if (not chat) then error("error: chatBox not found") end
if (not det) then error("error: playerDetector not found") end

local args = {...}
if (#args ~= 1) then
    error("usage: blast [string] (you may need to add quotes)")
end
local msg = tostring(args[1])

local players = det.getOnlinePlayers()
for _, p in ipairs(players) do
    messenger.message(msg, false, p)
    os.sleep(1)
end