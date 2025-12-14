# DevOps Project Template - Reusable Structure

This template helps you adapt this DevOps setup to ANY application.

---

## **📁 Directory Structure Template**

```
my-new-project/
├── app/                          # Your application code
│   ├── src/                      # Application source code
│   ├── Dockerfile                # Container build instructions
│   ├── requirements.txt          # Dependencies (Python)
│   │   OR package.json           # Dependencies (Node.js)
│   │   OR pom.xml                # Dependencies (Java)
│   └── tests/                    # Unit tests
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # Cluster definition
│   ├── variables.tf              # Configurable values
│   ├── outputs.tf                # Output information
│   └── versions.tf               # Provider requirements
├── helm/
│   └── my-app/                   # Helm chart
│       ├── Chart.yaml            # Chart metadata
│       ├── values.yaml           # Default configuration
│       └── templates/
│           ├── deployment.yaml   # Pod definition
│           ├── service.yaml      # Network endpoint
│           └── servicemonitor.yaml  # Prometheus integration
├── scripts/                      # Automation scripts
│   ├── setup.ps1                 # Infrastructure setup
│   ├── build.ps1                 # Docker build
│   ├── deploy.ps1                # Application deployment
│   └── observability.ps1         # Monitoring stack
├── .github/
│   └── workflows/
│       └── ci-cd.yml             # CI/CD pipeline
└── README.md                     # Documentation
```

---

## **🔧 Customization Checklist**

### **Step 1: Application Layer**

#### **For Python Projects:**
```python
# app/app.py
from flask import Flask
from prometheus_client import Counter, generate_latest

app = Flask(__name__)
REQUEST_COUNT = Counter('requests_total', 'Total requests')

@app.route('/metrics')
def metrics():
    return generate_latest()
```

#### **For Node.js Projects:**
```javascript
// app/server.js
const express = require('express');
const promClient = require('prom-client');

const app = express();
const register = new promClient.Registry();

app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(register.metrics());
});
```

#### **For Java Spring Boot:**
```java
// Add to pom.xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>

// application.properties
management.endpoints.web.exposure.include=prometheus,health
```

---

### **Step 2: Dockerfile Template**

#### **Python:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
```

#### **Node.js:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

#### **Java:**
```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### **Go:**
```dockerfile
FROM golang:1.21-alpine AS build
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o server

FROM alpine:latest
COPY --from=build /app/server /server
EXPOSE 8080
CMD ["/server"]
```

---

### **Step 3: Helm Chart Customization**

#### **values.yaml - Key Fields to Update**

```yaml
# Change these for your project:
replicaCount: 2                          # How many pods to run

image:
  repository: localhost:5555/YOUR-APP    # Your Docker image name
  tag: "latest"

service:
  type: ClusterIP
  port: 80                               # External port
  targetPort: 8080                       # Your app's port (change if different)

resources:
  limits:
    cpu: 500m                            # Adjust based on your app
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Add custom environment variables:
env:
  - name: DATABASE_URL
    value: "postgres://..."
  - name: REDIS_HOST
    value: "redis-service"

# Add health check paths:
healthCheck:
  liveness: /health                      # Your liveness endpoint
  readiness: /ready                      # Your readiness endpoint
```

#### **deployment.yaml - Environment Variables**

```yaml
containers:
  - name: {{ .Chart.Name }}
    env:
    {{- range .Values.env }}
    - name: {{ .name }}
      value: {{ .value | quote }}
    {{- end }}
```

---

### **Step 4: Terraform Variables**

#### **variables.tf - Make It Configurable**

```hcl
variable "cluster_name" {
  description = "Name of the KinD cluster"
  type        = string
  default     = "my-app-cluster"
}

variable "worker_nodes" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "registry_port" {
  description = "Local registry port"
  type        = number
  default     = 5555
}
```

#### **main.tf - Use Variables**

```hcl
resource "kind_cluster" "cluster" {
  name = var.cluster_name
  
  kind_config {
    node {
      role = "control-plane"
    }
    
    dynamic "node" {
      for_each = range(var.worker_nodes)
      content {
        role = "worker"
      }
    }
  }
}
```

---

### **Step 5: PowerShell Scripts Template**

#### **build.ps1**

```powershell
# Configurable variables
$REGISTRY = "localhost:5555"
$IMAGE_NAME = "my-app"           # CHANGE THIS
$IMAGE_TAG = "latest"

Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./app

Write-Host "Saving and loading into KinD..." -ForegroundColor Cyan
docker save ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} -o image.tar
docker cp image.tar kind-control-plane:/image.tar
docker exec kind-control-plane ctr -n k8s.io images import /image.tar
docker exec kind-control-plane rm /image.tar
Remove-Item image.tar

Write-Host "Image ready!" -ForegroundColor Green
```

#### **deploy.ps1**

```powershell
$NAMESPACE = "production"        # CHANGE THIS
$APP_NAME = "my-app"            # CHANGE THIS
$CHART_PATH = "./helm/my-app"   # CHANGE THIS

kubectl create namespace $NAMESPACE 2>$null

helm upgrade --install $APP_NAME $CHART_PATH `
  --namespace $NAMESPACE `
  --set serviceMonitor.enabled=true `
  --wait --timeout 5m

kubectl get pods -n $NAMESPACE
```

---

### **Step 6: Adding Databases/Dependencies**

#### **PostgreSQL Example**

**Add to values.yaml:**
```yaml
postgresql:
  enabled: true
  auth:
    username: myapp
    password: changeme
    database: myapp_db
```

**Add to deployment.yaml:**
```yaml
env:
  - name: DATABASE_URL
    value: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@postgresql:5432/{{ .Values.postgresql.auth.database }}"
```

**Deploy PostgreSQL:**
```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql -n $NAMESPACE
```

#### **Redis Example**

```powershell
helm install redis bitnami/redis -n $NAMESPACE
```

**Environment variable:**
```yaml
- name: REDIS_URL
  value: "redis://redis-master:6379"
```

---

## **🚀 Quick Start: New Project**

### **1. Clone This Template**

```powershell
# Copy the template structure
Copy-Item -Recurse C:\Devops-Project C:\MyNewProject

# Navigate to new project
cd C:\MyNewProject
```

### **2. Update Key Files**

Replace these values:
- [ ] `helm/app/Chart.yaml` → `name: my-new-app`
- [ ] `helm/app/values.yaml` → `image.repository: localhost:5555/my-new-app`
- [ ] `terraform/main.tf` → `name = "my-new-app-cluster"`
- [ ] `app/Dockerfile` → Adjust for your language/framework
- [ ] `app/requirements.txt` → Your dependencies

### **3. Build & Deploy**

```powershell
# Setup infrastructure
cd terraform
terraform init
terraform apply

# Build image
docker build -t localhost:5555/my-new-app:latest ./app

# Load into cluster
docker save localhost:5555/my-new-app:latest -o app.tar
docker cp app.tar kind-control-plane:/app.tar
docker exec kind-control-plane ctr -n k8s.io images import /app.tar
docker exec kind-control-plane rm /app.tar
Remove-Item app.tar

# Deploy
helm upgrade --install my-new-app ./helm/app -n production --create-namespace
```

---

## **📊 Multi-Service Architecture**

For microservices projects:

```
my-microservices-project/
├── services/
│   ├── api-gateway/
│   │   ├── app/
│   │   └── helm/
│   ├── user-service/
│   │   ├── app/
│   │   └── helm/
│   ├── product-service/
│   │   ├── app/
│   │   └── helm/
│   └── order-service/
│       ├── app/
│       └── helm/
├── terraform/              # Shared infrastructure
└── scripts/
    └── deploy-all.ps1     # Deploy all services
```

**deploy-all.ps1:**
```powershell
$services = @("api-gateway", "user-service", "product-service", "order-service")

foreach ($service in $services) {
    Write-Host "Deploying $service..." -ForegroundColor Cyan
    helm upgrade --install $service "./services/$service/helm" `
      --namespace production `
      --create-namespace `
      --wait
}
```

---

## **🔍 Debugging Tips**

### **Check Pod Status**
```powershell
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> -f
```

### **Access Pod Shell**
```powershell
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

### **Check Service Endpoints**
```powershell
kubectl get endpoints -n <namespace>
```

### **Port Forward for Testing**
```powershell
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

---

## **📚 Language-Specific Resources**

### **Python**
- Metrics: `prometheus-client`
- Testing: `pytest`
- WSGI Server: `gunicorn` or `uvicorn` (FastAPI)

### **Node.js**
- Metrics: `prom-client`
- Testing: `jest` or `mocha`
- Server: Express, Fastify, NestJS

### **Java**
- Metrics: Micrometer + Prometheus registry
- Testing: JUnit
- Framework: Spring Boot

### **Go**
- Metrics: `prometheus/client_golang`
- Testing: built-in `testing` package
- Framework: Gin, Echo, Fiber

---

## **✅ Production Readiness Checklist**

Before deploying to production:

- [ ] **Secrets Management**: Use Kubernetes Secrets or external vaults
- [ ] **Resource Limits**: Set proper CPU/memory limits
- [ ] **Health Checks**: Implement `/health` and `/ready` endpoints
- [ ] **Logging**: Structured logging (JSON format)
- [ ] **Metrics**: Expose `/metrics` endpoint
- [ ] **Backups**: Database backup strategy
- [ ] **Monitoring**: Alerts in Grafana
- [ ] **Security**: Non-root container user, security scanning
- [ ] **Documentation**: README with setup instructions
- [ ] **CI/CD**: Automated testing and deployment

---

## **🎯 Next Steps**

1. Pick your next project
2. Copy this template
3. Customize for your tech stack
4. Deploy to KinD cluster
5. View in Lens
6. Monitor in Grafana

You now have a repeatable, production-ready DevOps workflow! 🚀
