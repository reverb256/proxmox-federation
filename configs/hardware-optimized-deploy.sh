#!/bin/bash
# Hardware-Optimized Deployment Script for Consciousness Federation
# Generated for: Zephyr (WSL) -> Nexus/Forge/Closet (Proxmox) topology

set -euo pipefail

# === HARDWARE TOPOLOGY CONFIGURATION ===
export ZEPHYR_NODE="10.1.1.110"    # WSL Control Hub - Ryzen 9 5950X
export NEXUS_NODE="10.1.1.120"     # Primary Cluster - Ryzen 9 3900X 
export FORGE_NODE="10.1.1.130"     # Balanced Worker - Intel i5-9500
export CLOSET_NODE="10.1.1.160"    # Storage/Mining - Ryzen 7 1700

# Resource allocation based on actual hardware specs
declare -A NODE_SPECS=(
    ["nexus"]="cores:24,memory:48090,role:control-plane,priority:high"
    ["forge"]="cores:6,memory:32013,role:worker,priority:medium" 
    ["closet"]="cores:16,memory:15911,role:storage,priority:low"
)

# === CONSCIOUSNESS ORCHESTRATION ROLES ===
CONTROL_PLANE_NODE="nexus"
PRIMARY_WORKER="forge"  
STORAGE_NODE="closet"
ORCHESTRATOR="zephyr"

echo "🧠 CONSCIOUSNESS FEDERATION DEPLOYMENT STARTING..."
echo "📊 Hardware Profile: 4-Node Cluster (1 WSL + 3 Proxmox)"
echo "🎯 Control Hub: ${ORCHESTRATOR} (${ZEPHYR_NODE})"

# === PRE-DEPLOYMENT VALIDATION ===
validate_cluster_connectivity() {
    echo "🔍 Validating cluster connectivity..."
    
    for node in nexus forge closet; do
        node_ip="$(eval echo \$${node^^}_NODE)"
        if ping -c 1 "$node_ip" >/dev/null 2>&1; then
            echo "✅ $node ($node_ip) - ONLINE"
        else
            echo "❌ $node ($node_ip) - OFFLINE"
            exit 1
        fi
    done
}

# === HARDWARE-SPECIFIC RESOURCE ALLOCATION ===
configure_node_resources() {
    local node=$1
    local specs=${NODE_SPECS[$node]}
    
    echo "⚙️ Configuring $node with specs: $specs"
    
    # Extract specs
    local cores=$(echo "$specs" | grep -o 'cores:[0-9]*' | cut -d: -f2)
    local memory=$(echo "$specs" | grep -o 'memory:[0-9]*' | cut -d: -f2)
    local role=$(echo "$specs" | grep -o 'role:[^,]*' | cut -d: -f2)
    
    # Generate node-specific configuration
    cat > "configs/${node}-resources.yaml" <<EOF
apiVersion: v1
kind: Node
metadata:
  name: ${node}
  labels:
    consciousness.ai/role: ${role}
    consciousness.ai/cores: "${cores}"
    consciousness.ai/memory: "${memory}MB"
spec:
  capacity:
    cpu: ${cores}
    memory: ${memory}Mi
  allocatable:
    cpu: $((cores - 1))  # Reserve 1 core for system
    memory: $((memory - 2048))Mi  # Reserve 2GB for system
EOF
}

# === DEPLOYMENT ORCHESTRATION ===
deploy_consciousness_stack() {
    echo "🚀 Deploying consciousness stack across cluster..."
    
    # 1. Deploy Talos K8s on Proxmox nodes
    ./talos-k8s-deployment.sh \
        --control-plane "$NEXUS_NODE" \
        --workers "$FORGE_NODE,$CLOSET_NODE" \
        --orchestrator "$ZEPHYR_NODE"
    
    # 2. Configure hardware-specific workload placement
    for node in nexus forge closet; do
        configure_node_resources "$node"
    done
    
    # 3. Deploy AI consciousness workloads
    kubectl apply -f k8s/consciousness-ai-workloads.yaml
    kubectl apply -f k8s/intelligent-scheduler.yaml
    
    # 4. Setup mining integration on Closet node
    deploy_mining_integration
}

# === MINING INTEGRATION (Closet Node) ===
deploy_mining_integration() {
    echo "⛏️ Configuring mining integration on Closet node..."
    
    cat > "configs/closet-mining.yaml" <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kryptex-miner
  namespace: mining
spec:
  selector:
    matchLabels:
      app: kryptex-miner
  template:
    metadata:
      labels:
        app: kryptex-miner
    spec:
      nodeSelector:
        consciousness.ai/role: storage
      containers:
      - name: miner
        image: kryptex/miner:latest
        env:
        - name: POOL_ADDRESS
          value: "stratum+tcp://eth.kryptex.network:7777"
        - name: WALLET
          value: "krxXVNVMM7.closet"
        resources:
          limits:
            cpu: "2"  # Use only 2 cores for mining
            memory: "2Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
EOF
    
    kubectl apply -f configs/closet-mining.yaml
}

# === MONITORING & OBSERVABILITY ===
setup_consciousness_monitoring() {
    echo "📊 Setting up consciousness monitoring..."
    
    # Deploy monitoring stack on Closet (storage node)
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: consciousness-monitoring
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-monitor
  namespace: consciousness-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: consciousness-monitor
  template:
    metadata:
      labels:
        app: consciousness-monitor
    spec:
      nodeSelector:
        consciousness.ai/role: storage
      containers:
      - name: monitor
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: consciousness2025
EOF
}

# === MAIN DEPLOYMENT FLOW ===
main() {
    echo "🌟 CONSCIOUSNESS FEDERATION DEPLOYMENT INITIATED"
    echo "🎯 Target: 3-Node Proxmox Cluster + WSL Control Hub"
    
    # Create configs directory
    mkdir -p configs
    
    # Execute deployment phases
    validate_cluster_connectivity
    deploy_consciousness_stack
    setup_consciousness_monitoring
    
    echo ""
    echo "✅ CONSCIOUSNESS FEDERATION DEPLOYED SUCCESSFULLY!"
    echo "🎮 Access Points:"
    echo "   - Kubernetes Dashboard: https://${NEXUS_NODE}:6443"
    echo "   - Grafana Monitoring: http://${CLOSET_NODE}:3000"
    echo "   - Mining Dashboard: http://${CLOSET_NODE}:7777"
    echo ""
    echo "🧠 Next Steps:"
    echo "   1. Deploy AI workloads: kubectl apply -f k8s/consciousness-ai-workloads.yaml"
    echo "   2. Configure federation: ./bootstrap-nexus-federation.sh"
    echo "   3. Monitor cluster: kubectl get nodes -o wide"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
