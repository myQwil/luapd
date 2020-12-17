# LuaPd
libpd bindings for lua and love2d

## Building Luapd

### Download libpd & checkout the submodules with git:

    git clone --recurse-submodules https://github.com/libpd/libpd.git

Luapd's Makefile assumes that the libpd folder is adjacent to the luapd folder. This section will work under that assumption.

### Apply luapd's git patch to libpd's pure-data folder:

    cd libpd/pure-data
    git apply ../../luapd/diff/pure-data.diff

**pure-data.diff** changes the name of a function called `error` because Lua also has a function with the same name, which can confuse Lua and cause crashes.

There is also a diff patch called **libpd-extra.diff** but it only needs to be applied if you plan on building libpd with additional libraries that some of the LÖVE examples use.

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
