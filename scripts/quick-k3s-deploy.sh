#!/bin/bash

# Quick K3s Federation Setup - Minimal dependencies
echo "🚀 Quick K3s Federation Setup"
echo "============================="

# Create containers with minimal Ubuntu setup
create_minimal_container() {
    local ct_id=$1
    local hostname=$2
    local ip=$3
    
    echo "📦 Creating minimal container CT$ct_id ($hostname)"
    
    pct create $ct_id local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --hostname $hostname \
        --memory 2048 \
        --cores 2 \
        --storage local-lvm \
        --rootfs local-lvm:12 \
        --net0 name=eth0,bridge=vmbr0,gw=10.0.0.1,ip=$ip/24 \
        --unprivileged 0 \
        --features nesting=1,keyctl=1 \
        --onboot 1 \
        --startup order=1
    
    pct start $ct_id
    sleep 5
    
    # Minimal setup - just curl and K3s
    pct exec $ct_id -- bash -c "
        apt update -qq
        apt install -y curl
        hostnamectl set-hostname $hostname
        echo '127.0.0.1 $hostname' >> /etc/hosts
    "
    
    echo "✅ Container $ct_id ready"
}

# Setup K3s master
setup_k3s_master() {
    echo "🔧 Setting up K3s master on nexus..."
    
    pct exec 310 -- bash -c "
        # Install K3s server
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--disable=traefik' sh -
        
        # Wait for K3s to be ready
        sleep 10
        systemctl enable k3s
        systemctl restart k3s
        
        echo 'K3s master ready'
    "
}

# Setup K3s agents
setup_k3s_agents() {
    local token=$(pct exec 310 -- cat /var/lib/rancher/k3s/server/node-token 2>/dev/null)
    
    if [ -z "$token" ]; then
        echo "❌ Failed to get K3s token"
        return 1
    fi
    
    echo "🔗 Setting up agents with token: ${token:0:20}..."
    
    for node in "311:forge" "312:closet"; do
        IFS=':' read -r ct_id hostname <<< "$node"
        
        echo "🔗 Joining $hostname to cluster..."
        pct exec $ct_id -- bash -c "
            curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.10:6443 K3S_TOKEN=$token sh -
            systemctl enable k3s-agent
        "
    done
}

# Main execution
NODES=(
    "310:nexus:10.0.0.10"
    "311:forge:10.0.0.11" 
    "312:closet:10.0.0.12"
)

echo "🔄 Creating containers..."
for node_config in "${NODES[@]}"; do
    IFS=':' read -r ct_id hostname ip <<< "$node_config"
    
    # Skip if container exists and is running
    if pct status $ct_id 2>/dev/null | grep -q "running"; then
        echo "✅ CT$ct_id already running"
    else
        create_minimal_container $ct_id $hostname $ip
    fi
done

echo "🎯 Setting up K3s cluster..."
setup_k3s_master

echo "⏳ Waiting for master to stabilize..."
sleep 20

setup_k3s_agents

echo "🌐 Verifying cluster..."
sleep 10
pct exec 310 -- kubectl get nodes

echo ""
echo "✅ Quick K3s deployment complete!"
echo "🔧 Access: pct enter 310"
echo "🔍 Status: kubectl get nodes"