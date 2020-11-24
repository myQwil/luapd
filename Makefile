# detect platform, move libpd dylib to local folder on mac
UNAME = $(shell uname)

ifeq ($(UNAME), Darwin) # Mac
  SOLIB_EXT = dylib
  LDFLAGS   = -stdlib=libc++
  CXXFLAGS  = -stdlib=libc++
else
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    SOLIB_EXT = dll
  else # assume Linux
    SOLIB_EXT = so
  endif
endif

SRC    := src/PdObject.cpp src/main.cpp
TARGET := luapd.$(SOLIB_EXT)

# using luajit for love2d compatibility
CXXFLAGS += -I/usr/include/luajit-2.1 -I./src -fPIC -O3
LDFLAGS  += -shared


.PHONY: dynamic clean

$(TARGET): ${SRC:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ -Wl,-Bstatic -lpd -Wl,-Bdynamic -lpthread

dynamic: ${SRC:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ -lpd

clean:
	rm -f src/*.o
