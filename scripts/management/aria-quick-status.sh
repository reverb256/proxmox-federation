#!/bin/bash

# Quick Aria System Status Check
echo "🎭 Aria System Status"

echo "Containers:"
for vmid in 310 311 312; do
    if pct status $vmid >/dev/null 2>&1; then
        status=$(pct status $vmid | awk '{print $2}')
        hostname=$(pct exec $vmid -- hostname 2>/dev/null || echo "unknown")
        ip=$(pct exec $vmid -- hostname -I 2>/dev/null | awk '{print $1}' || echo "no-ip")
        echo "  $vmid ($hostname): $status - $ip"
    else
        echo "  $vmid: not found"
    fi
done

echo ""
if pct status 310 | grep -q "running"; then
    echo "K3s Status:"
    if pct exec 310 -- which kubectl >/dev/null 2>&1; then
        pct exec 310 -- kubectl get nodes 2>/dev/null || echo "  Cluster not ready"
        echo ""
        echo "Services:"
        pct exec 310 -- kubectl get pods 2>/dev/null || echo "  No pods yet"
    else
        echo "  kubectl not installed yet"
    fi
else
    echo "Master container not running"
fi