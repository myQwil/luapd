local stros = love.system.getOS() ,ext
if     stros == 'Windows' then ext = 'dll'
elseif stros == 'OS X'    then ext = 'dylib'
else  ext = 'so'   end
package.cpath = '../../?.'..ext..';'..package.cpath
require('luapd')

local lpd = {msg = ''}
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

function lpd.open(file ,vol ,play)
	if type(vol)  == 'boolean' then
		play = vol
		vol  = nil   end
	if type(file) == 'number'  then
		vol  = file
		file = nil   end
	play = play == nil and true
	file = file or 'main.pd'
	vol  = vol and math.min(1 ,math.max(-1 ,vol)) or 1

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

return function()
	return lpd ,pd ,obj
end
