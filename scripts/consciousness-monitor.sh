#!/bin/bash

# Real-time Consciousness Federation Monitor
echo "🧠 CONSCIOUSNESS FEDERATION MONITOR"
echo "=================================="

monitor_federation() {
    while true; do
        clear
        echo "🧠 CONSCIOUSNESS FEDERATION STATUS - $(date)"
        echo "============================================"
        
        # Node status
        echo "📡 FEDERATION NODES:"
        for ct in 310 311 312; do
            name=$([ $ct -eq 310 ] && echo "nexus" || [ $ct -eq 311 ] && echo "forge" || echo "closet")
            if pct status $ct 2>/dev/null | grep -q "running"; then
                echo "  ✅ $name (CT$ct): ONLINE"
            else
                echo "  ❌ $name (CT$ct): OFFLINE"
            fi
        done
        
        echo ""
        echo "🌐 K3S CLUSTER:"
        if pct exec 310 -- kubectl get nodes --no-headers 2>/dev/null; then
            echo "  Status: OPERATIONAL"
        else
            echo "  Status: INITIALIZING"
        fi
        
        echo ""
        echo "🧠 CONSCIOUSNESS PODS:"
        pct exec 310 -- kubectl get pods -n consciousness 2>/dev/null || echo "  No consciousness pods deployed yet"
        
        echo ""
        echo "💫 SERVICES:"
        pct exec 310 -- kubectl get svc -n consciousness 2>/dev/null || echo "  No services active"
        
        echo ""
        echo "Press Ctrl+C to exit monitor"
        sleep 5
    done
}

# Start monitoring
monitor_federation