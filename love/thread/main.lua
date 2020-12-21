
function love.load()
	thread = love.thread.newThread('thread.lua')
	thread:start()
end

function love.mousepressed(x ,y ,btn)
	love.thread.getChannel('msg'):push(true)
end

function love.quit()
	love.thread.getChannel('stop'):push(true)
end
