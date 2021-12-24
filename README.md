# LuaPd
libpd bindings for lua and love2d

## Building Luapd

### Download libpd & checkout the submodules with git:

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

### Clone the PdXtra and Cyclone libraries adjacent to libpd:

    git clone https://github.com/myQwil/pdxtra.git
    git clone https://github.com/porres/pd-cyclone.git

### Apply luapd's git patches to their respective folders:

    cd libpd
    git apply ../luapd/diff/libpd.diff
    cd ../pd-cyclone
    git apply ../luapd/diff/pd-cyclone.diff

Then re-build libpd and luapd.

For Linux and Mac users, the examples should run normally without any necessary changes.
For Windows users, the 3 lib\*.dll files in the main folder need to be copied into an example folder before they can be detected by luapd.dll.
