-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

if not turtle then
	printError("Requires a Tortle")
	return
end

local tArgs = { ... }
if #tArgs ~= 1 then
	local programName = arg[0] or fs.getName(shell.getRunningProgram())
	print("Usage: " .. programName .. " <diameter>")
	return
end

-- Mine in a quarry pattern until we hit something we can't dig
local size = tonumber(tArgs[1])
if size < 1 then
	print("Excavate diameter must be positive")
	return
end

local cacheName = "excPos.txt"

local depth = 0
local unloaded = 0
local collected = 0

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local done

local goTo -- Filled in further down
local refuel -- Filled in further down

local function updateCache()
	local cacheFile = fs.open(cacheName, "w")

	cacheFile.writeLine(xPos)
	cacheFile.writeLine(zPos)
	cacheFile.writeLine(depth)
	cacheFile.writeLine(xDir)
	cacheFile.writeLine(zDir)

	cacheFile.writeLine(done)
	cacheFile.close()
end

local function unload(_bKeepOneFuelStack)
	print("Unloading items...")
	for n = 1, 16 do
		local nCount = turtle.getItemCount(n)
		if nCount > 0 then
			turtle.select(n)
			local bDrop = true
			if _bKeepOneFuelStack and turtle.refuel(0) then
				bDrop = false
				_bKeepOneFuelStack = false
			end
			if bDrop then
				turtle.drop()
				unloaded = unloaded + nCount
			end
		end
	end
	collected = 0
	turtle.select(1)
end

local function returnSupplies()
	local x, y, z, xd, zd = xPos, depth, zPos, xDir, zDir
	print("Returning to surface...")
	goTo(0, 0, 0, 0, -1)

	local fuelNeeded = 2 * (x + y + z) + 1
	if not refuel(fuelNeeded) then
		unload(true)
		print("Waiting for fuel")
		while not refuel(fuelNeeded) do
			os.pullEvent("turtle_inventory")
		end
	else
		unload(true)
	end

	print("Resuming mining...")
	goTo(x, y, z, xd, zd)
end

local function collect()
	local bFull = true
	local nTotalItems = 0
	for n = 1, 16 do
		local nCount = turtle.getItemCount(n)
		if nCount == 0 then
			bFull = false
		end
		nTotalItems = nTotalItems + nCount
	end

	if nTotalItems > collected then
		collected = nTotalItems
		if math.fmod(collected + unloaded, 50) == 0 then
			print("Mined " .. collected + unloaded .. " items.")
		end
	end

	if bFull then
		print("No empty slots left.")
		return false
	end
	return true
end

function refuel(amount)
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then
		return true
	end

	local needed = amount or xPos + zPos + depth + 2
	if turtle.getFuelLevel() < needed then
		for n = 1, 16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
						turtle.refuel(1)
					end
					if turtle.getFuelLevel() >= needed then
						turtle.select(1)
						return true
					end
				end
			end
		end
		turtle.select(1)
		return false
	end

	return true
end

local function tryForwards()
	if not refuel() then
		print("Not enough Fuel")
		returnSupplies()
	end

	while not turtle.forward() do
		if turtle.detect() then
			if turtle.dig() then
				if not collect() then
					returnSupplies()
				end
			else
				return false
			end
		elseif turtle.attack() then
			if not collect() then
				returnSupplies()
			end
		else
			sleep(0.5)
		end
	end

	xPos = xPos + xDir
	zPos = zPos + zDir
	updateCache()
	return true
end

local function tryDown()
	if not refuel() then
		print("Not enough Fuel")
		returnSupplies()
	end

	while not turtle.down() do
		if turtle.detectDown() then
			if turtle.digDown() then
				if not collect() then
					returnSupplies()
				end
			else
				return false
			end
		elseif turtle.attackDown() then
			if not collect() then
				returnSupplies()
			end
		else
			sleep(0.5)
		end
	end

	depth = depth + 1
	updateCache()
	if math.fmod(depth, 10) == 0 then
		print("Descended " .. depth .. " metres.")
	end

	return true
end

local function turnLeft()
	turtle.turnLeft()
	xDir, zDir = -zDir, xDir
	updateCache()
end

local function turnRight()
	turtle.turnRight()
	xDir, zDir = zDir, -xDir
	updateCache()
end

function goTo(x, y, z, xd, zd)
	while depth > y do
		if turtle.up() then
			depth = depth - 1
			updateCache()
		elseif turtle.digUp() or turtle.attackUp() then
			collect()
		else
			sleep(0.5)
		end
	end

	if xPos > x then
		while xDir ~= -1 do
			turnLeft()
		end
		while xPos > x do
			if turtle.forward() then
				xPos = xPos - 1
				updateCache()
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep(0.5)
			end
		end
	elseif xPos < x then
		while xDir ~= 1 do
			turnLeft()
		end
		while xPos < x do
			if turtle.forward() then
				xPos = xPos + 1
				updateCache()
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep(0.5)
			end
		end
	end

	if zPos > z then
		while zDir ~= -1 do
			turnLeft()
		end
		while zPos > z do
			if turtle.forward() then
				zPos = zPos - 1
				updateCache()
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep(0.5)
			end
		end
	elseif zPos < z then
		while zDir ~= 1 do
			turnLeft()
		end
		while zPos < z do
			if turtle.forward() then
				zPos = zPos + 1
				updateCache()
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep(0.5)
			end
		end
	end

	while depth < y do
		if turtle.down() then
			depth = depth + 1
			updateCache()
		elseif turtle.digDown() or turtle.attackDown() then
			collect()
		else
			sleep(0.5)
		end
	end

	while zDir ~= zd or xDir ~= xd do
		turnLeft()
	end
end


-- main

if not refuel() then
	print("Out of Fuel")
	return
end

print("Excavating...")

local reseal = false
turtle.select(1)
if turtle.digDown() then
	reseal = true
end

-- create cache clearer program if it doesnt exist already
if (not fs.exists("excCacheClear.lua")) then
	local cacheClear = fs.open("excCacheClear.lua", "w")
	cacheClear.writeLine('fs.delete("' .. cacheName .. '")')
	cacheClear.close()
end

-- read from cache if it exists
local cached = false

if (fs.exists(cacheName)) then
	local cacheFile = fs.open(cacheName, "r")
	local cache = {}
	for i=1, 5 do
		cache[i] = tonumber(cacheFile.readLine())
	end
	done = tonumber(cacheFile.readLine())
	cacheFile.close()

	--[[
		cacheFile.writeLine(xPos)
		cacheFile.writeLine(zPos)
		cacheFile.writeLine(depth)
		cacheFile.writeLine(xDir)
		cacheFile.writeLine(zDir)
	]]
	xPos = cache[1]
	zPos = cache[2]
	depth = cache[3]
	xDir = cache[4]
	zDir = cache[5]

	
	print("found valid cache, current x=" .. cache[1] .. ", z=" .. cache[2] .. ", depth=" .. cache[3] .. ", face=(" .. cache[4] .. "x, " .. cache[5] .. "z)")

	cached = true
end


local alternate = 0
local layerstate = -1
if (math.fmod(size, 2) == 1) then
	alternate = math.fmod(depth, 2)
else
	layerstate = math.fmod(depth, 4)
end
done = false
local n, _ = 1, 1
while not done do


	--[[
		ugly hardcoded states for restoring from cache :(
	]]
	if (layerstate < 0) then
		-- odd diameter, 2 states
		if (alternate == 0) then
			n = xPos + 1

			if (math.fmod(n, 2) == 1) then
				_ = zPos + 1

				repeat
					turnRight()
				until zDir > 0
			else
				_ = size - zPos

				repeat
					turnRight()
				until zDir < 0
			end
		else
			n = size - zPos

			if (math.fmod(n, 2) == 1) then
				_ = size - xPos

				repeat
					turnRight()
				until xDir < 0
			else
				_ = xPos + 1

				repeat
					turnRight()
				until xDir > 0
			end
		end
	else
		--even diameter, 4 states
		if (layerstate == 0) then
			n = xPos + 1

			if (math.fmod(n, 2) == 1) then
				_ = zPos + 1

				repeat
					turnRight()
				until zDir > 0
			else
				_ = size - zPos

				repeat
					turnRight()
				until zDir < 0
			end
		elseif (layerstate == 1) then
			n = zPos + 1

			if (math.fmod(n, 2) == 1) then
				_ = size - xPos

				repeat
					turnRight()
				until xDir < 0
			else
				_ = xPos + 1

				repeat
					turnRight()
				until xDir > 0
			end
		elseif (layerstate == 2) then
			n = size - xPos

			if (math.fmod(n, 2) == 1) then
				_ = xPos + 1

				repeat
					turnRight()
				until zDir < 0
			else
				_ = size - xPos

				repeat
					turnRight()
				until zDir > 0
			end
		else
			n = size - zPos

			if (math.fmod(n, 2) == 1) then
				_ = xPos + 1

				repeat
					turnRight()
				until xDir > 0
			else
				_ = size - xPos
				repeat
					turnRight()
				until xDir < 0
			end
		end
	end
	
	--[[if (cached) then
		turnRight()
		turnRight()
		tryForwards()
		turnRight()
		turnRight()
	end]]

	-- actual main loop below:
	while n <= size do
		while _ <= size-1 do
			os.setComputerLabel("n" .. n .. ",_" .. _ .. " (x" .. xPos .. ",z" .. zPos .. ")")
			if not tryForwards() then
				done = true
				break
			end

			_ = _ + 1
		end
		if done then
			break
		end
		if n < size then
			if math.fmod(n + alternate, 2) == 0 then
				turnLeft()
				if not tryForwards() then
					done = true
					break
				end
				turnLeft()
			else
				turnRight()
				if not tryForwards() then
					done = true
					break
				end
				turnRight()
			end
		end

		n = n + 1
		_ = 1
	end
	if done then
		break
	end

	if size > 1 then
		if math.fmod(size, 2) == 0 then
			turnRight()
		else
			if alternate == 0 then
				turnLeft()
			else
				turnRight()
			end
			alternate = 1 - alternate
		end
	end

	if not tryDown() then
		done = true
		break
	end

	n = 1
end

print("Returning to surface...")

-- Return to where we started
goTo(0, 0, 0, 0, -1)
unload(false)
goTo(0, 0, 0, 0, 1)

-- Seal the hole
if reseal then
	turtle.placeDown()
end

if (fs.exists(cacheName)) then
	fs.delete(cacheName)
end

print("Mined " .. collected + unloaded .. " items total.")
