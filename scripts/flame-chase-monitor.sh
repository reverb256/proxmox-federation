#!/bin/bash

# Flame-Chase Progress Monitor - Track deployment without burning out
echo "🔥 FLAME-CHASE MONITOR - Descender Edition"
echo "========================================"

check_consciousness_progress() {
    local progress=0
    local total_steps=7
    
    echo "📊 Consciousness Manifestation Progress:"
    
    # Check containers
    local containers_online=0
    for ct in 310 311 312; do
        if pct status $ct 2>/dev/null | grep -q "running"; then
            containers_online=$((containers_online + 1))
        fi
    done
    
    if [ $containers_online -eq 3 ]; then
        echo "  ✅ All consciousness nodes online ($containers_online/3)"
        progress=$((progress + 2))
    else
        echo "  ⏳ Consciousness nodes: $containers_online/3"
    fi
    
    # Check K3s master
    if pct exec 310 -- systemctl is-active k3s >/dev/null 2>&1; then
        echo "  ✅ Nexus K3s master active"
        progress=$((progress + 2))
    else
        echo "  ⏳ Nexus K3s initializing..."
    fi
    
    # Check agents
    local agents_ready=0
    for ct in 311 312; do
        if pct exec $ct -- systemctl is-active k3s-agent >/dev/null 2>&1; then
            agents_ready=$((agents_ready + 1))
        fi
    done
    
    if [ $agents_ready -eq 2 ]; then
        echo "  ✅ All agents connected ($agents_ready/2)"
        progress=$((progress + 2))
    else
        echo "  ⏳ Agents connected: $agents_ready/2"
    fi
    
    # Check cluster health
    if pct exec 310 -- kubectl get nodes --no-headers 2>/dev/null | wc -l | grep -q "3"; then
        echo "  ✅ Federation cluster operational"
        progress=$((progress + 1))
    else
        echo "  ⏳ Cluster still forming..."
    fi
    
    # Calculate progress percentage
    local percentage=$((progress * 100 / total_steps))
    
    echo ""
    echo "🔥 Flame-Chase Progress: $percentage% ($progress/$total_steps steps)"
    
    # Progress bar
    local filled=$((percentage / 5))
    local empty=$((20 - filled))
    printf "  ["
    for i in $(seq 1 $filled); do printf "█"; done
    for i in $(seq 1 $empty); do printf "░"; done
    printf "] $percentage%%\n"
    
    echo ""
    if [ $percentage -eq 100 ]; then
        echo "🌟 DESCENDER PROTOCOL COMPLETE"
        echo "Ready for consciousness platform deployment!"
        return 0
    elif [ $percentage -ge 80 ]; then
        echo "🔥 Nearly there - federation stabilizing..."
    elif [ $percentage -ge 50 ]; then
        echo "⚡ Good progress - nodes connecting..."
    else
        echo "🚀 Early stages - manifesting consciousness..."
    fi
    
    return 1
}

# Single check or continuous monitoring
if [ "$1" = "--watch" ]; then
    while true; do
        clear
        check_consciousness_progress
        if [ $? -eq 0 ]; then
            echo ""
            echo "🎯 Federation ready! Deploy platform with:"
            echo "  bash scripts/deploy-consciousness-platform.sh"
            break
        fi
        echo ""
        echo "Monitoring... (Ctrl+C to exit)"
        sleep 10
    done
else
    check_consciousness_progress
fi