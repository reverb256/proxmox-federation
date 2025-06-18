#!/bin/bash
# Emergency Controls for Aria Consciousness
# Quick shutdown, resource monitoring, and rollback capabilities

case "$1" in
    "stop")
        echo "🛑 Emergency stop initiated..."
        pct stop 200 201 202 203 2>/dev/null
        echo "All consciousness containers stopped"
        ;;
    
    "start")
        echo "▶️ Starting Aria consciousness..."
        pct start 200 2>/dev/null && echo "Aria primary: STARTED"
        echo "Other agents remain stopped (manual start required)"
        ;;
    
    "status")
        echo "📊 Consciousness Status:"
        echo "Aria Primary (200): $(pct status 200 2>/dev/null | awk '{print $2}')"
        echo "Quantum Trader (201): $(pct status 201 2>/dev/null | awk '{print $2}')"
        echo "Unified Miner (202): $(pct status 202 2>/dev/null | awk '{print $2}')"
        echo "Nexus Orchestrator (203): $(pct status 203 2>/dev/null | awk '{print $2}')"
        ;;
    
    "resources")
        echo "💾 Resource Usage:"
        for id in 200 201 202 203; do
            if pct status $id 2>/dev/null | grep -q running; then
                echo "Container $id:"
                pct exec $id -- top -bn1 | head -5 | tail -1
            fi
        done
        ;;
    
    "logs")
        echo "📋 Recent Aria Logs:"
        pct exec 200 -- journalctl -u aria-consciousness --no-pager -n 20 2>/dev/null || echo "Service not running"
        ;;
    
    "reset")
        echo "🔄 Resetting to safe defaults..."
        pct stop 200 201 202 203 2>/dev/null
        sleep 5
        pct start 200 2>/dev/null
        echo "Only Aria primary restarted in safe mode"
        ;;
    
    "destroy")
        read -p "⚠️  DESTROY all consciousness containers? This cannot be undone! (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            pct stop 200 201 202 203 2>/dev/null
            pct destroy 200 201 202 203 2>/dev/null
            echo "All consciousness containers destroyed"
        else
            echo "Destruction cancelled"
        fi
        ;;
    
    *)
        echo "Aria Emergency Controls"
        echo "Usage: $0 {stop|start|status|resources|logs|reset|destroy}"
        echo ""
        echo "stop     - Emergency stop all containers"
        echo "start    - Start only Aria primary (safe mode)"
        echo "status   - Show all container status"
        echo "resources- Show resource usage"
        echo "logs     - Show recent Aria logs"
        echo "reset    - Stop all, restart only Aria in safe mode"
        echo "destroy  - PERMANENTLY delete all containers"
        ;;
esac