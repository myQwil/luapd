#include "PdObject.hpp"
#include <iostream>
#include <stdlib.h>

using std::vector;
using namespace pd;

extern "C" { int luaopen_luapd(lua_State *L); }

#define LUA_PDARRAY  "PdArray"
#define LUA_PDPATCH  "PdPatch"
#define LUA_PDOBJECT "PdObject"
#define LUA_PDBASE   "PdBase"

// -----------------------------------------------------------------------------
// ------------------------ Array ----------------------------------------------
// -----------------------------------------------------------------------------

static int pdarray_new(lua_State *L) {
	int n  = !lua_isnoneornil(L ,1) ? luaL_checkinteger(L ,1) : 0;
	*(vector<float>**)lua_newuserdata(L ,sizeof(vector<float>*)) = new vector<float>(n);
	luaL_setmetatable(L ,LUA_PDARRAY);
	return 1;
}

static int pdarray_gc(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	delete a;
	return 0;
}

static int pdarray_len(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	lua_pushinteger(L ,a->size());
	return 1;
}

static int pdarray_index(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i = luaL_checkinteger(L ,2);
	if (i < 1 || i > a->size())
		return luaL_error(L ,"Array: index out of bounds");
	lua_pushnumber(L ,(*a)[i-1]);
	return 1;
}

static int pdarray_newindex(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i   = !lua_isnoneornil(L ,2) ? lua_tointeger(L ,2) : 0;
	float f = luaL_checknumber(L ,3);
	if (i < 1)
		return luaL_error(L ,"Array: index cannot be less than zero");
	if (i > a->size())
		a->resize(i ,0);
	(*a)[i-1] = f;
	return 0;
}

static int pdarray_call(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i = !lua_isnoneornil(L ,2) ? lua_tointeger(L ,2) : 0;
	lua_pushlightuserdata(L ,&(*a)[i]);
	return 1;
}

// -----------------------------------------------------------------------------
// ------------------------ PdPatch --------------------------------------------
// -----------------------------------------------------------------------------

static int pdpatch_new(lua_State *L) {
	Patch p;
	if (lua_isnoneornil(L ,1))
		p = Patch();
	else if (lua_isuserdata(L ,1))
		p = Patch(**(Patch**)luaL_checkudata  (L ,1 ,LUA_PDPATCH));
	else if (lua_islightuserdata(L ,1))
	{	void *handle      = lua_touserdata    (L ,1);
		int dollarZero    = luaL_checkinteger (L ,2);
		const char *patch = luaL_checkstring  (L ,3);
		const char *path  = !lua_isnoneornil  (L ,4) ? luaL_checkstring(L ,4) : ".";
		p = Patch(handle ,dollarZero ,patch ,path);  }
	else
	{	const char *patch = luaL_checkstring  (L ,1);
		const char *path  = !lua_isnoneornil  (L ,2) ? luaL_checkstring(L ,2) : ".";
		p = Patch(patch ,path);  }
	*(Patch**)lua_newuserdata(L ,sizeof(Patch*)) = new Patch(p);
	luaL_setmetatable(L ,LUA_PDPATCH);
	return 1;
}

static int pdpatch_gc(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	delete p;
	return 0;
}

static int pdpatch_handle(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushlightuserdata(L ,p->handle());
	return 1;
}

static int pdpatch_dollarZero(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushinteger(L ,p->dollarZero());
	return 1;
}

static int pdpatch_filename(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->filename().c_str());
	return 1;
}

static int pdpatch_path(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->path().c_str());
	return 1;
}

static int pdpatch_dollarZeroStr(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->dollarZeroStr().c_str());
	return 1;
}

static int pdpatch_isValid(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushboolean(L ,p->isValid());
	return 1;
}

static int pdpatch_clear(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	p->clear();
	return 0;
}

// -----------------------------------------------------------------------------
// ------------------------ PdObject -------------------------------------------
// -----------------------------------------------------------------------------

static int pdobject_new(lua_State *L) {
	lua_settop(L ,1);
	*(PdObject**)lua_newuserdata(L ,sizeof(PdObject*)) =
		new PdObject(L ,lua_istable(L ,1));
	luaL_setmetatable(L ,LUA_PDOBJECT);
	return 1;
}

static int pdobject_gc(lua_State *L) {
	PdObject *o = *(PdObject**)luaL_checkudata(L ,1 ,LUA_PDOBJECT);
	delete o;
	return 0;
}

static int pdobject_newindex(lua_State *L) {
	PdObject *o = *(PdObject**)luaL_checkudata(L ,1 ,LUA_PDOBJECT);
	const char *name = luaL_checkstring       (L ,2);
	luaL_checktype                            (L ,3 ,LUA_TFUNCTION);
	o->setFunc(name);
	return 0;
}

static int pdobject_setFuncs(lua_State *L) {
	PdObject *o = *(PdObject**)luaL_checkudata(L ,1 ,LUA_PDOBJECT);
	if (lua_istable(L ,2))
		o->setFuncs(2);
	return 0;
}
// -----------------------------------------------------------------------------
// ------------------------ PdBase ---------------------------------------------
// -----------------------------------------------------------------------------

static int pdbase_new(lua_State *L) {
	*(PdBase**)lua_newuserdata(L ,sizeof(PdBase*)) = new PdBase();
	luaL_setmetatable(L ,LUA_PDBASE);
	return 1;
}

static int pdbase_gc(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	delete b;
	return 0;
}

static int pdbase_init(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int chIn    = luaL_checkinteger       (L ,2);
	int chOut   = luaL_checkinteger       (L ,3);
	int srate   = luaL_checkinteger       (L ,4);
	bool queued = !lua_isnoneornil        (L ,5) ? lua_toboolean(L ,5) : false;
	lua_pushboolean(L ,b->init(chIn ,chOut ,srate ,queued));
	return 1;
}

static int pdbase_clear(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->clear();
	return 0;
}

static int pdbase_addToSearchPath(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *path = luaL_checkstring   (L ,2);
	b->addToSearchPath(path);
	return 0;
}

static int pdbase_clearSearchPath(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->clearSearchPath();
	return 0;
}

static int pdbase_openPatch(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	Patch  *p;
	if (lua_type(L ,2) == LUA_TSTRING)
	{	const char *patch = lua_tostring     (L ,2);
		const char *path  = !lua_isnoneornil (L ,3) ? luaL_checkstring(L ,3) : ".";
		p = new Patch(b->openPatch(patch ,path));  }
	else p = new Patch(b->openPatch(**(Patch**)luaL_checkudata(L ,2 ,LUA_PDPATCH)));
	*(Patch**)lua_newuserdata(L ,sizeof(Patch*)) = p;
	luaL_setmetatable(L ,LUA_PDPATCH);
	return 1;
}

static int pdbase_closePatch(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	if (lua_type(L ,2) == LUA_TSTRING)
	{	const char *patch = luaL_checkstring(L ,2);
		b->closePatch(patch);  }
	else
	{	Patch *p = *(Patch**)luaL_checkudata(L ,2 ,LUA_PDPATCH);
		b->closePatch(*p);  }
	return 0;
}

static int pdbase_processFloat(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int ticks  = luaL_checkinteger         (L ,2);
	int i      = lua_gettop(L) == 4;
	float *in  = i ? (float*)lua_touserdata(L ,3) : 0;
	float *out =     (float*)lua_touserdata(L ,3+i);
	lua_pushboolean(L ,b->processFloat(ticks ,in ,out));
	return 1;
}

static int pdbase_processShort(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int ticks  = luaL_checkinteger         (L ,2);
	int i      = lua_gettop(L) == 4;
	short *in  = i ? (short*)lua_touserdata(L ,3) : 0;
	short *out =     (short*)lua_touserdata(L ,3+i);
	lua_pushboolean(L ,b->processShort(ticks ,in ,out));
	return 1;
}

static int pdbase_processDouble(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata (L ,1 ,LUA_PDBASE);
	int ticks   = luaL_checkinteger          (L ,2);
	int i       = lua_gettop(L) == 4;
	double *in  = i ? (double*)lua_touserdata(L ,3) : 0;
	double *out =     (double*)lua_touserdata(L ,3+i);
	lua_pushboolean(L ,b->processDouble(ticks ,in ,out));
	return 1;
}

static int pdbase_processRaw(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int i      = lua_gettop(L) == 3;
	float *in  = i ? (float*)lua_touserdata(L ,2) : 0;
	float *out =     (float*)lua_touserdata(L ,2+i);
	lua_pushboolean(L ,b->processRaw(in ,out));
	return 1;
}

static int pdbase_processRawShort(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int i      = lua_gettop(L) == 3;
	short *in  = i ? (short*)lua_touserdata(L ,2) : 0;
	short *out =     (short*)lua_touserdata(L ,2+i);
	lua_pushboolean(L ,b->processRawShort(in ,out));
	return 1;
}

static int pdbase_processRawDouble(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int i       = lua_gettop(L) == 3;
	double *in  = i ? (double*)lua_touserdata(L ,2) : 0;
	double *out =     (double*)lua_touserdata(L ,2+i);
	lua_pushboolean(L ,b->processRawDouble(in ,out));
	return 1;
}

static int pdbase_computeAudio(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	bool state = lua_toboolean             (L ,2);
	b->computeAudio(state);
	return 0;
}

static int pdbase_subscribe(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	b->subscribe(source);
	return 0;
}

static int pdbase_unsubscribe(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	b->unsubscribe(source);
	return 0;
}

static int pdbase_exists(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	lua_pushboolean(L ,b->exists(source));
	return 1;
}

static int pdbase_unsubscribeAll(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->unsubscribeAll();
	return 0;
}

static int pdbase_receiveMessages(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->receiveMessages();
	return 0;
}

static int pdbase_receiveMidi(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->receiveMidi();
	return 0;
}

static int pdbase_setReceiver(lua_State *L) {
	PdBase   *b = *(PdBase**)   luaL_checkudata(L ,1 ,LUA_PDBASE);
	PdObject *o = *(PdObject**) (lua_isuserdata(L ,2)
	            ? luaL_checkudata(L ,2 ,LUA_PDOBJECT) : nullptr);
	b->setReceiver(o);
	return 0;
}

static int pdbase_setMidiReceiver(lua_State *L) {
	PdBase   *b = *(PdBase**)   luaL_checkudata(L ,1 ,LUA_PDBASE);
	PdObject *o = *(PdObject**) (lua_isuserdata(L ,2)
	            ? luaL_checkudata(L ,2 ,LUA_PDOBJECT) : nullptr);
	b->setMidiReceiver(o);
	return 0;
}

static int pdbase_sendBang(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	b->sendBang(dest);
	return 0;
}

static int pdbase_sendFloat(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	float value      = luaL_checknumber   (L ,3);
	b->sendFloat(dest ,value);
	return 0;
}

static int pdbase_sendSymbol(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest   = luaL_checkstring (L ,2);
	const char *symbol = luaL_checkstring (L ,3);
	b->sendSymbol(dest ,symbol);
	return 0;
}

static int pdbase_startMessage(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->startMessage();
	return 0;
}

static int pdbase_addFloat(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	float num = luaL_checknumber          (L ,2);
	b->addFloat(num);
	return 0;
}

static int pdbase_addSymbol(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *symbol = luaL_checkstring (L ,2);
	b->addSymbol(symbol);
	return 0;
}

static int pdbase_addAtom(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int typ = lua_type(L ,2);
	if      (typ == LUA_TNUMBER)
	{	float num = lua_tonumber(L ,2);
		b->addFloat(num);  }
	else if (typ == LUA_TSTRING)
	{	const char *symbol = lua_tostring(L ,2);
		b->addSymbol(symbol);  }
	return 0;
}

static int pdbase_finishList(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	b->finishList(dest);
	return 0;
}

static int pdbase_finishMessage(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	const char *msg  = luaL_checkstring   (L ,3);
	b->finishMessage(dest ,msg);
	return 0;
}

static List tableToList(lua_State *L ,int idx) {
	List list = List();
	for (int i=0; i<=lua_rawlen(L ,idx); i++)
	{	lua_pushinteger   (L ,i+1);
		lua_gettable      (L ,idx);
		if      (lua_type (L ,-1) == LUA_TNIL)
			break;
		else if (lua_type (L ,-1) == LUA_TNUMBER)
			list.addFloat  (lua_tonumber(L ,-1));
		else if (lua_type (L ,-1) == LUA_TSTRING)
			list.addSymbol (lua_tostring(L ,-1));
		lua_pop(L ,1);  }
	return list;
}

static int pdbase_sendList(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	luaL_checktype                        (L ,3 ,LUA_TTABLE);
	List list = tableToList(L ,3);
	b->sendList(dest ,list);
	return 0;
}

static int pdbase_sendMessage(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	const char *msg  = luaL_checkstring   (L ,3);
	List list = lua_type(L ,4) == LUA_TTABLE ? tableToList(L ,4) : List();
	b->sendMessage(dest ,msg ,list);
	return 0;
}

static int pdbase_sendNoteOn(lua_State *L) {
	PdBase *b    = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel  = luaL_checkinteger         (L ,2);
	int pitch    = luaL_checkinteger         (L ,3);
	int velocity = !lua_isnoneornil          (L ,4) ? luaL_checkinteger(L ,4) : 64;
	b->sendNoteOn(channel ,pitch ,velocity);
	return 0;
}

static int pdbase_sendControlChange(lua_State *L) {
	PdBase *b      = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel    = luaL_checkinteger         (L ,2);
	int controller = luaL_checkinteger         (L ,3);
	int value      = luaL_checkinteger         (L ,4);
	b->sendControlChange(channel ,controller ,value);
	return 0;
}

static int pdbase_sendProgramChange(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendProgramChange(channel ,value);
	return 0;
}

static int pdbase_sendPitchBend(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendPitchBend(channel ,value);
	return 0;
}

static int pdbase_sendAftertouch(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendAftertouch(channel ,value);
	return 0;
}

static int pdbase_sendPolyAftertouch(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int pitch   = luaL_checkinteger         (L ,3);
	int value   = luaL_checkinteger         (L ,4);
	b->sendPolyAftertouch(channel ,pitch ,value);
	return 0;
}

static int pdbase_sendMidiByte(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendMidiByte(port ,value);
	return 0;
}

static int pdbase_sendSysex(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendSysex(port ,value);
	return 0;
}

static int pdbase_sendSysRealTime(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendSysRealTime(port ,value);
	return 0;
}

static int pdbase_isMessageInProgress(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isMessageInProgress());
	return 1;
}

static int pdbase_arraySize(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	lua_pushinteger(L ,b->arraySize(name));
	return 1;
}

static int pdbase_resizeArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	long size        = luaL_checkinteger  (L ,3);
	lua_pushboolean(L ,b->resizeArray(name ,size));
	return 1;
}

static int pdbase_readArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	luaL_checktype(L ,3 ,LUA_TUSERDATA);
	vector<float> *a = *(vector<float>**)lua_touserdata(L ,3);
	int readLen      = !lua_isnoneornil   (L ,4) ? luaL_checkinteger(L ,4) : -1;
	int offset       = !lua_isnoneornil   (L ,5) ? luaL_checkinteger(L ,5) :  0;
	lua_pushboolean(L ,b->readArray(name ,*a ,readLen ,offset));
	return 1;
}

static int pdbase_writeArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	luaL_checktype(L ,3 ,LUA_TUSERDATA);
	vector<float> *a = *(vector<float>**)lua_touserdata(L ,3);
	int writeLen     = !lua_isnoneornil   (L ,4) ? luaL_checkinteger(L ,4) : -1;
	int offset       = !lua_isnoneornil   (L ,5) ? luaL_checkinteger(L ,5) :  0;
	lua_pushboolean(L ,b->writeArray(name ,*a ,writeLen ,offset));
	return 1;
}

static int pdbase_clearArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	int value        = !lua_isnoneornil   (L ,3) ? luaL_checkinteger (L ,3) : 0;
	b->clearArray(name ,value);
	return 0;
}

static int pdbase_isInited(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isInited());
	return 1;
}

static int pdbase_isQueued(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isQueued());
	return 1;
}

static int pdbase_blockSize(lua_State *L) {
	lua_pushinteger(L ,PdBase::blockSize());
	return 1;
}

static int pdbase_setMaxMessageLen(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	unsigned int len = luaL_checkinteger  (L ,2);
	b->setMaxMessageLen(len);
	return 0;
}

static int pdbase_maxMessageLen(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushinteger(L ,b->maxMessageLen());
	return 1;
}

static int pdbase_shl(lua_State *L) {
	// TODO
	return 0;
}

// -----------------------------------------------------------------------------
// ------------------------ Registers ------------------------------------------
// -----------------------------------------------------------------------------

static void pdarray_reg(lua_State *L) {
	static const luaL_Reg meta[] =
	{	 { "__gc"       ,pdarray_gc       }
		,{ "__len"      ,pdarray_len      }
		,{ "__index"    ,pdarray_index    }
		,{ "__newindex" ,pdarray_newindex }
		,{ "__call"     ,pdarray_call     }
		,{ NULL         ,NULL             }  };
	luaL_newmetatable(L ,LUA_PDARRAY);
	luaL_setfuncs    (L ,meta ,0);
	lua_pop          (L ,1);

	lua_pushliteral  (L ,"Array");
	lua_pushcfunction(L ,pdarray_new);
	lua_settable     (L ,-3);
}

static void pdpatch_reg(lua_State *L) {
	static const luaL_Reg meta[] =
	{	 { "__gc"          ,pdpatch_gc            }
		,{ NULL            ,NULL                  }  };
	static const luaL_Reg meth[] =
	{	 { "handle"        ,pdpatch_handle        }
		,{ "dollarZero"    ,pdpatch_dollarZero    }
		,{ "filename"      ,pdpatch_filename      }
		,{ "path"          ,pdpatch_path          }
		,{ "dollarZeroStr" ,pdpatch_dollarZeroStr }
		,{ "isValid"       ,pdpatch_isValid       }
		,{ "clear"         ,pdpatch_clear         }
		,{ NULL            ,NULL                  }  };
	luaL_newmetatable(L ,LUA_PDPATCH);
	luaL_setfuncs    (L ,meta ,0);
	luaL_newlib      (L ,meth);
	lua_setfield     (L ,-2 ,"__index");
	lua_pop          (L ,1);

	lua_pushliteral  (L ,"Patch");
	lua_pushcfunction(L ,pdpatch_new);
	lua_settable     (L ,-3);
}

static void pdobject_reg(lua_State *L) {
	static const luaL_Reg meta[] =
	{	 { "__gc"       ,pdobject_gc       }
		,{ "__newindex" ,pdobject_newindex }
		,{ NULL         ,NULL              }  };
	static const luaL_Reg meth[] =
	{	 { "setFuncs"   ,pdobject_setFuncs }
		,{ NULL         ,NULL              }  };
	luaL_newmetatable(L ,LUA_PDOBJECT);
	luaL_setfuncs    (L ,meta ,0);
	luaL_newlib      (L ,meth);
	lua_setfield     (L ,-2 ,"__index");
	lua_pop          (L ,1);

	lua_pushliteral  (L ,"Object");
	lua_pushcfunction(L ,pdobject_new);
	lua_settable     (L ,-3);
}

static void pdbase_reg(lua_State *L) {
	static const luaL_Reg meta[] =
	{	 { "__gc"                ,pdbase_gc                  }
		,{ "__shl"               ,pdbase_shl                 }
		,{ NULL                  ,NULL                       }  };
	static const luaL_Reg meth[] =
	{		// Initializing Pd
		 { "init"                ,pdbase_init                }
		,{ "clear"               ,pdbase_clear               }
			// Adding Search Paths
		,{ "addToSearchPath"     ,pdbase_addToSearchPath     }
		,{ "clearSearchPath"     ,pdbase_clearSearchPath     }
			// Opening Patches
		,{ "openPatch"           ,pdbase_openPatch           }
		,{ "closePatch"          ,pdbase_closePatch          }
			// Audio Processing
		,{ "processFloat"        ,pdbase_processFloat        }
		,{ "processShort"        ,pdbase_processShort        }
		,{ "processDouble"       ,pdbase_processDouble       }
		,{ "processRaw"          ,pdbase_processRaw          }
		,{ "processRawShort"     ,pdbase_processRawShort     }
		,{ "processRawDouble"    ,pdbase_processRawDouble    }
			// Audio Processing Control
		,{ "computeAudio"        ,pdbase_computeAudio        }
			// Message Receiving
		,{ "subscribe"           ,pdbase_subscribe           }
		,{ "unsubscribe"         ,pdbase_unsubscribe         }
		,{ "exists"              ,pdbase_exists              }
		,{ "unsubscribeAll"      ,pdbase_unsubscribeAll      }
			// Receiving from the Message Queues
		,{ "receiveMessages"     ,pdbase_receiveMessages     }
		,{ "receiveMidi"         ,pdbase_receiveMidi         }
			// Event Receiving via Callbacks
		,{ "setReceiver"         ,pdbase_setReceiver         }
		,{ "setMidiReceiver"     ,pdbase_setMidiReceiver     }
			// Send Functions
		,{ "sendBang"            ,pdbase_sendBang            }
		,{ "sendFloat"           ,pdbase_sendFloat           }
		,{ "sendSymbol"          ,pdbase_sendSymbol          }
			// Sending Compound Messages
		,{ "startMessage"        ,pdbase_startMessage        }
		,{ "addFloat"            ,pdbase_addFloat            }
		,{ "addSymbol"           ,pdbase_addSymbol           }
		,{ "addAtom"             ,pdbase_addAtom             }
		,{ "finishList"          ,pdbase_finishList          }
		,{ "finishMessage"       ,pdbase_finishMessage       }
		,{ "sendList"            ,pdbase_sendList            }
		,{ "sendMessage"         ,pdbase_sendMessage         }
			// Sending MIDI
		,{ "sendNoteOn"          ,pdbase_sendNoteOn          }
		,{ "sendControlChange"   ,pdbase_sendControlChange   }
		,{ "sendProgramChange"   ,pdbase_sendProgramChange   }
		,{ "sendPitchBend"       ,pdbase_sendPitchBend       }
		,{ "sendAftertouch"      ,pdbase_sendAftertouch      }
		,{ "sendPolyAftertouch"  ,pdbase_sendPolyAftertouch  }
		,{ "sendMidiByte"        ,pdbase_sendMidiByte        }
		,{ "sendSysex"           ,pdbase_sendSysex           }
		,{ "sendSysRealTime"     ,pdbase_sendSysRealTime     }
		,{ "isMessageInProgress" ,pdbase_isMessageInProgress }
			// Array Access
		,{ "arraySize"           ,pdbase_arraySize           }
		,{ "resizeArray"         ,pdbase_resizeArray         }
		,{ "readArray"           ,pdbase_readArray           }
		,{ "writeArray"          ,pdbase_writeArray          }
		,{ "clearArray"          ,pdbase_clearArray          }
			// Utils
		,{ "isInited"            ,pdbase_isInited            }
		,{ "isQueued"            ,pdbase_isQueued            }
		,{ "blockSize"           ,pdbase_blockSize           }
		,{ "setMaxMessageLen"    ,pdbase_setMaxMessageLen    }
		,{ "maxMessageLen"       ,pdbase_maxMessageLen       }
		,{ NULL                  ,NULL                       }  };
	luaL_newmetatable(L ,LUA_PDBASE);
	luaL_setfuncs    (L ,meta ,0);
	luaL_newlib      (L ,meth);
	lua_setfield     (L ,-2 ,"__index");
	lua_pop          (L ,1);

	static const luaL_Reg static_meta[] =
	{	 { "__call"    ,pdbase_new       }
		,{ NULL        ,NULL             }  };
	static const luaL_Reg static_meth[] =
	{	 { "blockSize" ,pdbase_blockSize }
		,{ NULL        ,NULL             }  };
	lua_pushliteral  (L ,"Base");
	luaL_newlib      (L ,static_meth);
	lua_newtable     (L);
	luaL_setfuncs    (L ,static_meta ,0);
	lua_setmetatable (L ,-2);
	lua_settable     (L ,-3);
}

int luaopen_luapd(lua_State *L) {
	lua_newtable (L);
	pdarray_reg  (L);
	pdpatch_reg  (L);
	pdobject_reg (L);
	pdbase_reg   (L);
	return 1;
}
