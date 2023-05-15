if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

math.randomseed(os.time())

package.path = '../?.lua;' .. package.path
local lpd = require('pdmain')
local pd = lpd.pd
local patch ---@type PdPatch
local dlra, dlrb ---@type string, string

local margin = 5
local arr = { size = 26 }
arr.lo, arr.hi = 1, arr.size
local frac = 1 / (arr.size + 1 + margin * 2)
local auto = { on = false }
local swaps, sorter, mode

local rgb = {
	  normal = { 0.3, 0.3, 0.3 }
	, swap   = { 0.0, 1.0, 1.0 }
	, range  = { 0.5, 0.0, 0.5 }
	, pivot  = { 0.3, 0.7, 1.0 }
}

local gui = require('pdgui')(pd)
local sliders, buttons, toggles

local function setRange(lo, hi)
	local w = love.graphics.getWidth()
	arr.lo = w * frac * (lo + margin) - 10
	arr.hi = w * frac * (hi + margin) + 10
end

local function resetSort()
	swaps = nil
	sorter.step = 0
end

local function quicksort(a, lo, hi)
	while lo < hi do
		local pivot = a[lo]
		local i, j = lo + 1, hi
		while true do
			while a[j] > pivot do
				j = j - 1
			end
			while a[i] < pivot and i < j do
				i = i + 1
			end
			if i >= j then
				if j ~= lo then
					a[lo], a[j] = a[j], a[lo]
					swaps[#swaps + 1] = {lo, j, lo, hi, true}
				end
				break
			end
			a[i], a[j] = a[j], a[i]
			swaps[#swaps + 1] = {i, j, lo, hi, false}
			i = i + 1 ; j = j - 1
		end
		if j - lo < hi - j then
			quicksort(a, lo, j - 1)
			lo = j + 1
		else
			quicksort(a, j + 1, hi)
			hi = j - 1
		end
	end
end

---------- Widget Callbacks ----------

local function btnShuffle()
	resetSort()
	setRange(1, arr.size)
	sorter.on = false
	for i = #arr, 2, -1 do
		local j = math.random(i)
		arr[i].x, arr[j].x = arr[j].x, arr[i].x
		arr[i], arr[j] = arr[j], arr[i]
		arr[i].rgb = rgb.normal
	end
	arr[1].rgb = rgb.normal
end

local function tglMode(self, on)
	auto.on = false
	sorter.on = false
	self.on = not self.on
	pd:sendFloat(self.dest, self.on and self.non0 or 0)
end

local function tglSort(self)
	auto.on = false
	mode.on = false
	pd:sendFloat(mode.dest, 0)
	self.on = not self.on
	if swaps or not self.on then
		return
	end

	local a = {}
	swaps = {}
	for i = 1, #arr do
		a[#a + 1] = arr[i].val
	end
	quicksort(a, 1, #a)
	if #swaps > 0 then
		self.on = true
		self.time = 0
	else
		self.on = false
		swaps = nil
	end
end

local function tempoChange(self, num)
	self.num = num
	sorter.dur = num / 1000
	auto.dur = sorter.dur * 2
	pd:sendFloat(self.dest, 1 / sorter.dur)
end

--------------------------------------

function love.load()
	lpd.init()
	patch = lpd.open({ play = false })

	local w, h = love.graphics.getDimensions()
	local dlr = patch:dollarZeroStr()
	dlra, dlrb = dlr..'a', dlr..'b'

	-- fill the array
	for i = 1, arr.size do
		arr[i] = {
			  val = i - 1
			, x = w * frac * (i + margin) - 5
			, y = h - h * frac * (i + margin)
			, rgb = rgb.normal
		}
	end
	arr.y = h - h * frac * (arr.size + margin)
	setRange(1, arr.size)

	gui.button.size, gui.toggle.size = 30, 30
	local half = gui.button.size / 2
	buttons = {
		  gui.button(w * 3/8 - half, 50, { dest = 'shuffle'
			, label = { x = -13 }, click = btnShuffle })
	}

	toggles = {
		  gui.toggle(w * 4/8 - half, 50, { dest = 'sort'
			, label = { x = -1 }, click = tglSort })
		, gui.toggle(w * 5/8 - half, 50, { dest = dlr..'mode'
			, label = { text = 'random', x = -18 }, click = tglMode })
	}
	sorter = toggles[1]
	mode = toggles[2]
	for k, v in next, { time = 1, dur = 1, step = 0 } do
		sorter[k] = v
	end

	local vol = {
		  dest = dlr..'vol', min = -60, max = 0, num = -15
		, label = { text = 'volume', x = -100 }, snap = 10
		, len = h - 100, change = gui.volChange
	}
	local tpo = {
		  dest = dlr..'met', min = 4000, max = 31.25, num = sorter.dur * 1000
		, label = { text = 'tempo' }, snap = 2, log = true, len = h - 100
		, fmt = '%s: %s ms', drawText = gui.drawFixed, change = tempoChange
	}

	gui.slider.rad = 25
	gui.slider.len = w - 150
	local h = gui.slider.rad / 2
	sliders = {
		  gui.slider(w - 90, 60, { y = vol }, { rgb = { .75, .5, .75 } })
		, gui.slider(40    , 60, { y = tpo }, { rgb = { .5, .75, .75 } })
	}
	for _, v in next, sliders do
		v:send()
	end
	pd:sendBang(dlr..'play')
end

function love.update(dt)
	gui.updateSliders(sliders)
	for i = #buttons, 1, -1 do buttons[i]:update(dt) end
	if auto.on then
		auto.time = auto.time - dt
		if auto.time <= 0 then
			btnShuffle()
			tglSort(sorter)
			sorter.time = auto.time + auto.dur
		end
	elseif sorter.on then
		sorter.time = sorter.time - dt
		if sorter.time <= 0 then
			if sorter.step > 0 then
				local i, j = swaps[sorter.step][1], swaps[sorter.step][2]
				arr[i].rgb, arr[j].rgb = rgb.normal, rgb.normal
			end
			sorter.step = sorter.step + 1
			local i, j = swaps[sorter.step][1], swaps[sorter.step][2]
			setRange(swaps[sorter.step][3], swaps[sorter.step][4])

			arr[i].x, arr[j].x = arr[j].x, arr[i].x
			arr[i], arr[j] = arr[j], arr[i]
			arr[i].rgb = rgb.swap
			arr[j].rgb = swaps[sorter.step][5] and rgb.pivot or rgb.swap
			local a, b = arr[i].val, arr[j].val
			local diff = b - a
			if diff < 5 and a < 5 then
				b = b + 10
			elseif diff < 10 and a < 10 then
				b = b + 5
			end
			pd:sendFloat(dlra, a)
			pd:sendFloat(dlrb, b)

			if sorter.step >= #swaps then
				auto.on = true
				local even = #swaps % 2 == 0 and 2 or 1
				auto.time = sorter.time + auto.dur / even
				resetSort()
			end
			sorter.time = sorter.time + sorter.dur
		end
	end
	lpd.update()
end

function love.mousepressed(x, y)
	for i = #buttons, 1, -1 do
		if buttons[i]:mousepressed(x, y) then return end
	end
	for i = #toggles, 1, -1 do
		if toggles[i]:mousepressed(x, y) then return end
	end
end

function love.draw()
	for i = 1, #sliders do sliders[i]:draw() end
	for i = 1, #buttons do buttons[i]:draw() end
	for i = 1, #toggles do toggles[i]:draw() end

	local h = love.graphics.getHeight()
	h = h - 50
	for i = 1, #arr do
		love.graphics.setColor(arr[i].rgb)
		local x, y = arr[i].x, arr[i].y
		love.graphics.rectangle('fill', x, y, 10, h - y, 5)
	end
	love.graphics.setColor(rgb.range)
	love.graphics.line(arr.lo, arr.y, arr.lo, h)
	love.graphics.line(arr.hi, arr.y, arr.hi, h)
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
