
local slider = { focus = nil }

local function _send(self ,k)
	if k then
		pd:sendFloat(self.t[k].dest ,self.t[k].cur)
	else for _,v in pairs(self.t) do
		pd:sendFloat(v.dest ,v.cur)   end   end
end

local function _check(self ,ck ,v ,x)
	if     x < v.xmin then x = v.xmin
	elseif x > v.xmax then x = v.xmax   end
	if self[ck] ~= x then
		self[ck]  = x
		v.cur = (x - v.xmin) * v.f + v.min
		pd:sendFloat(v.dest ,v.cur)   end
end

local function _update(self ,x ,y)
	if love.mouse.isDown(1) then
		if     slider.focus == self then
			if self.t.x then self:check('cx' ,self.t.x ,x) end
			if self.t.y then self:check('cy' ,self.t.y ,y) end
		elseif slider.focus == nil
		 and x >= self.x and x <= self.xx
		 and y >= self.y and y <= self.yy then
			if self.t.x then self:check('cx' ,self.t.x ,x) end
			if self.t.y then self:check('cy' ,self.t.y ,y) end
			slider.focus = self   end
	elseif slider.focus then slider.focus = nil   end
end

local function _draw(self)
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

local function bounds(num ,min ,max)
	if     num < min then num = min
	elseif num > max then num = max   end
	return num
end

local function setup(sl ,k ,v)
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
		v.label.x    = (v.label.x or 0) + math.floor(sl.x + sl.rad)
		v.label.y    = (v.label.y or 0) + math.floor(sl.y - 24)

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

local function copy(t)
	local cpy = {}
	for k,v in pairs(t) do
		cpy[k] = type(v) == 'table' and copy(v) or v   end
	return cpy
end

slider.new = function(x ,y ,t ,rad ,rgb)
	local sl =
	{	 x = x
		,y = y
		,t = copy(t)
		,send   = _send
		,check  = _check
		,update = _update
		,draw   = _draw   }

	if type(rad) == 'table' then
		rgb = rad
		rad = nil   end
	sl.rad = math.abs(rad or 25)
	sl.rgb = rgb or {.5,.5,.5}
	setup(sl ,'x' ,sl.t.x)
	setup(sl ,'y' ,sl.t.y)
	return sl
end

return slider
