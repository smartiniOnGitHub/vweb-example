# Tests of static builds (with MUSL libraries) on Ubuntu 20.04 LTS #

This document describes the initial setup for the creation of static executables for aplication binaries, 
but in a normal vm running Ubuntu Linux, and not inside a Docker container (for another document).


## Setup

First we need to install some libraries:
```bash
sudo apt-get install libssl-dev
sudo apt-get install musl-tools gcc-multilib
# sudo apt-get --reinstall install libc6 libc6-dev
# sudo apt-get install --reinstall musl-dev libc6-dev
sudo apt-get install --reinstall musl-dev # reinstall if no musl header found
```

Then we need to locate folders for header files, for example mine are under '/usr/include/'.
Optional (but useful), under /usr/local/include/ I added the following symbolic links:
```bash
sudo ln -s /usr/lib/x86_64-linux-musl /usr/local/include/musl
sudo ln -s /usr/include/openssl /usr/local/include/openssl
```
to solve a compile error I had to create another symbolic link:
```bash
sudo ln -s /usr/include/x86_64-linux-gnu/openssl/opensslconf.h /usr/local/include/openssl/opensslconf.h
```
Then locate even libraries to link, like ssl (libssl*.so*) etc, for example mine are in subfolders of '/usr/lib'.
Get some libraries info with:
```bash
# ldconfig -p|grep crypto
ldconfig -p|grep ssl
```

So now I have:
- libc: headers in /usr/lib/x86_64-linux-gnu/ , with libraries in /usr/lib/x86_64-linux-gnu/
- musl: headers in /usr/lib/x86_64-linux-musl/ , with libraries in /usr/lib/x86_64-linux-musl/
- openssl: headers in /usr/include/openssl and in /usr/local/include/openssl (symlink) , 
  with libraries in /usr/lib/x86_64-linux-gnu/

After all these changes, code seems to compile now, but (important) 
musl libraries must have precedence over all others.

But I have some linker flags still to fix ... wip
But they seems related to not having openssl built as a static library, see 
[here](https://github.com/openssl/openssl/issues/7207) for some info, but note that 
self compiling OpenSSL is not so simple (and it has many dependencies for its build system), 
and I need to build with musl here, see 
[here](https://github.com/openssl/openssl/blob/master/INSTALL.md#quick-installation-guide), 
[here](https://github.com/openssl/openssl/issues/7207), 
[here](https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux/), etc ... 
so probably it's simpler (at least for now) to try all this stuff in Alpine Linux 
(maybe in a Docker container).


## Build OpenSSL (with MUSL libraries)

Just for test, tried to build OpenSSL with musl, to be able to use as dependency in my builds here.

Get sources, unzip and fix permissions:
```bash
cd /usr/local/src/
wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1g.tar.gz
sudo chown $USER:$USER .
tar -xf OpenSSL_1_1_1g.tar.gz
sudo chown $USER:$USER -R .
sudo mkdir /usr/local/ssl
sudo chown $USER:$USER -R /usr/local/ssl/*
```
go into the folder and configure with
```bash
export CC=musl-gcc # set musl-gcc, important here
./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl no-shared no-async no-engine  --release -DOPENSSL_NO_SECURE_MEMORY
```
(added the flag '-DOPENSSL_NO_SECURE_MEMORY' to avoid a compilation error, as seen in related bug; 
of course for a real production usage a workaround like that is not acceptable and a better solution must be used).
Then `make clean` and `make` and (optional) `make test` and then install in the given (secondary) folder 
with `make install` and finally `ll /usr/local/ssl/lib/`.

Note that crypto is linked statically in ssl here, so library consumers doesn't need to refer to it.


## Build

With all setup done in the machine (and OpenSSL built with musl), 
now when running buils static from my Makefile (see related tasks) all is built; 
of course executable/s is/are bigger but no more dependencies are needed.
This is even a great use case for running applications inside near-empty containers (like Docker 'scratch' 
base image), for very minimal applications, so the phrase "from microservices to nanoservices" apply here.

Remember to give priority to references to musl and static libraries built with it
(list them first in compiler options).

Just to have some numbers, current version of main executable for this application 
(no dependencies other than vweb, so openssl), statically linked with musl is 
approx. 3.8 MB for the normal build, and 1.2 MB for the optimized build, which is amazing.


## Note

A simpler approach would be to build all inside a Docker container that run Alpine Linux; 
I'll do it and write in another document all steps; anyway see official Docker images from V guys:
- 'thevlang/vlang:latest' (based on debian buster, same of the 'buster' tag here)
- 'thevlang/vlang:alpine'
- 'thevlang/vlang:alpine-dev'
- 'thevlang/vlang:ubuntu'
- etc

Used the '-compress' build flag (in both tasks to generate dynamic and static executable), 
to further optimize generated executable/s, 
but it requires the [UPX](https://upx.github.io/) compressor utility (so it must be installed, 
from usual Linux distribution repositories, or pre-built binaries from UPX sources site).
Not sure if executable/s compressed works in the 'scratch' image, but need to try.

Note that running that executable all is good, and compiling with the flag '-cg' enables the 'debug' symbol 
(so all code wrapped by `$if debug` like debug output to console is enabled, both in my code and in V code).

To verify if a binary file is linked in a dynamic (default) or static way with the utility 'ldd', for example with `ldd <binary_file_name>`; to get other info on an executable file, use the utility 'file', for example with `file <binary_file_name>`, or even 'objdump'.


----
