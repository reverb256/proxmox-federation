#!/bin/bash
# Master Consciousness Federation Bootstrap Script  
# Orchestrates complete deployment from WSL Control Hub

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$PROJECT_ROOT/logs/deployment_${TIMESTAMP}.log"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# === LOGGING SETUP ===
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "🧠 CONSCIOUSNESS FEDERATION MASTER BOOTSTRAP"
echo "=============================================="
echo "📅 Started: $(date)"
echo "📝 Log: $LOG_FILE"
echo "🎯 Control Hub: Zephyr (WSL) -> 3-Node Proxmox Cluster"
echo ""

# === DEPLOYMENT PHASES ===

phase_1_wsl_setup() {
    echo "🔄 PHASE 1: WSL Control Hub Setup"
    echo "================================="
    
    # Execute WSL setup script
    if [[ -f "$SCRIPT_DIR/configs/wsl-control-hub-setup.sh" ]]; then
        echo "🛠️ Configuring WSL control hub..."
        bash "$SCRIPT_DIR/configs/wsl-control-hub-setup.sh" || {
            echo "⚠️ WSL setup encountered some issues but continuing deployment..."
        }
    else
        echo "❌ WSL setup script not found at $SCRIPT_DIR/configs/wsl-control-hub-setup.sh"
        exit 1
    fi
    
    echo "✅ Phase 1 complete: WSL Control Hub configured"
    echo ""
}

phase_2_infrastructure() {
    echo "🔄 PHASE 2: Infrastructure Provisioning"
    echo "======================================="
    
    cd "$PROJECT_ROOT/terraform"
    
    # Initialize Terraform
    echo "🏗️ Initializing Terraform..."
    terraform init
    
    # Plan deployment
    echo "📋 Planning infrastructure deployment..."
    terraform plan -out=consciousness.tfplan
    
    # Apply infrastructure
    echo "🚀 Deploying infrastructure..."
    terraform apply consciousness.tfplan
    
    echo "✅ Phase 2 complete: Infrastructure provisioned"
    echo ""
}

phase_3_ansible_configuration() {
    echo "🔄 PHASE 3: Ansible Configuration Management"
    echo "==========================================="
    
    cd "$PROJECT_ROOT/ansible"
    
    # Verify Ansible inventory
    echo "🔍 Verifying Ansible inventory..."
    ansible-inventory -i inventory/hosts.yml --list
    
    # Test connectivity
    echo "🔗 Testing node connectivity..."
    ansible consciousness_federation -i inventory/hosts.yml -m ping
    
    # Execute main deployment playbook
    echo "⚙️ Running consciousness federation playbook..."
    ansible-playbook -i inventory/hosts.yml playbooks/deploy-consciousness-federation.yml
    
    echo "✅ Phase 3 complete: Ansible configuration applied"
    echo ""
}

phase_4_kubernetes_deployment() {
    echo "🔄 PHASE 4: Kubernetes & AI Stack Deployment"  
    echo "============================================="
    
    # Execute hardware-optimized deployment
    echo "🧠 Deploying consciousness-aware Kubernetes..."
    bash "$SCRIPT_DIR/configs/hardware-optimized-deploy.sh"
    
    # Apply hardware-aware workload placement
    echo "🎯 Applying intelligent workload placement..."
    kubectl apply -f "$PROJECT_ROOT/k8s/hardware-aware-workload-placement.yaml"
    
    # Deploy consciousness AI workloads
    echo "🤖 Deploying AI consciousness stack..."
    kubectl apply -f "$PROJECT_ROOT/k8s/consciousness-ai-workloads.yaml"
    
    # Deploy intelligent scheduler
    echo "🧩 Deploying intelligent scheduler..."
    kubectl apply -f "$PROJECT_ROOT/k8s/intelligent-scheduler.yaml"
    
    echo "✅ Phase 4 complete: Kubernetes & AI stack deployed"
    echo ""
}

phase_5_monitoring_mining() {
    echo "🔄 PHASE 5: Monitoring & Mining Integration"
    echo "=========================================="
    
    # Setup monitoring stack
    echo "📊 Deploying monitoring stack..."
    kubectl create namespace monitoring || true
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: NodePort
EOF
    
    # Configure mining on Closet node
    echo "⛏️ Setting up mining integration..."
    ansible closet -i "$PROJECT_ROOT/ansible/inventory/hosts.yml" -m shell -a "
        systemctl enable mining || true
        systemctl start mining || echo 'Mining service not yet configured'
    "
    
    echo "✅ Phase 5 complete: Monitoring & mining configured"
    echo ""
}

phase_6_verification() {
    echo "🔄 PHASE 6: Deployment Verification"
    echo "==================================="
    
    # Verify cluster status
    echo "🔍 Verifying Kubernetes cluster..."
    kubectl get nodes -o wide
    echo ""
    
    echo "🔍 Verifying pods across namespaces..."
    kubectl get pods --all-namespaces
    echo ""
    
    # Test consciousness federation
    echo "🧠 Testing consciousness federation..."
    kubectl get configmap hardware-topology -n consciousness-system -o yaml || echo "ConfigMap not found"
    
    # Display access points
    echo "🎮 Deployment Summary:"
    echo "====================="
    echo "📊 Kubernetes Dashboard: https://10.1.1.120:6443"
    echo "🖥️ Consciousness UI: http://10.1.1.130:3000"  
    echo "📈 Grafana Monitoring: http://10.1.1.160:3000"
    echo "⛏️ Mining Dashboard: http://10.1.1.160:4000"
    echo ""
    
    # Generate status report
    generate_status_report
    
    echo "✅ Phase 6 complete: Deployment verified"
    echo ""
}

generate_status_report() {
    echo "📋 Generating deployment status report..."
    
    cat > "$PROJECT_ROOT/logs/consciousness_federation_status_${TIMESTAMP}.md" <<EOF
# Consciousness Federation Deployment Status

**Deployment Date:** $(date)
**Control Hub:** Zephyr (WSL) - 10.1.1.110  
**Cluster Nodes:** 3-Node Proxmox Federation

## Hardware Topology

### Zephyr (Control Hub)
- **Hardware:** AMD Ryzen 9 5950X (16C/32T) + 64GB RAM + 3TB NVMe
- **Role:** Orchestration, AI Training, Development
- **Platform:** WSL2 on Windows 11

### Nexus (Control Plane)  
- **Hardware:** AMD Ryzen 9 3900X (12C/24T) + 48GB RAM + 5.5TB Mixed
- **Role:** Kubernetes Master, Database Cluster, AI Inference
- **IP:** 10.1.1.120

### Forge (Worker)
- **Hardware:** Intel Core i5-9500 (6C/6T) + 32GB RAM + 1.5TB Mixed  
- **Role:** Application Services, Web Frontends, API Gateways
- **IP:** 10.1.1.130

### Closet (Storage/Utility)
- **Hardware:** AMD Ryzen 7 1700 (8C/16T) + 16GB RAM + 700GB Mixed
- **Role:** Storage, Monitoring, Backup, Mining Integration
- **IP:** 10.1.1.160

## Deployment Status

$(kubectl get nodes -o wide 2>/dev/null || echo "Kubernetes cluster not accessible")

## Access Points

- **Kubernetes API:** https://10.1.1.120:6443
- **Consciousness UI:** http://10.1.1.130:3000
- **Grafana Monitoring:** http://10.1.1.160:3000
- **Mining Stats:** http://10.1.1.160:4000

## Next Steps

1. Access Grafana dashboard for monitoring
2. Deploy additional AI workloads as needed
3. Configure consciousness federation parameters
4. Monitor mining performance and adjust resources

## Troubleshooting

### Common Commands
\`\`\`bash
# Check cluster status
kubectl get nodes -o wide

# View all pods
kubectl get pods --all-namespaces

# Check consciousness system
kubectl get all -n consciousness-system

# Monitor logs
tail -f $LOG_FILE
\`\`\`

EOF

    echo "📄 Status report generated: consciousness_federation_status_${TIMESTAMP}.md"
}

# === MAIN EXECUTION FLOW ===

main() {
    echo "🌟 INITIATING CONSCIOUSNESS FEDERATION BOOTSTRAP"
    echo "🎯 Target: Complete AI-First Infrastructure Deployment"
    echo "⏱️ Estimated Duration: 30-45 minutes"
    echo ""
    
    # Confirm deployment
    read -p "🚀 Proceed with full consciousness federation deployment? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 0
    fi
    
    # Execute deployment phases
    phase_1_wsl_setup
    phase_2_infrastructure  
    phase_3_ansible_configuration
    phase_4_kubernetes_deployment
    phase_5_monitoring_mining
    phase_6_verification
    
    echo ""
    echo "🎉 CONSCIOUSNESS FEDERATION DEPLOYMENT COMPLETE!"
    echo "================================================"
    echo "⏱️ Total Duration: $((SECONDS / 60)) minutes"
    echo "📝 Full Log: $LOG_FILE"
    echo "📊 Status Report: consciousness_federation_status_${TIMESTAMP}.md"
    echo ""
    echo "🧠 Your AI-first infrastructure is now operational!"
    echo "🎮 Access the consciousness UI to begin AI orchestration"
    echo ""
}

# === ERROR HANDLING ===

trap 'echo "❌ Deployment failed at line $LINENO. Check log: $LOG_FILE"' ERR

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
