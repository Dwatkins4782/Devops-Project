# DevOps Project - AI Agent Instructions

## Architecture Overview

This is a complete DevOps demonstration project featuring a **Python Flask application** deployed to a **local KinD (Kubernetes in Docker) cluster** with full observability via **Prometheus + Grafana**.

**Key components:**
- **Infrastructure**: Terraform-managed KinD cluster (1 control-plane + 1 worker) with local Docker registry on `localhost:5555`
- **Application**: Flask app (`app/app.py`) with Prometheus metrics endpoints (`/metrics`, `/health`, `/api/hello`)
- **Deployment**: Helm chart (`helm/app/`) with ServiceMonitor integration for metrics scraping
- **Observability**: Prometheus Operator stack deployed to `monitoring` namespace, app deployed to `app` namespace
- **CI/CD**: GitHub Actions workflow (`.github/workflows/ci-cd.yml`) for build → push → deploy

## Critical Workflows

### Local Development & Deployment
Use **Makefile** as the primary interface - all scripts are wrapped:
```bash
make setup          # Terraform applies KinD cluster + registry
make build          # Builds Docker image, pushes to localhost:5555
make deploy         # Helm installs/upgrades app with serviceMonitor.enabled=true
make observability  # Deploys Prometheus + Grafana to 'monitoring' namespace
make all            # Complete setup: infrastructure → build → deploy → observability
make teardown       # Destroys cluster and registry
```

**Environment variables** for customization (all scripts respect these):
- `REGISTRY` (default: `localhost:5555`)
- `IMAGE_NAME` (default: `devops-app`)
- `IMAGE_TAG` (default: `latest`)

### Testing
- Run tests: `make test` or `cd app && python -m pytest`
- Test file: `app/test_app.py` uses pytest fixtures, tests all Flask endpoints including metrics

### Accessing Services
```bash
# Application
kubectl port-forward -n app svc/devops-app 8080:80

# Grafana (credentials: admin / prom-operator)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## Project-Specific Conventions

### Helm Chart Patterns
- **ServiceMonitor**: Enabled via `serviceMonitor.enabled=true` in `values.yaml` - this is crucial for Prometheus to scrape the app's `/metrics` endpoint
- **Health checks**: Deployment uses `/health` endpoint for both liveness (30s initial delay) and readiness (5s initial delay) probes
- **Port mapping**: Flask runs on `8080` (container), exposed as port `80` (service)

### Flask Application Structure
- **Prometheus metrics**: Uses `prometheus_client` library with decorators for tracking:
  - `REQUEST_COUNT` (Counter): Total requests by method/endpoint/status
  - `REQUEST_DURATION` (Histogram): Request latency by method/endpoint
- **Endpoints**: All endpoints have metrics instrumentation via context managers
- **Production**: Uses `gunicorn` with 2 workers (see `Dockerfile`)

### Terraform Patterns
- **Provider**: Uses `kind` provider (not AWS/Azure) - cluster creation is declarative
- **Registry**: Created via `null_resource` with `local-exec` provisioner running Docker commands
- **Networking**: Registry connected to `kind` Docker network for cluster-to-registry communication

### CI/CD Pipeline
- **Single job workflow**: Build → Push → Deploy in one sequential job (not parallelized)
- **Image tagging**: Both `${GITHUB_SHA}` and `latest` tags pushed; SHA used in deployment for traceability
- **Observability-first**: Prometheus stack deployed *before* application to ensure ServiceMonitor CRD exists
- **KinD in CI**: Uses `helm/kind-action@v1.10.0`, creates cluster inline with `kind create cluster --config -`

## Key Files Reference

- **`Makefile`**: Primary developer interface - check here first for available commands
- **`scripts/setup.sh`**: Prerequisites check, Terraform init/apply, registry setup
- **`scripts/deploy.sh`**: Helm deployment with `--set serviceMonitor.enabled=true` (critical!)
- **`helm/app/values.yaml`**: Default `serviceMonitor.enabled=false` - must override in deployment
- **`app/app.py`**: Flask app with Prometheus metrics - all routes follow same pattern
- **`terraform/main.tf`**: KinD cluster config with custom port mappings (80, 443) and node labels

## Important Notes

- **Local registry port**: External port `5555`, internal (to KinD) port `5000` - scripts handle this mapping
- **Namespace separation**: `app` for application workloads, `monitoring` for Prometheus/Grafana
- **ServiceMonitor dependency**: Application deployment will create ServiceMonitor resource, but Prometheus Operator CRDs must exist first (deploy observability before app in fresh clusters)
- **Shell scripts**: All scripts in `scripts/` use bash and `set -e` for fail-fast behavior
