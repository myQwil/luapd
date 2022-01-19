#include "PdObject.hpp"
#include <iostream>
#include <string.h>

using namespace std;
using namespace pd;

#define NMSG  13

static const char* const msgname[]  =
{	 "print" ,"bang" ,"float" ,"symbol" ,"list" ,"message"
	,"noteOn"     ,"controlChange"  ,"programChange" ,"pitchBend"
	,"aftertouch" ,"polyAftertouch" ,"midiByte"  };

PdObject::PdObject(lua_State *l ,bool has_table) {
	L = l;
	for (int i=0; i<NMSG;  i++)
		*msgs[i] = LUA_REFNIL;
	if (has_table) setFuncs(1);
}

void PdObject::setFuncs(int idx) {
	int ref;
	for (int i=0; i<NMSG; i++)
	{	lua_getfield(L ,idx ,msgname[i]);
		if ((ref = luaL_ref(L ,LUA_REGISTRYINDEX)) != LUA_REFNIL)
			*msgs[i] = ref;  }
}

void PdObject::setFunc(const char *name) {
	for (int i=0; i<NMSG; i++)
	{	if (!strcmp(msgname[i] ,name))
		{	*msgs[i] = luaL_ref(L ,LUA_REGISTRYINDEX);
			return;  }  }
}

//--------------------------------------------------------------
void PdObject::print(const string &message) {
	if (fnprint == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnprint);
	lua_pushstring (L ,message.c_str());
	lua_call       (L ,1 ,0);
}

//--------------------------------------------------------------
void PdObject::receiveBang(const string &dest) {
	if (fnbang == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnbang);
	lua_pushstring (L ,dest.c_str());
	lua_call       (L ,1 ,0);
}

void PdObject::receiveFloat(const string &dest ,float num) {
	if (fnfloat == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnfloat);
	lua_pushstring (L ,dest.c_str());
	lua_pushnumber (L ,num);
	lua_call       (L ,2 ,0);
}

void PdObject::receiveSymbol(const string &dest ,const string &symbol) {
	if (fnsymbol == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnsymbol);
	lua_pushstring (L ,dest.c_str());
	lua_pushstring (L ,symbol.c_str());
	lua_call       (L ,2 ,0);
}

static void listToTable(lua_State *L ,const List &list) {
	lua_createtable(L ,list.len() ,0);
	for(int i=0; i<list.len(); i++)
	{	if      (list.isFloat(i))
			lua_pushnumber(L ,list.getFloat(i));
		else if (list.isSymbol(i))
			lua_pushstring(L ,list.getSymbol(i).c_str());
		lua_rawseti(L ,-2 ,i+1);  }
}

void PdObject::receiveList(const string &dest ,const List &list) {
	if (fnlist == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnlist);
	lua_pushstring (L ,dest.c_str());
	listToTable    (L ,list);
	lua_call       (L ,2 ,0);
}

void PdObject::receiveMessage(const string &dest ,const string &msg ,const List &list) {
	if (fnmessage == LUA_REFNIL) return;
	lua_rawgeti    (L ,LUA_REGISTRYINDEX ,fnmessage);
	lua_pushstring (L ,dest.c_str());
	lua_pushstring (L ,msg.c_str());
	listToTable    (L ,list);
	lua_call       (L ,3 ,0);
}

//--------------------------------------------------------------
void PdObject::receiveNoteOn(const int channel ,const int pitch ,const int velocity) {
	if (fnnote == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnnote);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,pitch);
	lua_pushinteger (L ,velocity);
	lua_call        (L ,3 ,0);
}

void PdObject::receiveControlChange
(const int channel ,const int controller ,const int value) {
	if (fnctrl == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnctrl);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,controller);
	lua_pushinteger (L ,value);
	lua_call        (L ,3 ,0);
}

void PdObject::receiveProgramChange(const int channel ,const int value) {
	if (fnprog == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnprog);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,value);
	lua_call        (L ,2 ,0);
}

void PdObject::receivePitchBend(const int channel ,const int value) {
	if (fnpitch == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnpitch);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,value);
	lua_call        (L ,2 ,0);
}

void PdObject::receiveAftertouch(const int channel ,const int value) {
	if (fnafter == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnafter);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,value);
	lua_call        (L ,2 ,0);
}

void PdObject::receivePolyAftertouch
(const int channel ,const int pitch ,const int value) {
	if (fnpoly == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnpoly);
	lua_pushinteger (L ,channel);
	lua_pushinteger (L ,pitch);
	lua_pushinteger (L ,value);
	lua_call        (L ,3 ,0);
}

void PdObject::receiveMidiByte(const int port ,const int byte) {
	if (fnbyte == LUA_REFNIL) return;
	lua_rawgeti     (L ,LUA_REGISTRYINDEX ,fnbyte);
	lua_pushinteger (L ,port);
	lua_pushinteger (L ,byte);
	lua_call        (L ,2 ,0);
}
