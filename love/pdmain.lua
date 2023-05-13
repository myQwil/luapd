local function clamp(x, min, max)
	return (x < min and min) or (x > max and max) or x
end

local ext = {
	  ['Linux'] = 'so'
	, ['Windows'] = 'dll'
	, ['OS X'] = 'dylib'
}
local stros = love.system.getOS()
package.cpath = '../../?.' .. ext[stros] .. ';' .. package.cpath

Pd = require('luapd') ---@type Pd
local ticks, bufs ---@type integer, integer
local message ---@type string

local lpd = { -- default options
	  ticks = 1
	, bufs = 33
	, play = true
	, patch = 'main.pd'
	, volume = 1
}

lpd.pd = Pd.Base()
lpd.obj = Pd.Object {
	print = function(msg)
		message = msg
		print(msg)
	end
}
local pd = lpd.pd
local sdata ---@type love.SoundData
local source ---@type love.Source
local srate = require('samplerate')

local chIn = 0
local chOut = 2
local queued = false
local bitdepth = 16

local function getOptions(opt)
	if type(opt) ~= 'table' then opt = lpd
	else setmetatable(opt, {__index = lpd}) end
	return opt
end

---@param opt table|nil # A list of options
function lpd.init(opt)
	opt = getOptions(opt)
	ticks, bufs = opt.ticks, opt.bufs
	pd:setReceiver(opt.obj)
	if not pd:init(chIn, chOut, srate, queued) then
		print('Could not initialize pd')
		love.event.quit()
	end
	pd:addToSearchPath('../../pd/lib')
	pd:computeAudio(true)

	local size = pd.blockSize() * ticks
	sdata = love.sound.newSoundData(size, srate, bitdepth, chOut)
	source = love.audio.newQueueableSource(srate, bitdepth, chOut, bufs)
	love.graphics.setFont(love.graphics.newFont(16))
end

---@param opt table|nil # A list of options
---@return PdPatch
function lpd.open(opt)
	opt = getOptions(opt)
	local play, patch, volume = opt.play, opt.patch, clamp(opt.volume, -1, 1)
	patch = pd:openPatch(patch)
	local dlr = patch:dollarZeroStr()
	pd:sendFloat(dlr .. 'vol', volume)
	if play then
		pd:sendBang(dlr .. 'play')
	end
	return patch
end

function lpd.update()
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks, nil, sdata:getPointer())
		source:queue(sdata)
	end
	source:play() -- keep playing if there are underruns
end

function lpd.draw()
	love.graphics.print(message, 0, 0)
end

function lpd.print_delay()
	local blk = pd.blockSize()
	local sr = srate / 1000
	print('delay = ' .. ticks .. ' * ' .. bufs .. ' * ' .. blk
		.. ' / ' .. sr .. ' = ' .. ticks * bufs * blk / sr .. ' ms')
end

return lpd
