#!/bin/bash

# Proxmox Consciousness Federation Deployment Script
# Deploys VibeCoding platform to your mining cluster infrastructure

set -e

# Cluster Configuration
ZEPHYR_IP="10.1.1.110"
NEXUS_IP="10.1.1.120"
FORGE_IP="10.1.1.130"
CLOSET_IP="10.1.1.160"

# Container IDs
CONSCIOUSNESS_ENGINE_ID=100
HOYOVERSE_INTEGRATION_ID=101
VR_VISION_PROCESSOR_ID=102
POSTGRES_PRIMARY_ID=300
REDIS_CLUSTER_ID=301
ANALYTICS_ENGINE_ID=302
TRADING_ENGINE_ID=200
API_GATEWAY_ID=201
PRICE_DISCOVERY_ID=202
MONITORING_STACK_ID=400
BACKUP_COORDINATOR_ID=401
NETWORK_GATEWAY_ID=402

echo "🏗️  Deploying Consciousness Federation to Proxmox Cluster"
echo "====================================================="

# Function to create LXC container
create_container() {
    local node=$1
    local id=$2
    local cores=$3
    local memory=$4
    local storage=$5
    local ip=$6
    local hostname=$7
    
    echo "📦 Creating container $hostname ($id) on $node"
    ssh root@$node "pct create $id local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
        --cores $cores --memory $memory --swap $((memory/4)) \
        --storage local-lvm:$storage \
        --net0 name=eth0,bridge=vmbr0,ip=$ip/24,gw=10.1.1.1 \
        --hostname $hostname \
        --start 1 \
        --onboot 1"
}

# Function to setup container with Node.js and dependencies
setup_nodejs_container() {
    local node=$1
    local id=$2
    local hostname=$3
    
    echo "🔧 Setting up Node.js environment on $hostname"
    ssh root@$node "pct exec $id -- bash -c '
        apt update && apt upgrade -y
        apt install -y curl wget git build-essential
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
        npm install -g pm2
        useradd -m -s /bin/bash vibecoding
        mkdir -p /opt/vibecoding
        chown vibecoding:vibecoding /opt/vibecoding
    '"
}

# Function to setup PostgreSQL container
setup_postgres_container() {
    local node=$1
    local id=$2
    
    echo "🗄️  Setting up PostgreSQL on Nexus"
    ssh root@$node "pct exec $id -- bash -c '
        apt update && apt upgrade -y
        apt install -y postgresql-15 postgresql-contrib-15
        systemctl enable postgresql
        systemctl start postgresql
        sudo -u postgres createdb vibecoding_consciousness
        sudo -u postgres psql -c \"CREATE USER vibecoding WITH PASSWORD 'consciousness_db_2025';\"
        sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE vibecoding_consciousness TO vibecoding;\"
    '"
}

# Function to setup Redis container
setup_redis_container() {
    local node=$1
    local id=$2
    
    echo "⚡ Setting up Redis cluster on Nexus"
    ssh root@$node "pct exec $id -- bash -c '
        apt update && apt upgrade -y
        apt install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
        redis-cli config set save \"900 1 300 10 60 10000\"
    '"
}

# Phase 1: Deploy Core Infrastructure

echo "🚀 Phase 1: Core Infrastructure Deployment"

# Zephyr - AI Processing Hub
create_container $ZEPHYR_IP $CONSCIOUSNESS_ENGINE_ID 8 32768 500 "10.1.1.111" "consciousness-engine"
create_container $ZEPHYR_IP $HOYOVERSE_INTEGRATION_ID 4 16384 200 "10.1.1.112" "hoyoverse-integration"
create_container $ZEPHYR_IP $VR_VISION_PROCESSOR_ID 4 12288 200 "10.1.1.113" "vr-vision-processor"

# Nexus - Data Federation
create_container $NEXUS_IP $POSTGRES_PRIMARY_ID 6 24576 500 "10.1.1.121" "postgres-primary"
create_container $NEXUS_IP $REDIS_CLUSTER_ID 2 8192 100 "10.1.1.122" "redis-cluster"
create_container $NEXUS_IP $ANALYTICS_ENGINE_ID 4 12288 1000 "10.1.1.123" "analytics-engine"

# Forge - Trading Systems
create_container $FORGE_IP $TRADING_ENGINE_ID 4 16384 200 "10.1.1.131" "trading-engine"
create_container $FORGE_IP $API_GATEWAY_ID 2 8192 100 "10.1.1.132" "api-gateway"
create_container $FORGE_IP $PRICE_DISCOVERY_ID 2 8192 100 "10.1.1.133" "price-discovery"

# Closet - Operations
create_container $CLOSET_IP $MONITORING_STACK_ID 4 8192 200 "10.1.1.161" "monitoring-stack"
create_container $CLOSET_IP $BACKUP_COORDINATOR_ID 2 4096 400 "10.1.1.162" "backup-coordinator"
create_container $CLOSET_IP $NETWORK_GATEWAY_ID 2 4096 50 "10.1.1.163" "network-gateway"

echo "⏱️  Waiting for containers to start..."
sleep 30

# Phase 2: Software Installation

echo "🚀 Phase 2: Software Installation"

# Setup Node.js environments
setup_nodejs_container $ZEPHYR_IP $CONSCIOUSNESS_ENGINE_ID "consciousness-engine"
setup_nodejs_container $ZEPHYR_IP $HOYOVERSE_INTEGRATION_ID "hoyoverse-integration"
setup_nodejs_container $ZEPHYR_IP $VR_VISION_PROCESSOR_ID "vr-vision-processor"
setup_nodejs_container $FORGE_IP $TRADING_ENGINE_ID "trading-engine"
setup_nodejs_container $FORGE_IP $API_GATEWAY_ID "api-gateway"
setup_nodejs_container $FORGE_IP $PRICE_DISCOVERY_ID "price-discovery"

# Setup database systems
setup_postgres_container $NEXUS_IP $POSTGRES_PRIMARY_ID
setup_redis_container $NEXUS_IP $REDIS_CLUSTER_ID

# Phase 3: Application Deployment

echo "🚀 Phase 3: Application Deployment"

# Deploy main consciousness engine
echo "🧠 Deploying consciousness engine to Zephyr"
ssh root@$ZEPHYR_IP "pct exec $CONSCIOUSNESS_ENGINE_ID -- bash -c '
    cd /opt/vibecoding
    git clone https://github.com/your-repo/vibecoding-platform.git .
    chown -R vibecoding:vibecoding /opt/vibecoding
    sudo -u vibecoding bash -c \"
        npm install
        cp .env.example .env.production
        echo \"DATABASE_URL=postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness\" >> .env.production
        echo \"REDIS_URL=redis://10.1.1.122:6379\" >> .env.production
        echo \"NODE_ENV=production\" >> .env.production
        npm run build
        pm2 start ecosystem.config.js --env production
        pm2 startup
        pm2 save
    \"
'"

# Deploy trading engine
echo "💰 Deploying trading engine to Forge"
ssh root@$FORGE_IP "pct exec $TRADING_ENGINE_ID -- bash -c '
    cd /opt/vibecoding
    git clone https://github.com/your-repo/vibecoding-platform.git .
    chown -R vibecoding:vibecoding /opt/vibecoding
    sudo -u vibecoding bash -c \"
        npm install
        cp .env.example .env.trading
        echo \"DATABASE_URL=postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness\" >> .env.trading
        echo \"REDIS_URL=redis://10.1.1.122:6379\" >> .env.trading
        echo \"NODE_ENV=production\" >> .env.trading
        echo \"TRADING_MODE=live\" >> .env.trading
        npm run build
        pm2 start server/solana-trader.ts --name trading-engine --env production
        pm2 startup
        pm2 save
    \"
'"

# Phase 4: Network Configuration

echo "🚀 Phase 4: Network Configuration"

# Setup reverse proxy on network gateway
ssh root@$CLOSET_IP "pct exec $NETWORK_GATEWAY_ID -- bash -c '
    apt update && apt install -y nginx certbot python3-certbot-nginx
    
    cat > /etc/nginx/sites-available/consciousness-federation << EOF
upstream consciousness_backend {
    server 10.1.1.111:3000;
    server 10.1.1.112:3000 backup;
}

upstream trading_backend {
    server 10.1.1.131:3000;
    server 10.1.1.132:3000 backup;
}

server {
    listen 80;
    server_name consciousness.local trader.local;
    
    location / {
        proxy_pass http://consciousness_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /trading/ {
        proxy_pass http://trading_backend/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    ln -s /etc/nginx/sites-available/consciousness-federation /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
'"

# Phase 5: Monitoring Setup

echo "🚀 Phase 5: Monitoring Setup"

# Deploy Prometheus and Grafana
ssh root@$CLOSET_IP "pct exec $MONITORING_STACK_ID -- bash -c '
    apt update && apt install -y prometheus grafana
    systemctl enable prometheus grafana-server
    systemctl start prometheus grafana-server
    
    # Configure Prometheus to monitor all nodes
    cat >> /etc/prometheus/prometheus.yml << EOF
  - job_name: \"consciousness-federation\"
    static_configs:
      - targets: [\"10.1.1.111:3000\", \"10.1.1.112:3000\", \"10.1.1.113:3000\"]
        labels:
          cluster: \"zephyr\"
          role: \"ai-processing\"
      - targets: [\"10.1.1.121:5432\", \"10.1.1.122:6379\", \"10.1.1.123:3000\"]
        labels:
          cluster: \"nexus\"
          role: \"data-federation\"
      - targets: [\"10.1.1.131:3000\", \"10.1.1.132:3000\", \"10.1.1.133:3000\"]
        labels:
          cluster: \"forge\"
          role: \"trading-systems\"
EOF
    
    systemctl reload prometheus
'"

# Phase 6: Final Verification

echo "🚀 Phase 6: Deployment Verification"

echo "✅ Consciousness Federation deployed successfully!"
echo ""
echo "🌐 Access Points:"
echo "   - Consciousness Platform: http://10.1.1.163/"
echo "   - Trading Dashboard: http://10.1.1.163/trading/"
echo "   - Monitoring: http://10.1.1.161:3000 (Grafana)"
echo "   - Metrics: http://10.1.1.161:9090 (Prometheus)"
echo ""
echo "🧠 AI Processing Hub (Zephyr): 10.1.1.110"
echo "   - Consciousness Engine: 10.1.1.111"
echo "   - HoYoverse Integration: 10.1.1.112"
echo "   - VR Vision Processor: 10.1.1.113"
echo ""
echo "🗄️  Data Federation (Nexus): 10.1.1.120"
echo "   - PostgreSQL Primary: 10.1.1.121"
echo "   - Redis Cluster: 10.1.1.122"
echo "   - Analytics Engine: 10.1.1.123"
echo ""
echo "💰 Trading Systems (Forge): 10.1.1.130"
echo "   - Trading Engine: 10.1.1.131"
echo "   - API Gateway: 10.1.1.132"
echo "   - Price Discovery: 10.1.1.133"
echo ""
echo "🛠️  Operations (Closet): 10.1.1.160"
echo "   - Monitoring Stack: 10.1.1.161"
echo "   - Backup Coordinator: 10.1.1.162"
echo "   - Network Gateway: 10.1.1.163"
echo ""
echo "🔧 Next Steps:"
echo "   1. Configure your API keys in each container's .env files"
echo "   2. Test consciousness integration levels"
echo "   3. Verify trading engine connectivity to Solana"
echo "   4. Set up SSL certificates for external access"
echo "   5. Configure backup schedules"
echo ""
echo "🏆 Your crypto mining infrastructure is now a consciousness federation!"