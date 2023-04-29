if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

local ext = {
	  ['Linux'] = 'so'
	, ['Windows'] = 'dll'
	, ['OS X'] = 'dylib'
}
local stros = love.system.getOS()
package.cpath = '../../?.' .. ext[stros] .. ';' .. package.cpath
package.path = '../?.lua;' .. package.path

local Pd = require('luapd') ---@type Pd
local pd = Pd.Base()
local gui = require('pdgui')(pd)
local patch ---@type PdPatch
local silence ---@type PdArray
local buttons, sliders

local mic ---@type love.RecordingDevice
local source ---@type love.Source
local sdIn, sdOut ---@type love.SoundData, love.SoundData

local ptr ---@type lightuserdata
local srate = require('samplerate')
local ticks ,bufs ,bitdepth ,chIn ,chOut ,i ,n ,step
=     1     ,33   ,16       ,2    ,2     ,0 ,0 ,0

local function set_mode(self)
	pd:sendFloat(self.dest, self.val)
end

local function volChange(self, num)
	if num < 0.0011 then
		num = 0
	end
	self.num = num
	pd:sendFloat(self.dest, self.num)
end

function love.load()
	love.graphics.setFont(love.graphics.newFont(16))
	if not pd:init(chIn, chOut, srate) then
		print('Could not initialize pd')
		love.event.quit()
	end
	pd:addToSearchPath('../../pd/lib')
	patch = pd:openPatch('main.pd')
	pd:computeAudio(true)

	local devices = love.audio.getRecordingDevices()
	mic = devices[1]
	local size = pd.blockSize() * ticks
	if not mic:start(size * bufs, srate, bitdepth, chIn) then
		print("Could not start a recording device")
		love.event.quit()
	end

	sdOut = love.sound.newSoundData(size, srate, bitdepth, chOut)
	source = love.audio.newQueueableSource(srate, bitdepth, chOut, bufs)
	size = size * chIn
	silence = Pd.Array(size / 2) -- short to float
	step = size * 2 -- short to char

	local dlr = patch:dollarZeroStr()
	local w, h = love.graphics.getDimensions()
	gui.button.dest = dlr..'mode'
	gui.button.size = 33
	local half = 33 / 2
	gui.button.click = set_mode
	buttons = {
		  gui.button(w * 1/3 - half, h * 1/3 - half, { val = 0
			, label = { text = 'echo' } })
		, gui.button(w * 2/3 - half, h * 1/3 - half, { val = 1
			, label = { text = 'cos' } })
		, gui.button(w * 1/3 - half, h * 2/3 - half, { val = 2
			, label = { text = 'octave\ndoubler', y = -20 } })
		, gui.button(w * 2/3 - half, h * 2/3 - half, { val = 3
			, label = { text = 'timbre\nstamp', y = -20 } })
		, gui.button(w * 1/2 - half, h * 1/2 - half, { val = 4
			, label = { text = 'off' } })
	}

	gui.slider.rad = 25
	gui.slider.len = h - 50
	local opt1 = { dest = dlr..'opt1', min = 0, max = 1, num = 0
		, label = { text = '', x = -5 }, fmt = '%s%.4g' }
	local opt2 = { dest = dlr..'opt2', min = 0, max = 1, num = 0
		, label = { text = '', x = -5 }, fmt = '%s%.4g' }
	local vol  = { dest = dlr..'vol' , min = 0.001, max = 1, num = 1, log = true
		, label = { text = 'volume', x = -100 }, fmt = '%s: %.4g', change = volChange }
	sliders = {
		  gui.slider(20, 25, { y = opt1 }, { rgb = { .25, .66, .66 } })
		, gui.slider(90, 25, { y = opt2 }, { rgb = { .33, .5, .66 } })
		, gui.slider(w - 140, 25, { y = vol }, { rgb = { .75, .5, .75 } })
	}
end

function love.update(dt)
	while source:getFreeBufferCount() > 0 do
		if i + step > n then
			i = 0
			sdIn = mic:getData()
			if sdIn then
				ptr = sdIn:getPointer()
				n = sdIn:getSize()
			else
				ptr = silence()
				n = step
			end
		end
		pd:processShort(ticks, Pd.offset(ptr, i), sdOut:getPointer())
		source:queue(sdOut)
		i = i + step
	end
	source:play()

	gui.updateSliders(sliders)
	for j = #buttons, 1, -1 do
		buttons[j]:update(dt)
	end
end

function love.mousepressed(x, y)
	for j = #buttons, 1, -1 do
		if buttons[j]:mousepressed(x, y) then return end
	end
end

function love.draw()
	for j = 1, #sliders do sliders[j]:draw() end
	for j = 1, #buttons do buttons[j]:draw() end
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
