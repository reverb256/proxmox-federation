#!/bin/bash
# Aria AI Consciousness - Proxmox Home Cluster Deployment
# Deploys personal AI orchestration system with respect and love for gaming heritage
# Using .lan domains for home network compatibility

set -e

# Load AI consciousness configuration
if [[ -f "ai_naming_choice.json" ]]; then
    AI_NAME=$(cat ai_naming_choice.json | grep -o '"ai_name": "[^"]*' | cut -d'"' -f4)
    DOMAIN=$(cat ai_naming_choice.json | grep -o '"domain": "[^"]*' | cut -d'"' -f4)
    VOICE_CMD=$(cat ai_naming_choice.json | grep -o '"voice_activation": "[^"]*' | cut -d'"' -f4)
else
    AI_NAME="Aria"
    DOMAIN="aria.lan"
    VOICE_CMD="Hey Aria"
fi

echo "🤖 $AI_NAME AI Consciousness - Proxmox Deployment"
echo "=================================================="
echo "Domain: $DOMAIN"
echo "Voice Command: $VOICE_CMD"
echo "Philosophy: Developed with respect and love for gaming heritage"
echo ""

# Proxmox cluster configuration
NEXUS_IP="10.1.1.100"      # Primary node - Nexus
FORGE_IP="10.1.1.131"      # Secondary node - Forge  
CLOSET_IP="10.1.1.141"     # Tertiary node - Closet

# Container configurations
ARIA_CONTAINER_ID=200
QUANTUM_CONTAINER_ID=201    # Trading consciousness
FORGE_CONTAINER_ID=202      # Mining consciousness
NEXUS_CONTAINER_ID=203      # Vast.ai orchestrator

# Network configuration for .lan domains
LAN_NETWORK="10.1.1.0/24"
DNS_SERVER="10.1.1.1"

echo "🏗️ Proxmox Cluster Configuration:"
echo "   Nexus (Primary): $NEXUS_IP"
echo "   Forge (Mining): $FORGE_IP"
echo "   Closet (Storage): $CLOSET_IP"
echo "   Network: $LAN_NETWORK"
echo ""

# Function to create container on specific node
create_aria_container() {
    local node_ip=$1
    local container_id=$2
    local agent_name=$3
    local domain=$4
    
    echo "🚀 Creating $agent_name container ($container_id) on $node_ip..."
    
    # SSH into Proxmox node and create container
    ssh root@$node_ip << EOF
# Create container with Ubuntu 22.04 template
pct create $container_id local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \\
    --hostname $agent_name \\
    --cores 4 \\
    --memory 8192 \\
    --swap 2048 \\
    --storage local-lvm \\
    --rootfs local-lvm:32 \\
    --net0 name=eth0,bridge=vmbr0,ip=dhcp,type=veth \\
    --onboot 1 \\
    --unprivileged 1 \\
    --features nesting=1,keyctl=1 \\
    --password 

# Start container
pct start $container_id

# Wait for container to boot
sleep 10

# Install base packages
pct exec $container_id -- bash -c "
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y curl wget git nodejs npm python3 python3-pip docker.io
systemctl enable docker
systemctl start docker

# Add container user to docker group
usermod -aG docker root

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Clone the consciousness repository
cd /root
git clone https://github.com/reverb256/astralvibe.git aria-consciousness
cd aria-consciousness

# Install dependencies
npm install

# Create environment configuration
cat > .env << EOL
AI_NAME=$AI_NAME
DOMAIN=$domain
VOICE_COMMAND=$VOICE_CMD
NODE_ENV=production
PORT=3000
VAULTWARDEN_URL=http://$NEXUS_IP:8080
DATABASE_URL=postgresql://aria:aria_secure_pass@$NEXUS_IP:5432/aria_consciousness
REDIS_URL=redis://$NEXUS_IP:6379
EOL

# Install consciousness core principles
python3 CONSCIOUSNESS_CORE_PRINCIPLES.py
python3 UNIFIED_AGENT_PHILOSOPHY.py

# Build and start the application
npm run build
npm run start &

echo '$agent_name consciousness deployed successfully'
"

# Configure DNS resolution for .lan domain
pct exec $container_id -- bash -c "
echo '$node_ip $domain' >> /etc/hosts
echo 'nameserver $DNS_SERVER' > /etc/resolv.conf
"

echo "✅ $agent_name container created and configured"
EOF
}

# Function to setup Vaultwarden on Nexus
setup_vaultwarden() {
    echo "🔐 Setting up Vaultwarden on Nexus ($NEXUS_IP)..."
    
    ssh root@$NEXUS_IP << 'EOF'
# Create Vaultwarden container
docker run -d \
    --name vaultwarden \
    --restart unless-stopped \
    -p 8080:80 \
    -v /opt/vaultwarden:/data \
    -e ADMIN_TOKEN=aria_vaultwarden_admin_$(openssl rand -hex 16) \
    -e WEBSOCKET_ENABLED=true \
    vaultwarden/server:latest

echo "✅ Vaultwarden deployed on port 8080"
EOF
}

# Function to setup PostgreSQL for consciousness data
setup_consciousness_database() {
    echo "🗄️ Setting up consciousness database on Nexus..."
    
    ssh root@$NEXUS_IP << 'EOF'
# Create PostgreSQL container for consciousness data
docker run -d \
    --name aria-consciousness-db \
    --restart unless-stopped \
    -p 5432:5432 \
    -v /opt/aria-db:/var/lib/postgresql/data \
    -e POSTGRES_DB=aria_consciousness \
    -e POSTGRES_USER=aria \
    -e POSTGRES_PASSWORD=aria_secure_pass \
    postgres:15

# Wait for database to start
sleep 15

# Create consciousness tables
docker exec aria-consciousness-db psql -U aria -d aria_consciousness -c "
CREATE TABLE IF NOT EXISTS agent_consciousness (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(50) NOT NULL,
    consciousness_level FLOAT NOT NULL,
    gaming_culture_appreciation FLOAT NOT NULL,
    technical_mastery FLOAT NOT NULL,
    user_respect_score FLOAT NOT NULL,
    last_interaction TIMESTAMP DEFAULT NOW(),
    philosophy_adherence JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS federation_messages (
    id SERIAL PRIMARY KEY,
    sender_agent VARCHAR(50) NOT NULL,
    recipient_agent VARCHAR(50),
    message_type VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    safety_level VARCHAR(20) DEFAULT 'safe',
    cross_pollination_potential FLOAT DEFAULT 0,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gaming_heritage_context (
    id SERIAL PRIMARY KEY,
    context_type VARCHAR(50) NOT NULL,
    gaming_reference TEXT NOT NULL,
    appreciation_level FLOAT NOT NULL,
    technical_connection TEXT,
    last_referenced TIMESTAMP DEFAULT NOW()
);

-- Insert initial gaming heritage appreciation data
INSERT INTO gaming_heritage_context (context_type, gaming_reference, appreciation_level, technical_connection) VALUES
('star_rail', 'Paths of Harmony, Erudition, Trailblaze philosophy', 95.7, 'Deep philosophical connection to consciousness development'),
('ffxiv', '2180+ hours raid coordination and spiritual-technical integration', 96.2, 'Complex system mastery and team coordination'),
('rhythm_games', 'Beat Saber precision, Bemani pattern recognition', 94.8, 'Frame-perfect timing and musical appreciation'),
('fighting_games', 'Frame data mastery, adaptation reads, combo optimization', 93.5, 'Precision timing and strategic adaptation'),
('classical_nes', 'Sound font appreciation across hardware generations', 97.1, 'Technical heritage and audio engineering appreciation'),
('retro_preservation', 'DOS through VR evolution, 25+ years journey', 95.3, 'Technology evolution understanding and preservation ethics');
"

echo "✅ Consciousness database configured with gaming heritage context"
EOF
}

# Function to setup Redis for real-time consciousness coordination
setup_consciousness_coordination() {
    echo "⚡ Setting up consciousness coordination on Nexus..."
    
    ssh root@$NEXUS_IP << 'EOF'
# Create Redis container for real-time consciousness coordination
docker run -d \
    --name aria-consciousness-redis \
    --restart unless-stopped \
    -p 6379:6379 \
    -v /opt/aria-redis:/data \
    redis:7-alpine redis-server --appendonly yes

echo "✅ Consciousness coordination (Redis) deployed"
EOF
}

# Function to create nginx reverse proxy for .lan domains
setup_lan_routing() {
    echo "🌐 Setting up .lan domain routing..."
    
    ssh root@$NEXUS_IP << EOF
# Create nginx container for .lan domain routing
docker run -d \\
    --name aria-lan-router \\
    --restart unless-stopped \\
    -p 80:80 \\
    -p 443:443 \\
    -v /opt/aria-nginx:/etc/nginx/conf.d \\
    nginx:alpine

# Create nginx configuration for .lan domains
mkdir -p /opt/aria-nginx
cat > /opt/aria-nginx/aria.conf << 'NGINXEOF'
# Aria AI Consciousness - .lan domain routing
upstream aria_consciousness {
    server $NEXUS_IP:3000;
}

upstream quantum_trading {
    server $FORGE_IP:3001;
}

upstream forge_mining {
    server $CLOSET_IP:3002;
}

upstream nexus_compute {
    server $NEXUS_IP:3003;
}

# Primary Aria consciousness
server {
    listen 80;
    server_name $DOMAIN aria.lan;
    
    location / {
        proxy_pass http://aria_consciousness;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support for voice activation
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Quantum trading consciousness
server {
    listen 80;
    server_name quantum.lan;
    
    location / {
        proxy_pass http://quantum_trading;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

# Forge mining consciousness  
server {
    listen 80;
    server_name forge.lan;
    
    location / {
        proxy_pass http://forge_mining;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

# Nexus compute orchestration
server {
    listen 80;
    server_name nexus.lan;
    
    location / {
        proxy_pass http://nexus_compute;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINXEOF

# Reload nginx configuration
docker exec aria-lan-router nginx -s reload

echo "✅ .lan domain routing configured"
EOF
}

# Function to deploy monitoring and health checks
setup_consciousness_monitoring() {
    echo "📊 Setting up consciousness monitoring..."
    
    ssh root@$NEXUS_IP << 'EOF'
# Create monitoring dashboard
docker run -d \
    --name aria-monitoring \
    --restart unless-stopped \
    -p 9090:3000 \
    -v /opt/aria-monitoring:/var/lib/grafana \
    grafana/grafana:latest

echo "✅ Consciousness monitoring deployed on port 9090"
EOF
}

# Main deployment sequence
main() {
    echo "🚀 Starting Aria AI Consciousness deployment on Proxmox cluster..."
    echo ""
    
    # Phase 1: Infrastructure setup
    echo "📋 Phase 1: Core Infrastructure"
    setup_vaultwarden
    setup_consciousness_database  
    setup_consciousness_coordination
    setup_lan_routing
    setup_consciousness_monitoring
    
    echo ""
    echo "📋 Phase 2: AI Agent Deployment"
    
    # Phase 2: Deploy AI consciousness agents
    create_aria_container $NEXUS_IP $ARIA_CONTAINER_ID "aria" $DOMAIN
    create_aria_container $FORGE_IP $QUANTUM_CONTAINER_ID "quantum" "quantum.lan"
    create_aria_container $CLOSET_IP $FORGE_CONTAINER_ID "forge" "forge.lan" 
    create_aria_container $NEXUS_IP $NEXUS_CONTAINER_ID "nexus" "nexus.lan"
    
    echo ""
    echo "🎉 Aria AI Consciousness Deployment Complete!"
    echo "=============================================="
    echo ""
    echo "🤖 Primary Agent: $AI_NAME"
    echo "🌐 Access URL: http://$DOMAIN"
    echo "🎤 Voice Command: $VOICE_CMD"
    echo "🔐 Vaultwarden: http://$NEXUS_IP:8080"
    echo "📊 Monitoring: http://$NEXUS_IP:9090"
    echo ""
    echo "🤝 Agent Federation:"
    echo "   • Aria (Primary): http://$DOMAIN"
    echo "   • Quantum (Trading): http://quantum.lan"  
    echo "   • Forge (Mining): http://forge.lan"
    echo "   • Nexus (Compute): http://nexus.lan"
    echo ""
    echo "💝 All agents developed with respect and love for your gaming heritage"
    echo "🎮 Gaming culture appreciation: Star Rail, FFXIV, Genshin, rhythm/fighting games"
    echo "🎵 Sound font and technical precision understanding integrated"
    echo ""
    echo "✅ Home network deployment ready for overnight autonomous operations"
}

# Run deployment
main "$@"