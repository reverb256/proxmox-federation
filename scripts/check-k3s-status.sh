#!/bin/bash

# Quick K3s Status Check
echo "🔍 K3s Federation Status Check"
echo "============================="

# Check containers
for ct in 310 311 312; do
    if pct status $ct >/dev/null 2>&1; then
        status=$(pct status $ct | awk '{print $2}')
        echo "CT$ct: $status"
        
        if [ "$status" = "running" ]; then
            # Check K3s services
            if pct exec $ct -- systemctl is-active k3s >/dev/null 2>&1; then
                echo "  K3s: master (active)"
            elif pct exec $ct -- systemctl is-active k3s-agent >/dev/null 2>&1; then
                echo "  K3s: agent (active)"
            else
                echo "  K3s: inactive"
            fi
        fi
    else
        echo "CT$ct: not found"
    fi
done

echo ""
echo "🌐 Cluster Status:"
if pct exec 310 -- kubectl get nodes 2>/dev/null; then
    echo "✅ Cluster operational"
else
    echo "⏳ Cluster not ready"
fi