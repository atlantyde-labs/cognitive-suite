SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

IMAGE ?= cognitive-frontend
PORT ?= 8501

# outputs lives at repo root by default
OUTPUTS_HOST ?= $(abspath ../outputs)
OUTPUTS_CONTAINER ?= /data/outputs

##@ Help
help: ## Show help
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets (frontend):\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ UI
ui-doctor: ## Check outputs/insights/analysis.json exists
	@bash scripts/ui/doctor.sh "$(OUTPUTS_HOST)"

ui-local: ## Run Streamlit locally (no Docker)
	@bash scripts/ui/ui_local.sh "$(PORT)" "$(OUTPUTS_HOST)"

ui-build: ## Build Docker image (context: frontend/)
	docker build -f Dockerfile -t $(IMAGE) .

ui-up: ## Run Docker UI at http://localhost:PORT
	@bash scripts/ui/ui_docker.sh "$(IMAGE)" "$(PORT)" "$(OUTPUTS_HOST)" "$(OUTPUTS_CONTAINER)"
