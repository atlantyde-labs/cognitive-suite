.PHONY: all build run clean zip push help

all: build run

build:
	docker compose build

run:
    # Create required directories before starting the stack
    mkdir -p data/input outputs/raw outputs/insights schemas qdrant_storage
    docker compose up -d

stop:
	docker compose down

clean:
	rm -rf outputs/* data/input/* qdrant_storage/*

zip:
	zip -r cognitive-suite.zip docker-compose.yml ingestor pipeline frontend gitops

push:
	cd outputs && bash ../gitops/sync.sh

logs:
	docker compose logs -f

help:
	@echo "make build      - Build all docker images"
	@echo "make run        - Run suite locally"
	@echo "make stop       - Stop all services"
	@echo "make clean      - Clean generated data"
	@echo "make zip        - Generate ZIP of suite"
	@echo "make push       - Push outputs to GitHub"
	@echo "make logs       - Follow container logs"
