
function math.clip(x ,min ,max)
	return (x < min and min) or (x > max and max) or x
end

local stros = love.system.getOS() ,ext
if     stros == 'Windows' then ext = 'dll'
elseif stros == 'OS X'    then ext = 'dylib'
else  ext = 'so'   end
package.cpath = '../../?.'..ext..';'..package.cpath
require('luapd')

local lpd =
{	 msg  = ''
	,file = 'main.pd'
	,vol  = 1
	,play = true   }

local pd  = PdBase()
local obj = PdObject{
	print = function(msg)
		print(msg)
		lpd.msg = msg
	end
}

local sdata ,source
local srate = require('samplerate')
local chIn ,chOut ,queued ,bitdepth ,ticks ,bufs =
      0    ,2     ,false  ,16       ,1     ,33
-- print('delay = '..ticks * bufs * pd.blockSize() / (srate/1000)..' ms')

function lpd.init()
	pd:setReceiver(obj)
	if not pd:init(chIn ,chOut ,srate ,queued) then
		print('Could not init pd')
		love.event.push('quit')   end
	pd:addToSearchPath('../../pd/lib')
	pd:computeAudio(true)

	local size = pd.blockSize() * ticks
	sdata  = love.sound.newSoundData(size ,srate ,bitdepth ,chOut)
	source = love.audio.newQueueableSource(srate ,bitdepth ,chOut ,bufs)
	love.graphics.setFont(love.graphics.newFont(16))
end

function lpd.open(opt)
	if type(opt) ~= 'table' then opt = lpd end
	local file ,vol ,play
	file = opt.file or lpd.file
	vol  = opt.vol and math.clip(opt.vol ,-1 ,1) or lpd.vol
	if opt.play ~= nil then
	     play = opt.play
	else play = lpd.play   end

	local pat = pd:openPatch(file)
	local dlr = pat:dollarZero()
	if dlr ~= 0 then
		pd:sendFloat(dlr..'vol' ,vol)
		if play then
			pd:sendBang(dlr..'play')   end   end
	return pat
end

function lpd.update()
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks ,sdata:getPointer())
		source:queue(sdata)
		source:play()   end
end

function lpd.draw()
	love.graphics.print(lpd.msg ,0 ,0)
end

return function()
	return lpd ,pd ,obj
end
