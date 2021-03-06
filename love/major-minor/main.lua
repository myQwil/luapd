package.path = '../?.lua;'..package.path
luapd ,pd = require('pdmain')()
gui    = require('pdgui')
scale  = Array()
doremi = 're:\nmi:\nfa:\nso:\nla:\nti:'

-- Button Callbacks
function invup(self)
	pd:sendMessage(self.dest ,'>1')
	pd:sendMessage(self.dest ,'send')
end

function invdn(self)
	pd:sendMessage(self.dest ,'<1')
	pd:sendMessage(self.dest ,'send')
end

function melmin(self)
	pd:sendList(self.dest ,{0,2,3,5,7,9,11})
	pd:sendMessage(self.dest ,'send')
end

function mixob6(self)
	pd:sendList(self.dest ,{0,2,4,5,7,8,10})
	pd:sendMessage(self.dest ,'send')
end

function stop(self)
	pd:sendBang('stop')
	toggles[2]:click(true)
end


function love.load()
	luapd.init()
	patch = luapd.open{play=false}

	local vol ,x  ,bx  ,wo  ,dlr                ,width ,height =
	      1   ,20 ,175 ,150 ,patch:dollarZero() ,love.graphics.getDimensions()

	local maj   = {dest='maj-min'  ,min=1    ,max=0  ,num=1   ,snap=.25  ,gap=12}
	local scl   = {dest='mode'     ,min=0    ,max=7  ,num=0   ,snap=.5}
	local phase = {dest='phase'    ,min=.5   ,max=0  ,num=.5  ,snap=1/48 ,gap=0}
	local tempo = {dest='tempo'    ,min=.25  ,max=4  ,num=1   ,snap=2    ,gap=10 ,log=true}
	local tvol  = {dest=dlr..'vol' ,min=.001 ,max=1  ,num=vol ,snap=.1           ,log=true
		,len=height-100 ,prec=4 ,label={text='volume' ,x=-100}}

	gui.slider.rad = 25
	gui.slider.len = width-wo
	sliders =
	{	 gui.slider(x        ,height*2/6 ,{x=maj}   ,{rgb={.25 ,.66 ,.66}})
		,gui.slider(x        ,height*3/6 ,{x=scl}   ,{rgb={.33 ,.5  ,.66}})
		,gui.slider(x        ,height*4/6 ,{x=phase} ,{rgb={.5  ,.66 ,.25}})
		,gui.slider(x        ,height*5/6 ,{x=tempo} ,{rgb={.75 ,.25 ,.25}})
		,gui.slider(width-90 ,60         ,{y=tvol}  ,{rgb={.75 ,.5  ,.75}})   }

	gui.button.dest = 'scdef'
	gui.button.size = 33
	buttons =
	{	 gui.button(bx     ,50  ,{label={text='inv-'}             ,click=invdn})
		,gui.button(bx+75  ,50  ,{label={text='inv+'}             ,click=invup})
		,gui.button(bx+300 ,50  ,{label={text='melodic-minor'}    ,click=melmin})
		,gui.button(bx+300 ,100 ,{label={text='mixo-b6' ,y=60}    ,click=mixob6})
		,gui.button(bx+375 ,75  ,{label={text='stop' ,x=40 ,y=30} ,click=stop})   }

	gui.toggle.size = 33
	toggles =
	{	 gui.toggle(bx+150 ,50  ,{dest='repeat' ,on=false})
		,gui.toggle(bx+225 ,50  ,{dest='pause'})
		,gui.toggle(bx     ,100 ,{dest='pulse1'   ,label={y=60}})
		,gui.toggle(bx+75  ,100 ,{dest='pulse2'   ,label={y=60}})
		,gui.toggle(bx+150 ,100 ,{dest='triangle' ,label={y=60}})
		,gui.toggle(bx+225 ,100 ,{dest='noise'    ,label={y=60}})   }

	for _,v in pairs(sliders) do v:send() end
	-- pd:sendBang(dlr..'play')
end

function love.update(dt)
	local x ,y = love.mouse.getPosition()
	for i = #sliders,1,-1 do
		sliders[i]:update(x ,y) end
	for i = #buttons,1,-1 do
		buttons[i]:update(dt) end
	luapd.update()
end

function love.mousepressed(x ,y)
	for i = #buttons,1,-1 do
		if buttons[i]:mousepressed(x ,y) then return end end
	for i = #toggles,1,-1 do
		if toggles[i]:mousepressed(x ,y) then return end end
end

function love.keypressed(k)
	pd:sendList('scdef' ,{0,2,4,5,7,9,11})
	pd:sendMessage('scdef' ,'send')
end

function love.draw()
	for i = 1,#sliders do sliders[i]:draw() end
	for i = 1,#buttons do buttons[i]:draw() end
	for i = 1,#toggles do toggles[i]:draw() end

	pd:readArray('default' ,scale)
	local str = ''
	for i = 1,#scale do
		str = str..string.format('%.2f' ,scale[i])..'\n' end
	love.graphics.printf(doremi ,10 ,10 ,30 ,'right')
	love.graphics.printf(str    ,45 ,10 ,50 ,'right')
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
