---@meta

---The LuaPd library
---@class Pd
local Pd = {}

---------------------------------------------------------
------------------------- Array -------------------------

---A wrapper for a std::vector\<float\>
---@class PdArray
Pd._Array = {}

---@param size? integer # size of the array (default 0)
---@return PdArray
function Pd.Array(size) end


---------------------------------------------------------
------------------------- Patch -------------------------

---A pd patch
---
---If you use the copy constructor/operator, keep in mind the libpd void*
---pointer patch handle is copied and problems can arise if one object is used
---to close a patch that other copies may be referring to
---@class PdPatch
Pd._Patch = {}

---@overload fun(filename:string, path?:string): PdPatch
---@overload fun(patch?:PdPatch): PdPatch # copy constructor
---@param handle lightuserdata # the raw pointer to the patch instance
---@param dollarZero integer # the unqiue instance $0 ID
---@param filename string # the patch filename
---@param path? string # the parent dir path for the file (default ".")
---@return PdPatch
function Pd.Patch(handle, dollarZero, filename, path) end

---get the raw pointer to the patch instance
---@return lightuserdata
function Pd._Patch:handle() end

---get the unqiue instance $0 ID
---@return integer
function Pd._Patch:dollarZero() end

---get the patch filename
---@return string
function Pd._Patch:filename() end

---get the parent dir path for the file
---@return string
function Pd._Patch:path() end

---get the unique instance $0 ID as a string
---@return string
function Pd._Patch:dollarZeroStr() end

---is the patch pointer valid?
---@return boolean
function Pd._Patch:isValid() end

---clear patch pointer and dollar zero (does not close patch!)
---
---note: does not clear filename and path so the object can be reused
---for opening multiple instances
function Pd._Patch:clear() end


------------------------------------------------------------
------------------------- PdObject -------------------------

---A pd message receiver
---@class PdObject
---@field print   fun(message:string)
---@field bang    fun(dest:string)
---@field float   fun(dest:string, num:number)
---@field symbol  fun(dest:string, symbol:string)
---@field list    fun(dest:string, list:table)
---@field message fun(dest:string, msg:string, list:table)
---@field noteOn         fun(channel:integer, pitch:integer, velocity:integer)
---@field controlChange  fun(channel:integer, controller:integer, value:integer)
---@field programChange  fun(channel:integer, value:integer)
---@field pitchBend      fun(channel:integer, value:integer)
---@field afterTouch     fun(channel:integer, value:integer)
---@field polyAfterTouch fun(channel:integer, pitch:integer, value:integer)
---@field midiByte       fun(port:integer, byte:integer)
Pd._Object = {}

---@param callbacks? function[] # a list of callback functions
---@return PdObject
function Pd.Object(callbacks) end

---set multiple callback functions
---@param funcs table
function Pd._Object:setFuncs(funcs) end


----------------------------------------------------------
------------------------- PdBase -------------------------

---A Pure Data instance
---
---note: libpd currently does not support multiple states and it is
---suggested that you use only one PdBase-derived object at a time
---
---calls from multiple PdBase instances currently use a global context
---kept in a singleton object, thus only one Receiver & one MidiReceiver
---can be used within a single program
---
---multiple context support will be added if/when it is included within libpd
---@class PdBase
Pd._Base = {}

---@return PdBase
function Pd.Base() end


----- Initializing Pd -----

---initialize resources and set up the audio processing
---
---set the audio latency by setting the libpd ticks per buffer:
---ticks per buffer * lib pd block size (always 64)
---
---ie 4 ticks per buffer * 64 = buffer len of 512
---
---you can call this again after loading patches & setting receivers
---in order to update the audio settings
---
---the lower the number of ticks, the faster the audio processing
---if you experience audio dropouts (audible clicks), increase the
---ticks per buffer
---
---set queued = true to use the built in ringbuffers for message and
---midi event passing, you will then need to call receiveMessages() and
---receiveMidi() in order to pass messages from the ringbuffers to your
---PdReceiver and PdMidiReceiver implementations
---
---the queued ringbuffers are useful when you need to receive events
---on a gui thread and don't want to use locking
---
---note: must be called before processing
---@param numInChannels integer # the number of audio-in channels
---@param numOutChannels integer # the number of audio-out channels
---@param sampleRate integer # the audio sample rate
---@param queued boolean # whether to use ringbuffers for message and midi event passing
---@return boolean # true if setup successfully
function Pd._Base:init(numInChannels, numOutChannels, sampleRate, queued) end

---clear resources
function Pd._Base:clear() end


----- Adding Search Paths -----

---add to the pd search path  
---takes an absolute or relative path (in data folder)
---
---note: fails silently if path not found
---@param path string # search path
function Pd._Base:addToSearchPath(path) end

---clear the current pd search path
function Pd._Base:clearSearchPath() end


----- Opening Patches -----

---open a patch file (aka somefile.pd) at a specified parent dir path
---
---if no path is specified, the parent dir will be local
---
---or open a patch file using the filename and path of an existing patch
---@overload fun(_, patch:PdPatch): PdPatch # use filename and path of an existing patch
---@param name string # the name of the patch
---@param path? string # the parent directory (default ".")
---@return PdPatch
function Pd._Base:openPatch(name, path) end

---close a patch file
---@overload fun(_, patch:PdPatch)
---@param name string # the patch's basename (filename without extension)
function Pd._Base:closePatch(name) end


----- Audio Processing -----

--- one of these must be called for audio dsp and message io to occur
---
--- inBuffer must be an array of the right size and never null
--- use inBuffer = new type[0] if no input is desired
---
--- outBuffer must be an array of size outBufferSize from openAudio call
---
--- note: raw does not interlace the buffers

---process float buffers for a given number of ticks
---@overload fun(_, ticks:integer, outBuffer:number[]): boolean
---@param ticks integer # the number of ticks to process
---@param inBuffer number[] # audio-in buffer
---@param outBuffer number[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processFloat(ticks, inBuffer, outBuffer) end

---process short buffers for a given number of ticks
---@overload fun(_, ticks:integer, outBuffer:number[]): boolean
---@param ticks integer # the number of ticks to process
---@param inBuffer integer[] # audio-in buffer
---@param outBuffer integer[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processShort(ticks, inBuffer, outBuffer) end

---process double buffers for a given number of ticks
---@overload fun(_, ticks:integer, outBuffer:number[]): boolean
---@param ticks integer # the number of ticks to process
---@param inBuffer number[] # audio-in buffer
---@param outBuffer number[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processDouble(ticks, inBuffer, outBuffer) end

---process one pd tick, writes raw float data to/from buffers
---@overload fun(_, outBuffer:number[]): boolean
---@param inBuffer number[] # audio-in buffer
---@param outBuffer number[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processRaw(inBuffer, outBuffer) end

---process one pd tick, writes raw short data to/from buffers
---@overload fun(_, outBuffer:number[]): boolean
---@param inBuffer integer[] # audio-in buffer
---@param outBuffer integer[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processRawShort(inBuffer, outBuffer) end

---process one pd tick, writes raw double data to/from buffers
---@overload fun(_, outBuffer:number[]): boolean
---@param inBuffer number[] # audio-in buffer
---@param outBuffer number[] # audio-out buffer
---@return boolean # false on error
function Pd._Base:processRawDouble(inBuffer, outBuffer) end


----- Audio Processing Control -----

---start/stop audio processing
---
---in general, once started, you won't need to turn off audio
---@param state boolean
function Pd._Base:computeAudio(state) end


----- Message Receiving -----

---subscribe to messages sent by a pd send source
---
---it acts like a virtual pd receive object
---@param source string
function Pd._Base:subscribe(source) end

---unsubscribe from messages sent by a pd send source
---@param source string
function Pd._Base:unsubscribe(source) end

---is a pd send source subscribed?
---@param source string
---@return boolean
function Pd._Base:exists(source) end

---receivers will be unsubscribed from *all* pd send sources
function Pd._Base:unsubscribeAll() end


----- Receiving from the Message Queues -----

---process waiting messages
function Pd._Base:receiveMessages() end

---process waiting midi messages
function Pd._Base:receiveMidi() end


----- Event Receiving via Callbacks -----

---set the incoming event receiver, disables the event queue
---
---automatically receives from all currently subscribed sources
---
---set this to NULL to disable callback receiving and re-enable the
---event queue
---@param receiver PdObject
function Pd._Base:setReceiver(receiver) end

---set the incoming midi event receiver, disables the midi queue
---
---automatically receives from all midi channels
---
---set this to NULL to disable callback receiving and re-enable the
---event queue
---@param receiver PdObject
function Pd._Base:setMidiReceiver(receiver) end


----- Send Functions -----

---send a bang message
---@param dest string # the destination
function Pd._Base:sendBang(dest) end

---send a float
---@param dest string # the destination
---@param value number # a float
function Pd._Base:sendFloat(dest, value) end

---send a symbol
---@param dest string # the destination
---@param symbol string # a string
function Pd._Base:sendSymbol(dest, symbol) end


----- Sending Compound Messages -----

---start a compound list or message
function Pd._Base:startMessage() end

---add a float to the current compound list or message
---@param num number
function Pd._Base:addFloat(num) end

---add a symbol to the current compound list or message
---@param symbol string
function Pd._Base:addSymbol(symbol) end

---add a float or symbol to the current compound list or message
---@param atom string|number
function Pd._Base:addAtom(atom) end

---finish and send as a list
---@param dest string # the destination
function Pd._Base:finishList(dest) end

---finish and send as a list with a specific message name
---@param dest string # the destination
---@param msg string # the message
function Pd._Base:finishMessage(dest, msg) end

---send a list using a table
---@param dest string # the destination
---@param list table # a table
function Pd._Base:sendList(dest, list) end

---send a message and accompanying args
---@param dest string # the destination
---@param msg string # the message
---@param list table|nil # accompanying args
function Pd._Base:sendMessage(dest, msg, list) end


----- Sending MIDI -----

---send a MIDI note on
---
---pd does not use note off MIDI messages, so send a note on with vel = 0
---@param channel integer
---@param pitch integer
---@param velocity? integer # default 64
function Pd._Base:sendNoteOn(channel, pitch, velocity) end

---send a MIDI control change
---@param channel integer
---@param controller integer
---@param value integer
function Pd._Base:sendControlChange(channel, controller, value) end

---send a MIDI program change
---@param channel integer
---@param value integer
function Pd._Base:sendProgramChange(channel, value) end

---send a MIDI pitch bend
---
---in pd: [bendin] takes 0 - 16383 while [bendout] returns -8192 - 8191
---@param channel integer
---@param value integer
function Pd._Base:sendPitchBend(channel, value) end

---send a MIDI aftertouch
---@param channel integer
---@param value integer
function Pd._Base:sendAftertouch(channel, value) end

---send a MIDI poly aftertouch
---@param channel integer
---@param pitch integer
---@param value integer
function Pd._Base:sendPolyAftertouch(channel, pitch, value) end

---send a raw MIDI byte
---
---value is a raw midi byte value 0 - 255
---port is the raw portmidi port #, similar to a channel
---
---for some reason, [midiin], [sysexin] & [realtimein] add 2 to the
---port num, so sending to port 1 in PdBase returns port 3 in pd
---
---however, [midiout], [sysexout], & [realtimeout] do not add to the
---port num, so sending port 1 to [midiout] returns port 1 in PdBase
---@param port integer
---@param value integer
function Pd._Base:sendMidiByte(port, value) end

---send a raw MIDI sysex byte
---@param port integer
---@param value integer
function Pd._Base:sendSysex(port, value) end

---send a raw MIDI realtime byte
---@param port integer
---@param value integer
function Pd._Base:sendSysRealTime(port, value) end

---is a message or byte stream currently in progress?
---@return boolean
function Pd._Base:isMessageInProgress() end


----- Array Access -----

---get the size of a pd array
---@param name string
---@return integer # 0 if array not found
function Pd._Base:arraySize(name) end

---(re)size a pd array
---
---sizes <= 0 are clipped to 1
---@param name string
---@param size integer
---@return boolean # true on success, false on failure
function Pd._Base:resizeArray(name, size) end

---read from a pd array
---
---resizes given vector to readLen, checks readLen and offset
---
---calling without setting readLen and offset reads the whole array:
---@param name string # the name of the pd array
---@param dest number[] # the vector that the array will be written to
---@param readLen? integer # the amount to read (default -1)
---@param offset? integer # the offset (default 0)
---@return boolean # true on success, false on failure
function Pd._Base:readArray(name, dest, readLen, offset) end

---write to a pd array
---
---calling without setting writeLen and offset writes the whole array:
---@param name string # the name of the pd array
---@param source number[] # the vector that the array will read from
---@param writeLen? integer # the amount to write (default -1)
---@param offset? integer # the offset (default 0)
---@return boolean # true on success, false on failure
function Pd._Base:writeArray(name, source, writeLen, offset) end

---clear array and set to a specific value
---@param name string
---@param value? integer # default 0
function Pd._Base:clearArray(name, value) end


----- Utils -----

---has the global pd instance been initialized?
---@return boolean
function Pd._Base:isInited() end

---is the global pd instance using the ringerbuffer queue
---for message padding?
---@return boolean
function Pd._Base:isQueued() end

---get the blocksize of pd (sample length per channel)
---@return integer
function Pd._Base.blockSize() end

---set the max length of messages and lists, default: 32
---@param len integer
function Pd._Base:setMaxMessageLen(len) end

---get the max length of messages and lists
---@return integer
function Pd._Base:maxMessageLen() end
