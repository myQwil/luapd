-- get the playback device's sample rate, code courtesy of zorg
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
local context = ffi.C.alcGetCurrentContext()
local device  = ffi.C.alcGetContextsDevice(context)
ffi.C.alcGetIntegerv(device ,ALC_FREQUENCY ,1 ,srate)

return srate[0]
