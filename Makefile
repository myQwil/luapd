
LIBPD_DIR ?= ../libpd

# detect platform
UNAME   = $(shell uname)
LDFLAGS = -lstdc++
ifeq ($(UNAME), Darwin) # Mac
  EXT      = dylib
  LDFLAGS += -std=c++11 -arch x86_64 -dynamiclib
  CXXFLAGS = -std=c++11 -arch x86_64 -I/usr/local/include/luajit-2.0
else
  LDFLAGS += -shared
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    EXT      = dll
    LDLIBS   = -Wl,--export-all-symbols -static-libgcc -lws2_32 -lkernel32
    CXXFLAGS = -I/mingw64/include/luajit-2.1
  else # assume Linux
    EXT      = so
    CXXFLAGS = -I/usr/include/luajit-2.1
  endif
endif

SRC       = src/PdObject.cpp src/main.cpp
LIBPD     = $(LIBPD_DIR)/libs/libpd
TARGET    = luapd.$(EXT)
LIBLUA    = -lluajit-5.1
LDLIBS   += -lm -lpthread $(LIBLUA)
CXXFLAGS += \
-I$(LIBPD_DIR)/pure-data/src -I$(LIBPD_DIR)/libpd_wrapper \
-I$(LIBPD_DIR)/libpd_wrapper/util -I$(LIBPD_DIR)/cpp -I./src -fPIC -O3

ifeq ($(DEBUG), true)
  CXXFLAGS += -g -O0
endif

.PHONY: dynamic clean

all: CXXFLAGS += -DEXTERN=extern
all: $(SRC:.cpp=.o) $(LIBPD).a
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $(TARGET)

$(LIBPD).a:
	cd $(LIBPD_DIR) && make STATIC=true

dynamic: ${SRC:.cpp=.o}
	$(CXX) $(LDFLAGS) $^ $(LIBPD).$(EXT) $(LIBLUA) -o $(TARGET)

clean:
	rm -f src/*.o
