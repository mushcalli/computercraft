--[[
wave version 0.1.5 PLUS OpenNBS support from wave-amp2

The MIT License (MIT)
Copyright (c) 2020 CrazedProgrammer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


local wave = { }
wave.version = "2.0.0"

wave._oldSoundMap = {"harp", "bassattack", "bd", "snare", "hat"}
wave._newSoundMap_original = {"harp", "bass", "basedrum", "snare", "hat", "guitar", "flute", "bell", "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling"}
wave._newSoundMap = deepcopy(wave._newSoundMap_original)
wave._defaultThrottle = 99
wave._defaultClipMode = 1
wave._maxInterval = 1
wave._isNewSystem = true
-- if _HOST then
--	wave._isNewSystem = _HOST:sub(15, #_HOST) >= "1.80"
-- end

wave.context = { }
wave.output = { }
wave.track = { }
wave.instance = { }

function wave.createContext(clock, volume)
	clock = clock or os.clock()
	volume = volume or 1.0

	local context = setmetatable({ }, {__index = wave.context})
	context.outputs = { }
	context.instances = { }
	context.vs = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	context.prevClock = clock
	context.volume = volume
	return context
end

function wave.context:addOutput(...)
	local output = wave.createOutput(...)
	self.outputs[#self.outputs + 1] = output
	return output
end

function wave.context:addOutputs(...)
	local outs = {...}
	if #outs == 1 then
		if not getmetatable(outs) then
			outs = outs[1]
		else
			if getmetatable(outs).__index ~= wave.outputs then
				outs = outs[1]
			end
		end
	end
	for i = 1, #outs do
		self:addOutput(outs[i])
	end
end

function wave.context:removeOutput(out)
	if type(out) == "number" then
		table.remove(self.outputs, out)
		return
	elseif type(out) == "table" then
		if getmetatable(out).__index == wave.output then
			for i = 1, #self.outputs do
				if out == self.outputs[i] then
					table.remove(self.outputs, i)
					return
				end
			end
			return
		end
	end
	for i = 1, #self.outputs do
		if out == self.outputs[i].native then
			table.remove(self.outputs, i)
			return
		end
	end
end

function wave.context:addInstance(...)
	local instance = wave.createInstance(...)
	self.instances[#self.instances + 1] = instance
	return instance
end

function wave.context:removeInstance(instance)
	if type(instance) == "number" then
		table.remove(self.instances, instance)
	else
		for i = 1, #self.instances do
			if self.instances == instance then
				table.remove(self.instances, i)
				return
			end
		end
	end
end

--[[
note: note block instrument, 0-15
pitch: F#3 is zero, F#5 is 24
volume: float 0.0-1.0, volume scalar
**stopNote() does not exist, note blocks usually play their note for ~0.2s or so
]]
function wave.context:playNote(note, pitch, volume)
	volume = volume or 1.0

    if not (self.vs[note]) then
        self.vs[note] = 0
    end

	self.vs[note] = self.vs[note] + volume
	for i = 1, #self.outputs do
		self.outputs[i]:playNote(note, pitch, volume * self.volume)
	end
end

function wave.context:update(interval)
	local clock = os.clock()
	interval = interval or (clock - self.prevClock)

	self.prevClock = clock
	if interval > wave._maxInterval then
		interval = wave._maxInterval
	end
	for i = 1, #self.outputs do
		self.outputs[i].notes = 0
	end
	for i = 1, 10 do
		self.vs[i] = 0
	end
	if interval > 0 then
		for i = 1, #self.instances do
			local notes = self.instances[i]:update(interval)
			for j = 1, #notes / 3 do
				self:playNote(notes[j * 3 - 2], notes[j * 3 - 1], notes[j * 3])
			end
		end
	end
end



function wave.createOutput(out, volume, filter, throttle, clipMode)
	volume = volume or 1.0
	filter = filter or {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
	throttle = throttle or wave._defaultThrottle
	clipMode = clipMode or wave._defaultClipMode

	local output = setmetatable({ }, {__index = wave.output})
	output.native = out
	output.volume = volume
	output.filter = deepcopy(filter)
	output.notes = 0
	output.throttle = throttle
	output.clipMode = clipMode
	if type(out) == "function" then
		output.nativePlayNote = out
		output.type = "custom"
		return output
	elseif type(out) == "string" then
		if peripheral.getType(out) == "speaker" then
			if wave._isNewSystem then
				local nb = peripheral.wrap(out)
				output.type = "speaker"
				function output.nativePlayNote(note, pitch, volume)
					if output.volume * volume > 0 then
						if note <= 16 then
                            --nb.playSound("minecraft:block.note_block."..wave._newSoundMap[note], volume, math.pow(2, (pitch - 12) / 12))
                            nb.playNote(wave._newSoundMap[note], volume, pitch)
                        else
                            nb.playSound(wave._newSoundMap[note], volume, math.pow(2, (pitch - 12) / 12))
                        end
					end
				end
				return output
			end
		end
	elseif type(out) == "table" then
		if out.execAsync then
			output.type = "commands"
			if wave._isNewSystem then
				function output.nativePlayNote(note, pitch, volume)
                    if note <= 16 then
					    out.execAsync("playsound minecraft:block.note_block."..wave._newSoundMap[note].." record @a ~ ~ ~ "..tostring(volume).." "..tostring(math.pow(2, (pitch - 12) / 12)))
                    else
                        -- custom instruments
                        out.execAsync("playsound "..wave._newSoundMap[note].." record @a ~ ~ ~ "..tostring(volume).." "..tostring(math.pow(2, (pitch - 12) / 12)))
                    end
                end
			else
				function output.nativePlayNote(note, pitch, volume)
					out.execAsync("playsound note_block."..wave._oldSoundMap[note].." @a ~ ~ ~ "..tostring(volume).." "..tostring(math.pow(2, (pitch - 12) / 12)))
				end
			end
			return output
		elseif getmetatable(out) then
			if getmetatable(out).__index == wave.output then
				return out
			end
		end
	end
end

function wave.scanOutputs()
	local outs = { }
	if commands then
		outs[#outs + 1] = wave.createOutput(commands)
	end
	local sides = peripheral.getNames()
	for i = 1, #sides do
		if peripheral.getType(sides[i]) == "speaker" then
			outs[#outs + 1] = wave.createOutput(sides[i])
		end
	end
	return outs
end

function wave.output:playNote(note, pitch, volume)
	volume = volume or 1.0

	if self.clipMode == 1 then
		if pitch < 0 then
			pitch = 0
		elseif pitch > 24 then
			pitch = 24
		end
	elseif self.clipMode == 2 then
		if pitch < 0 then
			while pitch < 0 do
				pitch = pitch + 12
			end
		elseif pitch > 24 then
			while pitch > 24 do
				pitch = pitch - 12
			end
		end
	end
	--print("DEBUG Plaing note "..note.." with instrument "..wave._newSoundMap[note].. " !")
    if not (self.filter[note]) then
        self.filter[note] = true
    end
	if self.filter[note] and self.notes < self.throttle then
		--print("TEST")
		self.nativePlayNote(note, pitch, volume * self.volume)
		self.notes = self.notes + 1
	end
end


function wave.loadNewTrack(path)

	local track = setmetatable({ }, {__index = wave.track})
    track._soundMap = deepcopy(wave._newSoundMap_original) -- inherit default sound map
	local handle = fs.open(path, "rb")
	if not handle then return end

	local function readInt(size)
		local num = 0
		for i = 0, size - 1 do
			local byte = handle.read()
			if not byte then -- dont leave open file handles no matter what
				handle.close()
				return
			end
			num = num + byte * (256 ^ i)
		end
		return num
	end
	local function readStr()
		local length = readInt(4)
		if not length then return end
		local data = { }
		for i = 1, length do
			data[i] = string.char(handle.read())
		end
		return table.concat(data)
	end

	-- Part #1: Metadata
	print("New format bytes: " .. readInt(2))

	track.version = readInt(1);
	track.instCount = readInt(1);
	track.length = readInt(2) -- song length (ticks)
	track.height = readInt(2) -- song height
	track.name = readStr() -- song name
	track.author = readStr() -- song author
	track.originalAuthor = readStr() -- original song author
	track.description = readStr() -- song description
	track.tempo = readInt(2) / 100 -- tempo (ticks per second)
	track.autoSaving = readInt(1) == 0 and true or false -- auto-saving
	track.autoSavingDuration = readInt(1) -- auto-saving duration
	track.timeSignature = readInt(1) -- time signature (3 = 3/4)
	track.minutesSpent = readInt(4) -- minutes spent
	track.leftClicks = readInt(4) -- left clicks
	track.rightClicks = readInt(4) -- right clicks
	track.blocksAdded = readInt(4) -- blocks added
	track.blocksRemoved = readInt(4) -- blocks removed
	track.schematicFileName = readStr() -- midi/schematic file name
	track.loop = readInt(1)
	track.maxLoopCount = readInt(1)
	track.loopStartTick = readInt(2)





	-- Part #2: Notes
	track.layers = { }
	for i = 1, track.height do
		track.layers[i] = {name = "Layer "..i, volume = 1.0}
		track.layers[i].notes = { }
	end

	local tick = 0
	while true do
		local tickJumps = readInt(2)
		if tickJumps == 0 then break end
		tick = tick + tickJumps
		local layer = 0
		while true do
			local layerJumps = readInt(2)
			if layerJumps == 0 then
				track.length = tick
				break
			end
			layer = layer + layerJumps
			if layer > track.height then -- nbs can be buggy
				for i = track.height + 1, layer do
					track.layers[i] = {name = "Layer "..i, volume = 1.0}
					track.layers[i].notes = { }
				end
				track.height = layer
			end
			local instrument = readInt(1)
			local key = readInt(1)
			local noteBlockVolume = readInt(1)
			local noteBlockPan = readInt(1)
			local noteBlockPitch = readInt(2)
			if instrument <= 16 then -- nbs can be buggy
				track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
            else
                -- custom instruments
                track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
			end
		end
	end


	-- Part #3: Layers
	for i = 1, track.height do
		local name = readStr()
		local layerLock = readInt(1)
		local layerVolume = readInt(1)
		local layerStereo = readInt(1)
		if not name then print("NO NAME") break end -- if layer data doesnt exist, abort
		track.layers[i].name = name
		track.layers[i].volume = layerVolume / 100
	end


    -- Part #4: Custom instruments
    local customInstCount = readInt(1)
    for i = 1, customInstCount do
        local name = readStr() -- sound name without
        local instFilename = readStr()
        local key = readInt(1)
        local press = readInt(1)
        -- Create new instrument
        table.insert(track._soundMap, name)
    end


	handle.close()
	return track
end

function wave.loadTrack(path)
	local track = setmetatable({ }, {__index = wave.track})
	local handle = fs.open(path, "rb")
	if not handle then return end

	local function readInt(size)
		local num = 0
		for i = 0, size - 1 do
			local byte = handle.read()
			if not byte then -- dont leave open file handles no matter what
				handle.close()
				return
			end
			num = num + byte * (256 ^ i)
		end
		return num
	end
	local function readStr()
		local length = readInt(4)
		if not length then return end
		local data = { }
		for i = 1, length do
			data[i] = string.char(handle.read())
		end
		return table.concat(data)
	end

	-- Part #1: Metadata

	firstBytes = readInt(2)
	if firstBytes == 0 then
		print("Found new NBS file; Using new loader...")
		handle.close()
		return wave.loadNewTrack(path)
	end

	track.length = firstBytes -- song length (ticks)
	track.height = readInt(2) -- song height
	track.name = readStr() -- song name
	track.author = readStr() -- song author
	track.originalAuthor = readStr() -- original song author
	track.description = readStr() -- song description
	track.tempo = readInt(2) / 100 -- tempo (ticks per second)
	track.autoSaving = readInt(1) == 0 and true or false -- auto-saving
	track.autoSavingDuration = readInt(1) -- auto-saving duration
	track.timeSignature = readInt(1) -- time signature (3 = 3/4)
	track.minutesSpent = readInt(4) -- minutes spent
	track.leftClicks = readInt(4) -- left clicks
	track.rightClicks = readInt(4) -- right clicks
	track.blocksAdded = readInt(4) -- blocks added
	track.blocksRemoved = readInt(4) -- blocks removed
	track.schematicFileName = readStr() -- midi/schematic file name

	-- Part #2: Notes
	track.layers = { }
	for i = 1, track.height do
		track.layers[i] = {name = "Layer "..i, volume = 1.0}
		track.layers[i].notes = { }
	end

	local tick = 0
	while true do
		local tickJumps = readInt(2)
		if tickJumps == 0 then break end
		tick = tick + tickJumps
		local layer = 0
		while true do
			local layerJumps = readInt(2)
			if layerJumps == 0 then
				track.length = tick
				break
			end
			layer = layer + layerJumps
			if layer > track.height then -- nbs can be buggy
				for i = track.height + 1, layer do
					track.layers[i] = {name = "Layer "..i, volume = 1.0}
					track.layers[i].notes = { }
				end
				track.height = layer
			end
			local instrument = readInt(1)
			local key = readInt(1)
			if instrument <= 9 then -- nbs can be buggy
				track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
			end
		end
	end

	-- Part #3: Layers
	for i = 1, track.height do
		local name = readStr()
		if not name then break end -- if layer data doesnt exist, abort
		track.layers[i].name = name
		track.layers[i].volume = readInt(1) / 100
	end

	handle.close()
	return track
end

function wave.loadNewTrackFromHandle(handle)

	local track = setmetatable({ }, {__index = wave.track})
    track._soundMap = deepcopy(wave._newSoundMap_original) -- inherit default sound map
	--local handle = fs.open(path, "rb")
	if not handle then return end

	local function readInt(size)
		local num = 0
		for i = 0, size - 1 do
			local byte = string.byte(handle.read())
			if not byte then -- dont leave open file handles no matter what
				handle.close()
				return
			end
			num = num + byte * (256 ^ i)
		end
		return num
	end
	local function readStr()
		local length = readInt(4)
		if not length then return end
		local data = { }
		for i = 1, length do
			data[i] = handle.read()
		end
		return table.concat(data)
	end

	-- Part #1: Metadata
	print("New format bytes: " .. readInt(2))

	track.version = readInt(1);
	track.instCount = readInt(1);
	track.length = readInt(2) -- song length (ticks)
	track.height = readInt(2) -- song height
	track.name = readStr() -- song name
	track.author = readStr() -- song author
	track.originalAuthor = readStr() -- original song author
	track.description = readStr() -- song description
	track.tempo = readInt(2) / 100 -- tempo (ticks per second)
	track.autoSaving = readInt(1) == 0 and true or false -- auto-saving
	track.autoSavingDuration = readInt(1) -- auto-saving duration
	track.timeSignature = readInt(1) -- time signature (3 = 3/4)
	track.minutesSpent = readInt(4) -- minutes spent
	track.leftClicks = readInt(4) -- left clicks
	track.rightClicks = readInt(4) -- right clicks
	track.blocksAdded = readInt(4) -- blocks added
	track.blocksRemoved = readInt(4) -- blocks removed
	track.schematicFileName = readStr() -- midi/schematic file name
	track.loop = readInt(1)
	track.maxLoopCount = readInt(1)
	track.loopStartTick = readInt(2)





	-- Part #2: Notes
	track.layers = { }
	for i = 1, track.height do
		track.layers[i] = {name = "Layer "..i, volume = 1.0}
		track.layers[i].notes = { }
	end

	local tick = 0
	while true do
		local tickJumps = readInt(2)
		if tickJumps == 0 then break end
		tick = tick + tickJumps
		local layer = 0
		while true do
			local layerJumps = readInt(2)
			if layerJumps == 0 then
				track.length = tick
				break
			end
			layer = layer + layerJumps
			if layer > track.height then -- nbs can be buggy
				for i = track.height + 1, layer do
					track.layers[i] = {name = "Layer "..i, volume = 1.0}
					track.layers[i].notes = { }
				end
				track.height = layer
			end
			local instrument = readInt(1)
			local key = readInt(1)
			local noteBlockVolume = readInt(1)
			local noteBlockPan = readInt(1)
			local noteBlockPitch = readInt(2)
			if instrument <= 16 then -- nbs can be buggy
				track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
            else
                -- custom instruments
                track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
			end
		end
	end


	-- Part #3: Layers
	for i = 1, track.height do
		local name = readStr()
		local layerLock = readInt(1)
		local layerVolume = readInt(1)
		local layerStereo = readInt(1)
		if not name then print("NO NAME") break end -- if layer data doesnt exist, abort
		track.layers[i].name = name
		track.layers[i].volume = layerVolume / 100
	end


    -- Part #4: Custom instruments
    local customInstCount = readInt(1)
    for i = 1, customInstCount do
        local name = readStr() -- sound name without
        local instFilename = readStr()
        local key = readInt(1)
        local press = readInt(1)
        -- Create new instrument
        table.insert(track._soundMap, name)
    end


	handle.close()
	return track
end

function wave.loadTrackFromHandle(handle)
	local track = setmetatable({ }, {__index = wave.track})
	--local handle = fs.open(path, "rb")
	if not handle then return end

	local function readInt(size)
		local num = 0
		for i = 0, size - 1 do
			local byte = string.byte(handle.read())
			if not byte then -- dont leave open file handles no matter what
				handle.close()
				return
			end
			num = num + byte * (256 ^ i)
		end
		return num
	end
	local function readStr()
		local length = readInt(4)
		if not length then return end
		local data = { }
		for i = 1, length do
			data[i] = handle.read()
		end
		return table.concat(data)
	end

	-- Part #1: Metadata

	firstBytes = readInt(2)
	if firstBytes == 0 then
		print("Found new NBS file; Using new loader...")
		--handle.close()
		return wave.loadNewTrackFromHandle(handle)
	end

	track.length = firstBytes -- song length (ticks)
	track.height = readInt(2) -- song height
	track.name = readStr() -- song name
	track.author = readStr() -- song author
	track.originalAuthor = readStr() -- original song author
	track.description = readStr() -- song description
	track.tempo = readInt(2) / 100 -- tempo (ticks per second)
	track.autoSaving = readInt(1) == 0 and true or false -- auto-saving
	track.autoSavingDuration = readInt(1) -- auto-saving duration
	track.timeSignature = readInt(1) -- time signature (3 = 3/4)
	track.minutesSpent = readInt(4) -- minutes spent
	track.leftClicks = readInt(4) -- left clicks
	track.rightClicks = readInt(4) -- right clicks
	track.blocksAdded = readInt(4) -- blocks added
	track.blocksRemoved = readInt(4) -- blocks removed
	track.schematicFileName = readStr() -- midi/schematic file name

	-- Part #2: Notes
	track.layers = { }
	for i = 1, track.height do
		track.layers[i] = {name = "Layer "..i, volume = 1.0}
		track.layers[i].notes = { }
	end

	local tick = 0
	while true do
		local tickJumps = readInt(2)
		if tickJumps == 0 then break end
		tick = tick + tickJumps
		local layer = 0
		while true do
			local layerJumps = readInt(2)
			if layerJumps == 0 then
				track.length = tick
				break
			end
			layer = layer + layerJumps
			if layer > track.height then -- nbs can be buggy
				for i = track.height + 1, layer do
					track.layers[i] = {name = "Layer "..i, volume = 1.0}
					track.layers[i].notes = { }
				end
				track.height = layer
			end
			local instrument = readInt(1)
			local key = readInt(1)
			if instrument <= 9 then -- nbs can be buggy
				track.layers[layer].notes[tick * 2 - 1] = instrument + 1
				track.layers[layer].notes[tick * 2] = key - 33
			end
		end
	end

	-- Part #3: Layers
	for i = 1, track.height do
		local name = readStr()
		if not name then break end -- if layer data doesnt exist, abort
		track.layers[i].name = name
		track.layers[i].volume = readInt(1) / 100
	end

	handle.close()
	return track
end


function wave.createInstance(track, volume, playing, loop)
	volume = volume or 1.0
	playing = (playing == nil) or playing
	loop = (loop ~=  nil) and loop

	if getmetatable(track).__index == wave.instance then
		return track
	end
	local instance = setmetatable({ }, {__index = wave.instance})
	instance.track = track
	instance.volume = volume or 1.0
	instance.playing = playing
	instance.loop = loop
	instance.tick = 1
	return instance
end

function wave.instance:update(interval)
	local notes = { }
	if self.playing then
		local dticks = interval * self.track.tempo
		local starttick = self.tick
		local endtick = starttick + dticks
		local istarttick = math.ceil(starttick)
		local iendtick = math.ceil(endtick) - 1
		for i = istarttick, iendtick do
			for j = 1, self.track.height do
				if self.track.layers[j].notes[i * 2 - 1] then
					notes[#notes + 1] = self.track.layers[j].notes[i * 2 - 1]
					notes[#notes + 1] = self.track.layers[j].notes[i * 2]
					notes[#notes + 1] = self.track.layers[j].volume
				end
			end
		end
		self.tick = self.tick + dticks

		if endtick > self.track.length then
			self.tick = 1
			self.playing = self.loop
		end
	end
	return notes
end

return wave