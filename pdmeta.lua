---@meta

---------------------------------------------------------
------------------------- Array -------------------------

---@class Array
---a pd float array
---@param size number
---@return Array
function Array(size) end


---------------------------------------------------------
------------------------- Patch -------------------------

---@class Patch
---a pd patch
---
---if you use the copy constructor/operator, keep in mind the libpd void*
---pointer patch handle is copied and problems can arise if one object is used
---to close a patch that other copies may be referring to
---@return Patch
function Patch() end

---get the raw pointer to the patch instance
---@return lightuserdata
function Patch:handle() end

---get the unqiue instance $0 ID
---@return number
function Patch:dollarZero() end

---get the patch filename
---@return string
function Patch:filename() end

---get the parent dir path for the file
---@return string
function Patch:path() end

---get the unique instance $0 ID as a string
---@return string
function Patch:dollarZeroStr() end

---is the patch pointer valid?
---@return boolean
function Patch:isValid() end

---clear patch pointer and dollar zero (does not close patch!)
---
---note: does not clear filename and path so the object can be reused
---for opening multiple instances
function Patch:clear() end


------------------------------------------------------------
------------------------- PdObject -------------------------

---@class PdObject
---@field print   fun(message: string)
---@field bang    fun(dest: string)
---@field float   fun(dest: string, num: number)
---@field symbol  fun(dest: string, symbol: string)
---@field list    fun(dest: string, list: table)
---@field message fun(dest: string, msg: string, list: table)
---@field noteOn         fun(channel: number, pitch: number, velocity: number)
---@field controlChange  fun(channel: number, controller: number, value: number)
---@field programChange  fun(channel: number, value: number)
---@field pitchBend      fun(channel: number, value: number)
---@field afterTouch     fun(channel: number, value: number)
---@field polyAfterTouch fun(channel: number, pitch: number, value: number)
---@field midiByte       fun(port: number, byte: number)
---
---a pd message receiver and MIDI receiver
---@param callbacks function[] # A list of callback functions
---@return PdObject
function PdObject(callbacks) end


----------------------------------------------------------
------------------------- PdBase -------------------------

---@class PdBase
---a Pure Data instance
---
---note: libpd currently does not support multiple states and it is
---suggested that you use only one PdBase-derived object at a time
---
---calls from multiple PdBase instances currently use a global context
---kept in a singleton object, thus only one Receiver & one MidiReceiver
---can be used within a single program
---
---multiple context support will be added if/when it is included within libpd
---@return PdBase
function PdBase() end


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
---@param numInChannels number # The number of audio-in channels
---@param numOutChannels number # The number of audio-out channels
---@param sampleRate number # The audio sample rate
---@param queued boolean # Whether to use ringbuffers for message and midi event passing
---@return boolean # true if setup successfully
function PdBase:init(numInChannels, numOutChannels, sampleRate, queued) end

---clear resources
function PdBase:clear() end


----- Adding Search Paths -----

---add to the pd search path
---takes an absolute or relative path (in data folder)
---
---note: fails silently if path not found
---@param path string # search path
function PdBase:addToSearchPath(path) end

---clear the current pd search path
function PdBase:clearSearchPath() end


----- Opening Patches -----

---open a patch file (aka somefile.pd) at a specified parent dir path
---
---if no path is specified, the parent dir will be local
---
---or open a patch file using the filename and path of an existing patch
---@overload fun(name: string):Patch
---@overload fun(patch: Patch):Patch
---@param name string # The name of the patch.
---@param path string # The parent directory.
---@return Patch
function PdBase:openPatch(name, path) end

---close a patch file
---@overload fun(patch: Patch)
---@param name string # the patch's basename (filename without extension)
function PdBase:closePatch(name) end


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
---@overload fun(ticks: number, outBuffer: number[]):boolean
---@param ticks number # The number of ticks to process
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processFloat(ticks, inBuffer, outBuffer) end

---process short buffers for a given number of ticks
---@overload fun(ticks: number, outBuffer: number[]):boolean
---@param ticks number # The number of ticks to process
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processShort(ticks, inBuffer, outBuffer) end

---process double buffers for a given number of ticks
---@overload fun(ticks: number, outBuffer: number[]):boolean
---@param ticks number # The number of ticks to process
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processDouble(ticks, inBuffer, outBuffer) end

---process one pd tick, writes raw float data to/from buffers
---@overload fun(outBuffer: number[]):boolean
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processRaw(inBuffer, outBuffer) end

---process one pd tick, writes raw short data to/from buffers
---@overload fun(outBuffer: number[]):boolean
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processRawShort(inBuffer, outBuffer) end

---process one pd tick, writes raw double data to/from buffers
---@overload fun(outBuffer: number[]):boolean
---@param inBuffer number[] # Audio-in buffer
---@param outBuffer number[] # Audio-out buffer
---@return boolean # false on error
function PdBase:processRawDouble(inBuffer, outBuffer) end


----- Audio Processing Control -----

---start/stop audio processing
---
---in general, once started, you won't need to turn off audio
---
---shortcut for [; pd dsp 1( & [; pd dsp 0(
---@param state boolean
function PdBase:computeAudio(state) end


----- Message Receiving -----

---subscribe to messages sent by a pd send source
---
---it acts like a virtual pd receive object
---@param source string
function PdBase:subscribe(source) end

---unsubscribe from messages sent by a pd send source
---@param source string
function PdBase:unsubscribe(source) end

---is a pd send source subscribed?
---@param source string
---@return boolean
function PdBase:exists(source) end

---receivers will be unsubscribed from *all* pd send sources
function PdBase:unsubscribeAll() end


----- Receiving from the Message Queues -----

---process waiting messages
function PdBase:receiveMessages() end

---process waiting midi messages
function PdBase:receiveMidi() end


----- Event Receiving via Callbacks -----

---set the incoming event receiver, disables the event queue
---
---automatically receives from all currently subscribed sources
---
---set this to NULL to disable callback receiving and re-enable the
---event queue
---@param receiver PdObject
function PdBase:setReceiver(receiver) end

---set the incoming midi event receiver, disables the midi queue
---
---automatically receives from all midi channels
---
---set this to NULL to disable callback receiving and re-enable the
---event queue
---@param receiver PdObject
function PdBase:setMidiReceiver(receiver) end


----- Send Functions -----

---send a bang message
---@param dest string # The destination
function PdBase:sendBang(dest) end

---send a float
---@param dest string # The destination
---@param value number # A float
function PdBase:sendFloat(dest, value) end

---send a symbol
---@param dest string # The destination
---@param symbol string # A string
function PdBase:sendSymbol(dest, symbol) end


----- Sending Compound Messages -----

---start a compound list or message
function PdBase:startMessage() end

---add a float to the current compound list or message
---@param num number
function PdBase:addFloat(num) end

---add a symbol to the current compound list or message
---@param symbol string
function PdBase:addSymbol(symbol) end

---add a float or symbol to the current compound list or message
---@param atom string|number
function PdBase:addAtom(atom) end

---finish and send as a list
---@param dest string # The destination
function PdBase:finishList(dest) end

---finish and send as a list with a specific message name
---@param dest string # The destination
---@param msg string # The message
function PdBase:finishMessage(dest, msg) end

---send a list using a table
---@param dest string # The destination
---@param list table # A table
function PdBase:sendList(dest, list) end

---send a message and accompanying args
---@param dest string # The destination
---@param msg string # The message
---@param list table # Accompanying args
function PdBase:sendMessage(dest, msg, list) end


----- Sending MIDI -----

---send a MIDI note on
---
---pd does not use note off MIDI messages, so send a note on with vel = 0
---@param channel number
---@param pitch number
---@param velocity number
function PdBase:sendNoteOn(channel, pitch, velocity) end

---send a MIDI control change
---@param channel number
---@param controller number
---@param value number
function PdBase:sendControlChange(channel, controller, value) end

---send a MIDI program change
---@param channel number
---@param value number
function PdBase:sendProgramChange(channel, value) end

---send a MIDI pitch bend
---
---in pd: [bendin] takes 0 - 16383 while [bendout] returns -8192 - 8191
---@param channel number
---@param value number
function PdBase:sendPitchBend(channel, value) end

---send a MIDI aftertouch
---@param channel number
---@param value number
function PdBase:sendAftertouch(channel, value) end

---send a MIDI poly aftertouch
---@param channel number
---@param pitch number
---@param value number
function PdBase:sendPolyAftertouch(channel, pitch, value) end

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
---@param port number
---@param value number
function PdBase:sendMidiByte(port, value) end

---send a raw MIDI sysex byte
---@param port number
---@param value number
function PdBase:sendSysex(port, value) end

---send a raw MIDI realtime byte
---@param port number
---@param value number
function PdBase:sendSysRealTime(port, value) end

---is a message or byte stream currently in progress?
---@return boolean
function PdBase:isMessageInProgress() end


----- Array Access -----

---get the size of a pd array
---@param name string
---@return number # 0 if array not found
function PdBase:arraySize(name) end

---(re)size a pd array
---
---sizes <= 0 are clipped to 1
---@param name string
---@param size number
---@return boolean # true on success, false on failure
function PdBase:resizeArray(name, size) end

---read from a pd array
---
---resizes given vector to readLen, checks readLen and offset
---
---calling without setting readLen and offset reads the whole array:
---@param name string # The name of the pd array
---@param dest number[] # The vector where the array will be stored
---@param readLen number # The amount to read (default -1)
---@param offset number # The offset (default 0)
---@return boolean # true on success, false on failure
function PdBase:readArray(name, dest, readLen, offset) end

---write to a pd array
---
---calling without setting writeLen and offset writes the whole array:
---@param name string
---@param source number[]
---@param writeLen number # (default -1)
---@param offset number # (default 0)
---@return boolean # true on success, false on failure
function PdBase:writeArray(name, source, writeLen, offset) end

---clear array and set to a specific value
---@param name string
---@param value number
function PdBase:clearArray(name, value) end


----- Utils -----

---has the global pd instance been initialized?
---@return boolean
function PdBase:isInited() end

---is the global pd instance using the ringerbuffer queue
---for message padding?
---@return boolean
function PdBase:isQueued() end

---get the blocksize of pd (sample length per channel)
---@return number
function PdBase.blockSize() end

---set the max length of messages and lists, default: 32
---@param len number
function PdBase:setMaxMessageLen(len) end

---get the max length of messages and lists
---@return number
function PdBase:maxMessageLen() end
