peripheral.find("modem", rednet.open)

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end

while true do
    local id, message
    repeat
        id, message = rednet.receive("CawwiCorp-mana")
    until (id == rednet.lookup("CawwiCorp", "cyber-irys"))

    if (message == "t mana") then
        -- toggle spawner
        local state = redstone.getOutput("bottom")
        redstone.setOutput("bottom", not state)
        if (state) then
            rednet.send(id, "f", "CawwiCorp-mana")
        else
            rednet.send(id, "t", "CawwiCorp-mana")
        end
    end
end