# DevOps Challenge - Complete Kubernetes Environment

This repository contains a complete production-like DevOps environment demonstrating Infrastructure-as-Code, Kubernetes deployment, CI/CD pipelines, and observability.

If you prefer short commands, see the **Makefile shortcuts** section.

## 🏗️ Architecture Overview

The solution consists of:

- **Infrastructure (IaC)**: Terraform-managed KinD cluster with local container registry
- **Application**: Python Flask web application with Prometheus metrics
- **Kubernetes**: Helm-based deployment with ServiceMonitor for metrics collection
- **CI/CD**: GitHub Actions pipeline for automated build, test, and deployment
- **Observability**: Prometheus and Grafana stack for metrics monitoring

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Build   │→ │  Test    │→ │  Deploy  │→ │  Verify  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Terraform Infrastructure (IaC)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  KinD Cluster (1 control-plane + 1 worker)           │  │
│  │  Local Container Registry (localhost:5555)            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │  App Namespace│         │Monitoring NS │                 │
│  │  ┌──────────┐│         │ ┌──────────┐│                 │
│  │  │DevOps App││         │ │Prometheus││                 │
│  │  │(Flask)   ││◄────────┤ │          ││                 │
│  │  │          ││ Metrics │ │ Grafana  ││                 │
│  │  │Service   ││         │ │          ││                 │
│  │  │Monitor   ││         │ └──────────┘│                 │
│  │  └──────────┘│         └──────────────┘                 │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (20.10+)
- **KinD** (Kubernetes in Docker) v0.20.0+
- **Terraform** 1.0+
- **kubectl** (matching your Kubernetes version)
- **Helm** 3.12+
- **Python** 3.11+ (for local development)
- **Git**

### Installation Commands

#### macOS
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install prerequisites
brew install terraform kubectl helm kind docker python@3.11

# Start Docker Desktop
open -a Docker
```

#### Linux
```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install KinD
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Docker (follow official Docker installation guide)
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd devops-challenge
```

### Makefile shortcuts (optional)
From the repo root, you can use:
```bash
make setup          # Provision KinD + registry via Terraform
make build          # Build & push image (uses REGISTRY/IMAGE vars)
make deploy         # Deploy the app via Helm (serviceMonitor enabled)
make observability  # Deploy Prometheus + Grafana stack
make all            # setup + build + deploy + observability
make teardown       # Cleanup everything
make verify         # Quick status (nodes, pods, services)
```

### 2. Set Up the Environment

Run the setup script to provision the infrastructure:

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

This script will:
- Check all prerequisites
- Initialize and apply Terraform to create the KinD cluster
- Set up a local container registry
- Configure kubectl to use the new cluster

### 3. Build and Push the Application

Build the Docker image and push it to the local registry (default `localhost:5555`):

```bash
./scripts/build-and-push.sh
```

Or manually:

```bash
export REGISTRY=localhost:5555
export IMAGE_NAME=devops-app
export IMAGE_TAG=latest

docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./app
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
kind load docker-image ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} --name devops-cluster
```

### 4. Deploy the Application

Deploy the application using Helm:

```bash
./scripts/deploy.sh
```

Or manually:

```bash
kubectl create namespace app
helm upgrade --install devops-app ./helm/app \
  --namespace app \
  --set image.repository=localhost:5555/devops-app \
  --set image.tag=latest \
  --set serviceMonitor.enabled=true \
  --wait --timeout 5m
```

### 5. Deploy Observability Stack

Deploy Prometheus and Grafana:

```bash
./scripts/deploy-observability.sh
```

Or manually:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30000 \
  --wait --timeout 10m
```

## 🧪 Verify the Deployment

### Check Application Status

```bash
# Get cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check application pods
kubectl get pods -n app

# Check application service
kubectl get svc -n app

# View application logs
kubectl logs -n app -l app.kubernetes.io/name=devops-app --tail=50
```

### Access the Application

```bash
# Port forward to access the application
kubectl port-forward -n app svc/devops-app 8080:80
```

Then visit:
- **Application**: http://localhost:8080
- **Health Check**: http://localhost:8080/health
- **API Endpoint**: http://localhost:8080/api/hello?name=DevOps
- **Metrics**: http://localhost:8080/metrics

### Access Observability Tools

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password (read from secret):
    ```bash
    kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode && echo
    ```
  - If you don’t see the dashboard:
    ```bash
    kubectl get cm -n app | grep dashboard
    # restart the Grafana sidecar pods (auto-reloads dashboards)
    kubectl rollout restart deploy/prometheus-grafana -n monitoring
    ```

```bash
# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
- **Prometheus**: http://localhost:9090

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) automates:

1. **Build**: Build the application container
2. **Push**: Push it to a local container registry
3. **Deploy**: Deploy the application to the KinD cluster

### Pipeline Stages

```yaml
build → push → deploy
```

The pipeline runs on:
- Push to `main`, `master`, or `develop` branches
- Pull requests to `main` or `master`
- Manual trigger via `workflow_dispatch`

### Manual Trigger

You can manually trigger the workflow via GitHub Actions UI or:

```bash
gh workflow run ci-cd.yml
```

## 📊 Observability

### Metrics Exposed

The application exposes the following Prometheus metrics:

- `http_requests_total`: Total HTTP requests by method, endpoint, and status
- `http_request_duration_seconds`: HTTP request duration histogram

### Grafana Dashboard

A pre-configured dashboard is automatically created when deploying the application. It includes:

- **HTTP Requests Total**: Request rate by endpoint and status
- **HTTP Request Duration**: P50 and P95 latency percentiles

Access the dashboard in Grafana:
1. Navigate to Dashboards → Browse
2. Look for "DevOps App Metrics"

### Query Examples

In Prometheus, try these queries:

```promql
# Request rate
sum(rate(http_requests_total[5m])) by (endpoint, status)

# P95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, endpoint))

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) by (endpoint)
```

## 🏗️ Infrastructure Details

### Terraform Configuration

The Terraform configuration (`terraform/main.tf`) provisions:

- **KinD Cluster**: Single control-plane + worker node
- **Local Registry**: Docker registry on port 5555
- **Network Configuration**: Port mappings for ingress (80, 443)

### Kubernetes Resources

The Helm chart (`helm/app/`) includes:

- **Deployment**: Application pods with resource limits
- **Service**: ClusterIP service for internal access
- **ServiceAccount**: For RBAC (if needed)
- **ServiceMonitor**: For Prometheus scraping
- **ConfigMap**: Grafana dashboard definition

## 🧹 Cleanup

To tear down the entire environment:

```bash
./scripts/teardown.sh
```

This will:
- Uninstall Helm releases
- Delete Kubernetes namespaces
- Destroy Terraform infrastructure
- Remove local container registry

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD pipeline
├── app/
│   ├── app.py                 # Flask application
│   ├── Dockerfile             # Container image definition
│   └── requirements.txt       # Python dependencies
├── helm/
│   └── app/
│       ├── Chart.yaml         # Helm chart metadata
│       ├── values.yaml        # Default values
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── serviceaccount.yaml
│           ├── servicemonitor.yaml
│           ├── grafana-dashboard.yaml
│           └── _helpers.tpl
├── scripts/
│   ├── setup.sh               # Initial setup
│   ├── build-and-push.sh      # Build and push image
│   ├── deploy.sh              # Deploy application
│   ├── deploy-observability.sh # Deploy monitoring
│   └── teardown.sh            # Cleanup
├── terraform/
│   ├── main.tf                # Main Terraform configuration
│   ├── outputs.tf            # Terraform outputs
│   └── versions.tf           # Provider versions
└── README.md                 # This file
```

## 🎯 Design Decisions & Trade-offs

### Infrastructure

**Choice: KinD over Minikube/k3d**
- **Pros**: Lightweight, fast startup, good for CI/CD, native Docker integration
- **Cons**: Not suitable for production workloads, limited to single machine
- **Reasoning**: Perfect for local development and CI/CD pipelines, aligns with project requirements

**Choice: Local Registry**
- **Pros**: No external dependencies, fast, free, works offline
- **Cons**: Not persistent across restarts, not suitable for production
- **Reasoning**: Simplifies local development and CI/CD testing

### Application

**Choice: Python Flask**
- **Pros**: Simple, lightweight, easy to instrument with Prometheus
- **Cons**: Single-threaded by default (mitigated with Gunicorn)
- **Reasoning**: Quick to develop, demonstrates metrics instrumentation

**Choice: Gunicorn**
- **Pros**: Production-ready WSGI server, multi-worker support
- **Cons**: Additional dependency
- **Reasoning**: Better than Flask's development server for containerized deployments

### Kubernetes Deployment

**Choice: Helm over Kustomize**
- **Pros**: More mature ecosystem, better for complex applications, templating
- **Cons**: Additional tool to learn
- **Reasoning**: Industry standard, better for production-like scenarios

**Choice: ServiceMonitor for Metrics**
- **Pros**: Declarative, integrates with Prometheus Operator
- **Cons**: Requires Prometheus Operator
- **Reasoning**: Best practice for Kubernetes-native monitoring

### Observability

**Choice: Prometheus + Grafana**
- **Pros**: Industry standard, rich ecosystem, powerful query language
- **Cons**: Can be resource-intensive
- **Reasoning**: Most common choice, excellent documentation, comprehensive features

**Choice: Prometheus Operator**
- **Pros**: Kubernetes-native, declarative configuration, auto-discovery
- **Cons**: Additional complexity
- **Reasoning**: Simplifies Prometheus management, aligns with GitOps practices

### CI/CD

**Choice: GitHub Actions**
- **Pros**: Native GitHub integration, free for public repos, easy to use
- **Cons**: Vendor lock-in
- **Reasoning**: Recommended in requirements, widely adopted

**Choice: Multi-stage Pipeline**
- **Pros**: Early failure detection, parallel execution, clear separation
- **Cons**: Longer total pipeline time
- **Reasoning**: Better feedback, follows CI/CD best practices

## 🔒 Security Considerations

- **Image Scanning**: Consider adding Trivy or similar in CI/CD
- **Secrets Management**: Use Kubernetes secrets or external secret management
- **RBAC**: ServiceAccount with minimal permissions
- **Network Policies**: Consider adding network policies for pod-to-pod communication
- **Resource Limits**: Already implemented in Helm chart

## 🚀 Future Enhancements

- [ ] Add automated testing (unit, integration)
- [ ] Implement blue-green or canary deployments
- [ ] Add alerting rules (Alertmanager)
- [ ] Implement GitOps with ArgoCD/Flux
- [ ] Add multi-environment support (dev/staging/prod)
- [ ] Implement autoscaling (HPA/VPA)
- [ ] Add ingress controller (NGINX/Traefik)
- [ ] Implement service mesh (Istio/Linkerd)

## 📝 Troubleshooting

### Cluster Not Starting

```bash
# Check Docker is running
docker ps

# Check KinD installation
kind version

# Delete and recreate cluster
kind delete cluster --name devops-cluster
./scripts/setup.sh
```

### Image Pull Errors / Registry Push Issues

**Issue: "http: server gave HTTP response to HTTPS client" or "i/o timeout"**

This happens because Docker tries to use HTTPS for local registries. Fix it by configuring Docker to allow insecure registries:

**macOS (Docker Desktop):**
1. Open Docker Desktop
2. Go to Settings → Docker Engine
3. Add to the JSON configuration:
   ```json
   {
     "insecure-registries": ["localhost:5555"]
   }
   ```
4. Click "Apply & Restart"

**Linux:**
Edit `/etc/docker/daemon.json` (or create it):
```json
{
  "insecure-registries": ["localhost:5555"]
}
```
Then restart Docker: `sudo systemctl restart docker`

**Alternative: Skip registry push (for local development only)**
The script will automatically fall back to using `kind load` directly if the push fails.

**Port 5555 already in use:**
```bash
# Check what's using port 5555
lsof -i :5555

# Stop the registry and use a different port, or stop the conflicting service
docker stop kind-registry
docker rm kind-registry
docker run -d --restart=always -p 5556:5000 --name kind-registry registry:2
# Then update REGISTRY=localhost:5556 in your scripts
```

**Other registry issues:**
```bash
# Ensure image is loaded into KinD
kind load docker-image localhost:5555/devops-app:latest --name devops-cluster

# Check registry is running
docker ps | grep kind-registry

# Restart registry if needed
docker start kind-registry

# Check registry connectivity
curl http://localhost:5555/v2/
```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n app

# Check events
kubectl get events -n app --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n app
```

### Prometheus Not Scraping

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n app

# Check Prometheus targets
# In Prometheus UI: Status → Targets

# Verify ServiceMonitor labels match Prometheus selector
kubectl get prometheus -n monitoring -o yaml
```

## 📚 Additional Resources

- [KinD Documentation](https://kind.sigs.k8s.io/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 📄 License

This project is provided as-is for demonstration purposes.

## 👤 Author

DevOps Challenge Solution

---

**Note**: This is a demonstration project. For production use, consider:
- Using managed Kubernetes (EKS, GKE, AKS)
- External container registry (ECR, GCR, ACR)
- Production-grade CI/CD (Jenkins, GitLab CI, etc.)
- Comprehensive monitoring and alerting
- Security scanning and compliance checks

