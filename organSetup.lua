shell.run("wget https://github.com/noodle2521/computercraft/raw/main/organChunk.lua")

local num = read()

local file = fs.open("offset.txt", "w")
file.writeLine(num)
file.close()

local file2 = fs.open("startup.lua", "w")
file2.writeLine('shell.run("organChunk.lua")')
file2.close()

os.reboot()