local chat = peripheral.find("chatBox")
if (not chat) then
    error("error: chatBox not found")
end

local function runInWindow(input)
    local w, h = term.getSize()
    local win = window.create(term.current(), 1, 1, w, h)
    local old = term.redirect(win)
    local ok = shell.run(input)
    term.redirect(old)
    return win, ok
end

local function messageCalli(msg, isError)
    if (string.find(msg, "\n")) then
        chat.sendMessageToPlayer(msg, "bonjour_baguette", "&bcyber-irys", "<>", "&3")
        return
    end

    if (not isError) then
        chat.sendToastToPlayer(msg, "^w^", "bonjour_baguette", "&bcyber irys", "<>", "&3")
    else
        chat.sendToastToPlayer("§c" .. msg, "@_@", "bonjour_baguette", "&bcyber-irys", "<>", "&3")
    end
end

function trim(s)
    local l = 1
    while string.sub(s,l,l) == ' ' do
      l = l+1
    end
    local r = string.len(s)
    while string.sub(s,r,r) == ' ' do
      r = r-1
    end
    return string.sub(s,l,r)
  end

--- main
local function runChatCommands()
    local event, command = os.pullEvent("chatCommand")
    local win, ok = runInWindow(command)
    local out = ""
    local _, lines = win.getSize()
    local i = 1
    local line = win.getLine(i)
    while (string.sub(line, 1, 1) ~= " " and i < lines) do
        out = out .. trim(line) .. "\n"

        i = i + 1
        line = win.getLine(i)
    end
    out = string.sub(out, 1, -1)
    
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
