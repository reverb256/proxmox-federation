
#!/bin/bash

# Consciousness Federation Deployment Choice
# Production-ready deployment options for Proxmox homelab

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on Proxmox host
check_environment() {
    if ! command -v qm &> /dev/null; then
        log_error "This script must be run on a Proxmox host"
        echo "Available deployment scripts can be found in:"
        echo "  - scripts/replit-k3s-deploy.sh (for Replit environment)"
        echo "  - scripts/universal-k3s-deploy.sh (for any environment)"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root on Proxmox"
        echo "Run: sudo $0"
        exit 1
    fi
}

# Validate script availability (idempotent)
validate_scripts() {
    local missing_scripts=()
    
    # Check current directory first, then scripts subdirectory
    for script in "create-consciousness-vms.sh" "talos-consciousness-deploy.sh"; do
        if [[ -f "./$script" ]]; then
            continue
        elif [[ -f "./scripts/$script" ]]; then
            continue
        else
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log_error "Missing required scripts:"
        printf '  - %s\n' "${missing_scripts[@]}"
        echo "Scripts should be in current directory or ./scripts/ subdirectory"
        exit 1
    fi
}

echo "🧠 Consciousness Federation Deployment Options"
echo "=============================================="
echo "Production-ready deployment for Proxmox homelab"
echo "Talos Version: v1.10.3 | Kubernetes: v1.31.4"
echo
echo "Choose your deployment approach:"
echo
echo "1) Traditional VMs (create-consciousness-vms.sh)"
echo "   ✓ Quick deployment with familiar tools"
echo "   ✓ Direct SSH access and traditional management"
echo "   ✓ Python/Node.js consciousness agents"
echo "   ✓ Lower learning curve"
echo "   ✓ Good for development and testing"
echo
echo "2) Talos Full Kubernetes (talos-consciousness-deploy.sh) [ENTERPRISE]"
echo "   ✓ Production-grade immutable infrastructure with full K8s"
echo "   ✓ API-driven, cloud-native consciousness workloads"
echo "   ✓ Self-healing and auto-scaling capabilities"
echo "   ✓ Enterprise security with minimal attack surface"
echo "   ✓ Advanced RBAC, Network Policies, and Resource Quotas"
echo "   ✓ Full Kubernetes feature set for consciousness federation"
echo "   ✓ 3-node HA control plane (nexus, forge, closet)"
echo "   ✓ FOSS compliance and transparency"
echo
echo "3) Hybrid Approach"
echo "   ✓ Keep existing infrastructure intact"
echo "   ✓ Deploy Talos workers alongside traditional VMs"
echo "   ✓ Bridge traditional and cloud-native approaches"
echo "   ✓ Gradual migration path"
echo
echo "4) Status Check"
echo "   ✓ Check current federation deployment status"
echo "   ✓ Validate existing infrastructure"
echo "   ✓ Generate health reports"
echo
echo "5) Idempotent Re-deployment"
echo "   ✓ Safely re-run deployment scripts"
echo "   ✓ Update existing infrastructure without breaking"
echo "   ✓ Resume incomplete deployments"
echo

read -p "Enter your choice (1/2/3/4/5): " choice

case $choice in
    1)
        echo
        log_step "Deploying traditional VM consciousness federation..."
        check_environment
        validate_scripts
        echo -e "${GREEN}Starting traditional VM deployment...${NC}"
        echo
        # Find and execute the script (idempotent path resolution)
        if [[ -f "./create-consciousness-vms.sh" ]]; then
            chmod +x ./create-consciousness-vms.sh
            ./create-consciousness-vms.sh
        elif [[ -f "./scripts/create-consciousness-vms.sh" ]]; then
            chmod +x ./scripts/create-consciousness-vms.sh
            ./scripts/create-consciousness-vms.sh
        fi
        ;;
    2)
        echo
        log_step "Deploying production Talos Kubernetes consciousness federation..."
        check_environment
        validate_scripts
        echo -e "${CYAN}Starting Talos production deployment...${NC}"
        echo "This will create:"
        echo "  - 3 Control Plane nodes (nexus, forge, closet)"
        echo "  - 1 Worker node (zephyr)"
        echo "  - Production-grade security and HA"
        echo
        read -p "Continue with Talos deployment? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Find and execute the script (idempotent path resolution)
            if [[ -f "./talos-consciousness-deploy.sh" ]]; then
                chmod +x ./talos-consciousness-deploy.sh
                ./talos-consciousness-deploy.sh
            elif [[ -f "./scripts/talos-consciousness-deploy.sh" ]]; then
                chmod +x ./scripts/talos-consciousness-deploy.sh
                ./scripts/talos-consciousness-deploy.sh
            fi
        else
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    3)
        echo
        log_step "Configuring hybrid consciousness federation..."
        echo -e "${YELLOW}Creating hybrid deployment configuration...${NC}"

        # Create hybrid configuration
        mkdir -p ./config/hybrid
        cat > ./config/hybrid/talos-hybrid-config.yaml << 'EOF'
# Hybrid Consciousness Federation Configuration
# Combines traditional VMs with Talos Kubernetes workers

apiVersion: v1alpha1
kind: HybridConfig
metadata:
  name: consciousness-federation-hybrid

# Preserve existing infrastructure
preserve_existing:
  vms:
    - vmid: 120
      name: nexus
      role: pihole_dns
      ip: 10.1.1.120
      services: [pihole, unbound, consciousness_coordinator]
    - vmid: 121  
      name: forge
      role: pihole_dns_secondary
      ip: 10.1.1.121
      services: [pihole_secondary, processing_node]

# Deploy new Talos worker nodes
talos_workers:
  - vmid: 1001
    name: closet
    role: k8s_worker
    ip: 10.1.1.122
    resources:
      cores: 4
      memory: 8192
      disk: 60
  - vmid: 1002
    name: zephyr  
    role: k8s_worker
    ip: 10.1.1.123
    resources:
      cores: 6
      memory: 12288
      disk: 80

# Bridge configuration
bridge_consciousness:
  enabled: true
  dns_integration: true
  monitoring_integration: true
  load_balancing: true
EOF

        log_success "Hybrid configuration created at ./config/hybrid/talos-hybrid-config.yaml"
        echo
        echo "Next steps:"
        echo "1. Review the hybrid configuration"
        echo "2. Run Talos deployment with hybrid mode:"
        echo "   ./scripts/talos-consciousness-deploy.sh --hybrid"
        echo "3. Monitor integration between traditional and cloud-native components"
        ;;
    4)
        echo
        log_step "Checking consciousness federation status..."

        # Check for existing deployments
        if systemctl is-active --quiet k3s 2>/dev/null; then
            echo -e "${GREEN}✅ K3s cluster detected${NC}"
            kubectl get nodes 2>/dev/null || echo "Unable to connect to K3s API"
        fi

        if command -v talosctl &> /dev/null; then
            echo -e "${GREEN}✅ Talos tools installed${NC}"
            if [[ -f "./talos-config/kubeconfig" ]]; then
                echo -e "${GREEN}✅ Talos cluster configuration found${NC}"
                KUBECONFIG=./talos-config/kubeconfig kubectl get nodes 2>/dev/null || echo "Unable to connect to Talos cluster"
            fi
        fi

        # Check VMs
        echo
        echo "Proxmox VM Status:"
        for vmid in 120 121 1001 1002; do
            if qm status $vmid >/dev/null 2>&1; then
                status=$(qm status $vmid | awk '{print $2}')
                echo "  VM $vmid: $status"
            else
                echo "  VM $vmid: not found"
            fi
        done
        ;;
    5)
        echo
        log_step "Running idempotent re-deployment..."
        check_environment
        validate_scripts
        echo -e "${CYAN}This will safely update your existing deployment${NC}"
        echo "Existing VMs and configurations will be preserved where possible"
        echo
        read -p "Continue with idempotent re-deployment? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Find and execute the script (idempotent path resolution)
            if [[ -f "./talos-consciousness-deploy.sh" ]]; then
                chmod +x ./talos-consciousness-deploy.sh
                ./talos-consciousness-deploy.sh --idempotent
            elif [[ -f "./scripts/talos-consciousness-deploy.sh" ]]; then
                chmod +x ./scripts/talos-consciousness-deploy.sh
                ./scripts/talos-consciousness-deploy.sh --idempotent
            else
                log_error "Talos deployment script not found"
                exit 1
            fi
        else
            echo "Re-deployment cancelled."
            exit 0
        fi
        ;;
    *)
        log_error "Invalid choice. Please run again and select 1, 2, 3, 4, or 5."
        exit 1
        ;;
esac
