# Building libcouchbase on Windows

NOTE:: we are currently not supporting 32bit Windows installations

1. Install [Python 2.7 x64](https://www.python.org/downloads/)
1. Install [cmake](https://cmake.org/download/)
1. Install [OpenSSL x64 Dev](https://slproweb.com/products/Win32OpenSSL.html)
1. Install [git](https://git-scm.com/downloads)
1. `git clone https://github.com/libuv/libuv.git`
1. Add libuv, openssl, cmake and python to Path ENV VAR
1. Install [Build Tools for Visual Studio 2017](https://www.visualstudio.com/downloads/)
   * Windows 10 SDK
   * Visual C++ tools for cmake
   * C++/CLI support
1. Build libuv (or use `gem install libuv` to automate)
   * `git clone https://chromium.googlesource.com/external/gyp build/gyp`
   * `vcbuild.bat vs2017 shared debug x64` -- libcouchbase looks for a debug build
   * `vcbuild.bat vs2017 shared release x64`
1. `git clone https://github.com/couchbase/libcouchbase.git`
   * `mkdir lcb-build`
   * `cd lcb-build`
   * `cmake -G "Visual Studio 15 Win64" ..\libcouchbase` (should include libuv + openssl)
   * `cmake --build .`

Seems to also support: https://github.com/google/snappy

* `mkdir snappybuild && cd snappybuild && cmake -G "Visual Studio 15 Win64" ..\snappy`
* I couldn't work out how to have libcouchbase include this in the build.

I also had to modify `plugin-libuv.c` before this would compile on Windows

* Installed the Visual Studio GUI using VS Installer
* `#include "libcouchbase\plugins\io\bsdio-inl.c"`
* The linker has some dependencies that need to be removed such as: `OPTIMIZED.lib` 

A pre-compiled version of libcouchbase.dll is shipped with the GEM
