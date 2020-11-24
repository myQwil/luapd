package.path = '../?.lua;'..package.path
require('loadpd')

width ,height = love.window.getMode()
press = {false ,false}
portamento = 0

function love.load()
	lpd.init()
	patch = lpd.open('../../pd/test.pd' ,.25)
	love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
	lpd.update(dt)
	pd:receiveMessages()
end

function love.draw()
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(lpd.msg ,0 ,0)
	if press[1] then
		love.graphics.setColor(1  ,.8 ,.8)
		love.graphics.print('Mouse1' ,100 ,0) end
	if press[2] then
		love.graphics.setColor(.8 ,1  ,.8)
		love.graphics.print('Mouse2' ,200 ,0) end
	mx ,my = love.mouse.getPosition()
	love.graphics.circle('fill' ,mx ,my ,5)
end

function span(f ,min ,max ,scale)
	return f * (max - min) / scale + min;
end

function pan(x ,y)
	pd:sendFloat   ('pan' ,span(x ,-45 ,45 ,width))
end

function none(x ,y) end

function fmod(x ,y)
	pd:sendFloat('mod-freq'  ,x/4)
	pd:sendFloat('mod-index' ,(height-y)*4)
end

fn = {[0]=none ,fmod}

function tone(x ,y)
	pd:sendFloat   ('tone-pos' ,span(x ,-45 ,45 ,width))
	pd:sendMessage ('tone' ,'pitch' ,{(height-y) / 6})
	pd:sendBang    ('tone')
end

function love.mousepressed(x ,y ,btn)
	if     btn == 1 then fn[1] (x ,y)
	elseif btn == 2 then tone  (x ,y) end
	press[btn] = true
end

function love.mousereleased(x ,y ,btn)
	press[btn] = false
end

function love.mousemoved(x ,y)
	if love.mouse.isDown(1) then
	     fn[1](x ,y)
	else fn[0](x ,y) end
end

function love.wheelmoved(x ,y)
	pd:sendFloat('carrier-freq' ,y*25)
end

function love.keypressed(k)
	if     k == 'tab'    then
		local state = not love.mouse.isGrabbed()
		love.mouse.setGrabbed(state)
		love.mouse.setVisible(not state)
	elseif k == 'space'  then
		fn[0] = fn[0]==none and fmod or none
		fn[1] = fn[1]==fmod and pan  or fmod
	elseif k == 'escape' then
		love.event.push('quit')
	elseif k == '='      then
		portamento = math.max(0 ,portamento + 50)
		pd:sendFloat('portamento' ,portamento)
	elseif k == '-'      then
		portamento = math.max(0 ,portamento - 50)
		pd:sendFloat('portamento' ,portamento) end
end
