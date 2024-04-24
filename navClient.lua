local pretty = require("cc.pretty")

local args = {...}
local arg = args[1]
local protocol = "turtleNav"
local hostname = "tortle"
local remote_hostname = "it_cawwi"

peripheral.find("modem", rednet.open)

if not netNav then
	if not os.loadAPI("netNav") then
		error("could not load netNav API")
	end
end

if (not rednet.isOpen()) then
    error("error: failed to open rednet")
end
rednet.host(protocol, hostname .. tostring(os.getComputerID()))

if type(arg) ~= "string" then
    error("remoteMap_name: string expected")
end
netNav.setMap(arg, 30)


--[[
    TODO:
    - go coords command (mode 1)
    - go to player command (probably just "go coords <pX, pY, pZ>" internally) (mode 1)
    - stop command (mode 2)
    - refuel command (mode 3)
    - get current pos (mode 4)
    - lua code passthrough for other turtle operations (mode 5)
    - send back returns from all commands through rednet
]]

local function sendBack(id, message)
    rednet.send(id, message, protocol)
end


local function getMoveRequests()
    local id, message
    local mTable
    repeat
        id, message = rednet.receive(protocol)
        mTable = textutils.unserialize(message)

        --if (id ~= rednet.lookup(protocol, remote_hostname)) then print("received msg from invalid host") end
    until (id == rednet.lookup(protocol, remote_hostname) and mTable[1] == 1)

    --[[if (id ~= rednet.lookup(protocol, remote_hostname)) then
        sendBack(id, "error: incorrect hostname for remote")
        return
    end
    ]]

    --if (id == rednet.lookup(protocol, remote_hostname) and mTable[1] == 1) then
    for i = 2, 4 do
        if tonumber(mTable[i]) then
            mTable[i] = math.floor(tonumber(mTable[i]))
        else
            sendBack(id, "argument "..(i-1).." must be a valid coordinate")
            return
        end
    end

    print("received move request")

    local maxDistance = turtle.getFuelLevel()
    print("going to coordinates = ", mTable[2], ",", mTable[3], ",", mTable[4])
    sendBack(id, "going to coordinates = " .. mTable[2] .. "," .. mTable[3] .. "," .. mTable[4])
    local ok, err = netNav.goto(mTable[2], mTable[3], mTable[4], maxDistance)
    if not ok then
        print("navigation failed: " .. tostring(err))
        sendBack(id, "navigation failed: " .. tostring(err))
    else
        print("succesfully navigated to coordinates")
        sendBack(id, "succesfully navigated to coordinates")
    end
    --end
end


local function getAsyncRequests()
    while (true) do
        local id, message
        local mTable
        repeat
            id, message = rednet.receive(protocol)
            mTable = textutils.unserialize(message)

            if (id ~= rednet.lookup(protocol, remote_hostname)) then
                print("error: incorrect hostname for remote")
                sendBack(id, "error: incorrect hostname for remote")
            end
        until (id == rednet.lookup(protocol, remote_hostname) and mTable[1] ~= 1)



        if (mTable[1] ~= 1) then
            print("async request received")
            if (mTable[1] == 2) then
                netNav.stop()
                sendBack(id, "turtle stopped")
            elseif (mTable[1] == 3) then
                local ret = turtle.refuel()
                sendBack(id, "turtle refueled")
            elseif (mTable[1] == 4) then
                local ret = {gps.locate()}
                sendBack(id, "turtle location: " .. tostring(ret[1]) .. ", " .. tostring(ret[2]) .. ", " .. tostring(ret[3]))
            elseif (mTable[1] == 5) then
                local func = load(mTable[2])
                local success = false
                local result = ""
                if (func ~= nil) then
                    success, result = pcall(func)
                end
                sendBack(id, mTable[2] .. (success and "run" or "failed") .. ", returned " .. tostring(result))
            end
        end
    end
end


-- main
while (true) do
    parallel.waitForAny(getMoveRequests, getAsyncRequests)
end