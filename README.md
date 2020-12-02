# LuaPd
libpd bindings for lua and love2d

## Getting Started

### Download libpd & checkout the submodules with git:

    git clone --recurse-submodules https://github.com/libpd/libpd.git

Luapd's Makefile assumes that the libpd folder is adjacent to the luapd folder. This section will work under that assumption.

### Apply luapd's git patches to libpd and pure-data:

    cd libpd
    git apply ../luapd/diff/libpd.diff
    cd pure-data
    git apply ../../luapd/diff/pure-data.diff
    cd ..

A quick overview of what these patches do:

- libpd.diff - Changes the declarations in the libpd_wrapper z headers from EXTERN to EXPORT, which will be left undefined for static builds. This makes it easier to link with libpd in MSYS2/MinGW.

- pure-data.diff - Lua and Pd both have a function called `error`, which can confuse lua and cause crashes. We can prevent this with a little bit of preprocessor trickery in m_pd.h.

### Build libpd:

    make STATIC=true

### Install LuaJIT

On Debian/Ubuntu:

    apt install luajit libluajit-5.1-dev

On Windows with MSYS2:

    pacman -S mingw-w64-i686-luajit mingw-w64-x86_64-luajit

On MacOS with Brew:

    brew install luajit

### Build luapd:

    cd luapd
    make

By default, `make` will try to link statically with libpd. You can also link dynamically with:

    make dynamic

You can test luapd with:

    luajit test.lua
