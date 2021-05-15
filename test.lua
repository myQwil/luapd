ffi = require('ffi')
if ffi.os == 'OSX' then
	package.cpath = './?.dylib;'..package.cpath   end
require('luapd')

inChannels ,outChannels ,sampleRate ,queued =
1          ,2           ,48000      ,false

-- our pd engine
pd = PdBase()

-- custom receiver object for messages and midi
obj = PdObject{
	-- message callbacks
	 print   = function(msg)       print('Lua$ '..msg) end
	,bang    = function(dest)      print('Lua: bang '  ..dest) end
	,float   = function(dest ,num) print('Lua: float ' ..dest..': '..num) end
	,symbol  = function(dest ,sym) print('Lua: symbol '..dest..': '..sym) end
	,list    = function(dest ,list)
		print('Lua: list '..dest..': '..table.concat(list ,' '))
	end
	,message = function(dest ,msg ,list)
		print('Lua: message '..dest..': |'..msg..'|'..table.concat(list ,' '))
	end

	-- midi callbacks
	,noteOn         = function(channel ,pitch ,velocity)
		print('Lua MIDI: note on: '..channel..' '..pitch..' '..velocity)
	end
	,controlChange  = function(channel ,controller ,value)
		print('Lua MIDI: control change: '..channel..' '..controller..' '..value)
	end
	,programChange  = function(channel ,value)
		print('Lua MIDI: program change: '..channel..' '..value)
	end
	,pitchBend      = function(channel ,value)
		print('Lua MIDI: pitch bend: '..channel..' '..value)
	end
	,aftertouch     = function(channel ,value)
		print('Lua MIDI: aftertouch: '..channel..' '..value)
	end
	,polyAftertouch = function(channel ,pitch ,value)
		print('Lua MIDI: poly aftertouch: '..channel..' '..pitch..' '..value)
	end
	,midiByte       = function(port ,byte)
		print('Lua MIDI: midi byte: '..port..' '..byte)
	end
}

blk    = PdBase.blockSize()
inbuf  = Array(blk * inChannels)
outbuf = Array(blk * outChannels)


-- init pd
--
-- set 4th arg to true for queued message passing using an internal ringbuffer
--
-- in this test, messages should return immediately when not queued otherwise
-- they should all return at once when pd is processing at the end of this
-- function
--
if not pd:init(inChannels ,outChannels ,sampleRate ,queued) then
	print('Could not init pd')
	os.exit()
end

midiChan = 1 -- midi channels are 0-15

-- subscribe to receive source names
pd:subscribe('toLua')
pd:subscribe('env')

-- set receivers
pd:setReceiver(obj)
pd:setMidiReceiver(obj)

-- add the data/pd folder to the search path
pd:addToSearchPath('pd/lib')

-- audio processing on
pd:computeAudio(true)


print('BEGIN Patch Test')
	-- open patch
	patch = pd:openPatch('pd/test.pd' ,'.')

	-- close patch
	pd:closePatch(patch)

	-- open patch again
	patch = pd:openPatch(patch)

	-- process any received messages
	--
	-- in a normal case (not a test like this), you would call this in
	-- your application main loop
	pd:processFloat(1 ,inbuf() ,outbuf())
	pd:receiveMessages()
print('FINISH Patch Test\n')


-- reassign a callback function
function obj.print(msg)
	print('!!'..msg)
end


print('BEGIN Message Test')
	-- test basic atoms
	pd:sendBang   ('fromLua')
	pd:sendFloat  ('fromLua' ,100)
	pd:sendSymbol ('fromLua' ,'test string')

	-- send a list
	pd:startMessage()
		pd:addFloat  (1.23)
		pd:addSymbol ('a symbol')
	pd:finishList('fromLua')

	-- send a message to the $0 receiver ie $0-toOF
	pd:startMessage()
		pd:addAtom(1.23)
		pd:addAtom('a symbol')
	pd:finishList(patch:dollarZeroStr()..'-fromLua')

	-- send a list using a table
	t = {1.23 ,'sent from a Lua table'}
	pd:sendList    ('fromLua' ,t)
	pd:sendMessage ('fromLua' ,'msg' ,t)
print('FINISH Message Test\n')


print('BEGIN MIDI Test')
	-- send functions
	pd:sendNoteOn         (midiChan ,60)
	pd:sendControlChange  (midiChan ,0 ,64)
	pd:sendProgramChange  (midiChan ,100)
	pd:sendPitchBend      (midiChan ,2000)
	pd:sendAftertouch     (midiChan ,100)
	pd:sendPolyAftertouch (midiChan ,64 ,100)
	pd:sendMidiByte    (0 ,239)
	pd:sendSysex       (0 ,239)
	pd:sendSysRealTime (0 ,239)
print('FINISH MIDI Test\n')


print('BEGIN Array Test')
	-- array check length
	print('array1 len: '..pd:arraySize('array1'))

	array1 = Array()

	function readArray1()
		pd:readArray('array1' ,array1)
		msg = 'array1'
		for i=1 ,#array1 do msg = msg..' '..array1[i] end
		print(msg)
	end

	-- read array
	readArray1()

	-- write array
	for i=1 ,#array1 do array1[i] = i end
	pd:writeArray('array1' ,array1);
	readArray1()

	-- clear array
	pd:clearArray('array1' ,10);
	readArray1()
print('FINISH Array Test\n')

print('BEGIN PD Test')
	pd:sendSymbol('fromLua' ,'test');
print('FINISH PD Test\n')


-- play a tone by sending a list
-- [list tone pitch 72 (
pd:sendList('tone' ,{'pitch' ,72});
pd:sendBang('tone');

-- now run pd for ten seconds (logical time)
-- you should see all the messages from pd print now
-- since processFloat actually runs the pd dsp engine and the recieve
-- functions pass messages to our PdObject
print('Processing PD')
for _=0 ,10 * sampleRate / blk do
	pd:processFloat(1 ,inbuf() ,outbuf())
	pd:receiveMessages()
	pd:receiveMidi()
end

-- be nice and clean up on exit
pd:closePatch(patch)
pd:computeAudio(false)
