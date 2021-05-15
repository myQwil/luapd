local this = {
	 size  = 25
	,rad   = 25
	,rgb   = {.5 ,.5 ,.5}
	,msg   = {m='bang'}
	,delay = 0.2
	,non0  = 1
	,on    = false
}
local focus

-------------------------------------------------------------------------
-------------------------------- Sliders --------------------------------
-------------------------------------------------------------------------
local function slider_send(self ,x)
	if x then
		pd:sendFloat(self.t[x].dest ,self.t[x].num)
	else for _,v in pairs(self.t) do
		pd:sendFloat(v.dest ,v.num)   end   end
end

local function slider_check(self ,v ,x ,cx)
	x = math.clip(x ,v.xmin ,v.xmax)
	if self[cx] ~= x then
		self[cx]  = x
		if v.log then
		     v.num = math.exp(v.k * (x - v.xmin)) * v.min
		else v.num =          v.k * (x - v.xmin)  + v.min   end
		pd:sendFloat(v.dest ,v.num)   end
end

local function slider_update(self ,x ,y)
	if love.mouse.isDown(1) then
		if     focus == self then
			if self.t.x then slider_check(self ,self.t.x ,x ,'cx') end
			if self.t.y then slider_check(self ,self.t.y ,y ,'cy') end
		elseif focus == nil
		 and x >= self.x and x < self.xx
		 and y >= self.y and y < self.yy then
			if self.t.x then slider_check(self ,self.t.x ,x ,'cx') end
			if self.t.y then slider_check(self ,self.t.y ,y ,'cy') end
			focus = self   end
	elseif focus then focus = nil   end
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
		love.graphics.print(v.label.text..': '..v.num ,v.label.x ,v.label.y)   end
end

local function slider_minmax(v ,min ,max ,diam)
	if min == 0.0 and max == 0.0 then
		max = 1.0   end
	if max > 0.0 then
		if min <= 0.0 then
			min = 0.01 * max   end
	else
		if min  > 0.0 then
			max = 0.01 * min   end
	end
	v.min = min
	v.max = max
	return math.log(v.max/v.min) / (v.len-diam)
end

local function slider_setup(sl ,v ,x)
	local diam      ,xlen      ,xx    ,cx =
	      sl.rad*2  ,x..'len'  ,x..x  ,'c'..x
	if v then
		if v.len < diam then v.len = diam end
		sl[xlen] = v.len
		sl[xx] = sl[x]  + v.len
		v.xmin = sl[x]  + sl.rad
		v.xmax = sl[xx] - sl.rad

		if x == 'y' then
			local temp = v.min
			v.min = v.max
			v.max = temp   end
		if v.num then v.num = v.min > v.max and
			math.clip(v.num ,v.max ,v.min) or math.clip(v.num ,v.min ,v.max)
		else v.num = v.min   end

		if v.log then
		     v.k = slider_minmax(v ,v.min ,v.max ,diam)
		else v.k = (v.max-v.min) / (v.len-diam)   end

		if  v.k == 0 then sl[cx] = v.xmin
		elseif v.log then sl[cx] = v.xmin + math.log(v.num / v.min) / v.k
		else              sl[cx] = v.xmin +         (v.num - v.min) / v.k   end

		if not v.label then v.label = {} end
		v.label.text = v.label.text or v.dest
		v.label.x    = math.floor((v.label.x or 0) + sl.x + sl.rad)
		v.label.y    = math.floor((v.label.y or 0) + sl.y - 24)
	else
		sl[cx]   = sl[x] + sl.rad
		sl[xx]   = sl[x] + diam
		sl[xlen] = diam   end
end

function this.slider(x ,y ,t ,opt)
	if type(opt) ~= 'table' then opt = this end
	local sl =
	{	 x = x
		,y = y
		,t = t
		,rad = math.abs(opt.rad or this.rad)
		,rgb = opt.rgb or this.rgb
		,send   = slider_send
		,update = slider_update
		,draw   = slider_draw   }

	slider_setup(sl ,sl.t.x ,'x')
	slider_setup(sl ,sl.t.y ,'y')
	return sl
end

-----------------------------------------------------------------------
-------------------------------- Boxes --------------------------------
-----------------------------------------------------------------------
local function gui_box(x ,y ,dest ,opt)
	local box =
	{	 x = x
		,y = y
		,dest = dest
		,size = opt.size or this.size   }
	box.xx = box.x + box.size
	box.yy = box.y + box.size

	local label = opt.label or {}
	label.text = label.text or dest
	label.x    = math.floor((label.x or 0) + box.x)
	label.y    = math.floor((label.y or 0) + box.y - 24)
	box.label  = label

	return box
end

local function button_draw(self)
	love.graphics.setColor(.25 ,.25 ,.25 )
	love.graphics.rectangle('fill' ,self.x ,self.y ,self.size ,self.size ,5)

	if self.circ.on then
		love.graphics.setColor(.85 ,.85 ,.85 )
		love.graphics.circle('fill' ,self.circ.x ,self.circ.y ,self.circ.rad)   end
	love.graphics.setColor(.5  ,.5  ,.5  )
	love.graphics.circle('line' ,self.circ.x ,self.circ.y ,self.circ.rad)

	love.graphics.setColor(1   ,1   ,1   )
	love.graphics.rectangle('line' ,self.x ,self.y ,self.size ,self.size ,5)

	love.graphics.print(self.label.text ,self.label.x ,self.label.y)
end

local function button_update(self ,dt)
	if self.circ.on then
		self.circ.dt = self.circ.dt + dt
		if self.circ.dt >= self.circ.delay then
			self.circ.on = false   end   end
end

local function button_mousepressed(self ,x ,y ,btn)
	if btn == 1
	and x >= self.x and x < self.xx
	and y >= self.y and y < self.yy then
		self.circ.dt = 0
		self.circ.on = true
		for _,v in ipairs(self.msg) do
			pd:sendMessage(self.dest ,v.m ,v.l)   end   end
end

function this.button(x ,y ,dest ,opt)
	if type(opt) ~= 'table' then opt = this end
	local btn = gui_box(x ,y ,dest ,opt)
	btn.draw         = button_draw
	btn.update       = button_update
	btn.mousepressed = button_mousepressed

	btn.circ = {dt=0 ,on=false ,delay = opt.delay or this.delay}
	btn.circ.rad = btn.size * 5/11
	btn.circ.x = btn.x + btn.size/2
	btn.circ.y = btn.y + btn.size/2
	btn.msg = opt.msg or this.msg
	return btn
end

local function toggle_mousepressed(self ,x ,y ,btn)
	if btn == 1
	and x >= self.x and x < self.xx
	and y >= self.y and y < self.yy then
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

function this.toggle(x ,y ,dest ,opt)
	if type(opt) ~= 'table' then opt = this end
	local tgl = gui_box(x ,y ,dest ,opt)
	tgl.draw         = toggle_draw
	tgl.mousepressed = toggle_mousepressed

	tgl.non0 = opt.non0 or this.non0
	tgl.on   = opt.on   or this.on
	return tgl
end

return this
