shell.run("wget https://github.com/noodle2521/computercraft/raw/main/organChunk.lua")

local num = read()

local file = fs.open("offset.txt", "w")
file.writeLine(num)
file.close()

file = fs.open("startup.lua", "w")
file.writeLine('shell.run("organChunk.lua")')
file.close()
