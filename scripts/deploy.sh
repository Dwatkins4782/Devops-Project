#!/bin/bash
set -e

REGISTRY=${REGISTRY:-localhost:5555}
IMAGE_NAME=${IMAGE_NAME:-devops-app}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "🚀 Deploying application to Kubernetes..."

# Create namespace
kubectl create namespace app || true

# Deploy using Helm
helm upgrade --install devops-app ./helm/app \
  --namespace app \
  --set image.repository=${REGISTRY}/${IMAGE_NAME} \
  --set image.tag=${IMAGE_TAG} \
  --set serviceMonitor.enabled=true \
  --wait --timeout 5m

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/devops-app -n app

echo "✅ Application deployed!"
echo ""
echo "To access the application:"
echo "  kubectl port-forward -n app svc/devops-app 8080:80"
echo "  Then visit: http://localhost:8080"

