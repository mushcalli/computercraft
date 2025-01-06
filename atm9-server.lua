local chat = peripheral.find("chatBox")
if (not chat) then
    error("error: chatBox not found")
end

local function runInWindow(input)
    local win = window.create(term.current(), 1, 1, term.getSize())
    term.redirect(win)
    local ok = shell.run(input)
    term.redirect(term.native())
    return win, ok
end

local function messageCalli(msg, isError)
    if (not isError) then
        chat.sendToastToPlayer(msg, "^w^", "bonjour_baguette", "&bcyber irys", "<>", "&3")
    else
        chat.sendToastToPlayer("§c" .. msg, "@_@", "bonjour_baguette", "&bcyber-irys", "<>", "&3")
    end

    if (string.find(msg, "\n")) then
        chat.sendMessageToPlayer(msg, "bonjour_baguette", "&bcyber-irys", "<>", "&3")
    end
end

--- main
local function runChatCommands()
    local event, command = os.pullEvent("chatCommand")
    local win, ok = runInWindow(command)
    local out = ""
    local _, lines = win.getSize()
    for i = 1, lines do
        out = out .. win.getLine(i)
    end
    
    messageCalli(out, not ok)
end

local function catchChatEvents()
    while true do
        local event, user, msg, _, hidden = os.pullEvent("chat")
        local command = nil
        if (hidden) then
            command = msg
        elseif (string.sub(msg, 1, 1) == ";") then
            command = string.sub(msg, 2)
        end
        if (command) then
            if (command == "kill") then
                messageCalli("rebooting server,,,", true)
                os.reboot()
            end

            os.queueEvent("chatCommand", command)
        end
    end
end


while true do
    parallel.waitForAny(catchChatEvents, runChatCommands)
end
