#!/bin/bash

# Proxmox Cluster SSH Setup and Verification
# Configures passwordless SSH between cluster nodes for consciousness federation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Get cluster nodes from Proxmox
get_cluster_nodes() {
    log_step "Discovering cluster nodes"
    
    # Get nodes from cluster status
    if command -v pvecm &> /dev/null && pvecm status &> /dev/null; then
        CLUSTER_NODES=$(pvecm nodes | grep -E "^\s*[0-9]+" | awk '{print $3}' | grep -v "$(hostname)")
        log_success "Found cluster nodes: $CLUSTER_NODES"
    else
        log_warning "Using your node names - nexus forge closet"
        CLUSTER_NODES="nexus forge closet"
    fi
    
    # Remove current hostname from list
    CURRENT_HOST=$(hostname)
    CLUSTER_NODES=$(echo $CLUSTER_NODES | tr ' ' '\n' | grep -v "^$CURRENT_HOST$" | tr '\n' ' ')
    
    echo "Cluster nodes to configure: $CLUSTER_NODES"
}

# Generate SSH keys if they don't exist
setup_ssh_keys() {
    log_step "Setting up SSH keys"
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        log_step "Generating SSH key pair"
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "proxmox-cluster-$(hostname)"
        log_success "SSH key pair generated"
    else
        log_success "SSH key pair already exists"
    fi
    
    # Ensure proper permissions
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
    
    # Create authorized_keys if it doesn't exist
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    # Add own key to authorized_keys
    if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        log_success "Added own key to authorized_keys"
    fi
}

# Attempt to setup SSH access to a node
setup_node_ssh() {
    local node=$1
    log_step "Setting up SSH access to $node"
    
    # Test if we can already SSH
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes root@$node "echo 'test'" &>/dev/null; then
        log_success "SSH access to $node already working"
        return 0
    fi
    
    # Try different methods to establish SSH access
    
    # Method 1: Try password authentication and copy key
    log_step "Attempting to copy SSH key to $node"
    if command -v ssh-copy-id &> /dev/null; then
        if ssh-copy-id -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$node &>/dev/null; then
            log_success "SSH key copied to $node using ssh-copy-id"
            return 0
        fi
    fi
    
    # Method 2: Manual key distribution via cluster filesystem
    log_step "Attempting cluster filesystem key distribution to $node"
    
    # Check if we can access the node via cluster filesystem
    local node_ssh_dir="/etc/pve/nodes/$node/ssh"
    if [ -d "$node_ssh_dir" ]; then
        # Copy key via cluster filesystem
        mkdir -p "$node_ssh_dir"
        cp ~/.ssh/id_rsa.pub "$node_ssh_dir/authorized_keys_$(hostname)"
        log_success "SSH key placed in cluster filesystem for $node"
        
        # Try to activate it on the remote node
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o PasswordAuthentication=yes root@$node \
            "cat /etc/pve/nodes/$node/ssh/authorized_keys_* >> ~/.ssh/authorized_keys 2>/dev/null; chmod 600 ~/.ssh/authorized_keys" &>/dev/null; then
            log_success "SSH key activated on $node"
            return 0
        fi
    fi
    
    # Method 3: Show manual instructions
    log_warning "Automatic SSH setup failed for $node"
    echo ""
    echo "Manual setup required for $node:"
    echo "  1. SSH to $node manually: ssh root@$node"
    echo "  2. Run this command on $node:"
    echo "     echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
    echo "  3. Set permissions: chmod 600 ~/.ssh/authorized_keys"
    echo ""
    
    return 1
}

# Configure SSH for all cluster nodes
configure_cluster_ssh() {
    log_step "Configuring SSH access for cluster nodes"
    
    local success_count=0
    local total_nodes=0
    
    for node in $CLUSTER_NODES; do
        total_nodes=$((total_nodes + 1))
        if setup_node_ssh "$node"; then
            success_count=$((success_count + 1))
        fi
    done
    
    log_step "SSH configuration results: $success_count/$total_nodes nodes accessible"
    
    if [ $success_count -eq $total_nodes ]; then
        log_success "All cluster nodes configured for SSH access"
        return 0
    else
        log_warning "Some nodes require manual SSH configuration"
        return 1
    fi
}

# Verify SSH access and collect keys
verify_and_collect_keys() {
    log_step "Verifying SSH access and collecting host keys"
    
    for node in $CLUSTER_NODES; do
        log_step "Testing SSH access to $node"
        
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "hostname" &>/dev/null; then
            log_success "SSH access to $node verified"
            
            # Collect host key to avoid future prompts
            ssh-keyscan -H $node >> ~/.ssh/known_hosts 2>/dev/null || true
            
            # Ensure the remote node has proper SSH setup
            ssh -o StrictHostKeyChecking=no root@$node "
                mkdir -p ~/.ssh
                chmod 700 ~/.ssh
                touch ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/authorized_keys
            " &>/dev/null || true
            
        else
            log_warning "SSH access to $node failed"
        fi
    done
}

# Exchange keys between all nodes
exchange_cluster_keys() {
    log_step "Exchanging SSH keys between all cluster nodes"
    
    # Collect all public keys
    local all_keys=""
    all_keys+="$(cat ~/.ssh/id_rsa.pub)"$'\n'
    
    for node in $CLUSTER_NODES; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "cat ~/.ssh/id_rsa.pub" &>/dev/null; then
            local node_key=$(ssh -o StrictHostKeyChecking=no root@$node "cat ~/.ssh/id_rsa.pub" 2>/dev/null)
            if [ -n "$node_key" ]; then
                all_keys+="$node_key"$'\n'
                log_success "Collected SSH key from $node"
            fi
        fi
    done
    
    # Distribute all keys to all nodes
    for node in $CLUSTER_NODES; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "echo 'test'" &>/dev/null; then
            log_step "Distributing all keys to $node"
            echo "$all_keys" | ssh -o StrictHostKeyChecking=no root@$node "
                cat >> ~/.ssh/authorized_keys
                sort ~/.ssh/authorized_keys | uniq > ~/.ssh/authorized_keys.tmp
                mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/authorized_keys
            "
            log_success "Keys distributed to $node"
        fi
    done
    
    # Update local authorized_keys with all collected keys
    echo "$all_keys" | sort | uniq >> ~/.ssh/authorized_keys
    sort ~/.ssh/authorized_keys | uniq > ~/.ssh/authorized_keys.tmp
    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    log_success "SSH key exchange completed"
}

# Test full cluster connectivity
test_cluster_connectivity() {
    log_step "Testing full cluster SSH connectivity"
    
    local success_count=0
    local total_count=0
    
    echo ""
    echo "SSH Connectivity Matrix:"
    echo "========================"
    
    for node in $CLUSTER_NODES; do
        total_count=$((total_count + 1))
        printf "%-15s: " "$node"
        
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes root@$node "echo 'OK'" 2>/dev/null; then
            echo "✓ Connected"
            success_count=$((success_count + 1))
        else
            echo "✗ Failed"
        fi
    done
    
    echo ""
    log_step "Connectivity results: $success_count/$total_count nodes accessible"
    
    if [ $success_count -eq $total_count ]; then
        log_success "Full cluster SSH connectivity established"
        return 0
    else
        log_warning "Some nodes still require manual configuration"
        return 1
    fi
}

# Create cluster management helper
create_cluster_ssh_helper() {
    log_step "Creating cluster SSH management helper"
    
    cat > /usr/local/bin/cluster-ssh << 'EOF'
#!/bin/bash

CLUSTER_NODES=$(pvecm nodes 2>/dev/null | grep -E "^\s*[0-9]+" | awk '{print $3}' | grep -v "$(hostname)" | tr '\n' ' ')

case "$1" in
    "test")
        echo "Testing SSH connectivity to cluster nodes..."
        for node in $CLUSTER_NODES; do
            printf "%-15s: " "$node"
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes root@$node "echo 'OK'" 2>/dev/null; then
                echo "✓ Connected"
            else
                echo "✗ Failed"
            fi
        done
        ;;
    "exec")
        if [ -z "$2" ]; then
            echo "Usage: cluster-ssh exec 'command'"
            exit 1
        fi
        command="$2"
        echo "Executing '$command' on all cluster nodes:"
        for node in $CLUSTER_NODES; do
            echo "--- $node ---"
            ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "$command" 2>/dev/null || echo "Failed to execute on $node"
        done
        ;;
    "status")
        echo "Cluster SSH Status:"
        pvecm status 2>/dev/null || echo "Cluster status unavailable"
        echo ""
        echo "SSH connectivity:"
        $0 test
        ;;
    *)
        echo "Usage: $0 {test|exec|status} [command]"
        echo ""
        echo "Commands:"
        echo "  test              - Test SSH connectivity to all cluster nodes"
        echo "  exec 'command'    - Execute command on all cluster nodes"
        echo "  status           - Show cluster and SSH status"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/cluster-ssh
    log_success "Cluster SSH helper created: cluster-ssh"
}

# Main execution
main() {
    echo "🔧 Proxmox Cluster SSH Setup"
    echo "============================="
    echo ""
    
    get_cluster_nodes
    setup_ssh_keys
    configure_cluster_ssh
    verify_and_collect_keys
    exchange_cluster_keys
    test_cluster_connectivity
    create_cluster_ssh_helper
    
    echo ""
    echo "🎯 SSH Setup Complete"
    echo ""
    echo "Management Commands:"
    echo "  cluster-ssh test     - Test connectivity to all nodes"
    echo "  cluster-ssh status   - Show cluster and SSH status"
    echo "  cluster-ssh exec 'cmd' - Run command on all nodes"
    echo ""
    echo "Next Steps:"
    echo "  1. Run: cluster-ssh test"
    echo "  2. If any nodes failed, configure them manually"
    echo "  3. Proceed with consciousness federation deployment"
    echo ""
}

# Execute setup
main "$@"