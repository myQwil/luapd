function math.clamp(x ,min ,max)
	return (x < min and min) or (x > max and max) or x
end

function Fif(cond ,T ,F)
	if cond then return T else return F end
end

local ext =
{	 ['Linux']   = 'so'
	,['Windows'] = 'dll'
	,['OS X']    = 'dylib'  }
local stros = love.system.getOS()
package.cpath = '../../?.'..ext[stros]..';'..package.cpath

Pd = require('luapd') ---@type Pd
local ticks ,bufs     ---@type number ,number
local message         ---@type string

local lpd =
{	-- default options
	 ticks = 1
	,bufs = 33
	,play = true
	,patch = 'main.pd'
	,volume = 1  }

lpd.pd  = Pd.Base()
lpd.obj = Pd.Object{
	print = function(msg)
		message = msg
		print(msg)
	end
}
local pd = lpd.pd
local sdata  ---@type love.SoundData
local source ---@type love.Source
local srate = require('samplerate')

local
chIn ,chOut ,queued ,bitdepth =
0    ,2     ,false  ,16

---@param opt table|nil # A list of options
function lpd.init(opt)
	if type(opt) ~= 'table' then opt = lpd end
	ticks = opt.ticks or lpd.ticks
	bufs  = opt.bufs  or lpd.bufs

	pd:setReceiver(opt.obj or lpd.obj)
	if not pd:init(chIn ,chOut ,srate ,queued) then
		print('Could not initialize pd')
		love.event.push('quit')   end
	pd:addToSearchPath('../../pd/lib')
	pd:computeAudio(true)

	local size = pd.blockSize() * ticks
	sdata  = love.sound.newSoundData(size ,srate ,bitdepth ,chOut)
	source = love.audio.newQueueableSource(srate ,bitdepth ,chOut ,bufs)
	love.graphics.setFont(love.graphics.newFont(16))
end

---@param opt table|nil # A list of options
---@return PdPatch
function lpd.open(opt)
	if type(opt) ~= 'table' then opt = lpd end
	local play ,patch ,volume
	play = Fif(opt.play ~= nil ,opt.play ,lpd.play)
	patch = opt.patch or lpd.patch
	volume = opt.volume and math.clamp(opt.volume ,-1 ,1) or lpd.volume

	patch = pd:openPatch(patch)
	local dlr = patch:dollarZero()
	if dlr ~= 0 then
		pd:sendFloat(dlr..'vol' ,volume)
		if play then
			pd:sendBang(dlr..'play')   end   end
	return patch
end

function lpd.update()
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks ,sdata:getPointer())
		source:queue(sdata)
		source:play()   end
end

function lpd.draw()
	love.graphics.print(message ,0 ,0)
end

function lpd.print_delay()
	local blk = pd.blockSize()
	local sr = srate / 1000
	print('delay = '..ticks..' * '..bufs..' * '..blk..' / '..sr..' = '
		..ticks * bufs * blk / sr..' ms')
end

return lpd
