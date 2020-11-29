package.cpath = '../../?.so;'..package.cpath
require('luapd')

srate = require('samplerate')
chIn ,chOut ,queued ,bitdepth ,ticks ,nbufs =
0    ,2     ,true   ,16       ,4     ,9

lpd = {msg = ''}
pd  = PdBase()
obj = PdObject{
	print = function(msg)
		print(msg)
		lpd.msg = msg
	end
}

function lpd.init()
	if not pd:init(chIn ,chOut ,srate ,queued) then
		print('Could not init pd')
		love.event.push('quit')
	end
	pd:addToSearchPath('../../pd/lib')
	pd:computeAudio(true)
	pd:setReceiver(obj)

	bsize  = PdBase.blockSize() * ticks * chOut
	sdata  = love.sound.newSoundData(bsize ,srate ,bitdepth ,chOut)
	source = love.audio.newQueueableSource( srate ,bitdepth ,chOut ,nbufs)
	bsize  = bsize * 2
end

function lpd.open(file ,vol ,play)
	if type(file) == 'number' then
		vol  = file
		file = nil end
	vol  = vol  or 1
	play = play or true
	file = file or 'main.pd'
	local pat = pd:openPatch(file)
	local dlr = pat:dollarZero()
	if dlr == 0 then return pat end
	pd:sendFloat(dlr..'vol' ,vol)
	if play then
		pd:sendBang(dlr..'play') end
	pd:receiveMessages()
	return pat
end

function lpd.update(dt)
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks ,nil ,sdata:getPointer())
		source:queue(sdata ,0 ,bsize)
		source:play()
	end
end
