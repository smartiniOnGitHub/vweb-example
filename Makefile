.PHONY: info clean clean-local all build dist

# app environment
ENV ?= dev
# repository / source control related vars
REPO = vweb-example
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
COMMIT = $(shell git rev-parse --short HEAD)
# container related vars
# NAME ?= $(REPO)
# NAME ?= $(REPO)_$(BRANCH)_$(COMMIT)
NAME ?= $(REPO)_$(BRANCH)
TAG ?= latest
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
	@ cd ./build && ./server && cd ..

run-dist:
	@echo "Run main application optimized for production/release, in the folder './dist'..."
	@echo "If not present in that folder, run: 'make dist' and re-run this."
	@ cd ./dist && ./server && cd ..


# others
