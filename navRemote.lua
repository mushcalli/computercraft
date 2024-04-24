local pretty = require("cc.pretty")

local args = {...}
local arg = args[1]
local protocol = "turtleNav"
local turtleHostname =  "tortle"

peripheral.find("modem", rednet.open)

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end

if type(arg) ~= "string" then
    error("hostname: string expected")
end
rednet.host(protocol, tostring(arg))


--[[
    TODO:
    - remember to use textutils.serialize() to send tables for requests
]]

local function sendPacket(turts, packet)
    --[[for i, turt in ipairs(turts) do
        rednet.send(turt, textutils.serialize(packet), protocol)
    end]]
    if (#turts <= 1) then
        rednet.send(turts[1], textutils.serialize(packet), protocol)
    else
        rednet.broadcast(textutils.serialize(packet), protocol)
    end
end


local msg = ""
local function receiveReturnMsgs()
    local id, message = rednet.receive(protocol)
    msg = msg .. message .. "\n"
end


local turtles = {}
local temp_turtles = {rednet.lookup(protocol)}
for i, id in ipairs(temp_turtles) do
    if (id == rednet.lookup(protocol, turtleHostname .. tostring(id))) then
        turtles[i] = id
    end
end

local uiLevel = 1
local currentTurtles = {}
local function main()
    term.clear()

    if (uiLevel == 1) then
        if (msg ~= "") then
            print(msg)
            msg = ""
        end
        
        print("turtles found:\n")
        --pretty.print(pretty.pretty(turtles))
        local turtString = ""
        for k, v in pairs(turtles) do
            turtString = turtString .. tostring(v) .. ", "
        end
        print(turtString)
        print("\nenter a turtle id to send commands (or enter 'a' for all):")

        local input = read()
        if (string.lower(input) == "a") then
            currentTurtles = turtles
            uiLevel = 2
            return
        else
            for i=1, #turtles do
                if (turtles[i] == tonumber(input)) then
                    currentTurtles = {tonumber(input)}
                    uiLevel = 2
                    return
                end
            end
        end
        -- if no return, invalid turtle id was entered
        printError("invalid turtle id")

    elseif (uiLevel == 2) then
        if (#currentTurtles <= 1) then
            print("controlling turtle id: " .. currentTurtles[1])
        else
            print("controlling all turtles (go back to see list)")
        end

        if (msg ~= "") then
            print(msg)
            msg = ""
        end

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
            currentTurtles = {}
            return
        elseif (key == keys.one) then
            local packet = {1}
            print("please enter coords: <x> <y> <z>")
            local input = read()
            for s in string.gmatch(input, "%S+") do
              table.insert(packet, s)
            end

            sendPacket(currentTurtles, packet)
        elseif (key == keys.two) then
            local location = {gps.locate()}

            if (location == nil) then
                printError("gps failed to get your location")
                return
            end

            local packet = {1, location[1], location[2], location[3]}
            sendPacket(currentTurtles, packet)
        elseif (key == keys.three) then
            local packet = {2,}
            sendPacket(currentTurtles, packet)
        elseif (key == keys.four) then
            local packet = {3,}
            sendPacket(currentTurtles, packet)
        elseif (key == keys.five) then
            local packet = {4,}
            sendPacket(currentTurtles, packet)
        elseif (key == keys.six) then
            print("enter code: ")
            local input = read()
            local packet = {5, input}
            sendPacket(currentTurtles, packet)
        end
    else
        uilevel = 1
        currentTurtles = {}
    end
end


-- main
while (true) do
    parallel.waitForAny(receiveReturnMsgs, main)
end