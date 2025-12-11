#!/bin/bash
set -e

echo "🧹 Tearing down environment..."

# Delete Helm releases
echo "Removing Helm releases..."
helm uninstall devops-app -n app || true
helm uninstall prometheus -n monitoring || true

# Delete namespaces
kubectl delete namespace app || true
kubectl delete namespace monitoring || true

# Destroy Terraform infrastructure
echo "Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve || true
cd ..

# Stop and remove local registry
echo "Removing local registry..."
docker stop kind-registry 2>/dev/null || true
docker rm kind-registry 2>/dev/null || true

echo "✅ Teardown complete!"

