# LuaPd
libpd bindings for lua and love2d

## Getting Started

Download libpd & checkout the pure-data submodule with git:

    git clone --recurse-submodules https://github.com/libpd/libpd.git

Apply luapd's git patches to libpd and pure-data:

    cd <libpd>
    git apply <luapd>/diff/libpd.diff
    cd <libpd>/pure-data
    git apply <luapd>/diff/pure-data.diff

A quick overview of what these patches do:

- libpd.diff - During the installation process, a folder called 'util' will be made specifically for util headers. With the patch, they are instead placed in the same folder as all the other libpd headers.

- pure-data.diff - Lua and Pd both have a function called `error`, which can confuse lua and cause crashes. We can prevent this from happening with a little bit of preprocessor trickery in m_pd.h.

Once the patches have been applied, install libpd:

    cd <libpd>
    make STATIC=true
    make install

Since luapd is meant to be compatible with love2d, it's recommended to install luajit and development headers. On Debian/Ubuntu, these can be installed with:

    apt install luajit libluajit-5.1-dev

With the necessary headers and libraries installed, we can now build luapd:

    cd <luapd>
    make

By default, `make` will try to link statically with libpd. You can also link dynamically with:

    make dynamic

You can test luapd with:

    luajit test.lua
