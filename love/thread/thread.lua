require('love.audio')
require('love.event')
require('love.font')
require('love.graphics')
require('love.sound')
require('love.system')
require('love.timer')

package.path = '../?.lua;'..package.path
local lpd ,pd = require('pdmain')()

lpd.init(2 ,16)
local patch = lpd.open({file = '../../pd/test.pd'})

while true do
	lpd.update()
	if     love.thread.getChannel('stop'):pop() then
		pd:closePatch(patch)
		pd:computeAudio(false)
		return
	elseif love.thread.getChannel('msg'):pop() then
		pd:sendFloat   ('tone-pos' ,0)
		pd:sendMessage ('tone' ,'pitch' ,{50})
		pd:sendBang    ('tone')
	end
	love.timer.sleep(0.001)
end
