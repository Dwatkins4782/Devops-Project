# DevOps Project - Complete Setup for Windows
# This script runs all steps: infrastructure, build, deploy, observability

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DevOps Project - Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Infrastructure Setup
Write-Host "Step 1/4: Creating KinD cluster with Terraform..." -ForegroundColor Yellow
Write-Host ""

cd terraform
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform init failed" -ForegroundColor Red
    exit 1
}

terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform apply failed" -ForegroundColor Red
    exit 1
}
cd ..

Write-Host ""
Write-Host "[OK] KinD cluster created successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Configure kubectl
Write-Host "Step 2/4: Configuring kubectl..." -ForegroundColor Yellow
kind export kubeconfig --name devops-cluster
Write-Host "[OK] kubectl configured" -ForegroundColor Green
Write-Host ""

# Step 3a: Setup local Docker registry
Write-Host "Step 3a/5: Setting up local Docker registry..." -ForegroundColor Yellow
$REGISTRY = "localhost:5555"
$IMAGE_NAME = "devops-app"
$IMAGE_TAG = "latest"

# Check if registry container exists
$registryExists = docker ps -a --filter "name=kind-registry" --format "{{.Names}}" 2>$null
if ($registryExists -eq "kind-registry") {
    # Start if stopped
    $registryRunning = docker ps --filter "name=kind-registry" --format "{{.Names}}" 2>$null
    if ($registryRunning -ne "kind-registry") {
        Write-Host "Starting existing registry container..." -ForegroundColor Yellow
        docker start kind-registry
    } else {
        Write-Host "Registry already running" -ForegroundColor Green
    }
} else {
    # Create new registry (host port 5555 maps to container port 5000)
    Write-Host "Creating new registry container..." -ForegroundColor Yellow
    docker run -d --restart=always -p 5555:5000 --name kind-registry registry:2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create registry" -ForegroundColor Red
        exit 1
    }
    Start-Sleep -Seconds 3
}

# Connect registry to kind network
Write-Host "Connecting registry to KinD network..." -ForegroundColor Yellow
docker network connect kind kind-registry 2>$null
# Ignore error if already connected

Write-Host "[OK] Registry ready at localhost:5555" -ForegroundColor Green
Write-Host ""

# Step 3b: Build and push image
Write-Host "Step 3b/5: Building Docker image..." -ForegroundColor Yellow

docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./app
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Pushing image to local registry..." -ForegroundColor Yellow
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} 2>&1 | Out-Null
$pushSuccess = $LASTEXITCODE -eq 0

if (-not $pushSuccess) {
    Write-Host "Warning: Could not push to registry (may need insecure-registries config)" -ForegroundColor Yellow
    Write-Host "Falling back to direct image loading..." -ForegroundColor Yellow
    kind load docker-image ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} --name devops-cluster
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to load image into KinD" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Image pushed to registry" -ForegroundColor Green
}

Write-Host "[OK] Image built and available to cluster" -ForegroundColor Green
Write-Host ""

# Step 4a: Deploy Observability Stack
Write-Host "Step 4a/5: Deploying Prometheus + Grafana..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring 2>$null
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
  --set prometheus.prometheusSpec.maximumStartupDurationSeconds=300 `
  --set grafana.service.type=NodePort `
  --set grafana.service.nodePort=30000 `
  --wait --timeout 10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Observability deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Observability stack deployed" -ForegroundColor Green
Write-Host ""

# Step 4b: Deploy Application
Write-Host "Step 4b/5: Deploying Flask application..." -ForegroundColor Yellow
kubectl create namespace app 2>$null
helm upgrade --install devops-app ./helm/app `
  --namespace app `
  --set image.repository=${REGISTRY}/${IMAGE_NAME} `
  --set image.tag=${IMAGE_TAG} `
  --set serviceMonitor.enabled=true `
  --wait --timeout 5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Application deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Application deployed" -ForegroundColor Green
Write-Host ""

# Verify deployment
Write-Host "Step 5/5: Verifying deployment..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/devops-app -n app
kubectl get pods -n app
kubectl get svc -n app

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n app svc/devops-app 8080:80" -ForegroundColor White
Write-Host "  Then visit: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "Access Grafana:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" -ForegroundColor White
Write-Host "  Then visit: http://localhost:3000" -ForegroundColor White
Write-Host "  Credentials: admin / prom-operator" -ForegroundColor White
Write-Host ""
Write-Host "Access Prometheus:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090" -ForegroundColor White
Write-Host "  Then visit: http://localhost:9090" -ForegroundColor White
Write-Host ""
