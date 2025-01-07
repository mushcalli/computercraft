local chat = peripheral.find("chatBox")
if (not chat) then
    error("error: chatBox not found")
end

local calliMessenger = {}

local regFaces = {
    "^w^",
    "*u*",
    "OwO",
    "UwU",
    "OwU",
    "::::D",
    ":33",
    ">:3"
}

local errFaces = {
    "@_@",
    "XnX",
    "0x0",
    "~m~"
}

math.randomseed(os.time())

function calliMessenger.messageCalli(msg, isError)
    if (string.find(msg, "\n")) then
        if (not isError) then
            chat.sendMessageToPlayer(regFaces[math.random(1, #regFaces)] .. "\n" .. msg, "bonjour_baguette", "&bcyber-irys", "<>", "&3")
        else
            chat.sendMessageToPlayer(errFaces[math.random(1, #errFaces)] .. "\n§c" .. msg, "bonjour_baguette", "&bcyber-irys", "<>", "&3")
        end
        return
    end

    if (not isError) then
        chat.sendToastToPlayer(msg, regFaces[math.random(1, #regFaces)], "bonjour_baguette", "&bcyber irys", "<>", "&3")
    else
        chat.sendToastToPlayer("§c" .. msg, errFaces[math.random(1, #errFaces)], "bonjour_baguette", "&bcyber-irys", "<>", "&3")
    end
end

return calliMessenger