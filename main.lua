require("luapd")

width ,height  = love.window.getMode()

chIn ,chOut ,srate ,queued ,bitdepth ,ticks =
0    ,2     ,48000 ,true   ,16       ,5

msg   = ""
press = {false ,false}
obj   = PdObject({
	print = function(m)
		print(m)
		msg = m
	end
})

function love.load()
	pd = PdBase()
	if not pd:init(chIn ,chOut ,srate ,queued) then
		print("Could not init pd")
		love.event.push('quit')
	end
	pd:setReceiver(obj)
	pd:computeAudio(true)
	pd:addToSearchPath("pd/lib")
	patch  = pd:openPatch("pd/test.pd")
	bsize  = pd:blockSize() * ticks * chOut
	sdata  = love.sound.newSoundData(bsize ,srate ,bitdepth ,chOut)
	source = love.audio.newQueueableSource( srate ,bitdepth ,chOut)
	bsize  = bsize * 2
	source:setVolume(.7)
end

function love.update(dt)
	pd:receiveMessages()
	while source:getFreeBufferCount() > 0 do
		pd:processShort(ticks ,sdata:getPointer())
		source:queue(sdata ,0 ,bsize)
		source:play()
	end
end

function love.draw()
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(msg ,0 ,0)
	if press[1] then
		love.graphics.setColor(1  ,.8 ,.8)
		love.graphics.print("Mouse1" ,100 ,0)
	end
	if press[2] then
		love.graphics.setColor(.8 ,1  ,.8)
		love.graphics.print("Mouse2" ,200 ,0)
	end
end

function span(f ,min ,max ,scale)
	return f * (max - min) / scale + min;
end

function fmshift(x ,y)
	pd:sendFloat("mod-freq"  ,x/4)
	pd:sendFloat("mod-index" ,(height-y)*2)
end

function tone(x ,y)
	pd:sendFloat   ("tone-pos"   ,span(x ,-45 ,45 ,width))
	pd:sendMessage ("tone" ,"pitch" ,{(height-y) / 6})
	pd:sendBang    ("tone")
end

function love.mousepressed(x ,y ,btn)
	if     btn == 2 then tone    (x ,y)
	elseif btn == 1 then fmshift (x ,y)
	end
	press[btn] = true
end

function love.mousereleased(x ,y ,btn)
	press[btn] = false
end

function love.keypressed(k)
	if k == 'lctrl' then
		tone(love.mouse.getPosition())
	end
end

function love.mousemoved(x ,y)
	if love.mouse.isDown(1) then
		fmshift(x ,y)
	end
end

function love.wheelmoved(x ,y)
	pd:sendFloat("carrier-freq" ,y*25)
end
