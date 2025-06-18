#!/bin/bash

# Deploy Aria Services to K3s Cluster
echo "🎭 Deploying Aria Services to K3s Cluster"

# Wait for K3s to be fully ready
echo "Waiting for K3s cluster to be ready..."
sleep 60

# Get master node IP
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')
echo "Master node IP: $MASTER_IP"

# Deploy dashboard
echo "Deploying Aria Dashboard..."
pct exec 310 -- kubectl apply -f - <<EOF
$(cat aria-dashboard.yaml)
EOF

# Deploy trading agent
echo "Deploying Trading Agent..."
pct exec 310 -- kubectl apply -f - <<EOF
$(cat aria-trading-agent.yaml)
EOF

# Check deployment status
echo "Checking deployment status..."
pct exec 310 -- kubectl get pods
pct exec 310 -- kubectl get services

echo ""
echo "🎉 Aria System Deployed!"
echo "Dashboard URL: http://$MASTER_IP:30080"
echo ""
echo "Next steps:"
echo "1. Access dashboard at http://$MASTER_IP:30080"
echo "2. Use 'aria-secrets' command to configure API keys"
echo "3. Configure trading strategies through the dashboard"