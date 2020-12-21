require('love.audio')
require('love.event')
require('love.sound')
require('love.system')
require('love.timer')

local stros = love.system.getOS() ,ext
if     stros == 'Windows' then ext = 'dll'
elseif stros == 'OS X'    then ext = 'dylib'
else  ext = 'so'   end
package.cpath = '../../?.'..ext..';'..package.cpath
require('luapd')

package.path = '../?.lua;'..package.path
local srate = require('samplerate')
local chIn ,chOut ,queued ,bitdepth ,ticks ,bufs =
      0    ,2     ,false  ,16       ,2     ,8

local pd = PdBase()
if not pd:init(chIn ,chOut ,srate ,queued) then
		print('Could not init pd')
		love.event.push('quit')   end
pd:addToSearchPath('../../pd/lib')
pd:computeAudio(true)

local size = pd.blockSize() * ticks
local sdata  = love.sound.newSoundData(size ,srate ,bitdepth ,chOut)
local source = love.audio.newQueueableSource(srate ,bitdepth ,chOut ,bufs)

local patch = pd:openPatch('../../pd/test.pd')
local dlr = patch:dollarZero()
if dlr ~= 0 then
	pd:sendFloat(dlr..'vol' ,.4)
	if play then
		pd:sendBang(dlr..'play')   end   end

local function process()
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks ,sdata:getPointer())
		source:queue(sdata)
		source:play()   end
end

while true do
	process()
	if     love.thread.getChannel('stop'):pop() then
		pd:closePatch(patch)
		pd:computeAudio(false)
		return
	else
		local msg = love.thread.getChannel('msg'):pop()
		if msg then
			pd:sendFloat   ('tone-pos' ,0)
			pd:sendMessage ('tone' ,'pitch' ,{50})
			pd:sendBang    ('tone')   end
	end
	love.timer.sleep(0.001)
end
