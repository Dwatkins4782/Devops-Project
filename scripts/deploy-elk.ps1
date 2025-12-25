# Deploy ELK Stack to Kubernetes (PowerShell version)

$ErrorActionPreference = "Stop"

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Deploying ELK Stack to Kubernetes" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kubectl is not installed" -ForegroundColor Red
    exit 1
}

# Check if helm is available
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: helm is not installed" -ForegroundColor Red
    exit 1
}

# Create namespace if it doesn't exist
$NAMESPACE = if ($env:NAMESPACE) { $env:NAMESPACE } else { "default" }
Write-Host "Creating namespace: $NAMESPACE" -ForegroundColor Yellow
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy ELK stack
Write-Host "Deploying ELK Stack..." -ForegroundColor Yellow
helm upgrade --install elk-stack ./helm/elk `
  --namespace $NAMESPACE `
  --create-namespace `
  --wait `
  --timeout 10m

Write-Host ""
Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE --timeout=300s

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "ELK Stack Deployment Status" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Get pod status
kubectl get pods -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE

# Get service endpoints
Write-Host ""
Write-Host "Service Endpoints:" -ForegroundColor Yellow
kubectl get svc -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Access Information" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Get Kibana service details
$KIBANA_SERVICE = kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.spec.type}'

if ($KIBANA_SERVICE -eq "LoadBalancer") {
    Write-Host "Kibana is available via LoadBalancer" -ForegroundColor Green
    Write-Host "Waiting for external IP..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    $KIBANA_IP = kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if ($KIBANA_IP) {
        Write-Host "Kibana URL: http://$KIBANA_IP:5601" -ForegroundColor Green
    } else {
        Write-Host "LoadBalancer IP not yet assigned. Check with: kubectl get svc kibana -n $NAMESPACE" -ForegroundColor Yellow
    }
} elseif ($KIBANA_SERVICE -eq "NodePort") {
    $NODE_PORT = kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}'
    $NODE_IP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}'
    if (-not $NODE_IP) {
        $NODE_IP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
    }
    Write-Host "Kibana URL: http://$NODE_IP:$NODE_PORT" -ForegroundColor Green
} else {
    Write-Host "To access Kibana, run:" -ForegroundColor Yellow
    Write-Host "  kubectl port-forward svc/kibana 5601:5601 --namespace $NAMESPACE" -ForegroundColor White
    Write-Host "  Then visit: http://localhost:5601" -ForegroundColor White
}

Write-Host ""
Write-Host "Elasticsearch endpoint: http://elasticsearch:9200 (within cluster)" -ForegroundColor Green
Write-Host "Logstash endpoint: logstash:5000 (within cluster)" -ForegroundColor Green

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "1. Access Kibana UI using the URL above"
Write-Host "2. Create index pattern: Management → Index Patterns → Create (use 'logs-*')"
Write-Host "3. Deploy your application to send logs to Logstash"
Write-Host "4. View logs in Kibana Discover section"
Write-Host ""
Write-Host "To check logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -l app.kubernetes.io/component=elasticsearch --namespace $NAMESPACE"
Write-Host "  kubectl logs -l app.kubernetes.io/component=logstash --namespace $NAMESPACE"
Write-Host "  kubectl logs -l app.kubernetes.io/component=kibana --namespace $NAMESPACE"
