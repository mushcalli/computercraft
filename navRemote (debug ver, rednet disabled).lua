local pretty = require("cc.pretty")

local args = {...}
local arg = args[1]
local protocol = "turtleNav"

--[[peripheral.find("modem", rednet.open)

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end

if type(arg) ~= "string" then
    error("hostname: string expected")
end
rednet.host(protocol, tostring(arg))]]


--[[
    TODO:
    - remember to use textutils.serialize() to send tables for requests
]]

local msg = ""
--[[local function receiveReturnMsgs()
    local id, message = rednet.receive(protocol)
    msg = msg .. message .. "\n"
end]]


local turtles = {--[[rednet.lookup(protocol, "tortle")]]}

local uiLevel = 2
local currentTurtle = 0
local function main()
    term.clear()

    if (uiLevel == 1) then
        if (msg ~= "") then
            print(msg)
            msg = ""
        end
        
        print("turtles found:\n")
        pretty.print(pretty.pretty(turtles))
        print("\nenter a turtle id to send commands:")

        local input = read()
        for i=1, #turtles do
            if (turtles[i] == tonumber(input)) then
                currentTurtle = tonumber(input)
                uiLevel = 2;
                return
            end
        end
        -- invalid turtle id entered
        printError("invalid turtle id")

    elseif (uiLevel == 2) then
        print("id: " .. currentTurtle)

        if (msg ~= "") then
            print(msg)
            msg = ""
        end

        --print("\n")
        print([[

1: send turtle to <x> <y> <z>
2: send turtle to your location
3: cancel turtle's destination
4: refuel turtle
5: get turtle's current location
6: enter custom code for turtle
or press x to go back]])

        local event, key = os.pullEvent("key_up")
        if (key == keys.x) then
            --go back to turtle selection
            uiLevel = 1
            currentTurtle = 0
            return
        elseif (key == keys.one) then
            local packet = {1}
            print("please enter coords: <x> <y> <z>")
            local input = read()
            for k, v in string.gmatch(input, "[^%s]+") do
              packet[k+1] = v
            end

            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
            msg = pretty.render(pretty.pretty(packet))
        elseif (key == keys.two) then
            local location = {gps.locate()}

            if (location == nil) then
                printError("gps failed to get your location")
                return
            end

            local packet = {1, location[1], location[2], location[3]}
            msg = pretty.render(pretty.pretty(packet))
            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
        elseif (key == keys.three) then
            local packet = {2,}
            msg = pretty.render(pretty.pretty(packet))
            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
        elseif (key == keys.four) then
            local packet = {3,}
            msg = pretty.render(pretty.pretty(packet))
            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
        elseif (key == keys.five) then
            local packet = {4,}
            msg = pretty.render(pretty.pretty(packet))
            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
        elseif (key == keys.six) then
            print("enter code: ")
            local input = read()
            local packet = {5, input}
            msg = pretty.render(pretty.pretty(packet))
            --rednet.send(currentTurtle, textutils.serialize(packet), protocol)
        end
    else
        uilevel = 1
    end
end

-- main
while (true) do
    parallel.waitForAny(--[[receiveReturnMsgs, ]]main)
end