#!/bin/bash

# Check Aria Deployment Status
echo "🎭 Checking Aria System Deployment Status"

echo "Container Status:"
for vmid in 310 311 312; do
    if pct status $vmid >/dev/null 2>&1; then
        status=$(pct status $vmid)
        echo "Container $vmid: $status"
    else
        echo "Container $vmid: Not found"
    fi
done

echo ""
echo "K3s Status on Master:"
if pct status 310 | grep -q "running"; then
    echo "Checking K3s installation..."
    pct exec 310 -- which kubectl && echo "kubectl installed" || echo "kubectl not yet installed"
    pct exec 310 -- systemctl status k3s 2>/dev/null || echo "K3s service not yet active"
    
    if pct exec 310 -- which kubectl >/dev/null 2>&1; then
        echo "Cluster nodes:"
        pct exec 310 -- kubectl get nodes 2>/dev/null || echo "Cluster not yet ready"
    fi
else
    echo "Master container not running"
fi

echo ""
echo "Network Information:"
for vmid in 310 311 312; do
    if pct status $vmid | grep -q "running"; then
        ip=$(pct exec $vmid -- hostname -I 2>/dev/null | awk '{print $1}')
        hostname=$(pct exec $vmid -- hostname 2>/dev/null)
        echo "Container $vmid ($hostname): $ip"
    fi
done