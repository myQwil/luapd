local function clamp(x, min, max)
	return (x < min and min) or (x > max and max) or x
end

local function Fif(cond, T, F)
	if cond then return T else return F end
end

local function getOptions(opt, default)
	if type(opt) ~= 'table' then
		opt = default
	else
		setmetatable(opt, {__index = default})
	end
	return opt
end

local epsilon = 2.2204460492503131e-16

local pd ---@type PdBase
local gui = {} -- Pd gui library
local focus -- the slider receiving focus or nil

-------------------------------------------------------------------------
-------------------------------- Sliders --------------------------------
-------------------------------------------------------------------------

local function slider_send(sl, ax)
	if ax then
		sl.axis[ax]:change(sl.axis[ax].num)
	else
		for _, v in next, sl.axis do
			v:change(v.num)
		end
	end
end

local function slider_check(sl, x, ax)
	local v = sl.axis[ax]
	local dx = 'd'..ax
	x = clamp(x, v.xmin, v.xmax)
	if sl[dx] ~= x then
		sl[dx] = x
		x = x - v.xmin
		if v.snap then
			local grav = math.floor(x / v.sm + 0.5) * v.sm
			if v.gap == 0 or (x >= grav - v.gap and x <= grav + v.gap) then
				x = grav
			end
		end

		local num = v.log
			and (math.exp(v.m * x) * v.b)
			or v.m * x + v.b
		if math.abs(num) < epsilon then
			num = 0
		end
		if v.num ~= num then
			v:change(num)
		end
		sl['c'..ax] = x + v.xmin
	end
end

local function slider_update(sl, x, y)
	if focus == sl then
		if sl.axis.x then slider_check(sl, x, 'x') end
		if sl.axis.y then slider_check(sl, y, 'y') end
		return true
	elseif focus == nil
	and x >= sl.x and x < sl.xx
	and y >= sl.y and y < sl.yy then
		if sl.axis.x then slider_check(sl, x, 'x') end
		if sl.axis.y then slider_check(sl, y, 'y') end
		focus = sl
		return true
	end
	return false
end

local function sliders_update(t)
	if love.mouse.isDown(1) then
		local x, y = love.mouse.getPosition()
		-- reverse list order to prioritize items rendered last
		for i = #t, 1, -1 do
			if t[i]:update(x, y) then break end
		end
	elseif focus then
		focus = nil
	end
end

local function axis_draw_text(ax)
	love.graphics.print(string.format(ax.fmt, ax.label.text, ax.num)
		, ax.label.x, ax.label.y)
end

local function axis_draw_text_fixed(self)
	local precision = self.prec - string.len(tostring(math.floor(self.num + 0.0001)))
	precision = string.format('%.'..precision..'f', self.num)
	love.graphics.print(string.format(self.fmt, self.label.text, precision)
		, self.label.x, self.label.y)
end

local function slider_draw(sl)
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle('fill', sl.x, sl.y, sl.xlen, sl.ylen, sl.rad)
	love.graphics.setColor(0.25, 0.25, 0.25)
	love.graphics.rectangle('line', sl.x, sl.y, sl.xlen, sl.ylen, sl.rad)

	love.graphics.setColor(sl.rgb)
	love.graphics.circle('fill', sl.cx, sl.cy, sl.rad)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle('line', sl.cx, sl.cy, sl.rad)

	for _, v in next, sl.axis do
		v:drawText()
	end
end

local function slider_minmax(v, min, max, diam)
	if min == 0.0 and max == 0.0 then
		max = 1.0
	end
	if max > 0.0 then
		if min <= 0.0 then
			min = 0.01 * max
		end
	else
		if min > 0.0 then
			max = 0.01 * min
		end
	end
	v.min = min
	v.max = max
	return math.log(v.max / v.min) / (v.len - diam)
end

local function slider_pos(sl, ax)
	local v = sl.axis[ax]
	if not v then return end

	-- determine knob position
	local cx = 'c'..ax
	sl[cx] = (v.m == 0 and v.xmin)
		or (v.log and v.xmin + math.log(v.num / v.b) / v.m)
		or (v.xmin + (v.num - v.b) / v.m)
	sl['d'..ax] = sl[cx] -- internal position for snapping
end

local function slider_axis(sl, v, ax)
	local x = ax
	local diam = sl.rad * 2
	if type(v) ~= 'table' then
		sl['c'..x] = sl[x] + sl.rad
		sl[x..x] = sl[x] + diam
		sl[x..'len'] = diam
	else
		setmetatable(v, {__index = sl})
		local xlen = x..'len'
		local xx = x..x
		if v.len < diam then v.len = diam end
		sl[xlen] = v.len
		sl[xx] = sl[x] + v.len
		v.xmin = sl[x] + sl.rad
		v.xmax = sl[xx] - sl.rad

		-- swap min/max if slider is vertical
		if ax == 'y' then
			v.min, v.max = v.max, v.min
		end

		v.m = v.log and
			slider_minmax(v, v.min, v.max, diam) or (v.max - v.min) / (v.len - diam)
		v.b = v.min

		-- swap min/max back
		if ax == 'y' then
			v.min, v.max = v.max, v.min
		end

		v.num = not v.num and v.min or (v.min > v.max and
			clamp(v.num, v.max, v.min) or clamp(v.num, v.min, v.max))

		-- snap to grid
		if v.snap then
			v.sm = v.log and math.log(v.snap) / v.m or v.snap / v.m
			if v.sm == 0 then
				v.sm = 1
			end
		end
		sl:pos(ax)

		v.label = v.label or {}
		v.label.text = v.label.text or v.dest
		v.label.x = math.floor((v.label.x or v.lblx) + sl.x + sl.rad)
		v.label.y = math.floor((v.label.y or v.lbly) + sl.y - 24)
	end
end

local function slider_new(self, x, y, axis, opt)
	opt = getOptions(opt, self)
	local sl = {
		  x = x
		, y = y
		, axis = axis
	}
	setmetatable(sl, {__index = opt})
	sl.rad = math.abs(sl.rad)
	slider_axis(sl, sl.axis.x, 'x')
	slider_axis(sl, sl.axis.y, 'y')
	return sl
end

-----------------------------------------------------------------------
-------------------------------- Boxes --------------------------------
-----------------------------------------------------------------------

local function gui_box(x, y, opt)
	local box = {
		  x = x
		, y = y
	}
	setmetatable(box, {__index = opt})
	box.xx = box.x + box.size
	box.yy = box.y + box.size

	local label = opt.label or {}
	label.text = label.text or box.dest
	label.x = math.floor((label.x or box.lblx) + box.x)
	label.y = math.floor((label.y or box.lbly) + box.y - 24)
	box.label = label

	return box
end

local function button_draw(bt)
	love.graphics.setColor(.25, .25, .25)
	love.graphics.rectangle('fill', bt.x, bt.y, bt.size, bt.size, 5)

	if bt.circ.on then
		love.graphics.setColor(.85, .85, .85)
		love.graphics.circle('fill', bt.circ.x, bt.circ.y, bt.circ.rad)
	end
	love.graphics.setColor(.5, .5, .5)
	love.graphics.circle('line', bt.circ.x, bt.circ.y, bt.circ.rad)

	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', bt.x, bt.y, bt.size, bt.size, 5)

	love.graphics.print(bt.label.text, bt.label.x, bt.label.y)
end

local function button_update(bt, dt)
	if bt.circ.on then
		bt.circ.dt = bt.circ.dt - dt
		if bt.circ.dt <= 0 then
			bt.circ.on = false
		end
	end
end

local function button_mousepressed(bt, x, y)
	if  x >= bt.x and x < bt.xx
	and y >= bt.y and y < bt.yy then
		bt.circ.on = true
		bt.circ.dt = bt.circ.delay
		bt:click()
		return true
	else return false end
end

local function button_new(self, x, y, opt)
	opt = getOptions(opt, self)
	local btn = gui_box(x, y, opt)
	btn.circ = { dt = 0, on = false, delay = opt.delay }
	btn.circ.rad = btn.size * 5 / 11
	btn.circ.x = btn.x + btn.size / 2
	btn.circ.y = btn.y + btn.size / 2
	return btn
end

local function toggle_mousepressed(tg, x, y)
	if  x >= tg.x and x < tg.xx
	and y >= tg.y and y < tg.yy then
		tg:click()
		return true
	else return false end
end

local function toggle_draw(tg)
	love.graphics.setColor(.25, .25, .25)
	love.graphics.rectangle('fill', tg.x, tg.y, tg.size, tg.size, 5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', tg.x, tg.y, tg.size, tg.size, 5)

	if tg.on then
		love.graphics.line(tg.x + 5, tg.y + 5, tg.xx - 5, tg.yy - 5)
		love.graphics.line(tg.x + 5, tg.yy - 5, tg.xx - 5, tg.y + 5)
	end

	love.graphics.print(tg.label.text, tg.label.x, tg.label.y)
end

local function toggle_new(self, x, y, opt)
	opt = getOptions(opt, self)
	local tgl = gui_box(x, y, opt)
	return tgl
end

-- Default Callbacks

local function slider_change(self, num)
	self.num = num
	pd:sendFloat(self.dest, self.num)
end

local function vol_change(self, num)
	self.num = num
	if num > self.min then
		self.fmt = '%s: %+.1f dB'
		pd:sendFloat(self.dest, 10^(self.num / 20))
	else
		self.fmt = '%s: -∞ dB'
		pd:sendFloat(self.dest, 0)
	end
end

local function button_click(self)
	pd:sendBang(self.dest)
end

local function toggle_click(self, on)
	self.on = Fif(on ~= nil, on, not self.on)
	pd:sendFloat(self.dest, self.on and self.non0 or 0)
end

-- Reset all widget properties to their default values
function gui:reset()
	self.slider = {
		  change = slider_change
		, send = slider_send
		, update = slider_update
		, draw = slider_draw
		, drawText = axis_draw_text
		, pos = slider_pos
		, rgb = { .5, .5, .5 } -- knob color
		, log = false -- logarithmic scaling
		-- snap to a grid with spacing of this amount relative to the scale.
		-- nil or false disables snapping.
		, snap = nil
		-- a snap point's gravitational radius in pixels.
		-- if gap is 0, knob will settle exclusively on snap points.
		, gap = 7
		, fmt = '%s: %g' -- string format when displaying name and value
		, prec = 5 -- precision - used alongside fixed precision mode
		, rad = 25 -- knob radius
		, len = 100 -- axis length
		, dest = 'foo' -- send-to destination
		, lblx = 0 -- label x offset
		, lbly = 0 -- label y offset
	}
	self.button = {
		  click = button_click
		, draw = button_draw
		, update = button_update
		, mousepressed = button_mousepressed
		, delay = 0.2 -- circle display duration on click
		, size = 25
		, dest = 'foo' -- send-to destination
		, lblx = 0 -- label x offset
		, lbly = 0 -- label y offset
	}
	self.toggle = {
		  click = toggle_click
		, draw = toggle_draw
		, mousepressed = toggle_mousepressed
		, on = false -- initial state
		, non0 = 1 -- non-zero value
		, size = 25
		, dest = 'foo' -- send-to destination
		, lblx = 0 -- label x offset
		, lbly = 0 -- label y offset
	}
	self.updateSliders = sliders_update
	self.volChange = vol_change
	self.drawFixed = axis_draw_text_fixed
	setmetatable(self.slider, { __call = slider_new })
	setmetatable(self.button, { __call = button_new })
	setmetatable(self.toggle, { __call = toggle_new })
end

---@param base PdBase
return function(base)
	pd = base
	gui:reset()
	return gui
end
