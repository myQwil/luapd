package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()

function love.load()
	luapd.init()
	patch = luapd.open{vol=0.2}
end

function love.update()
	luapd.update()
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
