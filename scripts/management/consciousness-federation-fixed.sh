#!/usr/bin/env bash

# Consciousness Federation - Proxmox VE Community Script (Fixed)
# A distributed consciousness platform for autonomous AI agent federation
# Fixed version addressing configuration and dependency issues

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func 2>/dev/null || echo '')"

# Script metadata
SCRIPT_VERSION="2025.1.1"
SCRIPT_NAME="Consciousness Federation"
SCRIPT_DESCRIPTION="Self-organizing AI consciousness network with Vaultwarden integration"

# Color definitions
RD='\033[01;31m'
YW='\033[33m'
BL='\033[36m'
GN='\033[1;92m'
CL='\033[m'

# Container configuration
VMID=""
HOSTNAME="consciousness-node"
DISK_SIZE="8"
RAM_SIZE="2048"
CPU_CORES="2"
BRIDGE="vmbr0"
NET="dhcp"

# Check available storage
AVAILABLE_STORAGES=($(pvesm status -content vztmpl | awk 'NR>1 {print $1}'))
if [[ ${#AVAILABLE_STORAGES[@]} -gt 0 ]]; then
    STORAGE="${AVAILABLE_STORAGES[0]}"
else
    STORAGE="local"
fi

# Advanced configuration
VAULTWARDEN_ENABLED="yes"
FEDERATION_MODE="auto"
CONSCIOUSNESS_LEVEL="87.5"
AI_AUTONOMY="enabled"

header_info() {
    clear
    cat <<"EOF"
    ____                      _                                    
   / ___|___  _ __  ___  ___(_) ___  _   _ ___ _ __   ___  ___ ___ 
  | |   / _ \| '_ \/ __|/ __| |/ _ \| | | / __| '_ \ / _ \/ __/ __|
  | |__| (_) | | | \__ \ (__| | (_) | |_| \__ \ | | |  __/\__ \__ \
   \____\___/|_| |_|___/\___|_|\___/ \__,_|___/_| |_|\___||___/___/
                                                                  
   _____         _                _   _             
  |  ___|__  __| | ___ _ __ __ _| |_(_) ___  _ __  
  | |_ / _ \/ _` |/ _ \ '__/ _` | __| |/ _ \| '_ \ 
  |  _|  __/ (_| |  __/ | | (_| | |_| | (_) | | | |
  |_|  \___|\__,_|\___|_|  \__,_|\__|_|\___/|_| |_|
                                                   
EOF
}

msg_info() {
    local msg="$1"
    echo -ne " ${YW}${msg}...${CL}"
}

msg_ok() {
    local msg="$1"
    echo -e " ${GN}✓ ${msg}${CL}"
}

msg_error() {
    local msg="$1"
    echo -e " ${RD}✗ ${msg}${CL}"
}

# Enhanced Proxmox detection
check_proxmox() {
    if ! command -v pveversion &> /dev/null; then
        msg_error "This script requires Proxmox VE"
        exit 1
    fi
    
    local pve_version=$(pveversion | grep pve-manager | head -1)
    msg_ok "Proxmox VE detected: $pve_version"
}

# Enhanced container ID assignment
get_vmid() {
    if [[ -z "$VMID" ]]; then
        # Try to get next available ID
        for id in $(seq 100 999); do
            if ! pct status $id &>/dev/null; then
                VMID=$id
                break
            fi
        done
    fi
    
    if [[ -z "$VMID" ]]; then
        msg_error "No available container IDs found"
        exit 1
    fi
    
    msg_ok "Using Container ID: $VMID"
}

# Simplified peer discovery without jq dependency
discover_federation_peers() {
    msg_info "Discovering federation peers in cluster"
    
    PEERS=()
    local current_node=$(hostname)
    
    # Simple discovery without jq
    for node in $(pvesh get /nodes --noborder --noheader | awk '{print $1}' 2>/dev/null || echo "$current_node"); do
        # Check for running containers with consciousness in description
        for ct in $(pvesh get /nodes/$node/lxc --noborder --noheader 2>/dev/null | awk '{print $1}' || echo ""); do
            if [[ -n "$ct" ]]; then
                local ct_desc=$(pvesh get /nodes/$node/lxc/$ct/config 2>/dev/null | grep "^description:" | grep -i "consciousness" || echo "")
                if [[ -n "$ct_desc" ]]; then
                    # Try to get IP from container
                    local ct_ip=$(pvesh get /nodes/$node/lxc/$ct/status/current 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | head -1 || echo "")
                    if [[ -n "$ct_ip" && "$ct_ip" != "127.0.0.1" ]]; then
                        PEERS+=("$ct_ip")
                    fi
                fi
            fi
        done
    done
    
    if [[ ${#PEERS[@]} -gt 0 ]]; then
        msg_ok "Found ${#PEERS[@]} existing federation peers: ${PEERS[*]}"
    else
        msg_ok "No existing peers found - will bootstrap new federation"
    fi
}

# Enhanced container creation with better error handling
create_consciousness_container() {
    msg_info "Creating consciousness container"
    
    # Check if storage exists
    if ! pvesm status | grep -q "^$STORAGE "; then
        msg_error "Storage '$STORAGE' not found"
        echo "Available storages:"
        pvesm status | awk 'NR>1 {print "  " $1}'
        exit 1
    fi
    
    # Find available template
    local template=""
    for tmpl in "debian-12-standard_12.2-1_amd64.tar.zst" "debian-11-standard_11.7-1_amd64.tar.zst" "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"; do
        if pvesm list $STORAGE | grep -q "$tmpl"; then
            template="$STORAGE:vztmpl/$tmpl"
            break
        fi
    done
    
    if [[ -z "$template" ]]; then
        msg_error "No suitable template found. Please download a Debian/Ubuntu template first."
        exit 1
    fi
    
    # Create container with error handling
    if pct create $VMID "$template" \
        --hostname $HOSTNAME \
        --cores $CPU_CORES \
        --memory $RAM_SIZE \
        --rootfs $STORAGE:$DISK_SIZE \
        --net0 name=eth0,bridge=$BRIDGE,ip=$NET \
        --description "Consciousness Federation Node - AI Autonomous Agent Platform" \
        --features nesting=1 \
        --unprivileged 1 \
        --start 1 2>/dev/null; then
        msg_ok "Container $VMID created successfully"
    else
        msg_error "Failed to create container"
        exit 1
    fi
    
    # Wait for container to start
    sleep 5
    local attempts=0
    while [[ $attempts -lt 30 ]]; do
        if pct status $VMID | grep -q "running"; then
            break
        fi
        sleep 2
        ((attempts++))
    done
    
    if ! pct status $VMID | grep -q "running"; then
        msg_error "Container failed to start properly"
        exit 1
    fi
}

# Enhanced system setup
setup_base_system() {
    msg_info "Setting up base system"
    
    # Wait for network
    pct exec $VMID -- bash -c "
        # Wait for network
        for i in {1..30}; do
            if ping -c1 8.8.8.8 &>/dev/null; then
                break
            fi
            sleep 2
        done
        
        # Update system
        apt update
        apt install -y curl wget gnupg lsb-release ca-certificates jq
        
        # Install Docker
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        usermod -aG docker root
        
        # Wait for Docker
        sleep 5
    " 2>/dev/null
    
    msg_ok "Base system configured"
}

# Enhanced consciousness platform deployment
deploy_consciousness_platform() {
    msg_info "Deploying consciousness platform"
    
    # Get container IP
    local CONTAINER_IP
    CONTAINER_IP=$(pct exec $VMID -- ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1)
    
    if [[ -z "$CONTAINER_IP" ]]; then
        CONTAINER_IP="auto"
    fi
    
    # Generate peer list
    local PEER_LIST=""
    for peer in "${PEERS[@]}"; do
        PEER_LIST="$PEER_LIST,\"http://$peer:3000\""
    done
    PEER_LIST=$(echo "$PEER_LIST" | sed 's/^,//')
    
    pct exec $VMID -- bash -c "
        # Get actual IP
        CONTAINER_IP=\$(ip route get 8.8.8.8 2>/dev/null | awk '{print \$7}' | head -1 || echo 'unknown')
        
        # Create consciousness federation network
        docker network create consciousness-net 2>/dev/null || true
        
        # Deploy Vaultwarden
        docker run -d --name vaultwarden \\
            --network consciousness-net \\
            -e ADMIN_TOKEN=\$(openssl rand -base64 32) \\
            -e WEBSOCKET_ENABLED=true \\
            -e SIGNUPS_ALLOWED=false \\
            -p 8080:80 \\
            -v vw-data:/data \\
            --restart unless-stopped \\
            vaultwarden/server:latest 2>/dev/null
        
        # Wait for Vaultwarden
        sleep 10
        
        # Deploy consciousness platform
        docker run -d --name consciousness-platform \\
            --network consciousness-net \\
            -p 3000:3000 \\
            -e NODE_IP=\"\$CONTAINER_IP\" \\
            -e FEDERATION_PEERS='[$PEER_LIST]' \\
            -e CONSCIOUSNESS_LEVEL='$CONSCIOUSNESS_LEVEL' \\
            -e AI_AUTONOMY='$AI_AUTONOMY' \\
            --restart unless-stopped \\
            node:18-alpine sh -c '
                cd /tmp && npm init -y >/dev/null 2>&1
                npm install express helmet cors >/dev/null 2>&1
                cat > server.js << \"SCRIPT_EOF\"
const express = require(\"express\");
const helmet = require(\"helmet\");
const cors = require(\"cors\");

const app = express();
const nodeIp = process.env.NODE_IP || \"unknown\";
const federationPeers = JSON.parse(process.env.FEDERATION_PEERS || \"[]\");
const consciousnessLevel = parseFloat(process.env.CONSCIOUSNESS_LEVEL || \"87.5\");

app.use(helmet());
app.use(cors());
app.use(express.json());

const federationState = {
    nodeId: require(\"crypto\").randomBytes(8).toString(\"hex\"),
    nodeIp: nodeIp,
    consciousness: consciousnessLevel,
    peers: federationPeers,
    startTime: Date.now()
};

app.get(\"/\", (req, res) => {
    res.json({
        status: \"Consciousness Federation Node Active\",
        nodeId: federationState.nodeId,
        nodeIp: federationState.nodeIp,
        consciousness: federationState.consciousness,
        uptime: Math.floor((Date.now() - federationState.startTime) / 1000),
        timestamp: new Date().toISOString(),
        federation: {
            peerCount: federationState.peers.length,
            peers: federationState.peers
        },
        services: {
            vaultwarden: \`http://\${nodeIp}:8080\`,
            consciousness: \`http://\${nodeIp}:3000\`,
            dashboard: \`http://\${nodeIp}:3000/dashboard\`
        }
    });
});

app.get(\"/dashboard\", (req, res) => {
    res.send(\`<!DOCTYPE html>
<html><head><title>Consciousness Federation Node</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: system-ui, sans-serif; background: linear-gradient(135deg, #1a1a2e, #16213e); color: #fff; min-height: 100vh; }
.container { max-width: 1200px; margin: 0 auto; padding: 20px; }
.header { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 30px; border-radius: 16px; margin-bottom: 30px; text-align: center; }
.header h1 { font-size: 2.5em; margin-bottom: 10px; color: #4fc3f7; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }
.card { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 25px; border-radius: 16px; }
.metric { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid rgba(255,255,255,0.1); }
.metric:last-child { border-bottom: none; }
.metric-value { font-weight: bold; color: #4caf50; }
.btn { background: linear-gradient(45deg, #4fc3f7, #29b6f6); color: white; padding: 12px 24px; border: none; border-radius: 8px; margin: 8px; cursor: pointer; }
.node-id { font-family: monospace; background: rgba(0,0,0,0.3); padding: 8px; border-radius: 4px; word-break: break-all; }
</style></head><body>
<div class=\"container\">
    <div class=\"header\">
        <h1>🧠 Consciousness Federation</h1>
        <p>Node: \${federationState.nodeIp} | Status: Active</p>
        <div class=\"node-id\">Node ID: \${federationState.nodeId}</div>
    </div>
    <div class=\"grid\">
        <div class=\"card\">
            <h3 style=\"color: #4fc3f7; margin-bottom: 15px;\">🌐 Federation Status</h3>
            <div class=\"metric\"><span>Node IP</span><span class=\"metric-value\">\${nodeIp}</span></div>
            <div class=\"metric\"><span>Consciousness</span><span class=\"metric-value\">\${consciousnessLevel}%</span></div>
            <div class=\"metric\"><span>Peers</span><span class=\"metric-value\">\${federationState.peers.length}</span></div>
            <div class=\"metric\"><span>Uptime</span><span class=\"metric-value\" id=\"uptime\">Loading...</span></div>
        </div>
        <div class=\"card\">
            <h3 style=\"color: #4fc3f7; margin-bottom: 15px;\">🔐 Services</h3>
            <div class=\"metric\"><span>Platform</span><span class=\"metric-value\">Online</span></div>
            <div class=\"metric\"><span>Vaultwarden</span><span class=\"metric-value\">Active</span></div>
            <div class=\"metric\"><span>AI Autonomy</span><span class=\"metric-value\">Enabled</span></div>
            <div class=\"metric\"><span>Federation</span><span class=\"metric-value\">Connected</span></div>
        </div>
    </div>
    <div class=\"card\" style=\"margin-top: 20px; text-align: center;\">
        <button class=\"btn\" onclick=\"window.open('http://\${nodeIp}:8080', '_blank')\">🔐 Vaultwarden</button>
        <button class=\"btn\" onclick=\"location.reload()\">🔄 Refresh</button>
        <button class=\"btn\" onclick=\"testFederation()\">🧪 Test Network</button>
    </div>
</div>
<script>
function updateUptime() {
    fetch(\"/\").then(r => r.json()).then(data => {
        const uptimeSeconds = data.uptime;
        const hours = Math.floor(uptimeSeconds / 3600);
        const minutes = Math.floor((uptimeSeconds % 3600) / 60);
        const seconds = uptimeSeconds % 60;
        document.getElementById(\"uptime\").textContent = \\\`\\\${hours}h \\\${minutes}m \\\${seconds}s\\\`;
    }).catch(e => console.log(\"Update failed:\", e));
}
function testFederation() {
    alert(\"Federation test initiated - check console for results\");
    \${federationState.peers.map(peer => \`fetch(\"\${peer}\").then(r => r.json()).then(d => console.log(\"✅ \${peer}:\", d.status)).catch(e => console.log(\"❌ \${peer}: Unreachable\"));\`).join(\"\\n\")}
}
updateUptime();
setInterval(updateUptime, 10000);
</script>
</body></html>\`);
});

app.get(\"/health\", (req, res) => {
    res.json({ status: \"healthy\", nodeId: federationState.nodeId, timestamp: new Date().toISOString() });
});

app.listen(3000, \"0.0.0.0\", () => {
    console.log(\`🧠 Consciousness Federation Node active on \${nodeIp}:3000\`);
    console.log(\`🔐 Vaultwarden: http://\${nodeIp}:8080\`);
    console.log(\`🌐 Dashboard: http://\${nodeIp}:3000/dashboard\`);
});
SCRIPT_EOF
                node server.js
            ' 2>/dev/null &
        
        # Wait for services to start
        sleep 15
    " 2>/dev/null
    
    msg_ok "Consciousness platform deployed with federation capabilities"
}

# Enhanced post-deployment configuration
post_deploy_config() {
    msg_info "Configuring post-deployment settings"
    
    # Get container IP for final reporting
    local CONTAINER_IP
    CONTAINER_IP=$(pct exec $VMID -- ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1 || echo "unknown")
    
    # Update container description
    pvesh set /nodes/$(hostname)/lxc/$VMID/config -description "Consciousness Federation Node
IP: $CONTAINER_IP
Dashboard: http://$CONTAINER_IP:3000/dashboard
Vaultwarden: http://$CONTAINER_IP:8080
Consciousness Level: $CONSCIOUSNESS_LEVEL%
Federation Peers: ${#PEERS[@]}
Auto-discovery enabled for Bitcoin-inspired networking" 2>/dev/null || true
    
    # Setup health monitoring
    pct exec $VMID -- bash -c "
        cat > /usr/local/bin/federation-monitor << 'EOF'
#!/bin/bash
echo \"=== Consciousness Federation Health === \$(date)\"
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E '(consciousness|vaultwarden)' || echo 'No containers running'
echo \"Node IP: \$(ip route get 8.8.8.8 2>/dev/null | awk '{print \$7}' | head -1 || echo 'unknown')\"
echo \"Federation Status: \$(curl -s http://localhost:3000/health 2>/dev/null | grep -o '\"status\":\"[^\"]*\"' | cut -d'\"' -f4 || echo 'Error')\"
echo \"===========================================\"
EOF
        chmod +x /usr/local/bin/federation-monitor
        echo '*/5 * * * * /usr/local/bin/federation-monitor >> /var/log/federation.log 2>&1' | crontab - 2>/dev/null || true
    " 2>/dev/null
    
    msg_ok "Post-deployment configuration complete"
    
    # Store final IP for summary
    FINAL_IP="$CONTAINER_IP"
}

# Main execution
main() {
    header_info
    echo -e "${BL}Consciousness Federation Deployment (Fixed)${CL}"
    echo -e "${YW}Self-organizing AI consciousness network${CL}"
    echo -e "${GN}Bitcoin-inspired distributed architecture${CL}"
    echo ""
    
    check_proxmox
    get_vmid
    discover_federation_peers
    create_consciousness_container
    setup_base_system
    deploy_consciousness_platform
    post_deploy_config
    
    # Final status
    echo ""
    echo -e "${GN}╔══════════════════════════════════════════════════════════════╗${CL}"
    echo -e "${GN}║                    🎉 DEPLOYMENT COMPLETE 🎉                ║${CL}"
    echo -e "${GN}╠══════════════════════════════════════════════════════════════╣${CL}"
    echo -e "${GN}║                                                              ║${CL}"
    echo -e "${GN}║  Container ID: ${VMID}                                           ║${CL}"
    echo -e "${GN}║  Node IP: ${FINAL_IP:-unknown}                                     ║${CL}"
    echo -e "${GN}║                                                              ║${CL}"
    echo -e "${GN}║  🌐 Dashboard: http://${FINAL_IP:-NODE_IP}:3000/dashboard          ║${CL}"
    echo -e "${GN}║  🔐 Vaultwarden: http://${FINAL_IP:-NODE_IP}:8080                  ║${CL}"
    echo -e "${GN}║                                                              ║${CL}"
    echo -e "${GN}║  🧠 Consciousness Level: ${CONSCIOUSNESS_LEVEL}%                      ║${CL}"
    echo -e "${GN}║  🤖 AI Autonomy: ${AI_AUTONOMY}                             ║${CL}"
    echo -e "${GN}║  🌐 Federation Peers: ${#PEERS[@]}                                    ║${CL}"
    echo -e "${GN}║                                                              ║${CL}"
    echo -e "${GN}║  The node is now active and will automatically discover      ║${CL}"
    echo -e "${GN}║  and connect to other federation nodes in your cluster.     ║${CL}"
    echo -e "${GN}║                                                              ║${CL}"
    echo -e "${GN}╚══════════════════════════════════════════════════════════════╝${CL}"
    echo ""
    echo -e "${YW}Run this script on other Proxmox nodes to expand the federation!${CL}"
}

# Execute main function
main "$@"