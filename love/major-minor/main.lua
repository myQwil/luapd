package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()
slider = require('slider')
scale  = Array()
doremi = 're:\nmi:\nfa:\nso:\nla:\nti:'

function love.load()
	luapd.init()
	patch = luapd.open(0 ,false)

	local vol ,x  ,wo  ,rad ,dlr                ,width ,height =
	      .1  ,20 ,140 ,30  ,patch:dollarZero() ,love.window.getMode()

	local lbl = {text='volume' ,x=-100}
	local tvol  = {dest=dlr..'vol',min=0  ,max=1  ,cur=vol ,len=height-100 ,label=lbl}
	local phase = {dest='phase'   ,min=0  ,max=.5 ,cur=.5  ,len=width-wo}
	local scale = {dest='scale'   ,min=-6 ,max=6  ,cur=-1  ,len=width-wo}
	local tempo = {dest='tempo'   ,min=.5 ,max=2  ,cur=1   ,len=width-wo}

	sliders =
	{	 slider.new(width-90 ,60         ,{y=tvol}  ,rad ,{.75 ,.5  ,.75})
		,slider.new(x        ,height*2/5 ,{x=scale} ,rad ,{.25 ,.66 ,.66})
		,slider.new(x        ,height*3/5 ,{x=phase} ,rad ,{.5  ,.66 ,.25})
		,slider.new(x        ,height*4/5 ,{x=tempo} ,rad ,{.75 ,.25 ,.25})   }

	for _,v in pairs(sliders) do v:send() end
	pd:sendBang(dlr..'play')
end

function love.update()
	luapd.update()
	local x ,y = love.mouse.getPosition()
	for i = #sliders,1,-1 do
		sliders[i]:update(x ,y)   end
end

function love.draw()
	for _,v in pairs(sliders) do v:draw() end
	pd:readArray('default' ,scale)
	local str = ''
	for i=1,#scale-1 do
		str = str..string.format('%.2f' ,scale[i])..'\n'   end
	love.graphics.printf(doremi ,10 ,10 ,30 ,'right')
	love.graphics.printf(str    ,45 ,10 ,50 ,'right')
	love.graphics.print('exception: '..string.format('%.2f' ,scale[#scale]) ,10 ,124)
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
