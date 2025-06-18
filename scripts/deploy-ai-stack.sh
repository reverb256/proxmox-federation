#!/bin/bash
# Deploy AI stack to Talos/Kubernetes
# Usage: ./scripts/deploy-ai-stack.sh <your-registry>

set -euo pipefail

REGISTRY=${1:-"your-registry"}
NAMESPACE=consciousness-federation

# Build and push Node.js Void Proxy image

echo "[1/5] Building Node.js Void Proxy image..."
docker build -t $REGISTRY/void-proxy:latest .
echo "[2/5] Pushing Node.js Void Proxy image..."
docker push $REGISTRY/void-proxy:latest

# Build and push Python LLM Proxy image

echo "[3/5] Building Python LLM Proxy image..."
cd llm-proxy
docker build -t $REGISTRY/llm-proxy:latest .
echo "[4/5] Pushing Python LLM Proxy image..."
docker push $REGISTRY/llm-proxy:latest
cd ..

# Deploy NVIDIA device plugin

echo "[5/5] Deploying NVIDIA device plugin to Kubernetes..."
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.15.0/nvidia-device-plugin.yml

# Apply Kubernetes manifests

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/llm-proxy-deployment.yaml
kubectl apply -f k8s/void-proxy-deployment.yaml

echo "Deployment complete! Check pod and service status with:"
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl get svc -n $NAMESPACE"
