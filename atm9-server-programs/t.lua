--- t for toggle pylon effect

local pylon = peripheral.find("pylons:infusion_pylon")
if (not pylon) then error("error: pylon not found") end
local filters = peripheral.find("minecraft:barrel")
if (not filters) then error("error: potion filters storage not found") end

-- 1-7 usable, 8+9 dedicated to UI
local slots = {
    ["aqua"] = 1,
    ["purification"] = 2,
    ["flight"] = 3,
    ["reach"] = 4,
    ["sight"] = 5,
    ["ui"] = 8
}

local args = {...}
if (#args ~= 1 or not slots[args[1]]) then
    error("usage: t [aqua|purification|flight|reach|sight|ui]")
end

local slot = slots[args[1]]
if (not pylon.getItemDetail(slot)) then
    -- pull into pylon
    if (slot == 8) then
        -- *BLASTS ULTRA INSTINCT THEME*
        pylon.pullItems(peripheral.getName(filters), 8, 1, 8)
        pylon.pullItems(peripheral.getName(filters), 9, 1, 9)
        return
    end

    pylon.pullItems(peripheral.getName(filters), slot, 1, slot)
else
    -- push into barrel
    if (slot == 8) then
        -- *stops blasting ultra instinct theme*
        pylon.pushItems(peripheral.getName(filters), 8, 1, 8)
        pylon.pushItems(peripheral.getName(filters), 9, 1, 9)
        return
    end

    pylon.pushItems(peripheral.getName(filters), slot, 1, slot)
end