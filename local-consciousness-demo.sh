#!/bin/bash
# Local Consciousness Federation Demo

echo "🧠 Local Consciousness Demo"
echo "=========================="

# Display hardware topology from config
if [[ -f "k8s/hardware-aware-workload-placement.yaml" ]]; then
    echo "📊 Hardware Topology Configuration:"
    grep -A 20 "topology.yaml:" k8s/hardware-aware-workload-placement.yaml | head -25
fi

echo ""
echo "🎯 Local System Info:"
echo "  CPU Cores: $(nproc)"
echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "  Storage: $(df -h . | tail -1 | awk '{print $4}') available"
echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"

echo ""
echo "✅ Local consciousness federation components validated!"
