if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

package.path = '../?.lua;'..package.path
local lpd = require('pdmain')
local pd ,obj  = lpd.pd ,lpd.obj
local patch ---@type Pd.Patch

local width ,height = love.graphics.getWidth()-1 ,love.graphics.getHeight()-1
local maxfrq ,maxidx ,mx ,my ,portamento =
      300    ,3200   ,0  ,0  ,0
local isPressed = {false ,false}
local isAuto = false
local hintx = width - 250
local grid = {}
local fm =
{	 modfrq = 1
	,modidx = 150
	,carfrq = 400   }

local clr =
{	 over  = {0.4  ,0.1  ,0.1  }
	,under = {0.05 ,0.15 ,0.15 }  }

function obj.float(dest ,num)
	fm[dest] = num
end

local function slope(x ,min ,max ,len)
	local m = (max - min) / len
	return m*x + min;
end

function love.load()
	local iter = 1/16
	for i=iter   ,.999 ,iter*2 do
		local wi ,hi = width*i ,height*i
		grid[#grid+1] = {line = {wi ,0  ,wi    ,height } ,color = clr.under}
		grid[#grid+1] = {line = {0  ,hi ,width ,hi     } ,color = clr.under}
	end
	for i=iter*2 ,.999 ,iter*2 do
		local wi ,hi = width*i ,height*i
		grid[#grid+1] = {line = {wi ,0  ,wi    ,height } ,color = clr.over}
		grid[#grid+1] = {line = {0  ,hi ,width ,hi     } ,color = clr.over}
	end

	lpd.init()
	patch = lpd.open{patch='../../pd/test.pd' ,volume=0.2}
	love.keyboard.setKeyRepeat(true)
	pd:subscribe('modfrq')
	pd:subscribe('modidx')
	pd:subscribe('carfrq')
end

function love.update()
	lpd.update()
	-- pd:receiveMessages()
end

function love.draw()
	-- grid
	love.graphics.setLineWidth(1)
	for _,v in pairs(grid) do
		love.graphics.setColor(v.color)
		love.graphics.line(v.line)   end

	-- values
	love.graphics.setColor(1 ,1 ,1)
	lpd.draw()
	love.graphics.print('mod-freq: ' ..fm.modfrq ,0 ,20)
	love.graphics.print('mod-index: '..fm.modidx ,0 ,40)

	-- hints
	love.graphics.printf('[-] / [+]\n[tab]\n[space]\n[escape]'
		,hintx     ,0 ,120 ,'right')
	love.graphics.print('portamento\nmouse-grab\nauto\nquit'
		,hintx+130 ,0  );

	-- mouse press
	if isPressed[1] then
		love.graphics.setColor(1  ,.8 ,.8)
		love.graphics.print('Mouse1' ,150 ,0)   end
	if isPressed[2] then
		love.graphics.setColor(.8 ,1  ,.8)
		love.graphics.print('Mouse2' ,300 ,0)   end

	-- circle
	love.graphics.setLineWidth(2)
	love.graphics.circle('line'
		,slope(fm.modfrq ,0      ,width ,maxfrq)
		,slope(fm.modidx ,height ,0     ,maxidx)
		,1 + fm.carfrq/8
	)
end

local function pancar(x ,y)
	pd:sendFloat('pan' ,slope(x ,-45 ,45 ,width))
	if y ~= my then
		pd:sendFloat('carrier-freq' ,(y > my) and -1 or 1)   end
end

local function fmod(x ,y)
	pd:sendFloat('mod-freq'  ,slope(x ,0      ,maxfrq ,width  ))
	pd:sendFloat('mod-index' ,slope(y ,maxidx ,0      ,height ))
end

local function tone(x ,y)
	pd:sendFloat   ('tone-pos'      , slope(x ,-45 ,45 ,width  )  )
	pd:sendMessage ('tone' ,'pitch' ,{slope(y ,100 ,0  ,height )} )
	pd:sendBang    ('tone')
end

local function none() end

local funcs =
{	 [false] = {[false] = none ,[true] = fmod}
	,[true]  = {[false] = fmod ,[true] = pancar}  }

local onPress = funcs[isAuto]
local onClick = {onPress[true] ,tone}

function love.mousepressed(x ,y ,btn)
	onClick[btn](x ,y)
	isPressed[btn] = true
end

function love.mousereleased(x ,y ,btn)
	isPressed[btn] = false
end

function love.mousemoved(x ,y)
	onPress[love.mouse.isDown(1)](x ,y)
	mx ,my = x ,y
end

function love.wheelmoved(x ,y)
	pd:sendFloat('carrier-freq' ,y*25)
end

local kpress =
{	 ['+']  = function()
		portamento = math.max(0 ,portamento + 25)
		pd:sendFloat('portamento' ,portamento) end
	,['-']  = function()
		portamento = math.max(0 ,portamento - 25)
		pd:sendFloat('portamento' ,portamento) end
	,tab    = function()
		local state = love.mouse.isGrabbed()
		love.mouse.setGrabbed(not state) end
	,space  = function()
		isAuto = not isAuto
		onPress = funcs[isAuto]
		onClick[1] = onPress[true] end
	,lctrl  = function() tone(love.mouse.getPosition()) end
	,escape = function() love.event.push('quit') end   }
kpress['='] = kpress['+']

function love.keypressed(k)
	if kpress[k] then
		kpress[k]() end
end

function love.quit()
	pd:closePatch(patch)
	pd:computeAudio(false)
end
