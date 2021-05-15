package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()
gui    = require('pdgui')
scale  = Array()
doremi = 're:\nmi:\nfa:\nso:\nla:\nti:'

function love.load()
	luapd.init()
	patch = luapd.open{play=false}
	gui.rad  = 30
	gui.size = 33

	local vol ,x  ,wo  ,dlr                ,width ,height =
	      .1  ,20 ,140 ,patch:dollarZero() ,love.graphics.getDimensions()

	local lbl = {text='volume' ,x=-100}
	local tvol  = {dest=dlr..'vol' ,min=.001 ,max=1 ,num=vol ,len=height-100
		,log=true ,label=lbl}
	local phase = {dest='phase'    ,min=0    ,max=1 ,num=.5  ,len=width-wo}
	local scale = {dest='scale'    ,min=-6   ,max=6 ,num=0   ,len=width-wo}
	local tempo = {dest='tempo'    ,min=.25  ,max=4 ,num=1   ,len=width-wo ,log=true}

	sliders =
	{	 gui.slider(width-90 ,60         ,{y=tvol}  ,{rgb={.75 ,.5  ,.75}})
		,gui.slider(x        ,height*2/5 ,{x=scale} ,{rgb={.25 ,.66 ,.66}})
		,gui.slider(x        ,height*3/5 ,{x=phase} ,{rgb={.5  ,.66 ,.25}})
		,gui.slider(x        ,height*4/5 ,{x=tempo} ,{rgb={.75 ,.25 ,.25}})   }

	buttons =
	{	 gui.button(200  ,50  ,'scdef' ,{label={text='inv-'}
			,msg={ {m='<1'} ,{m='send' ,l={1}} }})
		,gui.button(275  ,50  ,'scdef' ,{label={text='inv+'}
			,msg={ {m='>1'} ,{m='send' ,l={1}} }})
		,gui.button(500  ,50  ,'scdef' ,{label={text='min3'}
			,msg={ {m='@2' ,l={3}} ,{m='send' ,l={1}} }})   }

	toggles =
	{	 gui.toggle(350  ,50  ,'repeat')
		,gui.toggle(425  ,50  ,'pause')
		,gui.toggle(200  ,100 ,'pulse1'   ,{label={y=60} ,on=true})
		,gui.toggle(275  ,100 ,'pulse2'   ,{label={y=60} ,on=true})
		,gui.toggle(350  ,100 ,'triangle' ,{label={y=60} ,on=true})
		,gui.toggle(425  ,100 ,'noise'    ,{label={y=60} ,on=true})   }

	for _,v in pairs(sliders) do v:send() end
	pd:sendBang(dlr..'play')
end

function love.update(dt)
	local x ,y = love.mouse.getPosition()
	for i = #sliders,1,-1 do
		sliders[i]:update(x ,y)   end
	for i = #buttons,1,-1 do
		buttons[i]:update(dt)   end
	luapd.update()
end

function love.mousepressed(x ,y ,btn)
	for i = #buttons,1,-1 do
		buttons[i]:mousepressed(x ,y ,btn)   end
	for i = #toggles,1,-1 do
		toggles[i]:mousepressed(x ,y ,btn)   end
end

function love.draw()
	for i = 1,#sliders do sliders[i]:draw() end
	for i = 1,#buttons do buttons[i]:draw() end
	for i = 1,#toggles do toggles[i]:draw() end

	pd:readArray('default' ,scale)
	local str = ''
	for i=1,#scale do
		str = str..string.format('%.2f' ,scale[i])..'\n'   end
	love.graphics.printf(doremi ,10 ,10 ,30 ,'right')
	love.graphics.printf(str    ,45 ,10 ,50 ,'right')
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
