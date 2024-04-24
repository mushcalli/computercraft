local args = {...}
if (#args ~= 1) then
    error("usage: player [frameDelay]")
end
if (not tonumber(args[1])) then
    error("usage: player [frameDelay]")
end

if (not fs.exists("disk/frames")) then
    error("video frames not found, insert a video disk/phone")
end

local frameDelay = tonumber(args[1])
if (fs.exists("disk/frameDelay.txt")) then
    local file = fs.open("disk/frameDelay.txt", "r")
    frameDelay = tonumber(file.readLine())
end

local monitor = peripheral.find("monitor")
term.redirect(monitor)
monitor.setTextScale(0.5)

local frameFiles = fs.list("disk/frames")
local frames = {}
for i, file in ipairs(frameFiles) do
    frames[i] = paintutils.loadImage("disk/frames/" .. file)
end


--shell.openTab("loopMusic 1")

while (true) do
    for i=1, #frames do
        paintutils.drawImage(frames[i], 0, 0)
        os.sleep(frameDelay)
    end
    os.sleep(0.05)
end 