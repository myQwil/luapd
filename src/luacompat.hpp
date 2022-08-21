#include "lua.hpp"

// -------------- Compatibility for different lua versions ---------------------

#if LUA_VERSION_NUM == 501

#define lua_rawlen(L,i) lua_objlen(L,(i))

#if LUAJIT_VERSION_NUM < 20100 || defined(_WIN32)

#define luaL_setmetatable(L,n) (luaL_getmetatable(L,(n)) ,lua_setmetatable(L,-2))
LUALIB_API void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
  luaL_checkstack(L, nup, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    if (l->func == NULL)  /* place holder? */
      lua_pushboolean(L, 0);
    else {
      int i;
      for (i = 0; i < nup; i++)  /* copy upvalues to the top */
        lua_pushvalue(L, -nup);
      lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    }
    lua_setfield(L, -(nup + 2), l->name);
  }
  lua_pop(L, nup);  /* remove upvalues */
}

#endif // _WIN32

#if LUAJIT_VERSION_NUM < 20100

#define LUAL_NUMSIZES	(sizeof(lua_Integer)*16 + sizeof(lua_Number))
#define UNUSED(x)	((void)(x))
LUA_API lua_Number lua_version (lua_State *L) {
  UNUSED(L);
  return LUA_VERSION_NUM;
}

LUALIB_API void luaL_checkversion_ (lua_State *L, lua_Number ver, size_t sz) {
  lua_Number v = lua_version(L);
  if (sz != LUAL_NUMSIZES)  /* check numeric types */
    luaL_error(L, "core and library have incompatible numeric types");
  else if (v != ver)
    luaL_error(L, "version mismatch: app. needs %f, Lua core provides %f",
                  (LUAI_UACNUMBER)ver, (LUAI_UACNUMBER)v);
}

#define luaL_checkversion(L)  \
	  luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES)

#define luaL_newlibtable(L,l)	\
  lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)

#define luaL_newlib(L,l)  \
  (luaL_checkversion(L), luaL_newlibtable(L,l), luaL_setfuncs(L,l,0))

#endif // LUAJIT_VERSION_NUM
#endif // LUA_VERSION_NUM
