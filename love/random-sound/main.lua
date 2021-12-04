if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

package.path = '../?.lua;'..package.path
local lpd = require('pdmain')
local pd = lpd.pd
local patch ---@type Pd.Patch

function love.load()
	lpd.init()
	patch = lpd.open{volume = 0.2}
end

function love.update()
	lpd.update()
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
