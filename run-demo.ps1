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

# Step 3: Build and push image
Write-Host "Step 3/4: Building Docker image..." -ForegroundColor Yellow
$REGISTRY = "localhost:5555"
$IMAGE_NAME = "devops-app"
$IMAGE_TAG = "latest"

docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./app
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Loading image into KinD cluster..." -ForegroundColor Yellow
kind load docker-image ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} --name devops-cluster
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to load image into KinD" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Image built and loaded" -ForegroundColor Green
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
