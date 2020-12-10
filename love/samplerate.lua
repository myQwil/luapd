-- get the playback device's sample rate, code courtesy of zorg
local ffi = require('ffi')
local openal = (ffi.os == 'Windows') and ffi.load('OpenAL32') or ffi.C
ffi.cdef[[
typedef struct ALCcontext ALCcontext;
typedef struct ALCdevice  ALCdevice;
typedef int    ALCenum;
typedef int    ALCsizei;
typedef int    ALCint;
typedef void   ALCvoid;

void alcGetIntegerv(
	 ALCdevice *device
	,ALCenum    param
	,ALCsizei   size
	,ALCint    *data
);

ALCcontext *alcGetCurrentContext(ALCvoid);
ALCdevice  *alcGetContextsDevice(ALCcontext *context);
]]

local srate = ffi.new('ALCint[1]')
local ALC_FREQUENCY = 0x1007
local context = openal.alcGetCurrentContext()
local device  = openal.alcGetContextsDevice(context)
openal.alcGetIntegerv(device ,ALC_FREQUENCY ,1 ,srate)

return srate[0]
