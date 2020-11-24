
-- get the playback device's sample rate
local ffi = require 'ffi'
local liblove = (ffi.os == "Windows") and ffi.load('love') or ffi.C
ffi.cdef[[
typedef struct ALCcontext ALCcontext;
typedef struct ALCdevice ALCdevice;
typedef int ALCenum;
typedef int ALCsizei;
typedef int ALCint;
typedef void ALCvoid;

void alcGetIntegerv(
	 ALCdevice* device
	,ALCenum param
	,ALCsizei size
	,ALCint* data
);
ALCcontext* alcGetCurrentContext(ALCvoid);
ALCdevice* alcGetContextsDevice(ALCcontext *context);
]]

local buf = Buffer(4)
local ALC_FREQUENCY = 0x1007
local context = liblove.alcGetCurrentContext()
local device = liblove.alcGetContextsDevice(context)
liblove.alcGetIntegerv(device ,ALC_FREQUENCY ,1 ,buf:ptr())

return buf:at()
