local dfpwm = require("cc.audio.dfpwm")

local speaker = peripheral.find("speaker")
if (not speaker) then error("error: speaker not found") end

local decoder = dfpwm.make_decoder()
local listpath = "caches/music_list.txt"
local music_list = {}


local function updateCache()
	local cacheFile = fs.open(listpath, "w")

    for _, line in ipairs(music_list) do
        cacheFile.writeLine(line[1] .. "|" .. line[2])
    end

	cacheFile.close()
end

local function play(path)
    for chunk in io.lines(path, 16 * 1024) do
        local buf = decoder(chunk)
        while not speaker.playAudio(buf) do
            local event, data = os.pullEvent()

            if (event == "key_up" and data == keys.enter) then
                return
            end
        end
    end
end

local function wget_play(url, filename)
    shell.run("wget " .. url .. '"' .. filename .. '"')
    if (fs.exists(filename)) then
        print("(press enter to stop)")
        play(filename)
        fs.delete(filename)
    else
        print("wget failed :(")
    end
    os.sleep(2)
end


---- main
-- read from music_list if exists
if (fs.exists(listpath)) then
    local file = fs.open(listpath, "r")
    local line = file.readLine()
    local i = 1
    while (line) do
        --if (music_list == {""}) then music_list = {} end
        local song = {}
        for str in string.gmatch(line, "[^%|]+") do
            table.insert(song, str)
        end
        music_list[i] = song
        
        line = file.readLine()
        i = i + 1
    end
end

if (#music_list > 10) then
    error("music list too long! ik its a skill issue but i dont wanna implement multi page ui-")
end


-- ui loop
while true do
    term.clear()

    print("songs:\n")
    if (#music_list == 0) then
        print("none")
    else
        for i, line in ipairs(music_list) do
            print(i .. ". " .. line[1])
        end
    end

    print("\n\n1-0: play song, W: add song, E: edit song, D: delete song, X: exit")

    local event, key = os.pullEvent("key_up")
    if (key >= keys.zero and key <= keys.nine and #music_list ~= 0) then
        local num
        if (key == keys.zero) then
            num = 10
        else
            num = key - keys.one + 1
        end

        if (music_list[num]) then
            wget_play(music_list[num][2], music_list[num][1] .. ".dfpwm")
        end
    elseif (key == keys.w) then
        if (#music_list > 9) then
            print("no there's too many already")
        else
            term.clear()

            print("new song title (spaces fine, pls no | thats my string separator):")
            local input1 = read()
            if (input1 == "") then goto continue end
            while (string.find(input1, "%|")) do
                print(">:(")
                input1 = read()
            end
            --music_list[#music_list+1][1] = input

            print("new song url (pls no | here either):")
            local input2 = read()
            if (input2 == "") then goto continue end
            while (string.find(input2, "%|")) do
                print(">:(")
                input2 = read()
            end
            --music_list[#music_list+1][2] = input

            table.insert(music_list, {input1, input2})

            updateCache()
        end
    elseif (key == keys.e) then
        print("which one? (1-0)")
        local event, key = os.pullEvent("key_up")
        if (key >= keys.zero and key <= keys.nine and #music_list ~= 0) then
            local num
            if (key == keys.zero) then
                num = 10
            else
                num = key - keys.one + 1
            end

            if (music_list[num]) then
                term.clear()

                print("new song title (spaces fine, pls no | thats my string separator):")
                local input1 = read()
                if (input1 == "") then input1 = music_list[num][1] end
                while (string.find(input1, "%|")) do
                    print(">:(")
                    input1 = read()
                end

                print("new song url (pls no | here either):")
                local input2 = read()
                if (input2 == "") then input2 = music_list[num][2] end
                while (string.find(input2, "%|")) do
                    print(">:(")
                    input2 = read()
                end
                
                music_list[num] = {input1, input2}

                updateCache()
            end
        end
    elseif (key == keys.d) then
        print("which one? (1-0)")
        local event, key = os.pullEvent("key_up")
        if (key >= keys.zero and key <= keys.nine and #music_list ~= 0) then
            local num
            if (key == keys.zero) then
                num = 10
            else
                num = key - keys.one + 1
            end

            if (music_list[num]) then
                print("removing " .. music_list[num][1])
                table.remove(music_list, num)
                updateCache()
                os.sleep(1)
            end
        end
    elseif (key == keys.x) then
        break
    end

    ::continue::
end