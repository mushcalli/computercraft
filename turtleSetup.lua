-- on disk startup
if (turtle ~= nil and not fs.exists("startup.lua")) then
    local path = fs.getDir(shell.getRunningProgram())
    fs.copy(fs.combine(path, "turtleStartup.lua"), "startup.lua")
    --fs.copy(fs.combine(path, "navClient.lua"), "navClient.lua")
    shell.run("pastebin run J8azvLQg netnav_explore")
    shell.run("pastebin run J8azvLQg netnav")
    --shell.run("wget https://raw.githubusercontent.com/blunty666/CC-Pathfinding-and-Mapping/master/netNav/netNav_goto.lua goto.lua")
else
    shell.run("startup")
end
