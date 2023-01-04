
LIBPD_DIR ?= $(shell pwd)/../libpd

# detect platform
UNAME   = $(shell uname)
LDFLAGS = -lstdc++
ifeq ($(UNAME), Darwin) # Mac
  EXT      = dylib
  LDFLAGS += -std=c++11 -arch x86_64 -dynamiclib
  CXXFLAGS = -std=c++11 -arch x86_64
  LUA_DIR  = /usr/local/include/luajit-2.1
else
  LDFLAGS += -shared
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    EXT      = dll
    LDLIBS   = -Wl,--export-all-symbols -static-libgcc -lws2_32 -lkernel32
    LUA_DIR  = /mingw64/include/luajit-2.1
  else # assume Linux
    EXT      = so
    LUA_DIR  = /usr/include/luajit-2.1
  endif
endif
# LUA_DIR = ../lua

SRC       = $(wildcard $(shell pwd)/src/*.cpp)
LIBPD     = $(LIBPD_DIR)/libs/libpd
TARGET    = luapd.$(EXT)
LIBLUA    = -lluajit-5.1
# LIBLUA    = $(LUA_DIR)/liblua.a
LDLIBS   += -lm -lpthread $(LIBLUA)
CXXFLAGS += -I$(LUA_DIR) \
            -I$(LIBPD_DIR)/libpd_wrapper -I$(LIBPD_DIR)/libpd_wrapper/util \
            -I$(LIBPD_DIR)/pure-data/src -I$(LIBPD_DIR)/cpp -I./src -O3 -fPIC \
            -Wall -Wextra -Wshadow -Wstrict-aliasing

ifeq ($(DEBUG), true)
  CXXFLAGS += -g -O0
endif

.PHONY: dynamic clean

all: CXXFLAGS += -DEXTERN=extern
all: $(SRC:.cpp=.o) $(LIBPD).a
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $(TARGET)

$(LIBPD).a:
	cd $(LIBPD_DIR) && make STATIC=true

dynamic: $(SRC:.cpp=.o) $(LIBPD).$(EXT)
	$(CXX) $(LDFLAGS) $^ $(LIBLUA) -o $(TARGET)

$(LIBPD).$(EXT):
	cd $(LIBPD_DIR) && make

clean:
	rm -f $(shell pwd)/src/*.o
