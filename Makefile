.PHONY: help setup build push deploy observability teardown clean test lint verify

# Variables
REGISTRY ?= localhost:5555
IMAGE_NAME ?= devops-app
IMAGE_TAG ?= latest
NAMESPACE ?= app

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Set up the entire environment (cluster + registry)
	@echo "🚀 Setting up DevOps Challenge Environment"
	@./scripts/setup.sh

build: ## Build the Docker image
	@echo "🔨 Building Docker image..."
	@REGISTRY=$(REGISTRY) IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/build-and-push.sh

push: build ## Build and push the Docker image
	@echo "✅ Build and push complete"

deploy: ## Deploy the application to Kubernetes
	@echo "🚀 Deploying application..."
	@REGISTRY=$(REGISTRY) IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/deploy.sh

observability: ## Deploy Prometheus and Grafana
	@echo "📊 Deploying observability stack..."
	@./scripts/deploy-observability.sh

all: setup build deploy observability ## Set up everything (cluster, build, deploy, observability)
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

logs: ## Show application logs
	@kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=devops-app --tail=50 -f

status: verify ## Show status of all components

