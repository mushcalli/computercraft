local chat = peripheral.find("chatBox")
if (not chat) then
    error("error: chatBox not found")
end

local calliMessenger = {}

calliMessenger.regFaces = {
    "^w^",
    "*u*",
    "OwO",
    "UwU",
    "::::D",
    ":33",
    ">:3",
    ">w<",
    "~w~",
    "^u^",
    ":u"
}

calliMessenger.errFaces = {
    "@_@",
    "XnX",
    "0x0",
    "~m~",
    --">~<",
    ">n<",
    --"0~0",
    ":?",
    "u_u"
}

math.randomseed(os.time())

function calliMessenger.message(msg, isError, player)
    player = player or "bonjour_baguette"

    if (string.find(msg, "\n")) then
        if (not isError) then
            chat.sendMessageToPlayer(calliMessenger.regFaces[math.random(1, #calliMessenger.regFaces)] .. "\n" .. msg, player, "&bcyber-irys", "<>", "&3")
        else
            chat.sendMessageToPlayer(calliMessenger.errFaces[math.random(1, #calliMessenger.errFaces)] .. "\n§c" .. msg, player, "&bcyber-irys", "<>", "&3")
        end
        return
    end

    if (not isError) then
        chat.sendToastToPlayer(msg, calliMessenger.regFaces[math.random(1, #calliMessenger.regFaces)], player, "&bcyber-irys", "<>", "&3")
    else
        chat.sendToastToPlayer("§c" .. msg, calliMessenger.errFaces[math.random(1, #calliMessenger.errFaces)], player, "&bcyber-irys", "<>", "&3")
    end
end

return calliMessenger
