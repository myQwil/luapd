#include <stdlib.h>
#include <iostream>
#include "PdObject.hpp"

#if LUA_VERSION_NUM == 501
#define lua_rawlen(L,i) lua_objlen(L,(i))
#define luaL_setmetatable(L,n) (luaL_getmetatable(L,(n)) ,lua_setmetatable (L,-2))
#endif

using namespace std;
using namespace pd;

extern "C" { int LUA_API luaopen_luapd(lua_State *L); }

#define LUA_PDBASE   "PdBase"
#define LUA_PDPATCH  "Patch"
#define LUA_PDOBJECT "PdObject"
#define LUA_PDARRAY  "Array"

// ------------------------------------------------------------------------
// -------------------------------- PdBase --------------------------------
// ------------------------------------------------------------------------
static int pdbase_new(lua_State *L) {
	*(PdBase**)lua_newuserdata(L ,sizeof(PdBase*)) = new PdBase();
	luaL_setmetatable(L ,LUA_PDBASE);
	return 1;
}

static int pdbase_del(lua_State *L) {
	delete *(PdBase**)lua_touserdata(L ,1);
	return 0;
}

static int l_init(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int chIn    = luaL_checkinteger       (L ,2);
	int chOut   = luaL_checkinteger       (L ,3);
	int srate   = luaL_checkinteger       (L ,4);
	bool queued = !lua_isnoneornil        (L ,5) ? lua_toboolean(L ,5) : false;
	lua_pushboolean(L ,b->init(chIn ,chOut ,srate ,queued));
	return 1;
}

static int l_addToSearchPath(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *path = luaL_checkstring   (L ,2);
	b->addToSearchPath(path);
	return 0;
}

static int l_clearSearchPath(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->clearSearchPath();
	return 0;
}

static int l_openPatch(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	Patch  *p;
	int isString = (lua_type(L ,2) == LUA_TSTRING);
	if (isString)
	{	const char *patch = lua_tostring     (L ,2);
		const char *path  = !lua_isnoneornil (L ,3) ? luaL_checkstring(L ,3) : ".";
		p = new Patch(b->openPatch(patch ,path));   }
	else p = new Patch(b->openPatch(**(Patch**)luaL_checkudata(L ,2 ,LUA_PDPATCH)));
	*(Patch**)lua_newuserdata(L ,sizeof(Patch*)) = p;
	luaL_setmetatable(L ,LUA_PDPATCH);
	return 1;
}

static int l_closePatch(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int isString = (lua_type(L ,2) == LUA_TSTRING);
	if (isString)
	{	const char *patch = luaL_checkstring(L ,2);
		b->closePatch(patch);   }
	else
	{	Patch *p = *(Patch**)luaL_checkudata(L ,2 ,LUA_PDPATCH);
		b->closePatch(*p);   }
	return 0;
}

static int l_subscribe(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	b->subscribe(source);
	return 0;
}

static int l_unsubscribe(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	b->unsubscribe(source);
	return 0;
}

static int l_exists(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *source = luaL_checkstring (L ,2);
	lua_pushboolean(L ,b->exists(source));
	return 1;
}

static int l_unsubscribeAll(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->unsubscribeAll();
	return 0;
}

static int l_receiveMessages(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->receiveMessages();
	return 0;
}

static int l_receiveMidi(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->receiveMidi();
	return 0;
}

static int l_setReceiver(lua_State *L) {
	PdBase   *b = *(PdBase**)   luaL_checkudata(L ,1 ,LUA_PDBASE);
	PdObject *o = *(PdObject**) luaL_checkudata(L ,2 ,LUA_PDOBJECT);
	b->setReceiver(o);
	return 0;
}

static int l_setMidiReceiver(lua_State *L) {
	PdBase   *b = *(PdBase**)   luaL_checkudata(L ,1 ,LUA_PDBASE);
	PdObject *o = *(PdObject**) luaL_checkudata(L ,2 ,LUA_PDOBJECT);
	b->setMidiReceiver(o);
	return 0;
}

static int l_isMessageInProgress(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isMessageInProgress());
	return 1;
}

static int l_isInited(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isInited());
	return 1;
}

static int l_isQueued(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushboolean(L ,b->isQueued());
	return 1;
}

static int l_setMaxMessageLen(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	unsigned int len = luaL_checkinteger  (L ,2);
	b->setMaxMessageLen(len);
	return 0;
}

static int l_maxMessageLen(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	lua_pushinteger(L ,b->maxMessageLen());
	return 1;
}

static int l_sendBang(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	b->sendBang(dest);
	return 0;
}

static int l_sendFloat(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	float value      = luaL_checknumber   (L ,3);
	b->sendFloat(dest ,value);
	return 0;
}

static int l_sendSymbol(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest   = luaL_checkstring (L ,2);
	const char *symbol = luaL_checkstring (L ,3);
	b->sendSymbol(dest ,symbol);
	return 0;
}

static int l_startMessage(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	b->startMessage();
	return 0;
}

static int l_addFloat(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	float num = luaL_checknumber          (L ,2);
	b->addFloat(num);
	return 0;
}

static int l_addSymbol(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *symbol = luaL_checkstring (L ,2);
	b->addSymbol(symbol);
	return 0;
}

static int l_addAtom(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int typ = lua_type(L ,2);
	if      (typ == LUA_TNUMBER)
	{	float num = lua_tonumber(L ,2);
		b->addFloat(num);   }
	else if (typ == LUA_TSTRING)
	{	const char *symbol = lua_tostring(L ,2);
		b->addSymbol(symbol);   }
	return 0;
}

static int l_finishList(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	b->finishList(dest);
	return 0;
}

static int l_finishMessage(lua_State *L) {
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
		lua_pop(L ,1);   }
	return list;
}

static int l_sendList(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	luaL_checktype                        (L ,3 ,LUA_TTABLE);
	List list = tableToList(L ,3);
	b->sendList(dest ,list);
	return 0;
}

static int l_sendMessage(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *dest = luaL_checkstring   (L ,2);
	const char *msg  = luaL_checkstring   (L ,3);
	List list = lua_type(L ,4) == LUA_TTABLE ? tableToList(L ,4) : List();
	b->sendMessage(dest ,msg ,list);
	return 0;
}

static int l_sendNoteOn(lua_State *L) {
	PdBase *b    = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel  = luaL_checkinteger         (L ,2);
	int pitch    = luaL_checkinteger         (L ,3);
	int velocity = !lua_isnoneornil          (L ,4) ? luaL_checkinteger(L ,4) : 64;
	b->sendNoteOn(channel ,pitch ,velocity);
	return 0;
}

static int l_sendControlChange(lua_State *L) {
	PdBase *b      = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel    = luaL_checkinteger         (L ,2);
	int controller = luaL_checkinteger         (L ,3);
	int value      = luaL_checkinteger         (L ,4);
	b->sendControlChange(channel ,controller ,value);
	return 0;
}

static int l_sendProgramChange(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendProgramChange(channel ,value);
	return 0;
}

static int l_sendPitchBend(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendPitchBend(channel ,value);
	return 0;
}

static int l_sendAftertouch(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int value   = luaL_checkinteger         (L ,3);
	b->sendAftertouch(channel ,value);
	return 0;
}

static int l_sendPolyAftertouch(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int channel = luaL_checkinteger         (L ,2);
	int pitch   = luaL_checkinteger         (L ,3);
	int value   = luaL_checkinteger         (L ,4);
	b->sendPolyAftertouch(channel ,pitch ,value);
	return 0;
}

static int l_sendMidiByte(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendMidiByte(port ,value);
	return 0;
}

static int l_sendSysex(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendSysex(port ,value);
	return 0;
}

static int l_sendSysRealTime(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int port  = luaL_checkinteger         (L ,2);
	int value = luaL_checkinteger         (L ,3);
	b->sendSysRealTime(port ,value);
	return 0;
}

static int l_processRaw(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int i      = lua_gettop(L) == 3;
	float *in  = i?(float*)lua_touserdata  (L ,2):0;
	float *out =   (float*)lua_touserdata  (L ,2+i);
	bool success = b->processRaw(in ,out);
	lua_pushboolean(L ,success);
	return 1;
}

static int l_processShort(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int ticks  = luaL_checkinteger         (L ,2);
	int i      = lua_gettop(L) == 4;
	short *in  = i?(short*)lua_touserdata  (L ,3):0;
	short *out =   (short*)lua_touserdata  (L ,3+i);
	bool success = b->processShort(ticks ,in ,out);
	lua_pushboolean(L ,success);
	return 1;
}

static int l_processFloat(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int ticks  = luaL_checkinteger         (L ,2);
	int i      = lua_gettop(L) == 4;
	float *in  = i?(float*)lua_touserdata  (L ,3):0;
	float *out =   (float*)lua_touserdata  (L ,3+i);
	bool success = b->processFloat(ticks ,in ,out);
	lua_pushboolean(L ,success);
	return 1;
}

static int l_processDouble(lua_State *L) {
	PdBase *b   = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	int ticks   = luaL_checkinteger         (L ,2);
	int i       = lua_gettop(L) == 4;
	double *in  = i?(double*)lua_touserdata (L ,3):0;
	double *out =   (double*)lua_touserdata (L ,3+i);
	bool success = b->processDouble(ticks ,in ,out);
	lua_pushboolean(L ,success);
	return 1;
}

static int l_computeAudio(lua_State *L) {
	PdBase *b  = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	bool state = lua_toboolean             (L ,2);
	b->computeAudio(state);
	return 0;
}

static int l_blockSize(lua_State *L) {
	lua_pushinteger(L ,PdBase::blockSize());
	return 1;
}

static int l_arraySize(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	lua_pushinteger(L ,b->arraySize(name));
	return 1;
}

static int l_readArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	vector<float> *a = *(vector<float>**)luaL_checkudata (L ,3 ,LUA_PDARRAY);
	int readLen      = !lua_isnoneornil   (L ,4) ? luaL_checkinteger (L ,4) :-1;
	int offset       = !lua_isnoneornil   (L ,5) ? luaL_checkinteger (L ,5) : 0;
	lua_pushboolean(L ,b->readArray(name ,*a ,readLen ,offset));
	return 1;
}

static int l_writeArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	vector<float> *a = *(vector<float>**)luaL_checkudata (L ,3 ,LUA_PDARRAY);
	int writeLen     = !lua_isnoneornil   (L ,4) ? luaL_checkinteger (L ,4) :-1;
	int offset       = !lua_isnoneornil   (L ,5) ? luaL_checkinteger (L ,5) : 0;
	lua_pushboolean(L ,b->writeArray(name ,*a ,writeLen ,offset));
	return 1;
}

static int l_clearArray(lua_State *L) {
	PdBase *b = *(PdBase**)luaL_checkudata(L ,1 ,LUA_PDBASE);
	const char *name = luaL_checkstring   (L ,2);
	int value        = !lua_isnoneornil   (L ,3) ? luaL_checkinteger (L ,3) : 0;
	b->clearArray(name ,value);
	return 0;
}

static int pdbase_shl(lua_State *L) {
	// TODO
	return 0;
}

// -------------------------------------------------------------------------
// -------------------------------- PdPatch --------------------------------
// -------------------------------------------------------------------------
static int pdpatch_new(lua_State *L) {
	Patch p;
	if      (lua_isnoneornil     (L ,1))
		p = Patch();
	else if (lua_isuserdata      (L ,1))
		p = Patch(**(Patch**)luaL_checkudata  (L ,1 ,LUA_PDPATCH));
	else if (lua_islightuserdata (L ,1))
	{	void *handle      = lua_touserdata    (L ,1);
		int dollarZero    = luaL_checkinteger (L ,2);
		const char *patch = luaL_checkstring  (L ,3);
		const char *path  = !lua_isnoneornil  (L ,4) ? luaL_checkstring(L ,4) : ".";
		p = Patch(handle ,dollarZero ,patch ,path);   }
	else
	{	const char *patch = luaL_checkstring  (L ,1);
		const char *path  = !lua_isnoneornil  (L ,2) ? luaL_checkstring(L ,2) : ".";
		p = Patch(patch ,path);   }
	*(Patch**)lua_newuserdata(L ,sizeof(Patch*)) = new Patch(p);
	luaL_setmetatable(L ,LUA_PDPATCH);
	return 1;
}

static int pdpatch_del(lua_State *L) {
	delete *(Patch**)lua_touserdata(L ,1);
	return 0;
}

static int l_handle(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushlightuserdata(L ,p->handle());
	return 1;
}

static int l_dollarZero(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushinteger(L ,p->dollarZero());
	return 1;
}

static int l_filename(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->filename().c_str());
	return 1;
}

static int l_path(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->path().c_str());
	return 1;
}

static int l_dollarZeroStr(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushstring(L ,p->dollarZeroStr().c_str());
	return 1;
}

static int l_isValid(lua_State *L) {
	Patch *p = *(Patch**)luaL_checkudata(L ,1 ,LUA_PDPATCH);
	lua_pushboolean(L ,p->isValid());
	return 1;
}

// --------------------------------------------------------------------------
// -------------------------------- PdObject --------------------------------
// --------------------------------------------------------------------------
static int pdobject_new(lua_State *L) {
	lua_settop(L ,1);
	bool set = (lua_type(L ,1) == LUA_TTABLE);
	*(PdObject**)lua_newuserdata(L ,sizeof(PdObject*)) = new PdObject(set);
	luaL_setmetatable(L ,LUA_PDOBJECT);
	return 1;
}

static int pdobject_del(lua_State *L) {
	delete *(PdObject**)lua_touserdata(L ,1);
	return 0;
}

static int l_setFunc(lua_State *L) {
	PdObject *o = *(PdObject**)luaL_checkudata(L ,1 ,LUA_PDOBJECT);
	const char *name = luaL_checkstring       (L ,2);
	luaL_checktype                            (L ,3 ,LUA_TFUNCTION);
	o->setFunc(name);
	return 0;
}

// -----------------------------------------------------------------------
// -------------------------------- Array --------------------------------
// -----------------------------------------------------------------------
static int pdarray_new(lua_State *L) {
	int n  = !lua_isnoneornil(L ,1) ? luaL_checkinteger (L ,1) :0;
	*(vector<float>**)lua_newuserdata(L ,sizeof(vector<float>*)) = new vector<float>(n);
	luaL_setmetatable(L ,LUA_PDARRAY);
	return 1;
}

static int pdarray_del(lua_State *L) {
	delete *(vector<float>**)lua_touserdata(L ,1);
	return 0;
}

static int l_len(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	lua_pushinteger(L ,a->size());
	return 1;
}

static int l_ptr(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i    = !lua_isnoneornil(L ,2) ? lua_tointeger(L ,2) : 0;
	lua_pushlightuserdata(L ,&(*a)[i]);
	return 1;
}

static int l_set(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i    = !lua_isnoneornil         (L ,2) ? lua_tointeger(L ,2) : 0;
	float f  = luaL_checknumber         (L ,3);
	if (i < 1)
		return luaL_error(L ,"Array: index cannot be less than zero");
	if (a->size() < i)
		a->resize(i ,0);
	(*a)[i-1] = f;
	return 0;
}

static int l_at(lua_State *L) {
	vector<float> *a = *(vector<float>**)luaL_checkudata(L ,1 ,LUA_PDARRAY);
	int i = luaL_checkinteger(L ,2);
	if (a->size() < i)
		return luaL_error(L ,"Array: index out of bounds");
	lua_pushnumber(L ,(*a)[i-1]);
	return 1;
}

// ---------------------------------------------------------------------------
// -------------------------------- registers --------------------------------
// ---------------------------------------------------------------------------
static void pdbase_reg(lua_State *L) {
	lua_newtable     (L);
	lua_pushcfunction(L,l_blockSize           );lua_setfield(L,-2,"blockSize"           );
	lua_newtable     (L);
	lua_pushcfunction(L,pdbase_new            );lua_setfield(L,-2,"__call"              );
	lua_setmetatable (L,-2);
	lua_setglobal    (L,LUA_PDBASE);

	luaL_newmetatable(L,LUA_PDBASE);
	lua_pushvalue    (L,-1                    );lua_setfield(L,-2,"__index"             );
	lua_pushcfunction(L,pdbase_del            );lua_setfield(L,-2,"__gc"                );
	lua_pushcfunction(L,pdbase_shl            );lua_setfield(L,-2,"__shl"               );
	lua_pushcfunction(L,l_init                );lua_setfield(L,-2,"init"                );
	lua_pushcfunction(L,l_addToSearchPath     );lua_setfield(L,-2,"addToSearchPath"     );
	lua_pushcfunction(L,l_clearSearchPath     );lua_setfield(L,-2,"clearSearchPath"     );
	lua_pushcfunction(L,l_openPatch           );lua_setfield(L,-2,"openPatch"           );
	lua_pushcfunction(L,l_closePatch          );lua_setfield(L,-2,"closePatch"          );
	lua_pushcfunction(L,l_subscribe           );lua_setfield(L,-2,"subscribe"           );
	lua_pushcfunction(L,l_unsubscribe         );lua_setfield(L,-2,"unsubscribe"         );
	lua_pushcfunction(L,l_exists              );lua_setfield(L,-2,"exists"              );
	lua_pushcfunction(L,l_unsubscribeAll      );lua_setfield(L,-2,"unsubscribeAll"      );
	lua_pushcfunction(L,l_receiveMessages     );lua_setfield(L,-2,"receiveMessages"     );
	lua_pushcfunction(L,l_receiveMidi         );lua_setfield(L,-2,"receiveMidi"         );
	lua_pushcfunction(L,l_setReceiver         );lua_setfield(L,-2,"setReceiver"         );
	lua_pushcfunction(L,l_setMidiReceiver     );lua_setfield(L,-2,"setMidiReceiver"     );
	lua_pushcfunction(L,l_isMessageInProgress );lua_setfield(L,-2,"isMessageInProgress" );
	lua_pushcfunction(L,l_isInited            );lua_setfield(L,-2,"isInited"            );
	lua_pushcfunction(L,l_isQueued            );lua_setfield(L,-2,"isQueued"            );
	lua_pushcfunction(L,l_setMaxMessageLen    );lua_setfield(L,-2,"setMaxMessageLen"    );
	lua_pushcfunction(L,l_maxMessageLen       );lua_setfield(L,-2,"maxMessageLen"       );

	// message sending
	lua_pushcfunction(L,l_sendBang            );lua_setfield(L,-2,"sendBang"            );
	lua_pushcfunction(L,l_sendFloat           );lua_setfield(L,-2,"sendFloat"           );
	lua_pushcfunction(L,l_sendSymbol          );lua_setfield(L,-2,"sendSymbol"          );
	lua_pushcfunction(L,l_startMessage        );lua_setfield(L,-2,"startMessage"        );
	lua_pushcfunction(L,l_addFloat            );lua_setfield(L,-2,"addFloat"            );
	lua_pushcfunction(L,l_addSymbol           );lua_setfield(L,-2,"addSymbol"           );
	lua_pushcfunction(L,l_addAtom             );lua_setfield(L,-2,"addAtom"             );
	lua_pushcfunction(L,l_finishList          );lua_setfield(L,-2,"finishList"          );
	lua_pushcfunction(L,l_finishMessage       );lua_setfield(L,-2,"finishMessage"       );
	lua_pushcfunction(L,l_sendList            );lua_setfield(L,-2,"sendList"            );
	lua_pushcfunction(L,l_sendMessage         );lua_setfield(L,-2,"sendMessage"         );

	// midi sending
	lua_pushcfunction(L,l_sendNoteOn          );lua_setfield(L,-2,"sendNoteOn"          );
	lua_pushcfunction(L,l_sendControlChange   );lua_setfield(L,-2,"sendControlChange"   );
	lua_pushcfunction(L,l_sendProgramChange   );lua_setfield(L,-2,"sendProgramChange"   );
	lua_pushcfunction(L,l_sendPitchBend       );lua_setfield(L,-2,"sendPitchBend"       );
	lua_pushcfunction(L,l_sendAftertouch      );lua_setfield(L,-2,"sendAftertouch"      );
	lua_pushcfunction(L,l_sendPolyAftertouch  );lua_setfield(L,-2,"sendPolyAftertouch"  );
	lua_pushcfunction(L,l_sendMidiByte        );lua_setfield(L,-2,"sendMidiByte"        );
	lua_pushcfunction(L,l_sendSysex           );lua_setfield(L,-2,"sendSysex"           );
	lua_pushcfunction(L,l_sendSysRealTime     );lua_setfield(L,-2,"sendSysRealTime"     );

	// audio processing
	lua_pushcfunction(L,l_processRaw          );lua_setfield(L,-2,"processRaw"          );
	lua_pushcfunction(L,l_processShort        );lua_setfield(L,-2,"processShort"        );
	lua_pushcfunction(L,l_processFloat        );lua_setfield(L,-2,"processFloat"        );
	lua_pushcfunction(L,l_processDouble       );lua_setfield(L,-2,"processDouble"       );
	lua_pushcfunction(L,l_computeAudio        );lua_setfield(L,-2,"computeAudio"        );
	lua_pushcfunction(L,l_blockSize           );lua_setfield(L,-2,"blockSize"           );

	// arrays
	lua_pushcfunction(L,l_arraySize           );lua_setfield(L,-2,"arraySize"           );
	lua_pushcfunction(L,l_readArray           );lua_setfield(L,-2,"readArray"           );
	lua_pushcfunction(L,l_writeArray          );lua_setfield(L,-2,"writeArray"          );
	lua_pushcfunction(L,l_clearArray          );lua_setfield(L,-2,"clearArray"          );

	lua_pop          (L,1);
}

static void pdpatch_reg(lua_State *L) {
	lua_register     (L,LUA_PDPATCH,pdpatch_new);
	luaL_newmetatable(L,LUA_PDPATCH);
	lua_pushvalue    (L,-1                    );lua_setfield(L,-2,"__index"             );
	lua_pushcfunction(L,pdpatch_del           );lua_setfield(L,-2,"__gc"                );
	lua_pushcfunction(L,l_handle              );lua_setfield(L,-2,"handle"              );
	lua_pushcfunction(L,l_dollarZero          );lua_setfield(L,-2,"dollarZero"          );
	lua_pushcfunction(L,l_filename            );lua_setfield(L,-2,"filename"            );
	lua_pushcfunction(L,l_path                );lua_setfield(L,-2,"path"                );
	lua_pushcfunction(L,l_dollarZeroStr       );lua_setfield(L,-2,"dollarZeroStr"       );
	lua_pushcfunction(L,l_isValid             );lua_setfield(L,-2,"isValid"             );

	lua_pop          (L,1);
}

static void pdobject_reg(lua_State *L) {
	PdObject::L = L;
	lua_register     (L,LUA_PDOBJECT,pdobject_new);
	luaL_newmetatable(L,LUA_PDOBJECT);
	lua_pushvalue    (L,-1                    );lua_setfield(L,-2,"__index"             );
	lua_pushcfunction(L,pdobject_del          );lua_setfield(L,-2,"__gc"                );
	lua_pushcfunction(L,l_setFunc             );lua_setfield(L,-2,"__newindex"          );
	lua_pushcfunction(L,l_setFunc             );lua_setfield(L,-2,"setFunc"             );

	lua_pop          (L,1);
}

static void pdarray_reg(lua_State *L) {
	lua_register     (L,LUA_PDARRAY,pdarray_new);
	luaL_newmetatable(L,LUA_PDARRAY);
	lua_pushcfunction(L,pdarray_del           );lua_setfield(L,-2,"__gc"                );
	lua_pushcfunction(L,l_len                 );lua_setfield(L,-2,"__len"               );
	lua_pushcfunction(L,l_at                  );lua_setfield(L,-2,"__index"             );
	lua_pushcfunction(L,l_set                 );lua_setfield(L,-2,"__newindex"          );
	lua_pushcfunction(L,l_ptr                 );lua_setfield(L,-2,"__call"              );

	lua_pop          (L,1);
}

int LUA_API luaopen_luapd(lua_State *L) {
	pdbase_reg   (L);
	pdpatch_reg  (L);
	pdobject_reg (L);
	pdarray_reg  (L);
	return 0;
}
