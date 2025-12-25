#!/bin/bash
# Deploy ELK Stack to Kubernetes

set -e

echo "==================================="
echo "Deploying ELK Stack to Kubernetes"
echo "==================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed"
    exit 1
fi

# Create namespace if it doesn't exist
NAMESPACE="${NAMESPACE:-default}"
echo "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy ELK stack
echo "Deploying ELK Stack..."
helm upgrade --install elk-stack ./helm/elk \
  --namespace $NAMESPACE \
  --create-namespace \
  --wait \
  --timeout 10m

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE --timeout=300s

echo ""
echo "==================================="
echo "ELK Stack Deployment Status"
echo "==================================="

# Get pod status
kubectl get pods -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE

# Get service endpoints
echo ""
echo "Service Endpoints:"
kubectl get svc -l app.kubernetes.io/name=elk-stack --namespace $NAMESPACE

echo ""
echo "==================================="
echo "Access Information"
echo "==================================="

# Get Kibana service details
KIBANA_SERVICE=$(kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.spec.type}')

if [ "$KIBANA_SERVICE" == "LoadBalancer" ]; then
    echo "Kibana is available via LoadBalancer"
    echo "Waiting for external IP..."
    kubectl get svc kibana --namespace $NAMESPACE -w &
    sleep 10
    KIBANA_IP=$(kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$KIBANA_IP" ]; then
        echo "Kibana URL: http://$KIBANA_IP:5601"
    else
        echo "LoadBalancer IP not yet assigned. Check with: kubectl get svc kibana -n $NAMESPACE"
    fi
elif [ "$KIBANA_SERVICE" == "NodePort" ]; then
    NODE_PORT=$(kubectl get svc kibana --namespace $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    echo "Kibana URL: http://$NODE_IP:$NODE_PORT"
else
    echo "To access Kibana, run:"
    echo "  kubectl port-forward svc/kibana 5601:5601 --namespace $NAMESPACE"
    echo "  Then visit: http://localhost:5601"
fi

echo ""
echo "Elasticsearch endpoint: http://elasticsearch:9200 (within cluster)"
echo "Logstash endpoint: logstash:5000 (within cluster)"

echo ""
echo "==================================="
echo "Next Steps"
echo "==================================="
echo "1. Access Kibana UI using the URL above"
echo "2. Create index pattern: Management → Index Patterns → Create (use 'logs-*')"
echo "3. Deploy your application to send logs to Logstash"
echo "4. View logs in Kibana Discover section"
echo ""
echo "To check logs:"
echo "  kubectl logs -l app.kubernetes.io/component=elasticsearch --namespace $NAMESPACE"
echo "  kubectl logs -l app.kubernetes.io/component=logstash --namespace $NAMESPACE"
echo "  kubectl logs -l app.kubernetes.io/component=kibana --namespace $NAMESPACE"
