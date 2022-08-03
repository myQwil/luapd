if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

package.path = '../?.lua;'..package.path
local lpd = require('pdmain')
local pd = lpd.pd
local patch ---@type Pd.Patch

local gui = require('pdgui')(pd)
local sliders

local function volChange(self ,num)
	if num < 0.0011 then
		num = 0 end
	self.num = num
	pd:sendFloat(self.dest ,self.num)
end

function love.load()
	lpd.init()
	patch = lpd.open{play = false}

	local
	vol  ,dlr                ,width ,height =
	0.05 ,patch:dollarZero() ,love.graphics.getDimensions()

	local met  =
	{	 dest=dlr..'met' ,min=11   ,max=6000 ,num=1000 ,log=true
		,label={text='milliseconds per beat'}  }
	local tvol =
	{	 dest=dlr..'vol' ,min=.001 ,max=1    ,num=vol  ,snap=.1 ,log=true
		,len=height-100 ,prec=4 ,label={text='volume' ,x=-100} ,change=volChange  }

	gui.slider.rad = 25
	gui.slider.len = width-150
	local h = gui.slider.rad / 2
	sliders =
	{	 gui.slider(20       ,height/2-h ,{x=met}  ,{rgb={.25 ,.66 ,.66}})
		,gui.slider(width-90 ,60         ,{y=tvol} ,{rgb={.75 ,.5  ,.75}})  }

	for _,v in pairs(sliders) do
		v:send()
	end
	pd:sendBang(dlr..'play')
end

function love.update()
	for i = #sliders,1,-1 do
		sliders[i]:update(love.mouse.getPosition()) end
	lpd.update()
end

function love.draw()
	for i = 1,#sliders do
		sliders[i]:draw() end
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
