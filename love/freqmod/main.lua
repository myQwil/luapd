package.path = '../?.lua;'..package.path
require('pdmain')

width ,height = love.graphics.getWidth()-1 ,love.graphics.getHeight()-1
press = {false ,false}
portamento = 0
modfrq ,modidx ,carfrq = 1 ,150 ,400
hintx = width - 250
mx ,my = 0 ,0

obj.float = function(dest ,num)
	if     dest == 'modfrq' then
	   modfrq = num
	elseif dest == 'modidx' then
		modidx = num
	elseif dest == 'carfrq' then
		carfrq = num
	end
end

grid =
{	 {width/4   ,0          ,width/4   ,height     }
	,{width/2   ,0          ,width/2   ,height     }
	,{width*.75 ,0          ,width*.75 ,height     }
	,{0         ,height/4   ,width     ,height/4   }
	,{0         ,height/2   ,width     ,height/2   }
	,{0         ,height*.75 ,width     ,height*.75 }  }

function span(f ,min ,max ,scale)
	return f * (max - min) / scale + min;
end

function love.load()
	lpd.init()
	patch = lpd.open('../../pd/test.pd' ,.5)
	love.keyboard.setKeyRepeat(true)
	pd:subscribe('modfrq')
	pd:subscribe('modidx')
	pd:subscribe('carfrq')
end

function love.update(dt)
	lpd.update(dt)
	-- pd:receiveMessages()
end

function love.draw()
	-- grid
	love.graphics.setLineWidth(1)
	love.graphics.setColor(.25 ,0 ,0)
	for _,v in pairs(grid) do
		love.graphics.line(v)  end

	-- values
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(lpd.msg               ,0 ,0  )
	love.graphics.print('mod-freq: ' ..modfrq ,0 ,20 )
	love.graphics.print('mod-index: '..modidx ,0 ,40 )

	-- hints
	love.graphics.printf('[-] / [+]\n[tab]\n[space]\n[escape]'
		,hintx     ,0 ,120 ,'right')
	love.graphics.print('portamento\nmouse-grab\nauto\nquit'
		,hintx+130 ,0  );

	-- mouse press
	if press[1] then
		love.graphics.setColor(1  ,.8 ,.8)
		love.graphics.print('Mouse1' ,150 ,0)  end
	if press[2] then
		love.graphics.setColor(.8 ,1  ,.8)
		love.graphics.print('Mouse2' ,300 ,0)  end

	-- circle
	love.graphics.setLineWidth(2)
	love.graphics.circle('line'
		,span(modfrq ,0      ,width ,200  )
		,span(modidx ,height ,0     ,3200 )
		,1+carfrq/8
	)
end

function pan(x ,y)
	pd:sendFloat   ('pan' ,span(x ,-45 ,45 ,width))
end

function pancar(x ,y)
	pan(x ,y)
	if y ~= my then
		pd:sendFloat('carrier-freq' ,y>my and -1 or 1)  end
end

function none(...) end

function fmod(x ,y)
	pd:sendFloat('mod-freq'  ,span(x ,0    ,200 ,width  ))
	pd:sendFloat('mod-index' ,span(y ,3200 ,0   ,height ))
end

function tone(x ,y)
	pd:sendFloat   ('tone-pos'      , span(x ,-45 ,45 ,width  )  )
	pd:sendMessage ('tone' ,'pitch' ,{span(y ,100 ,0  ,height )} )
	pd:sendBang    ('tone')
end

fn = {[0]=none ,fmod}

function love.mousepressed(x ,y ,btn)
	if     btn == 1 then fn[1] (x ,y)
	elseif btn == 2 then tone  (x ,y)  end
	press[btn] = true
end

function love.mousereleased(x ,y ,btn)
	press[btn] = false
end

function love.mousemoved(x ,y)
	if love.mouse.isDown(1) then
	     fn[1](x ,y)
	else fn[0](x ,y)  end
	mx ,my = x ,y
end

function love.wheelmoved(x ,y)
	pd:sendFloat('carrier-freq' ,y*25)
end

function love.keypressed(k)
	if     k == 'tab'    then
		local state = not love.mouse.isGrabbed()
		love.mouse.setGrabbed(state)
	elseif k == 'space'  then
		fn[0] = fn[0]==none and fmod   or none
		fn[1] = fn[1]==fmod and pancar or fmod
	elseif k == '='      then
		portamento = math.max(0 ,portamento + 25)
		pd:sendFloat('portamento' ,portamento)
	elseif k == '-'      then
		portamento = math.max(0 ,portamento - 25)
		pd:sendFloat('portamento' ,portamento)
	elseif k == 'lctrl'  then
		tone(love.mouse.getPosition())
	elseif k == 'escape' then
		love.event.push('quit')
	end
end
