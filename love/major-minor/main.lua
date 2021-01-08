package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()
gui    = require('pdgui')
scale  = Array()
doremi = 're:\nmi:\nfa:\nso:\nla:\nti:'

function love.load()
	luapd.init()
	patch = luapd.open{play=false}

	local vol ,x  ,wo  ,rad ,dlr                ,width ,height =
	      .1  ,20 ,140 ,30  ,patch:dollarZero() ,love.window.getMode()

	local lbl = {text='volume' ,x=-100}
	local tvol  = {dest=dlr..'vol' ,min=0   ,max=1 ,cur=vol ,len=height-100 ,label=lbl}
	local phase = {dest='phase'    ,min=0   ,max=1 ,cur=.5  ,len=width-wo}
	local scale = {dest='scale'    ,min=-6  ,max=6 ,cur=0   ,len=width-wo}
	local tempo = {dest='tempo'    ,min=.25 ,max=4 ,cur=1   ,len=width-wo ,log=true}

	sliders =
	{	 gui.slider(width-90 ,60         ,{y=tvol}  ,{rad=rad ,rgb={.75 ,.5  ,.75}})
		,gui.slider(x        ,height*2/5 ,{x=scale} ,{rad=rad ,rgb={.25 ,.66 ,.66}})
		,gui.slider(x        ,height*3/5 ,{x=phase} ,{rad=rad ,rgb={.5  ,.66 ,.25}})
		,gui.slider(x        ,height*4/5 ,{x=tempo} ,{rad=rad ,rgb={.75 ,.25 ,.25}})   }

	buttons =
	{	 gui.button(200  ,50  ,'scdef' ,{size=33 ,label={text='inv-'}
			,msg={ {m='<1'} ,{m='send' ,l={1}} }})
		,gui.button(275  ,50  ,'scdef' ,{size=33 ,label={text='inv+'}
			,msg={ {m='>1'} ,{m='send' ,l={1}} }})
		,gui.button(500  ,50  ,'scdef' ,{size=33 ,label={text='min3'}
			,msg={ {m='@2' ,l={3}} ,{m='send' ,l={1}} }})   }

	toggles =
	{	 gui.toggle(350  ,50  ,'repeat'   ,{size=33})
		,gui.toggle(425  ,50  ,'pause'    ,{size=33})
		,gui.toggle(200  ,100 ,'pulse1'   ,{size=33 ,label={y=60} ,on=true})
		,gui.toggle(275  ,100 ,'pulse2'   ,{size=33 ,label={y=60} ,on=true})
		,gui.toggle(350  ,100 ,'triangle' ,{size=33 ,label={y=60} ,on=true})
		,gui.toggle(425  ,100 ,'noise'    ,{size=33 ,label={y=60} ,on=true})   }

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
	for _,v in pairs(sliders) do v:draw() end
	for _,v in pairs(buttons) do v:draw() end
	for _,v in pairs(toggles) do v:draw() end

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
