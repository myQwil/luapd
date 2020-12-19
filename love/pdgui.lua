
local gui = { focus = nil }

local function bounds(num ,min ,max)
	if     num < min then num = min
	elseif num > max then num = max   end
	return num
end

local function copy(t)
	local cpy = {}
	for k,v in pairs(t) do
		cpy[k] = type(v) == 'table' and copy(v) or v   end
	return cpy
end

-------------------------------------------------------------------------
-------------------------------- Sliders --------------------------------
-------------------------------------------------------------------------
local function slider_send(self ,k)
	if k then
		pd:sendFloat(self.t[k].dest ,self.t[k].cur)
	else for _,v in pairs(self.t) do
		pd:sendFloat(v.dest ,v.cur)   end   end
end

local function slider_check(self ,ck ,v ,x)
	if     x < v.xmin then x = v.xmin
	elseif x > v.xmax then x = v.xmax   end
	if self[ck] ~= x then
		self[ck]  = x
		v.cur = (x - v.xmin) * v.f + v.min
		pd:sendFloat(v.dest ,v.cur)   end
end

local function slider_update(self ,x ,y)
	if love.mouse.isDown(1) then
		if     gui.focus == self then
			if self.t.x then slider_check(self ,'cx' ,self.t.x ,x) end
			if self.t.y then slider_check(self ,'cy' ,self.t.y ,y) end
		elseif gui.focus == nil
		 and x >= self.x and x <= self.xx
		 and y >= self.y and y <= self.yy then
			if self.t.x then slider_check(self ,'cx' ,self.t.x ,x) end
			if self.t.y then slider_check(self ,'cy' ,self.t.y ,y) end
			gui.focus = self   end
	elseif gui.focus then gui.focus = nil   end
end

local function slider_draw(self)
	love.graphics.setColor(.1  ,.1  ,.1  )
	love.graphics.rectangle('fill' ,self.x ,self.y ,self.xlen ,self.ylen ,self.rad)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('line' ,self.x ,self.y ,self.xlen ,self.ylen ,self.rad)

	love.graphics.setColor(self.rgb)
	love.graphics.circle('fill' ,self.cx ,self.cy ,self.rad)
	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.circle('line' ,self.cx ,self.cy ,self.rad)

	for _,v in pairs(self.t) do
		love.graphics.print(v.label.text..': '..v.cur ,v.label.x ,v.label.y)   end
end

local function slider_setup(sl ,k ,v)
	local diam      ,klen      ,kk    ,ck =
	      sl.rad*2  ,k..'len'  ,k..k  ,'c'..k
	if v then
		if v.len < diam then v.len = diam end
		if k == 'y' then
			local temp = v.min
			v.min = v.max
			v.max = temp   end
		sl[klen] = v.len
		sl[kk]   = v.len + sl[k]
		v.xmin = sl[k]  + sl.rad
		v.xmax = sl[kk] - sl.rad
		v.f = (v.max-v.min) / (v.len-diam)

		if not v.label then v.label = {} end
		v.label.text = v.label.text or v.dest
		v.label.x    = math.floor((v.label.x or 0) + sl.x + sl.rad)
		v.label.y    = math.floor((v.label.y or 0) + sl.y - 24)

		if v.cur then v.cur = v.min > v.max and
			bounds(v.cur ,v.max ,v.min) or bounds(v.cur ,v.min ,v.max)
		else v.cur = v.min   end

		sl[ck] = sl[k] + sl.rad + (v.cur-v.min) * (v.len-diam) / (v.max-v.min)
		if sl[ck] ~= sl[ck] then sl[ck] = sl.rad + sl[k] end
	else
		sl[klen] = diam
		sl[kk]   = diam   + sl[k]
		sl[ck]   = sl.rad + sl[k]   end
end

function gui.slider(x ,y ,t ,opt)
	local sl =
	{	 x = x
		,y = y
		,t = copy(t)
		,rad = math.abs(opt and opt.rad or 25)
		,rgb = opt and opt.rgb or {.5,.5,.5}
		,send   = slider_send
		,update = slider_update
		,draw   = slider_draw   }

	slider_setup(sl ,'x' ,sl.t.x)
	slider_setup(sl ,'y' ,sl.t.y)
	return sl
end

-----------------------------------------------------------------------
-------------------------------- Boxes --------------------------------
-----------------------------------------------------------------------
local function gui_box(x ,y ,dest ,opt)
	local box =
	{	 x = x
		,y = y
		,dest = dest   }
	box.size  = opt and opt.size or 25
	box.xx = box.x + box.size
	box.yy = box.y + box.size

	label = opt and opt.label or {}
	label.text = label.text or dest
	label.x    = math.floor((label.x or 0) + box.x)
	label.y    = math.floor((label.y or 0) + box.y - 24)
	box.label  = label

	return box
end

local function button_update(self ,dt)
	if self.circle.on then
		self.circle.dt = self.circle.dt + dt
		if self.circle.dt >= self.circle.delay then
			self.circle.on = false   end   end
end

local function button_mousepressed(self ,x ,y ,btn)
	if btn == 1
	and x >= self.x and x <= self.xx
	and y >= self.y and y <= self.yy then
		self.circle.dt = 0
		self.circle.on = true
		pd:sendBang(self.dest)   end
end

local function button_draw(self)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('fill' ,self.x ,self.y ,self.size ,self.size ,5)
	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.rectangle('line' ,self.x ,self.y ,self.size ,self.size ,5)

	if self.circle.on then
		love.graphics.setColor(.5 ,.5 ,.5)
		love.graphics.circle('fill' ,self.circle.x ,self.circle.y ,self.circle.rad)
		love.graphics.setColor(.1 ,.1 ,.1)
		love.graphics.circle('line' ,self.circle.x ,self.circle.y ,self.circle.rad)
	end

	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(self.label.text ,self.label.x ,self.label.y)
end

function gui.button(x ,y ,dest ,opt)
	local btn = gui_box(x ,y ,dest ,opt)
	btn.draw   = button_draw
	btn.update = button_update
	btn.mousepressed = button_mousepressed

	btn.circle = {dt=0 ,on=false ,delay=.15}
	btn.circle.rad = btn.size * 4/9
	btn.circle.x = btn.x+btn.circle.rad + btn.circle.rad * 1/9
	btn.circle.y = btn.y+btn.circle.rad + btn.circle.rad * 1/9
	return btn
end

local function toggle_mousepressed(self ,x ,y ,btn)
	if btn == 1
	and x >= self.x and x <= self.xx
	and y >= self.y and y <= self.yy then
		self.on = not self.on
		pd:sendFloat(self.dest ,self.on and self.non0 or 0)   end
end

local function toggle_draw(self)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('fill' ,self.x ,self.y ,self.size ,self.size ,5)
	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.rectangle('line' ,self.x ,self.y ,self.size ,self.size ,5)

	if self.on then
		love.graphics.line(self.x+5 ,self.y+5  ,self.xx-5 ,self.yy-5)
		love.graphics.line(self.x+5 ,self.yy-5 ,self.xx-5 ,self.y+5)   end

	love.graphics.print(self.label.text ,self.label.x ,self.label.y)
end

function gui.toggle(x ,y ,dest ,opt)
	local tgl = gui_box(x ,y ,dest ,opt)
	tgl.draw = toggle_draw
	tgl.mousepressed = toggle_mousepressed

	tgl.non0 = opt and opt.non0 or 1
	tgl.on   = opt and opt.on   or false
	return tgl
end

return gui
