.PHONY: info clean clean-local all build dist

# app environment
ENV ?= dev
# repository / source control related vars
REPO = vweb-example
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
COMMIT = $(shell git rev-parse --short HEAD)
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
	@echo "Look into Makefile for details and other tasks ..."
	@echo "----"

all: info clean

clean-local:
	@echo "clean local binary artefacts (list manually updated)..."
	@rm -f ./server && rm -f ./server-minimal
	@rm -f ./healthcheck

clean: clean-local
	@echo "clean output/temporary artefacts..."
	@rm -rf ./build && mkdir -p ./build
	@rm -rf ./dist  && mkdir -p ./dist
	@rm -rf ./temp  && mkdir -p ./temp

build-local: clean-local
	@echo "Build all sources with destination in the same folder..."
	@ # v .
	@v server.v && v server-minimal.v
	@ # v healthcheck*.v

test:
	@echo "Run Unit Test all sources..."
	@v test .

build: clean
	@echo "Build all sources not optimized with destination in the folder './build'..."
	@ # v -o ./build .
	@v -o ./build/server server.v && v -o ./build/server-minimal server-minimal.v
	@cp -r ./public ./build # workaround for some resource still to add in binaries ...
	@ls -la ./build

dist: clean
	@echo "Build all sources optimized for production/release, with destination in the folder './dist'..."
	@ # v -prod -o ./dist .
	@v -prod -o ./dist/server server.v && v -prod -o ./dist/server-minimal server-minimal.v
	@cp -r ./public ./dist # workaround for some resource still to add in binaries ...
	@ls -la ./dist

run-server:
	@echo "Run server..."
	@echo "If not present in current folder, run: 'make build-local' and re-run this."
	@./server

run: run-server
	@echo "Run main application..."

run-build:
	@echo "Run main application not optimized, in the folder './build'..."
	@echo "If not present in that folder, run: 'make build' and re-run this."
	@cd ./build && ./server && cd ..

run-dist:
	@echo "Run main application optimized for production/release, in the folder './dist'..."
	@echo "If not present in that folder, run: 'make dist' and re-run this."
	@cd ./dist && ./server && cd ..

build-container: dist build-container-dist
	@echo "Build optimized binaries and package in a Docker container..."

build-container-dist:
	@echo "Build Docker container for run, using optimized binaries..."
	@echo "If not present in that folder, run: 'make dist' and re-run this."
	@cd ./dist && cp ../Dockerfile.run . \
		&& docker build -t $(NAME):$(TAG) -f ./Dockerfile.run . \
		&& cd ..
	@docker images "$(NAME)*"

run-container: run-container-dist
	@echo "Run Docker container..."

run-container-dist:
	@echo "Run Docker container with optimized binaries inside, on host port $(PORT_HOST)..."
	@docker run $(DOCKER_LOG_FLAGS) \
		--rm --name $(NAME) \
		-e "PORT=$(PORT_INTERNAL)" \
		-e "ENVIRONMENT=${ENV}" \
		-p $(PORT_HOST):$(PORT_INTERNAL) \
		-d $(NAME):$(TAG)

run-container-console:
	# only for local usage, an interactive console in the running container is opened
	@echo "Run an interactive shell into the running container ($(NAME))..."
	@docker exec -it $(NAME) bash

run-container-id:
	@echo "Get id of the running container ($(NAME))..."
	$(eval CONTAINER_ID = $(shell docker inspect --format='{{json .Id}}' $(NAME)) )
	@echo "container id: $(CONTAINER_ID)"

run-container-logs:
	# only for local usage, to exit from that console press <CTRL>C
	@echo "Get logs of running container ($(NAME))..."
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


# others
