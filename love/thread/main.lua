if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

function love.load()
	local thread = love.thread.newThread('thread.lua')
	thread:start()
end

function love.mousepressed()
	love.thread.getChannel('msg'):push(true)
end

function love.quit()
	love.thread.getChannel('stop'):push(true)
end
