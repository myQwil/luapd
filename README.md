# LuaPd
libpd bindings for lua and love2d

## Building Luapd

### Clone libpd and its submodules:

    git clone --recurse-submodules https://github.com/libpd/libpd.git

### Build libpd:

    cd libpd
    make STATIC=true

### Install LuaJIT

On Debian/Ubuntu:

    apt install luajit libluajit-5.1-dev

On Windows with MSYS2:

    pacman -S mingw-w64-i686-luajit mingw-w64-x86_64-luajit

On MacOS with Brew:

    brew install luajit

### Build luapd:

Luapd's Makefile assumes that the libpd folder is adjacent to the luapd folder.

    cd luapd
    make

By default, `make` will try to link statically with libpd. You can also link dynamically with:

    make dynamic

You can test luapd with:

    luajit test.lua

## Running LÖVE Examples

### Clone a fork of libpd
    git clone --recurse-submodules https://github.com/myQwil/libpd.git

### Clone the Quilt and Cyclone libraries adjacent to libpd:

    git clone --recurse-submodules https://github.com/myQwil/pd-quilt.git
    git clone https://github.com/porres/pd-cyclone.git

Then build libpd and luapd.

### For Windows users

There are 3 additional .dll files that need to be placed adjacent to the main lua file:

- libgcc_s_seh-1.dll
- libstdc++-6.dll
- libwinpthread-1.dll

These files are included in the release builds for Windows. They can also be downloaded separately here: <https://github.com/myQwil/luapd/releases/download/v0.3.1/luapd-dependencies.Windows-amd64-32.zip>
