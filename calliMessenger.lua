local chat = peripheral.find("chatBox")
if (not chat) then
    error("error: chatBox not found")
end

local calliMessenger = {}

function calliMessenger.messageCalli(msg, isError)
    if (string.find(msg, "\n")) then
        chat.sendMessageToPlayer("\n" .. msg, "bonjour_baguette", "&bcyber-irys", "<>", "&3")
        return
    end

    if (not isError) then
        chat.sendToastToPlayer(msg, "^w^", "bonjour_baguette", "&bcyber irys", "<>", "&3")
    else
        chat.sendToastToPlayer("§c" .. msg, "@_@", "bonjour_baguette", "&bcyber-irys", "<>", "&3")
    end
end

return calliMessenger