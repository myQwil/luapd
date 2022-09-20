if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

package.path = '../?.lua;'..package.path
local lpd = require('pdmain')
local pd = lpd.pd
local patch ---@type PdPatch

local gui = require('pdgui')(pd)
local sliders ,buttons


-- Widget Callbacks

local function btnClick(self)
	pd:sendFloat(self.dest ,self.num)
	sliders[1].t.y.num = self.num
	sliders[1].t.y.bpm = 60000 / self.num
	sliders[1]:pos('y')
end

local function volChange(self ,num)
	if num < 0.0011 then
		num = 0 end
	self.num = num
	pd:sendFloat(self.dest ,self.num)
end

local function metChange(self ,num)
	self.num = num
	self.bpm = 60000 / self.num
	pd:sendFloat(self.dest ,self.num)
end

local lbl = 'milliseconds per beat:\nbeats per minute:'
local function metDraw(self)
	local str = string.format('%.'..self.prec..'g' ,self.num)..'\n'
	         .. string.format('%.'..self.prec..'g' ,self.bpm)
	love.graphics.printf(lbl ,10  ,10 ,200 ,'right')
	love.graphics.printf(str ,215 ,10 ,50  ,'left')
end


function love.load()
	lpd.init()
	patch = lpd.open{play = false}

	local vol = 0.33
	local dlr = patch:dollarZero()
	local width ,height = love.graphics.getDimensions()

	local met  =
	{	 dest=dlr..'met' ,min=1500 ,max=125 ,num=1000 ,snap=125
		,prec=4 ,change=metChange ,draw=metDraw  }
	met.bpm = 60000 / met.num
	local tvol =
	{	 dest=dlr..'vol' ,min=.001 ,max=1   ,num=vol  ,snap=.1 ,log=true
		,prec=4 ,change=volChange ,label={text='volume' ,y=530}  }

	local rad = 25
	gui.slider.rad  = rad
	gui.slider.lblx = -100
	gui.slider.len  = height-100
	sliders =
	{	 gui.slider(rad*2       ,60 ,{y=met}  ,{rgb={.25 ,.66 ,.66}})
		,gui.slider(width-rad*4 ,60 ,{y=tvol} ,{rgb={.75 ,.5  ,.75}})  }

	gui.button.size = 33
	gui.button.click = btnClick
	gui.button.dest = dlr..'met'
	local bx ,by = width / 2 - 16 ,235
	buttons =
	{	 gui.button(bx ,by     ,{label={text='750'}  ,num=750})
		,gui.button(bx ,by+75  ,{label={text='875'}  ,num=875})
		,gui.button(bx ,by+150 ,{label={text='1000'} ,num=1000})  }

	for _,v in pairs(sliders) do
		v:send()
	end
	pd:sendBang(dlr..'play')
end

function love.update(dt)
	local x ,y = love.mouse.getPosition()
	-- reverse list order to prioritize items rendered last
	for i = #sliders,1,-1 do
		sliders[i]:update(x ,y) end
	for i = #buttons,1,-1 do
		buttons[i]:update(dt) end
	lpd.update()
end

function love.mousepressed(x ,y)
	for i = #buttons,1,-1 do
		if buttons[i]:mousepressed(x ,y) then return end end
end

function love.draw()
	for i = 1,#sliders do sliders[i]:draw() end
	for i = 1,#buttons do buttons[i]:draw() end
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end