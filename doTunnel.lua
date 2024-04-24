printError("pls start the turtle on the lower block of the strip mine uwu")
printError("btw type literally anything as a commandline argument to have the turtle keep making trips after returning when its inventory is full")
print("also: one time fuel in slot 1, block behind turtle, inventory for depositing under turtle (if no inventory is found itll just yeet the items on the ground and move on)")

local args = {...}
local oneTrip = true
if (#args >= 1) then
    oneTrip = false
end

local garbage = {["minecraft:stone"] = true, ["minecraft:cobblestone"] = true, ["minecraft:dirt"] = true, ["minecraft:gravel"] = true}
local garbageDropMin = 40


local fuelUsed = 0

local function updateCache()
    local cacheFile = fs.open("tunnelPos.txt", "w")
    cacheFile.write(tostring(fuelUsed))
    cacheFile.close()
end

local function checkExit()
    local outOfFuel = (turtle.getFuelLevel() - 5 <= math.floor(fuelUsed / 3))
    if outOfFuel then
        print("not enough fuel to continue, heading back")
        return true
    end

    local fullSlots = 0
    for n=1, 16 do
        local nCount = turtle.getItemCount(n)
        if (nCount > 0) then
            if (garbage[turtle.getItemDetail(n).name] and nCount > garbageDropMin) then
                turtle.select(n)
                turtle.dropUp()
            else
                fullSlots =  fullSlots + 1
            end
        end
    end
    turtle.select(1)

    if (fullSlots >= 16) then
        print("inventory full! heading back")
        return true
    else
        return false
    end
end

local function fullCheck()
    updateCache()
    return checkExit()
end

local function doTunnel()
    -- go straight to end of existing tunnel first
    while (turtle.forward()) do
        -- set fuelUsed to next multiple of 3 to set it to start of cycle
        fuelUsed = (math.floor(fuelUsed / 3) + 1) * 3
        if (fullCheck()) then break end
    end

    while (true) do
        if (checkExit()) then break end

        turtle.digUp()
        turtle.up()
        fuelUsed = fuelUsed + 1
        updateCache()
        repeat
            turtle.dig()
            os.sleep(0.4)
        until not turtle.detect()
        if (checkExit()) then break end

        turtle.down()
        fuelUsed = fuelUsed + 1
        if (fullCheck()) then break end

        turtle.dig()
        turtle.forward()
        fuelUsed = fuelUsed + 1
        if (fullCheck()) then break end
    end

    if (fuelUsed % 3 == 1) then
        turtle.digDown()
        turtle.down()

        -- set fuelUsed to next multiple of 3 to set it to start of cycle
        fuelUsed = (math.floor(fuelUsed / 3) + 1) * 3
        updateCache()
    end

    -- moonwalk until it hits a block, then deposit items/drop them on the ground, then exit
    while (turtle.back()) do end

    --[[turtle.turnLeft()
    turtle.turnLeft()]]
    for n=1, 16 do
        local nCount = turtle.getItemCount(n)
		if (nCount > 0) then
			turtle.select(n)
            turtle.dropDown()
        end
    end
    turtle.select(1)
    --[[turtle.turnRight()
    turtle.turnRight()]]
end

-- main
-- create cache clearer program if it doesnt exist already
if (not fs.exists("tunnelCacheClear.lua")) then
    local cacheClear = fs.open("tunnelCacheClear.lua", "w")
    cacheClear.writeLine('fs.delete("tunnelPos.txt")')
    cacheClear.close()
end

-- read from cache if it exists
if (fs.exists("tunnelPos.txt")) then
    local cacheFile = fs.open("tunnelPos.txt", "r")
    local cache = cacheFile.readLine()
    cacheFile.close()
    if (tonumber(cache)) then
        fuelUsed = math.floor(tonumber(cache))
        print("found valid cache, current fuelUsed = " .. fuelUsed)
    end
end

-- setup to continue the tunnel
if (fuelUsed % 3 == 1 and not checkExit()) then
    repeat
        turtle.dig()
        os.sleep(0.4)
    until not turtle.detect()

    turtle.digDown()
    turtle.down()

    -- set fuelUsed to next multiple of 3 to set it to start of cycle
    fuelUsed = (math.floor(fuelUsed / 3) + 1) * 3
    updateCache()
end

turtle.select(1)
turtle.refuel()

if (oneTrip) then
    doTunnel()
    fuelUsed = 0
else
    -- keep attempting to continue tunnel until fuel runs out
    while (turtle.getFuelLevel() > 0) do
        doTunnel()
        fuelUsed = 0
        checkExit()
    end
end

if (fs.exists("tunnelPos.txt")) then
    --[[
    local cacheFile = fs.open("tunnelPos.txt", "w")
    cacheFile.write("0")
    cacheFile.close()]]
    fs.delete("tunnelPos.txt")
end

print("done!")