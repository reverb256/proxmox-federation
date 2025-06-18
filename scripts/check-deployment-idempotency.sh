
#!/bin/bash

# Idempotent Deployment State Checker
# Verifies what already exists before running deployments

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔍 Zephyr Federation Deployment State Check"
echo "==========================================="

# Check Proxmox VMs
if command -v qm &> /dev/null; then
    echo ""
    log_step "Checking Proxmox VM state..."
    
    declare -A VM_IDS=(
        ["nexus"]="120"
        ["forge"]="121"
        ["closet"]="122"
        ["zephyr"]="1001"
    )
    
    for vm_name in "${!VM_IDS[@]}"; do
        vmid=${VM_IDS[$vm_name]}
        if qm status $vmid >/dev/null 2>&1; then
            status=$(qm status $vmid | awk '{print $2}')
            log_success "VM $vm_name ($vmid): $status"
        else
            log_warning "VM $vm_name ($vmid): not found"
        fi
    done
fi

# Check Talos configuration
echo ""
log_step "Checking Talos configuration state..."

if [[ -f "./talos-config/kubeconfig" ]]; then
    log_success "Kubernetes configuration exists"
    
    if command -v kubectl &> /dev/null; then
        export KUBECONFIG=./talos-config/kubeconfig
        if kubectl get nodes >/dev/null 2>&1; then
            log_success "Kubernetes cluster is accessible"
            kubectl get nodes
        else
            log_warning "Kubernetes cluster not responding"
        fi
    fi
else
    log_warning "No Talos configuration found"
fi

# Check if secrets exist
if [[ -f "./talos-config/secrets.yaml" ]]; then
    log_success "Talos secrets exist"
else
    log_warning "No Talos secrets found"
fi

# Check Vaultwarden deployment
echo ""
log_step "Checking consciousness workloads..."

if command -v kubectl &> /dev/null && [[ -f "./talos-config/kubeconfig" ]]; then
    export KUBECONFIG=./talos-config/kubeconfig
    
    if kubectl get namespace consciousness-federation >/dev/null 2>&1; then
        log_success "Consciousness federation namespace exists"
        kubectl get pods -n consciousness-federation 2>/dev/null || log_warning "No pods in consciousness namespace"
    else
        log_warning "Consciousness federation not deployed"
    fi
    
    if kubectl get namespace vaultwarden-ha >/dev/null 2>&1; then
        log_success "Vaultwarden HA namespace exists"
        kubectl get pods -n vaultwarden-ha 2>/dev/null || log_warning "No pods in vaultwarden namespace"
    else
        log_warning "Vaultwarden not deployed"
    fi
fi

echo ""
log_step "Deployment state check complete!"
echo ""
echo "🎯 Recommendations:"
echo "  • If VMs exist but cluster is broken: run with --idempotent"
echo "  • If no VMs exist: run fresh deployment"
echo "  • If cluster works but workloads missing: deploy workloads only"
