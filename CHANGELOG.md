# Change Log

## [0.1.0](https://github.com/smartiniOnGitHub/vweb-example/releases/tag/0.1.0) (unreleased)
Summary Changelog:
- Doc: First release, with minimal set of features
- Doc: add initial documentation
- Doc: add documentation on setup an Ubuntu machine for static builds with MUSL libraries
- Feature: add a minimal server, as a sample
- Feature: add a base server, with API reply (text and json) and some dynamic html page
- Feature: add makefile to simplify shell commands, via make (cmake)
- Feature: add Dockerfile/s to build and package all in a container
- Feature: add badge to DockerHub, where images are built from these sources
- Feature: add Apache License header to all source files
- Feature: add 'v.mod' file to describe the application in V standard way
- Feature: add 'Makefile' to simplify shell commands usage (tested on Linux)
- Feature: add 'Dockerfile.run.ubuntu' to run main server binary 
  (already built for now) inside a Docker container, based on Ubuntu
- Feature: move minimal server source in its own folder 'minimal' 
  (but not in a nested module)), to avoid confision with main server source, 
  and to be able to compile all without having to specify sources manually
- Feature: add a command-line utility 'healthcheck' (in its own folder 'healthcheck') 
  to call the given HTTP endpoint and check HTTP statup for health check 
  (useful for example when main application is running in a container)
- Feature: add a route '/health' so that container runtimes or external utilities 
  can call it to understand if the application is still alive 
  (useful for example when main application is running in a container)
- Feature: update main template 'index.html' to include dynamic content for 
  header and footer from related templates (resp. 'header.html' and 'footer.html')
- Feature: add a route '/info' that exposes some metadata of the application
  (retrieved at build time, from 'v.mod' module file)
- Feature: add a route '/user/:id' parametric (with id injected into related function/method)
- Feature: add a route '/mystatus' that always return an HTTP status error code
- Feature: add other routes
- Feature: build executables in a static way, using MUSL libraries
  (this will be used later even with some Docker containers, trying to use the 'scratch' base image)
- Feature: add 'Dockerfile.run.scratch' to run main server binary 
  (already built for now, and in a static way with MUSL libraries) inside a Docker container, 
  based on scratch (so empty and containing only application files)
- Feature: add 'Dockerfile.alpine' that uses V official Docker images to build and run 
  in a multistage image, with all layers derived from Alpine 
  (but no static build here, for simplicity); 
  approx. image size  12 MB
- Feature: add 'Dockerfile.scratch' that uses a multistage image with 
  as first stage the V official Docker image 'alpine-dev' to build 
  (but in a static way, so no external dependencies out of executables built) 
  and for the second stage, the 'scratch' (empty) image; this images is really tiny 
  because there is nothing other than application executables and resources inside id
  (no shell, no system commands, etc), so safer to run (but harder to debug); 
  approx. image size   2.2 MB (1.1 MB for the webapp, and 1.1 MB for the healthcheck app)
- Feature: add 'Dockerfile.ubuntu' that uses V official Docker images to build and run 
  in a multistage image, with all layers derived from Ubuntu; 
  approx. image size 125 MB
- Feature: add a default 'Dockerfile' that uses V official Docker images in first stage to build sources, 
  and a standard Alpine image for the second stage (for the run); 
  all was good in a similar way with Ubuntu derived images (the vlang one and the standard one respectively), 
  but final images was bigger (approx. 110 MB instead of 10 MB for the Alpine based), 
  so I think that the Alpine based as default makes sense here
- Feature: use V integrated logging, both in server source and in healthcheck (for consistency)

----
