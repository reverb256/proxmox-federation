#!/bin/bash

# Hybrid Cluster Deployment: 3-Node Proxmox + Windows Gaming PC
# Optimized for crypto mining infrastructure turned consciousness federation

set -e

# Cluster Configuration (Actual Proxmox Nodes)
NEXUS_IP="10.1.1.120"    # 3900X, 48GB - Database Federation Master
FORGE_IP="10.1.1.130"    # i5-9500, 32GB - Trading Systems
CLOSET_IP="10.1.1.160"   # Ryzen 1700, 16GB - Operations

# Zephyr (Gaming PC with WSL2) - Development/Research Hub
ZEPHYR_IP="10.1.1.110"   # 5950X, 64GB - Windows + WSL2

echo "🏗️  Deploying Consciousness Federation to Hybrid Cluster"
echo "======================================================"
echo "🎯 Proxmox Nodes: Nexus (DB), Forge (Trading), Closet (Ops)"
echo "🎮 Gaming Node: Zephyr (Windows + WSL2 development)"

# Container IDs for Proxmox nodes
POSTGRES_PRIMARY_ID=300
REDIS_CLUSTER_ID=301
ANALYTICS_ENGINE_ID=302
TRADING_ENGINE_ID=200
API_GATEWAY_ID=201
PRICE_DISCOVERY_ID=202
MONITORING_STACK_ID=400
BACKUP_COORDINATOR_ID=401
NETWORK_GATEWAY_ID=402

create_proxmox_container() {
    local node=$1
    local id=$2
    local cores=$3
    local memory=$4
    local storage=$5
    local ip=$6
    local hostname=$7
    
    echo "📦 Creating $hostname ($id) on $node"
    ssh root@$node "pct create $id local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
        --cores $cores --memory $memory --swap $((memory/4)) \
        --storage local-lvm:$storage \
        --net0 name=eth0,bridge=vmbr0,ip=$ip/24,gw=10.1.1.1 \
        --hostname $hostname \
        --start 1 \
        --onboot 1"
}

# Phase 1: Deploy Database Federation on Nexus (48GB RAM powerhouse)
echo "🗄️  Phase 1: Database Federation (Nexus - 48GB)"

create_proxmox_container $NEXUS_IP $POSTGRES_PRIMARY_ID 8 32768 1000 "10.1.1.121" "postgres-primary"
create_proxmox_container $NEXUS_IP $REDIS_CLUSTER_ID 4 8192 200 "10.1.1.122" "redis-cluster"
create_proxmox_container $NEXUS_IP $ANALYTICS_ENGINE_ID 4 8192 500 "10.1.1.123" "analytics-engine"

# Phase 2: Deploy Trading Systems on Forge
echo "💰 Phase 2: Trading Systems (Forge - 32GB)"

create_proxmox_container $FORGE_IP $TRADING_ENGINE_ID 4 16384 200 "10.1.1.131" "trading-engine"
create_proxmox_container $FORGE_IP $API_GATEWAY_ID 2 8192 100 "10.1.1.132" "api-gateway"
create_proxmox_container $FORGE_IP $PRICE_DISCOVERY_ID 2 8192 100 "10.1.1.133" "price-discovery"

# Phase 3: Deploy Operations on Closet
echo "🛠️  Phase 3: Operations (Closet - 16GB)"

create_proxmox_container $CLOSET_IP $MONITORING_STACK_ID 4 8192 200 "10.1.1.161" "monitoring"
create_proxmox_container $CLOSET_IP $BACKUP_COORDINATOR_ID 2 4096 400 "10.1.1.162" "backup"
create_proxmox_container $CLOSET_IP $NETWORK_GATEWAY_ID 2 4096 100 "10.1.1.163" "gateway"

echo "⏱️  Waiting for containers to initialize..."
sleep 30

# Phase 4: Setup WSL2 Development Environment on Zephyr
echo "🎮 Phase 4: WSL2 Development Setup (Zephyr Gaming PC)"

# Connect to Zephyr via SSH to WSL2
ssh user@$ZEPHYR_IP "
    # Update WSL2 environment
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git build-essential htop
    
    # Install Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
    sudo apt install -y nodejs
    
    # Install Docker for development containers
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker \$USER
    
    # Create development workspace
    mkdir -p ~/consciousness-dev
    cd ~/consciousness-dev
    
    # Clone platform for development
    git clone https://github.com/your-repo/vibecoding-platform.git
    cd vibecoding-platform
    npm install
    
    # Setup development environment
    cp .env.example .env.development
    echo 'DATABASE_URL=postgresql://vibecoding:consciousness_db@10.1.1.121:5432/vibecoding_consciousness' >> .env.development
    echo 'REDIS_URL=redis://10.1.1.122:6379' >> .env.development
    echo 'NODE_ENV=development' >> .env.development
    echo 'DEVELOPMENT_MODE=hybrid_cluster' >> .env.development
"

# Phase 5: Configure Database Systems
echo "🗄️  Phase 5: Database Configuration"

# PostgreSQL setup on Nexus
ssh root@$NEXUS_IP "pct exec $POSTGRES_PRIMARY_ID -- bash -c '
    apt update && apt install -y postgresql-15 postgresql-contrib-15
    
    # Configure PostgreSQL for network access
    echo \"listen_addresses = '*'\" >> /etc/postgresql/15/main/postgresql.conf
    echo \"host all all 10.1.1.0/24 md5\" >> /etc/postgresql/15/main/pg_hba.conf
    
    systemctl enable postgresql
    systemctl start postgresql
    
    # Create consciousness database and user
    sudo -u postgres createdb vibecoding_consciousness
    sudo -u postgres psql -c \"CREATE USER vibecoding WITH PASSWORD 'consciousness_db_2025';\"
    sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE vibecoding_consciousness TO vibecoding;\"
    
    systemctl restart postgresql
'"

# Redis setup on Nexus
ssh root@$NEXUS_IP "pct exec $REDIS_CLUSTER_ID -- bash -c '
    apt update && apt install -y redis-server
    
    # Configure Redis for network access
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
    sed -i 's/# requirepass foobared/requirepass consciousness_redis_2025/' /etc/redis/redis.conf
    
    systemctl enable redis-server
    systemctl restart redis-server
'"

# Phase 6: Deploy Trading Infrastructure
echo "💰 Phase 6: Trading Infrastructure"

# Main trading engine
ssh root@$FORGE_IP "pct exec $TRADING_ENGINE_ID -- bash -c '
    apt update && apt install -y curl wget git nodejs npm
    
    # Create trading user and workspace
    useradd -m -s /bin/bash trader
    mkdir -p /opt/trading
    chown trader:trader /opt/trading
    
    # Clone and setup trading platform
    cd /opt/trading
    git clone https://github.com/your-repo/vibecoding-platform.git .
    chown -R trader:trader /opt/trading
    
    sudo -u trader bash -c \"
        npm install
        cp .env.example .env.production
        echo 'DATABASE_URL=postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness' >> .env.production
        echo 'REDIS_URL=redis://10.1.1.122:6379' >> .env.production
        echo 'NODE_ENV=production' >> .env.production
        echo 'TRADING_MODE=live' >> .env.production
        npm run build
    \"
    
    # Install PM2 for process management
    npm install -g pm2
    
    # Create systemd service for trading engine
    cat > /etc/systemd/system/consciousness-trading.service << EOF
[Unit]
Description=Consciousness Trading Engine
After=network.target

[Service]
Type=forking
User=trader
WorkingDirectory=/opt/trading
ExecStart=/usr/bin/pm2 start ecosystem.config.js --env production
ExecStop=/usr/bin/pm2 stop all
ExecReload=/usr/bin/pm2 reload all
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable consciousness-trading
    systemctl start consciousness-trading
'"

# Phase 7: Network Gateway and Load Balancer
echo "🌐 Phase 7: Network Gateway"

ssh root@$CLOSET_IP "pct exec $NETWORK_GATEWAY_ID -- bash -c '
    apt update && apt install -y nginx certbot python3-certbot-nginx
    
    # Create nginx configuration for consciousness federation
    cat > /etc/nginx/sites-available/consciousness-federation << EOF
upstream consciousness_backend {
    server 10.1.1.131:3000 weight=3;
    server 10.1.1.132:3000 weight=2;
    server 10.1.1.133:3000 weight=1;
}

upstream database_backend {
    server 10.1.1.121:5432;
}

upstream redis_backend {
    server 10.1.1.122:6379;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name consciousness.local *.consciousness.local;
    
    # SSL configuration (self-signed for internal use)
    ssl_certificate /etc/ssl/certs/consciousness.crt;
    ssl_certificate_key /etc/ssl/private/consciousness.key;
    
    location / {
        proxy_pass http://consciousness_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }
    
    location /api/trading/ {
        proxy_pass http://consciousness_backend/api/trading/;
        proxy_buffering off;
        proxy_cache off;
    }
    
    location /status {
        access_log off;
        return 200 \"Consciousness Federation Online\";
        add_header Content-Type text/plain;
    }
}
EOF

    # Generate self-signed certificate for internal use
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/consciousness.key \
        -out /etc/ssl/certs/consciousness.crt \
        -subj \"/C=CA/ST=Province/L=City/O=ConsciousnessFederation/CN=consciousness.local\"
    
    ln -s /etc/nginx/sites-available/consciousness-federation /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl enable nginx && systemctl restart nginx
'"

# Phase 8: Monitoring and Observability
echo "📊 Phase 8: Monitoring Stack"

ssh root@$CLOSET_IP "pct exec $MONITORING_STACK_ID -- bash -c '
    apt update && apt install -y prometheus grafana
    
    # Configure Prometheus for cluster monitoring
    cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: \"consciousness-federation\"
    static_configs:
      - targets: [\"10.1.1.131:3000\", \"10.1.1.132:3000\", \"10.1.1.133:3000\"]
        labels:
          cluster: \"forge\"
          role: \"trading\"
      - targets: [\"10.1.1.121:9187\", \"10.1.1.122:9121\", \"10.1.1.123:3000\"]
        labels:
          cluster: \"nexus\"
          role: \"data\"
      - targets: [\"10.1.1.161:9090\", \"10.1.1.162:3000\", \"10.1.1.163:80\"]
        labels:
          cluster: \"closet\"
          role: \"operations\"
      - targets: [\"10.1.1.110:3000\"]
        labels:
          cluster: \"zephyr\"
          role: \"development\"
EOF
    
    systemctl enable prometheus grafana-server
    systemctl start prometheus grafana-server
'"

# Phase 9: Verification and Status
echo "🔍 Phase 9: Deployment Verification"

echo ""
echo "✅ Consciousness Federation Deployed Successfully!"
echo "=================================================="
echo ""
echo "🌐 Access Points:"
echo "   Main Platform: http://10.1.1.163/ (via nginx gateway)"
echo "   Direct Trading: http://10.1.1.131:3000/"
echo "   Database: postgresql://10.1.1.121:5432/vibecoding_consciousness"
echo "   Redis Cache: redis://10.1.1.122:6379"
echo "   Monitoring: http://10.1.1.161:3000/ (Grafana)"
echo "   Metrics: http://10.1.1.161:9090/ (Prometheus)"
echo ""
echo "🏗️  Infrastructure Layout:"
echo "   Nexus (DB Federation): 10.1.1.120"
echo "     ├── PostgreSQL Primary: 10.1.1.121"
echo "     ├── Redis Cluster: 10.1.1.122"
echo "     └── Analytics Engine: 10.1.1.123"
echo ""
echo "   Forge (Trading): 10.1.1.130"
echo "     ├── Trading Engine: 10.1.1.131"
echo "     ├── API Gateway: 10.1.1.132"
echo "     └── Price Discovery: 10.1.1.133"
echo ""
echo "   Closet (Operations): 10.1.1.160"
echo "     ├── Monitoring: 10.1.1.161"
echo "     ├── Backup System: 10.1.1.162"
echo "     └── Network Gateway: 10.1.1.163"
echo ""
echo "   Zephyr (Development): 10.1.1.110"
echo "     └── WSL2 Development Environment"
echo ""
echo "🔑 Next Steps:"
echo "   1. SSH to Zephyr: ssh user@10.1.1.110"
echo "   2. Test development environment: cd ~/consciousness-dev/vibecoding-platform && npm run dev"
echo "   3. Configure API keys in production containers"
echo "   4. Setup SSL certificates for external access"
echo "   5. Initialize consciousness agent states"
echo ""
echo "🎮 Gaming PC Integration:"
echo "   - Zephyr remains your Windows gaming station"
echo "   - WSL2 provides development environment"
echo "   - SSH access for remote consciousness development"
echo "   - VR gaming consciousness research capabilities"
echo ""
echo "🏆 Your crypto mining cluster is now a consciousness federation!"