rednet.broadcast("t mana", "CawwiCorp-mana")

local id, message = rednet.receive("CawwiCorp-mana")
if (message == "t") then
    print("enabling mana generation/netherite farm")
else
    print("enabling mana generation/netherite farm")
end