#!/bin/bash
set -e

REGISTRY=${REGISTRY:-localhost:5555}
IMAGE_NAME=${IMAGE_NAME:-devops-app}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "🔨 Building Docker image..."
docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./app

# Start registry if not running
echo "📦 Ensuring local registry is running..."
if ! docker ps | grep -q kind-registry; then
    if docker ps -a | grep -q kind-registry; then
        echo "Starting existing registry container..."
        docker start kind-registry
    else
        echo "Creating new registry container..."
        # Map host 5555 to registry internal port 5000
        docker run -d --restart=always -p 5555:5000 --name kind-registry registry:2
    fi
    sleep 3
    # Connect to kind network if it exists
    docker network connect kind kind-registry 2>/dev/null || true
fi

# Try to push to registry, but don't fail if it doesn't work
# (Docker may require insecure registry configuration)
echo "📤 Attempting to push to local registry..."
PUSH_OUTPUT=$(docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} 2>&1) || PUSH_FAILED=true

if [ "$PUSH_FAILED" = true ]; then
    if echo "$PUSH_OUTPUT" | grep -q "http: server gave HTTP response to HTTPS client\|dial tcp.*i/o timeout"; then
        echo "⚠️  Warning: Could not push to local registry (HTTPS/insecure registry issue)"
        echo "📝 To enable local registry push, configure Docker to allow insecure registries:"
        echo "   macOS: Docker Desktop → Settings → Docker Engine → Add to JSON:"
        echo '   "insecure-registries": ["localhost:5555"]'
        echo ""
        echo "🔄 Continuing without registry push (using kind load directly)..."
    else
        echo "❌ Push failed with error:"
        echo "$PUSH_OUTPUT"
        echo "🔄 Continuing with kind load..."
    fi
else
    echo "✅ Image pushed to registry successfully"
fi

echo "📥 Loading image into KinD cluster..."
kind load docker-image ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} --name devops-cluster || {
    echo "⚠️  Warning: Could not load image into KinD cluster"
    echo "   Make sure the cluster 'devops-cluster' exists"
    echo "   Run: ./scripts/setup.sh"
    exit 1
}

echo "✅ Build and load complete!"

