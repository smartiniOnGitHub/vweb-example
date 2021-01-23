.PHONY: info clean clean-local all build dist
.DEFAULT_GOAL := info

# app environment
ENV ?= dev
# repository / source control related vars
REPO = vweb-example
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
COMMIT = $(shell git rev-parse --short HEAD)
# compiler flags
# COMPILER_OPTIMIZE_FLAGS = -autofree -prod -compress
# COMPILER_OPTIMIZE_FLAGS = -autofree -prod # do compress manually
COMPILER_OPTIMIZE_FLAGS = -prod # no autofree for now, and do compress manually
# container related vars
NAME ?= $(REPO)
# NAME ?= $(REPO)_$(BRANCH)_$(COMMIT)
# NAME ?= $(REPO)_$(BRANCH)
TAG ?= latest
DOCKER_LOG_FLAGS ?= 
# NETWORK ?= example
PORT_INTERNAL = 8000
PORT_HOST ?= 8080
# application related vars
# using only values of current dev env (dev)
# ...

info:
	@echo "# $(NAME) #"
	@echo "Environment: $(ENV)"
	@echo "Repository: $(REPO), branch: $(BRANCH), commit: $(COMMIT)"
	@v version
	@echo "Main tasks here are: "
	@echo "all, test, run, build, dist, run, etc"
	@echo "For a quick build and run, use the task: build-and-run"
	@echo "Look into Makefile for details and other tasks ..."
	@echo "----"

all: info clean

clean-local:
	@echo "clean local binary artefacts (list manually updated)..."
	@rm -f ./server ./vweb-example
	@cd healthcheck && rm -f ./healthcheck
	@cd minimal && rm -f ./server-minimal ./minimal

clean: clean-local
	@echo "clean output/temporary artefacts..."
	@rm -rf ./build && mkdir -p ./build
	@rm -rf ./dist  && mkdir -p ./dist
	@rm -rf ./temp  && mkdir -p ./temp

setup: 
	@echo "setup folder structure etc..."
	@mkdir -p ./build
	@mkdir -p ./dist
	@mkdir -p ./temp

build-local: clean-local setup
	@echo "Build all sources with destination in the same folder..."
	@v .
	@cd healthcheck && v .
	@cd minimal && v .

test:
	@echo "Run Unit Test all sources..."
	@v test .

clean-build:
	@echo "Clean the folder './build'..."
	@rm -rf ./build/*

clean-dist:
	@echo "Clean the folder './dist'..."
	@rm -rf ./dist/*

fix-build:
	@sudo chown $(USER):$(USER) -R ./build/*

fix-dist:
	@sudo chown $(USER):$(USER) -R ./dist/*

build: build-normal
	@echo "Build all sources, in the folder './build'..."

build-normal: clean-build setup
	@echo "Build all sources not optimized, in the folder './build'..."
	@touch ./build/build-normal.out
	@v -o ./build/vweb-example server.v
	@cd minimal && v -o ../build/vweb-minimal server-minimal.v
	@cd healthcheck && v -o ../build/healthcheck healthcheck.v
	@ls -la ./build

build-optimized: clean-build setup
	@echo "Build all sources optimized, in the folder './build'..."
	@echo "note that this requires 'upx' installed (to compress/strip executables)"
	@touch ./build/build-optimized.out
	@$(eval opts := ${COMPILER_OPTIMIZE_FLAGS})
	@v ${opts} -o ./build/vweb-example server.v
	@cd minimal && v ${opts} -o ../build/vweb-minimal server-minimal.v
	@cd healthcheck && v ${opts} -o ../build/healthcheck healthcheck.v
	@ls -la ./build

build-static-ubuntu: clean-build setup
	@echo "Build all sources not optimized and with libraries statically linked, in the folder './build'..."
	@echo "note that this requires 'musl-gcc' installed (default in Alpine Linux) and libraries built with musl"
	@touch ./build/build-static.out
	@$(eval opts := -cg -cc musl-gcc -cflags '--static -I/usr/local/include/musl -I/usr/local/include -L/usr/lib/x86_64-linux-musl -L/usr/local/ssl/lib -L/usr/lib/x86_64-linux-gnu -lssl')
	@v ${opts} -o ./build/vweb-example server.v
	# @ cd minimal && v ${opts} -o ../build/vweb-minimal server-minimal.v
	@cd healthcheck && v ${opts} -o ../build/healthcheck healthcheck.v
	@ls -la ./build

build-optimized-static-ubuntu: clean-build setup
	@echo "Build all sources optimized and with libraries statically linked, in the folder './build'..."
	@echo "note that this requires 'musl-gcc' installed and libraries built with musl"
	@echo "note that this requires 'upx' installed (to compress/strip executables)"
	@touch ./build/build-optimized-static.out
	@$(eval opts := ${COMPILER_OPTIMIZE_FLAGS} -cc musl-gcc -cflags '--static -I/usr/local/include/musl -I/usr/local/include -L/usr/lib/x86_64-linux-musl -L/usr/local/ssl/lib -L/usr/lib/x86_64-linux-gnu -lssl')
	@v ${opts} -o ./build/vweb-example server.v
	# @ cd minimal && v ${opts} -o ../build/vweb-minimal server-minimal.v
	@cd healthcheck && v ${opts} -o ../build/healthcheck healthcheck.v
	@ls -la ./build

build-optimized-static-alpine: clean-build setup
	@echo "Build all sources optimized and with libraries statically linked, in the folder './build'..."
	@echo "note that this requires 'musl' libraries (default in Alpine Linux) and other libraries built with musl"
	@echo "note that this requires 'upx' installed (to compress/strip executables)"
	@touch ./build/build-optimized-static.out
	@$(eval opts := ${COMPILER_OPTIMIZE_FLAGS} -cflags '--static')
	@v ${opts} -o ./build/vweb-example server.v
	# @ cd minimal && v ${opts} -o ../build/vweb-minimal server-minimal.v
	@cd healthcheck && v ${opts} -o ../build/healthcheck healthcheck.v
	@ls -la ./build

copy-dist:
	@echo "Copy all resources in the folder './dist'..."
	@cp -r ./build/* ./dist
	@cp -r ./public ./dist # workaround for some resource still to add in binaries ...
	@ls -la ./dist

compress-dist-executables: dist
	@echo "Compress executables (not already optimized/compressed), in the folder './dist'..."
	@echo "note that this requires 'upx' installed (to compress/strip executables)"
	@touch ./dist/compress-executables.out
	@upx dist/healthcheck || echo "failure in compress/strip healthcheck"
	@upx dist/vweb-example
	@upx dist/vweb-minimal || echo "failure in compress/strip vweb-minimal"
	@ls -la ./dist

# dist: clean-dist copy-dist
dist: clean-dist copy-dist compress-dist-executables
	@echo "Setup all resources in the folder './dist'..."
	@echo "To build executables, before run one of 'build*' tasks via make..."

run: run-dist
	@echo "Run main application..."

run-local:
	@echo "Run server in main folder..."
	@echo "If not present in current folder, run: 'make build-local' and re-run this."
	@./vweb-example

run-build:
	@echo "Run main application from already built executables, in the folder './build'..."
	@echo "If not present in that folder, run: 'make build' and re-run this."
	@cd ./build && ./vweb-example && cd ..

run-dist:
	@echo "Run main application from already built executables, in the folder './dist'..."
	@echo "If not present in that folder, run: 'make dist' and re-run this."
	@cd ./dist && ./vweb-example && cd ..


build-and-run: build dist run
	@echo "Build and Run main application..."

build-optimized-and-run: build-optimized dist run
	@echo "Build and Run main application optimized..."


# container-related tasks

build-container:
	@$(eval dfile := Dockerfile)
	@echo "Build sources and run in a Docker container for run ('${dfile}'), using optimized binaries..."
	@docker build -t $(NAME):$(TAG) -f ./${dfile} .
	@docker images "$(NAME)*"

build-container-alpine:
	@$(eval dfile := Dockerfile.alpine)
	@echo "Build sources and run in a Docker container (alpine based) for run ('${dfile}'), "\
		"using optimized binaries..."
	@docker build -t $(NAME):$(TAG) -f ./${dfile} .
	@docker images "$(NAME)*"

build-container-alpine-scratch:
	@$(eval dfile := Dockerfile.scratch)
	@echo "Build sources in a Docker container (alpine based) and run in a minimal (scratch based) one, "\
		"for run ('${dfile}'), using optimized binaries (statically built)..."
	@docker build -t $(NAME):$(TAG) -f ./${dfile} .
	@docker images "$(NAME)*"

build-container-ubuntu:
	@$(eval dfile := Dockerfile.ubuntu)
	@echo "Build sources and run in a Docker container (ubuntu based) for run ('${dfile}'), "\
		"using optimized binaries..."
	@docker build -t $(NAME):$(TAG) -f ./${dfile} .
	@docker images "$(NAME)*"

build-local-and-run-in-container: build-optimized dist build-container-for-run-ubuntu
	@echo "Build optimized binaries and package in a Docker container based on ubuntu..."

build-container-for-run-ubuntu:
	@$(eval dfile := Dockerfile.run.ubuntu)
	@echo "Build Docker container (ubuntu based) for run ('${dfile}'), using optimized binaries..."
	@echo "If files aren't present in the folder './dist': "\
		"run one of make build* tasks, then 'make dist' and re-run this."
	@cd ./dist && cp ../${dfile} . \
		&& docker build -t $(NAME):$(TAG) -f ./${dfile} . \
		&& cd ..
	@docker images "$(NAME)*"

build-container-for-run-scratch:
	@$(eval dfile := Dockerfile.run.scratch)
	@echo "Build Docker container (based on scratch, so minimal) for run ('${dfile}'), "\
		"using optimized binaries (statically built)..."
	@echo "If files aren't present in the folder './dist': "\
		"run one of make build*-static tasks, then 'make dist' and re-run this."
	@cd ./dist && cp ../${dfile} . \
		&& docker build -t $(NAME):$(TAG) -f ./${dfile} . \
		&& cd ..
	@docker images "$(NAME)*"

run-container: run-container-dist
	@echo "Run Docker container $(NAME)..."

run-container-dist:
	@echo "Run Docker container with optimized binaries inside it..."
	@echo "Main traffic on host port $(PORT_HOST)..."
	@docker run $(DOCKER_LOG_FLAGS) \
		--rm --name $(NAME) \
		-e "PORT=$(PORT_HOST)" \
		-e "ENVIRONMENT=${ENV}" \
		-p $(PORT_HOST):$(PORT_INTERNAL) \
		-d $(NAME):$(TAG)

run-container-interactive-ubuntu:
	# only for local usage, an interactive console is opened in the running container
	# mainly for debugging purposes, so no env vars are needed in this run, and no detached mode
	@$(eval she := bash)
	@echo "Run an interactive shell ($(she)) into the running container ($(NAME))..."
	@docker run $(DOCKER_LOG_FLAGS) --rm -it --name $(NAME) $(NAME):$(TAG) $(she)

run-container-interactive-alpine-dev:
	# only for local usage, an interactive console is opened in the alpine-dev image/container
	# mainly for debugging purposes, so no env vars are needed in this run, and no detached mode
	@$(eval she := ash)
	@$(eval NAME := thevlang/vlang)
	@$(eval TAG  := alpine-dev)
	@$(eval NAME_SANITIZED := $(shell echo "${NAME}" | tr A-Z a-z | sed 's/@/_/;s/\//_/') )
	@echo "Run an interactive shell ($(she)) into the running container ($(NAME_SANITIZED))..."
	@docker run $(DOCKER_LOG_FLAGS) --rm -it --name $(NAME_SANITIZED) $(NAME):$(TAG) $(she)

run-container-console-alpine:
	# only for local usage, an interactive console in the running container is opened
	@$(eval she := ash)
	@echo "Run an interactive shell into the running container ($(NAME))..."
	@docker exec -it $(NAME) $(she)

run-container-console-ubuntu:
	# only for local usage, an interactive console in the running container is opened
	@$(eval she := bash)
	@echo "Run an interactive shell into the running container ($(NAME))..."
	@docker exec -it $(NAME) $(she)

run-container-id:
	@echo "Get id of the running container ($(NAME))..."
	$(eval CONTAINER_ID = $(shell docker inspect --format='{{json .Id}}' $(NAME)) )
	@echo "container id: $(CONTAINER_ID)"

run-container-logs:
	# only for local usage, to exit from that console press <CTRL>C
	@echo "Get logs of running container ($(NAME))..."
	@echo "Main traffic on host port $(PORT_HOST)..."
	@docker logs --follow --tail=1000 $(NAME)

run-container-ps:
	@echo "Get the process status of running container ($(NAME)), on host port $(PORT_HOST)..."
	@docker ps --filter "name=$(NAME)"

run-container-status:
	@echo "Get the status of running container ($(NAME))..."
	@docker inspect --format '{{ json .State.Health }}' $(NAME)

stop-container:
	@echo "Stop the container ($(NAME))..."
	@docker stop $(NAME)

clean-container:
	@echo "Clean container-related stuff..."
	# @docker rm $(NAME):$(TAG)
	# @docker rm $(shell docker ps -a -q)
	@docker rmi $(NAME):$(TAG)

clean-container-old:
	@echo "Clean old containers..."
	@docker system prune -f


# others

bench-simple:
	@echo "Simple benchmark using 'ab' (run it in another terminal)..."
	@ab -n 100000 -c 8 http://localhost:8000/

valgrind-check-for-memory-leaks-summary:
	@echo "Check for memory leaks in the 'vweb-example' using 'valgrind' (run it in another terminal)..."
	@cd dist && valgrind --log-file="vweb-example-valgrind-summary.log" ./vweb-example

valgrind-check-for-memory-leaks-details:
	@echo "Check for memory leaks in the 'vweb-example' using 'valgrind' (run it in another terminal)..."
	@cd dist && valgrind --leak-check=full --show-leak-kinds=all --log-file="vweb-example-valgrind-details.log" ./vweb-example
