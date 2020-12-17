package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()

function love.load()
	luapd.init()
	local vol = .2
	patch = luapd.open(vol)
end

function love.update()
	luapd.update()
end

function love.keypressed(k)
	pd:sendBang('press')
end

function love.keyreleased(k)
	pd:sendBang('release')
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
