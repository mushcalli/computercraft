local messenger = require("calliMessenger")

local chat = peripheral.find("chatBox")
local det = peripheral.find("playerDetector")
if (not chat) then error("error: chatBox not found") end
if (not det) then error("error: playerDetector not found") end

local args = {...}
if (#args < 1) then error("usage: dox [username] [private=false]") end

local user = args[1]
local private = (args[2] == "true")

local info = det.getPlayer(user)

-- if info == {}
if (next(info) == nil) then
    error("error: failed to detect " .. user)
end

messenger.message("doxxing " .. user .. ",,,")
os.sleep(1)

if (not private) then
    chat.sendMessage(user .. ":\n" .. textutils.serialize(info), "&bcyber-irys", "<>", "&3")
else
    chat.sendMessageToPlayer(user .. ":\n" .. textutils.serialize(info), "bonjour_baguette", "&bcyber-irys", "<>", "&3")
end