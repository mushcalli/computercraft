printError("pls start the turtle on the bottom left crop of the farm (relative to direction turtle is facing)")
--print("also put deposit chest behind the turtle's starting spot, the fuel hopper's redstone torch on a block on the left side, and some fuel items already in the hopper")
-- yeah that one was way too long for the terminal so its a code comment for the user now ^^

local usageMsg = 'usage: "farm [width] [length] [waitTime (in seconds)] [fuelBurnTicks]"\n(length is direction turtle is facing)\n(get fuel burn ticks from a wiki)'
local cacheName = "farmPos.txt"


local args = {...}
if (#args < 4) then
    error(usageMsg)
end

for i=1,4 do
    if (tonumber(args[i]) == nil) then
        error(usageMsg)
    end
end
local width = math.floor(tonumber(args[1]))
local length = math.floor(tonumber(args[2]))
local waitTime = math.floor(tonumber(args[3]))
local fuelValue = math.floor((tonumber(args[4]) * 5) / 100)

local fuelCost = 0
-- +5 to be safe
if (width % 2 == 1) then
    fuelCost = (width * length) + width + length + 5
else
    fuelCost = (width * length) + width + 5
end

--local harvestAges = {["minecraft"] = 7, ["harvestcraft"] = 3, ["pizzacraft"] = 6}
--local unplantable = {["minecraft:wheat"] = true}
local harvestBlock = {["minecraft:melon_block"] = true, ["minecraft:pumpkin"] = true}

local face = {["north"] = 1, ["east"] = 2, ["south"] = 3, ["west"] = 4}
local position = {0, 0, face.north}
local fullyHarvested = 0

local lastInventory = {}
local posBookmark = {0, 0}

local function updateCache()
    local cacheFile = fs.open(cacheName, "w")
    for i=1, 3 do
        cacheFile.writeLine(position[i])
    end
    cacheFile.writeLine(fullyHarvested)
    cacheFile.close()
end

local function checkExit()
    if (fullyHarvested >= 1) then
        print("all crops already harvested, heading back")
        return true
    end

    local fullSlots = 0
    for n=1, 16 do
        local nCount = turtle.getItemCount(n)
        if (nCount > 0) then
            --[[if (garbage[turtle.getItemDetail(n).name] and nCount > garbageDropMin) then
                turtle.select(n)
                turtle.dropUp()
            else]]
                fullSlots =  fullSlots + 1
            --end
        end
    end
    --turtle.select(1)

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

local function updateFace(amount)
    position[3] = (((position[3]-1) + amount) % 4) + 1
end


-- behavior functions
local function refuel()
    while (position[3] ~= face.north) do
        turtle.turnRight()
        updateFace(1)
        updateCache()
    end

    if (turtle.getFuelLevel() > fuelCost) then
        return
    end

    local fuelNeeded = math.ceil(math.max(0, fuelCost - turtle.getFuelLevel()) / fuelValue)
    redstone.setOutput("left", true)
    -- hoppers move 1 item every 0.4s
    os.sleep(0.4 * fuelNeeded)
    redstone.setOutput("left", false)
    for n=1, 16 do
        local nCount = turtle.getItemCount(n)
		if (nCount > 0) then
			turtle.select(n)
            turtle.refuel()
            os.sleep(0.1)
        end
    end
    turtle.select(1)
end

local function depositItems()
    while (position[3] ~= face.south) do
        turtle.turnLeft()
        updateFace(-1)
        updateCache()
    end

    for n=1, 16 do
        local nCount = turtle.getItemCount(n)
		if (nCount > 0) then
			turtle.select(n)
            turtle.drop()
            os.sleep(0.1)
        end
    end
    turtle.select(1)
end

local function goHome()
    -- left until x=0
    while (position[3] ~= face.west) do
        turtle.turnLeft()
        updateFace(-1)
    end
    while (position[1] > 0) do
        turtle.forward()
        position[1] = position[1] - 1
        updateCache()
    end

    -- down until y=0
    while (position[3] ~= face.south) do
        turtle.turnLeft()
        updateFace(-1)
        updateCache()
    end
    while (position[2] > 0) do
        turtle.forward()
        position[2] = position[2] - 1
        updateCache()
    end

    -- restock turtle
    depositItems()

    while (position[3] ~= face.north) do
        turtle.turnRight()
        updateFace(1)
        updateCache()
    end
end

local function getCrop()
    -- check and harvest crop under
    local success, data = turtle.inspectDown()
    if (data.name) then
        --local i, j, cropSource = string.find(data.name, "(.+):")
        os.setComputerLabel(data.name)
        --local harvestAge = harvestAges[cropSource] or 7

        --if (data.state.age == harvestAge) then
        if (harvestBlock[data.name]) then
            -- 'cache' current inventory for comparison (absolutely awful i know but i couldnt think of anything better)
            --[[
            for n=1, 16 do
                local nCount = turtle.getItemCount(n)
                lastInventory[n] = nCount
            end
            ]]

            turtle.digDown()
            turtle.suckDown()

            --[[
            for n=1, 16 do
                local nCount = turtle.getItemCount(n)
                if (nCount > lastInventory[n] and not unplantable[turtle.getItemDetail(n).name]) then
                    turtle.select(n)
                    turtle.placeDown()
                end
            end
            ]]
            
            turtle.select(1)
        end
    end
end

local function doStep()
    -- move
    local suc, msg = turtle.forward()
    if (not suc) then error("failed to move: " .. msg) end

    if (position[3] == face.north) then
        position[2] = position[2] + 1
    elseif (position[3] == face.east) then
        position[1] = position[1] + 1
    elseif (position[3] == face.south) then
        position[2] = position[2] - 1
    elseif (position[3] == face.west) then
        position[1] = position[1] - 1
    end
end

local function doHarvest()
    while (fullyHarvested < 1) do
        -- return to where it left off
        if (posBookmark[1] ~= 0 or posBookmark[2] ~= 0) then
            print("returning to bookmark x=" .. posBookmark[1] .. ", y=" .. posBookmark[2])

            while (position[2] < posBookmark[2]) do
                doStep()
                updateCache()
            end

            while (position[3] ~= face.east) do
                turtle.turnRight()
                updateFace(1)
                updateCache()
            end
            while (position[1] < posBookmark[1]) do
                doStep()
                updateCache()
            end

            -- adjust face and then continue
            local intendedDir = face.north
            -- if on an even column of farm, should be going south
            if (position[1] % 2 == 1) then
                intendedDir = face.south
            end
            while (position[3] ~= intendedDir) do
                turtle.turnRight()
                updateFace(1)
                updateCache()
            end
        end

        repeat
            if (checkExit()) then break end

            if (position[3] == face.north) then
                while (position[2] < length-1) do
                    getCrop()
                    doStep()
                    if (fullCheck()) then break end
                end
                if (checkExit()) then break end

                turtle.turnRight()
                updateFace(1)
                updateCache()
                getCrop()
                doStep()
                if (fullCheck()) then break end
                turtle.turnRight()
                updateFace(1)
                updateCache()
            else
                while (position[2] > 0) do
                    getCrop()
                    doStep()
                    if (fullCheck()) then break end
                end
                if (checkExit()) then break end

                turtle.turnLeft()
                updateFace(-1)
                updateCache()
                getCrop()
                doStep()
                if (fullCheck()) then break end
                turtle.turnLeft()
                updateFace(-1)
                updateCache()
            end
        
            -- check if at end of farm
            if (position[1] >= width-1 and ((width % 2 == 1 and position[2] >= length-1) or (width % 2 == 0 and position[2] <= 0))) then
                fullyHarvested = 1
                getCrop()
                print("harvest done!")
            end
        until (fullyHarvested >= 1)

        -- come back
        posBookmark[1] = position[1]
        posBookmark[2] = position[2]
        goHome()
        refuel()
    end
end


-- main
-- create cache clearer program if it doesnt exist already
if (not fs.exists("farmCacheClear.lua")) then
    local cacheClear = fs.open("farmCacheClear.lua", "w")
    cacheClear.writeLine('fs.delete("' .. cacheName .. '")')
    cacheClear.close()
end

-- read from cache if it exists
if (fs.exists(cacheName)) then
    local cacheFile = fs.open(cacheName, "r")
    local cache = {}
    for i=1, 3 do
        cache[i] = tonumber(cacheFile.readLine())
    end
    fullyHarvested = tonumber(cacheFile.readLine())
    cacheFile.close()
    
    position = cache
    print("found valid cache, current x=" .. cache[1] .. ", y=" .. cache[2] .. "face=" .. cache[3])
end

-- adjust face and then continue
local intendedDir = face.north
-- if on an even column of farm, should be going south
if (position[1] % 2 == 1) then
    intendedDir = face.south
end
while (position[3] ~= intendedDir) do
    turtle.turnRight()
    updateFace(1)
    updateCache()
end


-- main
if (position[1] == 0 and position[2] == 0 and position[3] == face.north) then
    refuel()
end

while (true) do
    doHarvest()
    fullyHarvested = 0
    posBookmark = {0, 0}
    if (fs.exists(cacheName)) then
        fs.delete(cacheName)
    end

    local timer = os.startTimer(waitTime)
    local event, id
    repeat
        event, id = os.pullEvent("timer")
    until id == timer
end