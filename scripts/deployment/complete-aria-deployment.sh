#!/bin/bash

# Complete Aria Deployment - Secrets + Services
echo "🎭 Complete Aria System Deployment"

# Step 1: Setup secrets management
echo "Setting up secrets management..."
./setup-aria-secrets.sh

# Step 2: Wait for K3s to be fully ready
echo "Waiting for K3s cluster to be ready..."
while ! pct exec 310 -- kubectl get nodes >/dev/null 2>&1; do
    echo "K3s not ready yet, waiting..."
    sleep 30
done

# Step 3: Deploy Aria services
echo "Deploying Aria services to K3s..."
./deploy-aria-services.sh

# Step 4: Get system information
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')

echo ""
echo "🎉 Aria Personal Trading System Deployed Successfully!"
echo ""
echo "System Access:"
echo "  Dashboard: http://$MASTER_IP:30080"
echo "  K3s Master: $MASTER_IP"
echo ""
echo "Configuration:"
echo "  Use 'aria-secrets setup-trading' to configure API keys"
echo "  Use 'aria-secrets list' to view configured secrets"
echo ""
echo "Container Status:"
pct list | grep -E "(310|311|312)"
echo ""
echo "K3s Cluster:"
pct exec 310 -- kubectl get nodes
echo ""
echo "Deployed Services:"
pct exec 310 -- kubectl get pods
pct exec 310 -- kubectl get services