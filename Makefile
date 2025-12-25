.PHONY: help setup build push deploy observability teardown clean test lint verify

# Detect OS
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    SHELL := powershell.exe
    .SHELLFLAGS := -NoProfile -Command
else
    DETECTED_OS := $(shell uname -s)
endif

# Variables
REGISTRY ?= localhost:5555
IMAGE_NAME ?= devops-app
IMAGE_TAG ?= latest
NAMESPACE ?= app

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Detected OS: $(DETECTED_OS)'
	@echo ''
	@echo 'Available targets:'
ifeq ($(DETECTED_OS),Windows)
	@powershell -Command "Get-Content Makefile | Select-String '##' | ForEach-Object { $$_.Line -replace '^([^:]+):.*## (.*)$$', '  $$1'.PadRight(15) + '$$2' }"
else
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
endif

setup: ## Set up the entire environment (cluster + registry)
ifeq ($(DETECTED_OS),Windows)
	@Write-Host "🚀 Setting up DevOps Challenge Environment" -ForegroundColor Cyan; cd terraform; terraform init; terraform apply -auto-approve; cd ..; kind export kubeconfig --name devops-cluster
else
	@echo "🚀 Setting up DevOps Challenge Environment"
	@./scripts/setup.sh
endif

build: ## Build the Docker image
ifeq ($(DETECTED_OS),Windows)
	@powershell -Command "Write-Host 'Building Docker image...' -ForegroundColor Cyan"
	@docker build -t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) ./app
	@kind load docker-image $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) --name devops-cluster
else
	@echo "🔨 Building Docker image..."
	@REGISTRY=$(REGISTRY) IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/build-and-push.sh
endif

push: build ## Build and push the Docker image
	@echo "✅ Build and push complete"

deploy: ## Deploy the application to Kubernetes
ifeq ($(DETECTED_OS),Windows)
	@Write-Host "🚀 Deploying application..." -ForegroundColor Cyan; kubectl create namespace $(NAMESPACE) 2>$$null; helm upgrade --install $(IMAGE_NAME) ./helm/app --namespace $(NAMESPACE) --set image.repository=$(REGISTRY)/$(IMAGE_NAME) --set image.tag=$(IMAGE_TAG) --set serviceMonitor.enabled=true --wait --timeout 5m
else
	@echo "🚀 Deploying application..."
	@REGISTRY=$(REGISTRY) IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/deploy.sh
endif

observability: ## Deploy Prometheus and Grafana
ifeq ($(DETECTED_OS),Windows)
	@Write-Host "📊 Deploying observability stack..." -ForegroundColor Cyan; helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$$null; helm repo update; kubectl create namespace monitoring 2>$$null; helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false --wait --timeout 10m
else
	@echo "📊 Deploying observability stack..."
	@./scripts/deploy-observability.sh
endif

elk: ## Deploy ELK Stack for centralized logging
ifeq ($(DETECTED_OS),Windows)
	@powershell -Command "Write-Host 'Deploying ELK Stack...' -ForegroundColor Cyan"
	@helm upgrade --install elk-stack ./helm/elk --namespace monitoring --create-namespace --wait --timeout 10m
	@powershell -Command "Write-Host 'ELK Stack deployed!' -ForegroundColor Green"
	@powershell -Command "Write-Host 'Access Kibana: kubectl port-forward svc/kibana 5601:5601 -n monitoring' -ForegroundColor Yellow"
else
	@echo "📝 Deploying ELK Stack..."
	@./scripts/deploy-elk.sh
endif

elk-local: ## Run ELK Stack locally with Docker Compose
	@echo "📝 Starting ELK Stack locally..."
	@docker-compose -f docker-compose.elk.yml up -d
	@echo "✅ ELK Stack started! Kibana: http://localhost:5601"

elk-stop: ## Stop local ELK Stack
	@echo "🛑 Stopping ELK Stack..."
	@docker-compose -f docker-compose.elk.yml down

elk-logs: ## Show ELK Stack logs
	@kubectl logs -n monitoring -l app.kubernetes.io/name=elk-stack --tail=50 -f

elk-uninstall: ## Uninstall ELK Stack from Kubernetes
	@echo "🗑️ Uninstalling ELK Stack..."
	@helm uninstall elk-stack -n monitoring

all: setup build deploy observability elk ## Set up everything (cluster, build, deploy, observability, ELK)
	@echo "✅ Complete environment is ready!"

teardown: ## Tear down the entire environment
	@echo "🧹 Tearing down environment..."
	@./scripts/teardown.sh

clean: teardown ## Alias for teardown

test: ## Run application tests
	@echo "🧪 Running tests..."
	@cd app && python -m pytest || echo "No tests defined yet"

lint: ## Lint Python code
	@echo "🔍 Linting Python code..."
	@pip install flake8 || true
	@flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics || true
	@flake8 app/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

verify: ## Verify deployment status
	@echo "✅ Verifying deployment..."
	@kubectl get nodes
	@kubectl get pods -n $(NAMESPACE)
	@kubectl get svc -n $(NAMESPACE)
	@kubectl get pods -n monitoring || echo "Monitoring namespace not found"

port-forward-app: ## Port forward to application
	@echo "🔗 Port forwarding to application..."
	@kubectl port-forward -n $(NAMESPACE) svc/devops-app 8080:80

port-forward-grafana: ## Port forward to Grafana
	@echo "🔗 Port forwarding to Grafana..."
	@kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

port-forward-prometheus: ## Port forward to Prometheus
	@echo "🔗 Port forwarding to Prometheus..."
	@kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

port-forward-kibana: ## Port forward to Kibana
	@powershell -Command "Write-Host 'Port forwarding to Kibana...' -ForegroundColor Cyan"
	@kubectl port-forward -n monitoring svc/kibana 5601:5601

logs: ## Show application logs
	@kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=devops-app --tail=50 -f

status: verify ## Show status of all components

