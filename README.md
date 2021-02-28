# vweb-example

  [![Docker Pulls](https://img.shields.io/docker/pulls/smartiniatdocker09/vweb-example.svg)](https://hub.docker.com/r/smartiniatdocker09/vweb-example/)
  [![Apache 2.0 License](https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat)](./LICENSE)

Example webapp with vweb (V integrated web framework).


## Setup and run

Ensure V is updated (maybe force an update with `v up`) and in PATH.

A make file (cmake) has been added to simplify shell commands execution and related dependencies, 
just for convenience; to run it with a default (informative only) task, do:
```
make
```
all commands inside are for the Bash shell (so for Linux and similar systems).

Note that required resources are bundled inside the executable, 
or will be copied (by additional shell commands in build phase) in the same folder of the executable, 
to ensure to have all consistent there.

Inside this project there are other (utility) sources, moved in its own folder:
- './healthcheck/' contains a command-line utility that calls the given HTTP endpoint 
  to check its health status, useful for example when main server application is running in a container
- './minimal/' contains a (very) minimal web application that only exposes 
  a fixed message on its root route
- others later ...

Note that there are many Dockerfiles (and related make tasks), to use different base images; 
see details in the 'Makefile'. To build sources in containers, it's recommended to use 
official vlang Docker images, otherwise dependencies must be added manually.
When executables are built with static dependencies (all inside it), it's even possible 
to run them in a special Docker image ('scratch') empty, so really minimal and safer 
(no shell inside and nothing other than my executables and related resources).

In the [docs](./docs/) folder there is other documentation.


## Requirements

Latest V (vlang) stable, or built from latest sources.

To run the application in a container, an updated version of Docker is needed.


## Note

Current setup (and related commands) are for a Linux system, 
but can be updated for other platforms (Mac, Windows, etc).

Executable files generated from V code are very small, 
and by default all published web resources are bundled inside executables 
to simplify deploy.

Just to have an idea, the minimal web server script ('server-minimal.v' -> 'vweb-minimal') 
when built on a modern Linux distribution (like Ubuntu 20.04 LTS at 64 bit) is:
- normal build: from 140 KB to 240 KB
- normal build optimized (for production and compressed): from 70 KB to 100 KB
- static build (no external libraries): approx. 4.5 MB
- static build optimized (no external libraries): approx. 1.8 MB

all this is impressive.

When building the same sources in Windows, executables are bigger 
(double than Linux, approx.), but anyway very small.


## License

Licensed under [Apache-2.0](./LICENSE).

----
