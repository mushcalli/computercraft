--- t for toggle pylon effect

local pylon = peripheral.find("pylons:infusion_pylon")
if (not pylon) then error("error: pylon not found") end
local filters = peripheral.find("minecraft:barrel")
if (not filters) then error("error: potion filters storage not found") end

-- 1-7 usable, 8+9 dedicated to UI
local slots = {
    ["aqua"] = 1,
    ["purify"] = 2,
    ["flight"] = 3,
    ["reach"] = 4,
    ["sight"] = 5,
    ["ui"] = 8,
    ["hs"] = 9
}

local fullNames = {[1] = "aquatic life", [2] = "purification", [3] = "flight", [4] = "reach", [5] = "true sight", [9] = "heart stop"}

local args = {...}
if (#args ~= 1 or not slots[args[1]]) then
    error("usage: t [aqua|purification|flight|reach|sight|hs|ui]")
end

local slot = slots[args[1]]
if (not pylon.getItemDetail(slot)) then
    -- pull into pylon
    if (slot == 8) then
        -- *BLASTS ULTRA INSTINCT THEME*
        print("§d*BLASTS ULTRA INSTINCT THEME*")
        pylon.pullItems(peripheral.getName(filters), 8, 1, 8)
        pylon.pullItems(peripheral.getName(filters), 9, 1, 9)
        return
    end

    print("enabling " .. fullNames[slot] .. ",,,")
    pylon.pullItems(peripheral.getName(filters), slot, 1, slot)
else
    -- push into barrel
    if (slot == 8) then
        -- *stops blasting ultra instinct theme*
        print("§ddisabling ultra instinct,,,")
        pylon.pushItems(peripheral.getName(filters), 8, 1, 8)
        pylon.pushItems(peripheral.getName(filters), 9, 1, 9)
        return
    end

    print("disabling " .. fullNames[slot] .. ",,,")
    pylon.pushItems(peripheral.getName(filters), slot, 1, slot)
end