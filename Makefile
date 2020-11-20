# detect platform, move libpd dylib to local folder on mac
UNAME = $(shell uname)

ifeq ($(UNAME), Darwin) # Mac
  SOLIB_EXT = dylib
  PLATFORM = mac
  LDFLAGS = -stdlib=libc++
  CXXFLAGS = -stdlib=libc++
else
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    SOLIB_EXT = dll
    PLATFORM = windows
  else # assume Linux
    SOLIB_EXT = so
    PLATFORM = linux
  endif
endif

TARGET = luapd.$(SOLIB_EXT)
LIBPD = ./libpd.$(SOLIB_EXT)
SRC_FILES = src/PdObject.cpp src/main.cpp

CXXFLAGS += -I/usr/include/luajit-2.1 -I./src -fPIC -O3
LDFLAGS = -shared

.PHONY: clean

$(TARGET): ${SRC_FILES:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ $(LIBPD)
ifeq ($(PLATFORM), mac)
	mkdir -p ./libs && cp $(LIBPD) ./libs
endif

clean:
	rm -f src/*.o
