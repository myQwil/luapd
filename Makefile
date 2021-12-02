
LIBPD_DIR ?= ../libpd

# detect platform
UNAME  = $(shell uname)
LIBLUA = -lluajit-5.1
ifeq ($(UNAME), Darwin) # Mac
  EXT      = dylib
  LDFLAGS  = -std=c++11 -arch x86_64 -dynamiclib
  CXXFLAGS = -std=c++11 -arch x86_64 -I/usr/local/include/luajit-2.0
else
  LDFLAGS  = -shared
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    EXT      = dll
    PREFIX   =
    LDLIBS   = -Wl,--export-all-symbols -static-libgcc -lws2_32 -lkernel32
    CXXFLAGS = -I/mingw64/include/luajit-2.1
  else # assume Linux
    EXT      = so
    CXXFLAGS = -I/usr/include/luajit-2.1
  endif
endif

SRC       = src/PdObject.cpp src/main.cpp
LIBPD     = $(LIBPD_DIR)/libs/$(PREFIX)pd
TARGET   := luapd.$(EXT)
LDLIBS   += -lm -lpthread $(LIBLUA)
PREFIX   ?= lib
CXXFLAGS += \
-I$(LIBPD_DIR)/pure-data/src -I$(LIBPD_DIR)/libpd_wrapper \
-I$(LIBPD_DIR)/libpd_wrapper/util -I$(LIBPD_DIR)/cpp -I./src -fPIC -g -O3

.PHONY: dynamic clean

$(TARGET): PREFIX    = lib
$(TARGET): CXXFLAGS += -DEXTERN=extern
$(TARGET): ${SRC:.cpp=.o} $(LIBPD).a
	g++ $(LDFLAGS) -o $(TARGET) $^ $(LDLIBS)

$(LIBPD).a:
	cd $(LIBPD_DIR) && make STATIC=true

dynamic: ${SRC:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ $(LIBPD).$(EXT) $(LIBLUA)

clean:
	rm -f src/*.o
