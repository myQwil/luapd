
LIBPD_DIR ?= ../libpd

# detect platform
UNAME = $(shell uname)
ifeq ($(UNAME), Darwin) # Mac
  SUFFIX   = dylib
  LDFLAGS  = -stdlib=libc++
  CXXFLAGS = -stdlib=libc++
else
  LDFLAGS = -shared
  ifeq ($(OS), Windows_NT) # Windows, use Mingw
    PREFIX   =
    SUFFIX   = dll
    LIBLUA   = -lluajit-5.1
    LDLIBS  := -lws2_32 -lkernel32 $(LIBLUA)
    LDFLAGS += -Wl,--export-all-symbols -static-libgcc
  else # assume Linux
    SUFFIX = so
  endif
endif

SRC       = src/PdObject.cpp src/main.cpp
LIBPD     = $(LIBPD_DIR)/libs/$(PREFIX)pd
TARGET   := luapd.$(SUFFIX)
LDLIBS   += -lm -lpthread
PREFIX   ?= lib
CXXFLAGS += \
-I$(LIBPD_DIR)/pure-data/src -I$(LIBPD_DIR)/libpd_wrapper \
-I$(LIBPD_DIR)/libpd_wrapper/util -I$(LIBPD_DIR)/cpp -I./src -fPIC -O3

.PHONY: dynamic clean

$(TARGET): PREFIX   := lib
$(TARGET): CXXFLAGS += -DBUILD_STATIC
$(TARGET): ${SRC:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ $(LIBPD).a $(LDLIBS)

dynamic: ${SRC:.cpp=.o}
	g++ $(LDFLAGS) -o $(TARGET) $^ $(LIBPD).$(SUFFIX) $(LIBLUA)

clean:
	rm -f src/*.o
