if (not fs.exists("she_knows_what_you_are.nfp")) then
    shell.run("wget https://drive.google.com/uc?export=download&id=15URCleFaudfI0Ca1zHVf_wKYQ3JzSoMu she_knows_what_you_are.nfp")
end

local monitor = peripheral.find("monitor")
term.redirect(monitor)
monitor.setTextScale(0.5)
local brisket = paintutils.loadImage("she_knows_what_you_are.nfp")
paintutils.drawImage(brisket, 0, 0)

while true do os.sleep(120) end