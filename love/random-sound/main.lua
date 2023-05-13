if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

package.path = '../?.lua;' .. package.path
local lpd = require('pdmain')
local pd = lpd.pd
local patch ---@type PdPatch

local gui = require('pdgui')(pd)
local sliders

function love.load()
	lpd.init()
	patch = lpd.open { play = false }

	local dlr = patch:dollarZeroStr()
	local width, height = love.graphics.getDimensions()

	local met = {
		  dest = dlr..'met', min = 11, max = 6000, num = 1000, log = true
		, label = { text = 'milliseconds per beat' }
	}
	local vol = {
		  dest = dlr..'vol', min = -60, max = 0, num = -15
		, label = { text = 'volume', x = -100 }
		, snap = 10, len = height - 100, change = gui.volChange
	}

	gui.slider.rad = 25
	gui.slider.len = width - 150
	local h = gui.slider.rad / 2
	sliders = {
		  gui.slider(20, height / 2 - h, { x = met }, { rgb = { .25, .66, .66 } })
		, gui.slider(width - 90, 60, { y = vol }, { rgb = { .75, .5, .75 } })
	}

	for _, v in next, sliders do
		v:send()
	end
	pd:sendBang(dlr .. 'play')
end

function love.update()
	gui.updateSliders(sliders)
	lpd.update()
end

function love.draw()
	for i = 1, #sliders do
		sliders[i]:draw()
	end
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
