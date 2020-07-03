# vweb-example

Example webapp with vweb (V integrated web framework).


## Setup and run

Ensure V is updated (maybe force an update with `v up`) and in PATH.

To build and run V sources, for example it's enough to do:
```
v run server.v
```
executable will be generated in current folder.
Otherwise, to generate normal executables in the 'build' folder do:
```
v -o build/server server.v
v -o build/server-minimal server-minimal.v
```
and to generate production (optimized) executables in the 'dist' folder do:
```
v -o dist/server -prod server.v
v -o dist/server-minimal -prod server-minimal.v
```
then go into desired folder, and run executable/s from there.

Note that required resources are bundled inside the executable, 
or will be copied (by additional shell commands in build phase) in the same folder of the executable, 
to ensure to have all consistent there.

A make file (cmake) has been added to simplify shell commands execution and related dependencies, 
just for convenience; to run it with a default (informative only) task, do:
```
make
```
note that all commands inside are for the Bash shell (so for Linux and similar systems).


## Requirements

Latest V (vlang) stable, or built from latest sources.


## Note

Current setup (and related commands) are for a Linux system, 
but can be updated for other platforms (Mac, Windows, etc).

Executable files generated from V code are very small, 
and by default all published web resources are bundled inside executables 
to simplify deploy.

Just to have an idea, the minimal web server script ('server-minimal.v') 
when built on a modern Linux distribution (like Ubuntu 20.04 LTS at 64 bit) is:
- normal build: ranging from 365 KB to 420 KB
- optimized build (for production): ranging from 53 KB to 120 KB
and this is impressive.

When building the same sources in Windows, executables are bigger 
(double than Linux, approx.), but anyway very small even here.


## License

Licensed under [Apache-2.0](./LICENSE).

----
