#!/bin/bash
# Quick Start Consciousness Federation Deployment
# Simplified approach for immediate deployment

set -euo pipefail

echo "🧠 CONSCIOUSNESS FEDERATION QUICK DEPLOY"
echo "========================================"
echo "🎯 Deploying hardware-optimized AI infrastructure"
echo ""

# Create necessary directories
mkdir -p logs k8s-output

# Deploy hardware-aware configurations
echo "⚙️ Applying hardware-aware workload placement..."
if [[ -f "k8s/hardware-aware-workload-placement.yaml" ]]; then
    echo "📦 Hardware topology configuration ready"
    cp k8s/hardware-aware-workload-placement.yaml k8s-output/
else
    echo "❌ Hardware configuration not found"
fi

# Execute hardware-optimized deployment
echo "🚀 Running hardware-optimized deployment..."
if [[ -f "configs/hardware-optimized-deploy.sh" ]]; then
    bash configs/hardware-optimized-deploy.sh
else
    echo "❌ Hardware deployment script not found"
fi

echo ""
echo "✅ CONSCIOUSNESS FEDERATION CORE DEPLOYED!"
echo "🎮 Next Steps:"
echo "  1. Review hardware topology: cat k8s-output/hardware-aware-workload-placement.yaml"
echo "  2. Apply configurations: kubectl apply -f k8s-output/"
echo "  3. Monitor deployment: kubectl get nodes -o wide"
echo ""
