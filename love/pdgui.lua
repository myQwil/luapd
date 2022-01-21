math.epsilon = 2.2204460492503131e-16

local function fif(cond ,T ,F)
	if cond then return T else return F end
end

local pd       ---@type Pd.Base
local gui = {} -- Pd gui library
local focus    -- the slider receiving focus or nil

-------------------------------------------------------------------------
-------------------------------- Sliders --------------------------------
-------------------------------------------------------------------------

local function slider_send(sl ,x)
	if x then
		pd:sendFloat(sl.t[x].dest ,sl.t[x].num)
	else for _,v in next,sl.t do
		pd:sendFloat(v.dest ,v.num) end end
end

local function slider_check(sl ,x ,axis)
	local v  = sl.t[axis]
	local dx = 'd'..axis
	x = math.clip(x ,v.xmin ,v.xmax)
	if sl[dx] ~= x then
		sl[dx]  = x
		x = x - v.xmin
		if v.snap then
			local grav = math.floor(x/v.sk + 0.5) * v.sk
			if v.gap == 0 or (x >= grav-v.gap and x <= grav+v.gap) then
				x = grav end end

		local num = v.log
			and (math.exp(v.k * x) * v.min)
			or            v.k * x  + v.min
		if num < math.epsilon then
			num = 0 end
		if v.num ~= num then
			v:change(num) end
		sl['c'..axis] = x + v.xmin end
end

local function slider_update(sl ,x ,y)
	if love.mouse.isDown(1) then
		if     focus == sl then
			if sl.t.x then slider_check(sl ,x ,'x') end
			if sl.t.y then slider_check(sl ,y ,'y') end
		elseif focus == nil
		and x >= sl.x and x < sl.xx
		and y >= sl.y and y < sl.yy then
			if sl.t.x then slider_check(sl ,x ,'x') end
			if sl.t.y then slider_check(sl ,y ,'y') end
			focus = sl end
	elseif focus then focus = nil end
end

local function slider_draw(sl)
	love.graphics.setColor(0.1  ,0.1  ,0.1  )
	love.graphics.rectangle('fill' ,sl.x ,sl.y ,sl.xlen ,sl.ylen ,sl.rad)
	love.graphics.setColor(0.25 ,0.25 ,0.25 )
	love.graphics.rectangle('line' ,sl.x ,sl.y ,sl.xlen ,sl.ylen ,sl.rad)

	love.graphics.setColor(sl.rgb)
	love.graphics.circle('fill' ,sl.cx ,sl.cy ,sl.rad)
	love.graphics.setColor(1    ,1    ,1   )
	love.graphics.circle('line' ,sl.cx ,sl.cy ,sl.rad)

	for _,v in next,sl.t do
		love.graphics.print(v.label.text..': '..string.format('%.'..v.prec..'g' ,v.num)
			,v.label.x ,v.label.y) end
end

local function slider_minmax(v ,min ,max ,diam)
	if min == 0.0 and max == 0.0 then
		max = 1.0 end
	if max > 0.0 then
		if min <= 0.0 then
			min = 0.01 * max end
	else
		if min >  0.0 then
			max = 0.01 * min end
	end
	v.min = min
	v.max = max
	return math.log(v.max/v.min) / (v.len-diam)
end

local function slider_axis(self ,sl ,v ,axis)
	local x = axis
	local diam      ,xlen      ,xx    ,cx =
	      sl.rad*2  ,x..'len'  ,x..x  ,'c'..x
	if v then
		v.len  = v.len  or self.len
		v.prec = v.prec or self.prec
		if v.len < diam then v.len = diam end
		sl[xlen] = v.len
		sl[xx] = sl[x]  + v.len
		v.xmin = sl[x]  + sl.rad
		v.xmax = sl[xx] - sl.rad

		-- swap min/max if slider is vertical
		if axis == 'y' then
			local temp = v.min
			v.min = v.max
			v.max = temp end

		if v.num then v.num = v.min > v.max and
			math.clip(v.num ,v.max ,v.min) or math.clip(v.num ,v.min ,v.max)
		else v.num = v.min end

		-- linear or logarithmic
		if v.log == nil then v.log = self.log end
		if v.log then
		     v.k = slider_minmax(v ,v.min ,v.max ,diam)
		else v.k = (v.max-v.min) / (v.len-diam) end

		-- snap to grid
		if v.snap then
			v.gap = v.gap or self.gap
			if v.log then
			     v.sk = math.log(v.snap) / v.k
			else v.sk = v.snap / v.k end
			if v.sk == 0 then
				v.sk = 1 end end

		-- knob position
		if  v.k == 0 then sl[cx] = v.xmin
		elseif v.log then sl[cx] = v.xmin + math.log(v.num / v.min) / v.k
		else              sl[cx] = v.xmin +         (v.num - v.min) / v.k end
		sl['d'..x] = sl[cx] -- internal position for snapping

		v.label = v.label or {}
		v.dest  = v.dest  or self.dest
		v.change = v.change or self.change
		v.label.text = v.label.text or v.dest
		v.label.x    = math.floor((v.label.x or 0) + sl.x + sl.rad)
		v.label.y    = math.floor((v.label.y or 0) + sl.y - 24)
	else
		sl[cx]   = sl[x] + sl.rad
		sl[xx]   = sl[x] + diam
		sl[xlen] = diam end
end

local function slider_new(self ,x ,y ,t ,opt)
	if type(opt) ~= 'table' then opt = self end
	local sl =
	{	 x = x
		,y = y
		,t = t
		,rad = math.abs(opt.rad or self.rad)
		,rgb = opt.rgb or self.rgb
		,send   = slider_send
		,update = slider_update
		,draw   = slider_draw   }

	slider_axis(self ,sl ,sl.t.x ,'x')
	slider_axis(self ,sl ,sl.t.y ,'y')
	return sl
end

-----------------------------------------------------------------------
-------------------------------- Boxes --------------------------------
-----------------------------------------------------------------------

local function gui_box(self ,x ,y ,opt)
	local box =
	{	 x = x
		,y = y
		,click = opt.click or self.click
		,dest  = opt.dest  or self.dest
		,size  = opt.size  or self.size   }
	box.xx = box.x + box.size
	box.yy = box.y + box.size

	local label = opt.label or {}
	label.text = label.text or box.dest
	label.x    = math.floor((label.x or 0) + box.x)
	label.y    = math.floor((label.y or 0) + box.y - 24)
	box.label  = label

	return box
end

local function button_draw(bt)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('fill' ,bt.x ,bt.y ,bt.size ,bt.size ,5)

	if bt.circ.on then
		love.graphics.setColor(.85 ,.85 ,.85 )
		love.graphics.circle('fill' ,bt.circ.x ,bt.circ.y ,bt.circ.rad) end
	love.graphics.setColor(.5  ,.5  ,.5  )
	love.graphics.circle('line' ,bt.circ.x ,bt.circ.y ,bt.circ.rad)

	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.rectangle('line' ,bt.x ,bt.y ,bt.size ,bt.size ,5)

	love.graphics.print(bt.label.text ,bt.label.x ,bt.label.y)
end

local function button_update(bt ,dt)
	if bt.circ.on then
		bt.circ.dt = bt.circ.dt + dt
		if bt.circ.dt >= bt.circ.delay then
			bt.circ.on = false end end
end

local function button_mousepressed(bt ,x ,y)
	if  x >= bt.x and x < bt.xx
	and y >= bt.y and y < bt.yy then
		bt.circ.on = true
		bt.circ.dt = 0
		bt:click()
		return true
	else return false end
end

local function button_new(self ,x ,y ,opt)
	if type(opt) ~= 'table' then opt = self end
	local btn = gui_box(self ,x ,y ,opt)
	btn.draw         = button_draw
	btn.update       = button_update
	btn.mousepressed = button_mousepressed

	btn.circ = {dt=0 ,on=false ,delay = opt.delay or self.delay}
	btn.circ.rad = btn.size * 5/11
	btn.circ.x = btn.x + btn.size/2
	btn.circ.y = btn.y + btn.size/2
	return btn
end

local function toggle_mousepressed(tg ,x ,y)
	if  x >= tg.x and x < tg.xx
	and y >= tg.y and y < tg.yy then
		tg:click()
		return true
	else return false end
end

local function toggle_draw(tg)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('fill' ,tg.x ,tg.y ,tg.size ,tg.size ,5)
	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.rectangle('line' ,tg.x ,tg.y ,tg.size ,tg.size ,5)

	if tg.on then
		love.graphics.line(tg.x+5 ,tg.y+5  ,tg.xx-5 ,tg.yy-5)
		love.graphics.line(tg.x+5 ,tg.yy-5 ,tg.xx-5 ,tg.y+5) end

	love.graphics.print(tg.label.text ,tg.label.x ,tg.label.y)
end

local function toggle_new(self ,x ,y ,opt)
	if type(opt) ~= 'table' then opt = self end
	local tgl = gui_box(self ,x ,y ,opt)
	tgl.draw         = toggle_draw
	tgl.mousepressed = toggle_mousepressed

	tgl.non0 = opt.non0 or self.non0
	tgl.on = fif(opt.on ~= nil ,opt.on ,self.on)
	return tgl
end

-- Default Callbacks

local function slider_change(self ,num)
	self.num = num
	pd:sendFloat(self.dest ,self.num)
end

local function button_click(self)
	pd:sendBang(self.dest)
end

local function toggle_click(self ,on)
	self.on = fif(on ~= nil ,on ,not self.on)
	pd:sendFloat(self.dest ,self.on and self.non0 or 0)
end

-- Reset all widget properties to their default values
function gui:reset()
	self.slider =
	{	 change = slider_change
		,rgb  = {.5 ,.5 ,.5} -- knob color
		,log  = false -- logarithmic scaling
		-- snap to a grid with spacing of this amount relative to the scale.
		-- nil or false disables snapping.
		,snap = nil
		-- a snap point's gravitational radius in pixels.
		-- if gap is 0, knob will settle exclusively on snap points.
		,gap  = 7
		,prec = 8     -- precision when displaying number
		,rad  = 25    -- knob radius
		,len  = 100   -- axis length
		,dest = 'foo' -- send-to destination
	}
	self.button =
	{	 click = button_click
		,delay = 0.2   -- circle display duration on click
		,size  = 25
		,dest  = 'foo' -- send-to destination
	}
	self.toggle =
	{	 click = toggle_click
		,on    = false -- initial state
		,non0  = 1     -- non-zero value
		,size  = 25
		,dest  = 'foo' -- send-to destination
	}
	setmetatable(self.slider ,{__call = slider_new})
	setmetatable(self.button ,{__call = button_new})
	setmetatable(self.toggle ,{__call = toggle_new})
end

---@param base Pd.Base
return function(base)
	pd = base
	gui:reset()
	return gui
end
