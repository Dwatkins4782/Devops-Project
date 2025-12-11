#!/bin/bash
set -e

echo "🚀 Setting up DevOps Challenge Environment"

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v kind >/dev/null 2>&1 || { echo "❌ KinD is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is required but not installed. Aborting." >&2; exit 1; }

echo "✅ All prerequisites met"

# Initialize and apply Terraform
echo "🏗️  Creating KinD cluster with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Start local registry if not running
echo "📦 Setting up local container registry..."
docker start kind-registry 2>/dev/null || docker run -d --restart=always -p 5000:5000 --name kind-registry registry:2
sleep 2

# Connect registry to kind network
docker network connect kind kind-registry 2>/dev/null || true

# Configure kubectl to use the cluster
KUBECONFIG_PATH=$(terraform -chdir=terraform output -raw kubeconfig_path)
export KUBECONFIG=${KUBECONFIG_PATH}

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Build and push the application: ./scripts/build-and-push.sh"
echo "2. Deploy the application: ./scripts/deploy.sh"
echo "3. Deploy observability: ./scripts/deploy-observability.sh"

