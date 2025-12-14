# New Project Generator
# Creates a new DevOps project based on this template

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("python", "nodejs", "java", "go")]
    [string]$Language = "python",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = "C:\"
)

$ProjectPath = Join-Path $TargetPath $ProjectName

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  DevOps Project Generator" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project: $ProjectName" -ForegroundColor Yellow
Write-Host "Language: $Language" -ForegroundColor Yellow
Write-Host "Location: $ProjectPath" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$ProjectPath\app" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectPath\terraform" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectPath\helm\$ProjectName\templates" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectPath\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectPath\.github\workflows" -Force | Out-Null

# Copy Terraform files (language-agnostic)
Write-Host "Setting up Terraform..." -ForegroundColor Cyan
Copy-Item ".\terraform\*" "$ProjectPath\terraform\" -Recurse

# Update cluster name in main.tf
$mainTf = Get-Content "$ProjectPath\terraform\main.tf" -Raw
$mainTf = $mainTf -replace 'name\s*=\s*"devops-cluster"', "name = `"$ProjectName-cluster`""
Set-Content "$ProjectPath\terraform\main.tf" $mainTf

# Create Helm chart
Write-Host "Creating Helm chart..." -ForegroundColor Cyan
Copy-Item ".\helm\app\*" "$ProjectPath\helm\$ProjectName\" -Recurse

# Update Chart.yaml
$chartYaml = @"
apiVersion: v2
name: $ProjectName
description: A Helm chart for $ProjectName
type: application
version: 0.1.0
appVersion: "1.0.0"
"@
Set-Content "$ProjectPath\helm\$ProjectName\Chart.yaml" $chartYaml

# Update values.yaml
$valuesContent = Get-Content "$ProjectPath\helm\$ProjectName\values.yaml" -Raw
$valuesContent = $valuesContent -replace 'repository:\s*localhost:5555/devops-app', "repository: localhost:5555/$ProjectName"
Set-Content "$ProjectPath\helm\$ProjectName\values.yaml" $valuesContent

# Create language-specific app files
Write-Host "Creating $Language application template..." -ForegroundColor Cyan

switch ($Language) {
    "python" {
        # app.py
        $appPy = @'
#!/usr/bin/env python3
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import os

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])

@app.route('/')
def index():
    with REQUEST_DURATION.labels(method='GET', endpoint='/').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
        return jsonify({
            'message': 'Welcome to ''' + $ProjectName + @'''',
            'status': 'healthy'
        })

@app.route('/health')
def health():
    with REQUEST_DURATION.labels(method='GET', endpoint='/health').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='200').inc()
        return jsonify({'status': 'healthy', 'timestamp': time.time()})

@app.route('/metrics')
def metrics():
    REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
'@
        Set-Content "$ProjectPath\app\app.py" $appPy

        # requirements.txt
        $requirements = @"
Flask==3.0.0
prometheus-client==0.19.0
gunicorn==21.2.0
pytest==7.4.3
"@
        Set-Content "$ProjectPath\app\requirements.txt" $requirements

        # Dockerfile
        $dockerfile = @"
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "30", "app:app"]
"@
        Set-Content "$ProjectPath\app\Dockerfile" $dockerfile
    }
    
    "nodejs" {
        # server.js
        $serverJs = @"
const express = require('express');
const promClient = require('prom-client');

const app = express();
const register = new promClient.Registry();

// Prometheus metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'endpoint', 'status'],
  registers: [register]
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'endpoint'],
  registers: [register]
});

app.get('/', (req, res) => {
  const end = httpRequestDuration.labels('GET', '/').startTimer();
  httpRequestsTotal.labels('GET', '/', '200').inc();
  res.json({ message: 'Welcome to $ProjectName', status: 'healthy' });
  end();
});

app.get('/health', (req, res) => {
  const end = httpRequestDuration.labels('GET', '/health').startTimer();
  httpRequestsTotal.labels('GET', '/health', '200').inc();
  res.json({ status: 'healthy', timestamp: Date.now() });
  end();
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});
"@
        Set-Content "$ProjectPath\app\server.js" $serverJs

        # package.json
        $packageJson = @"
{
  "name": "$ProjectName",
  "version": "1.0.0",
  "description": "$ProjectName service",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^15.0.0"
  },
  "devDependencies": {
    "jest": "^29.7.0"
  }
}
"@
        Set-Content "$ProjectPath\app\package.json" $packageJson

        # Dockerfile
        $dockerfile = @"
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
"@
        Set-Content "$ProjectPath\app\Dockerfile" $dockerfile
    }
}

# Create PowerShell scripts
Write-Host "Creating automation scripts..." -ForegroundColor Cyan

# build.ps1
$buildScript = @"
`$REGISTRY = "localhost:5555"
`$IMAGE_NAME = "$ProjectName"
`$IMAGE_TAG = "latest"

Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t `${REGISTRY}/`${IMAGE_NAME}:`${IMAGE_TAG} ./app

Write-Host "Loading into KinD cluster..." -ForegroundColor Cyan
docker save `${REGISTRY}/`${IMAGE_NAME}:`${IMAGE_TAG} -o image.tar
docker cp image.tar $ProjectName-cluster-control-plane:/image.tar
docker exec $ProjectName-cluster-control-plane ctr -n k8s.io images import /image.tar
docker exec $ProjectName-cluster-control-plane rm /image.tar
Remove-Item image.tar

Write-Host "✓ Image ready!" -ForegroundColor Green
"@
Set-Content "$ProjectPath\scripts\build.ps1" $buildScript

# deploy.ps1
$deployScript = @"
`$NAMESPACE = "production"
`$APP_NAME = "$ProjectName"
`$HELM_PATH = "C:\Users\davon\AppData\Local\Microsoft\WinGet\Packages\Helm.Helm_Microsoft.Winget.Source_8wekyb3d8bbwe\windows-amd64\helm.exe"

kubectl create namespace `$NAMESPACE 2>`$null

& `$HELM_PATH upgrade --install `$APP_NAME ./helm/$ProjectName ``
  --namespace `$NAMESPACE ``
  --set serviceMonitor.enabled=true ``
  --wait --timeout 5m

kubectl get pods -n `$NAMESPACE
"@
Set-Content "$ProjectPath\scripts\deploy.ps1" $deployScript

# setup.ps1
$setupScript = @"
Write-Host "Setting up $ProjectName cluster..." -ForegroundColor Cyan

cd terraform
terraform init
terraform apply -auto-approve
cd ..

kind export kubeconfig --name $ProjectName-cluster

Write-Host "✓ Cluster ready!" -ForegroundColor Green
"@
Set-Content "$ProjectPath\scripts\setup.ps1" $setupScript

# Create README
Write-Host "Creating README..." -ForegroundColor Cyan
$readme = @"
# $ProjectName

Generated using DevOps Project Template

## Quick Start

### 1. Setup Infrastructure
``````powershell
cd scripts
.\setup.ps1
``````

### 2. Build Application
``````powershell
.\build.ps1
``````

### 3. Deploy Application
``````powershell
.\deploy.ps1
``````

### 4. Access Application
``````powershell
kubectl port-forward -n production svc/$ProjectName 8080:80
``````

Visit: http://localhost:8080

## Endpoints

- `/` - Main endpoint
- `/health` - Health check
- `/metrics` - Prometheus metrics

## Monitoring

Deploy observability stack:
``````powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack ``
  --namespace monitoring ``
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
``````

Access Grafana:
``````powershell
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
``````

## Cleanup

``````powershell
cd terraform
terraform destroy -auto-approve
``````
"@
Set-Content "$ProjectPath\README.md" $readme

Write-Host ""
Write-Host "✓ Project created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd $ProjectPath" -ForegroundColor White
Write-Host "2. cd scripts" -ForegroundColor White
Write-Host "3. .\setup.ps1" -ForegroundColor White
Write-Host "4. .\build.ps1" -ForegroundColor White
Write-Host "5. .\deploy.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: $ProjectPath\README.md" -ForegroundColor Cyan
Write-Host ""
