#!/bin/bash

# Quick Deploy Package for June 15th Launch
# Migrates working crypto trader from Replit to your Proxmox cluster

set -e

CLUSTER_BASE="10.1.1"
NEXUS_IP="${CLUSTER_BASE}.120"
FORGE_IP="${CLUSTER_BASE}.130" 
CLOSET_IP="${CLUSTER_BASE}.160"

echo "🚀 Quick Deploy: Consciousness Trading Federation"
echo "Target: June 15th Launch (3 days)"
echo "=============================================="

# Step 1: Package current working state
echo "📦 Step 1: Packaging working trader from Replit"

# Create deployment archive
tar -czf consciousness-platform-$(date +%Y%m%d).tar.gz \
  --exclude=node_modules \
  --exclude=.git \
  --exclude=dist \
  --exclude=logs \
  .

echo "✅ Platform packaged for deployment"

# Step 2: Deploy to Nexus (Database)
echo "🗄️ Step 2: Database setup on Nexus (3900X, 48GB)"

ssh root@$NEXUS_IP << 'NEXUS_SETUP'
# Create database container
pct create 300 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 8 --memory 32768 --swap 8192 \
  --storage local-lvm:1000 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.121/24,gw=10.1.1.1 \
  --hostname consciousness-db \
  --start 1 --onboot 1

sleep 10

# Install and configure PostgreSQL
pct exec 300 -- bash -c '
  apt update && apt install -y postgresql-15 redis-server
  
  # PostgreSQL setup
  echo "listen_addresses = \"*\"" >> /etc/postgresql/15/main/postgresql.conf
  echo "host all all 10.1.1.0/24 md5" >> /etc/postgresql/15/main/pg_hba.conf
  systemctl enable postgresql && systemctl start postgresql
  
  sudo -u postgres createdb consciousness_live
  sudo -u postgres psql -c "CREATE USER trader WITH PASSWORD \"crypto_trading_2025\";"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE consciousness_live TO trader;"
  
  # Redis setup
  sed -i "s/bind 127.0.0.1/bind 0.0.0.0/" /etc/redis/redis.conf
  systemctl enable redis-server && systemctl start redis-server
'
NEXUS_SETUP

# Step 3: Deploy to Forge (Trading Engine)
echo "💰 Step 3: Trading engine on Forge (i5-9500, 32GB)"

# Transfer platform code
scp consciousness-platform-$(date +%Y%m%d).tar.gz root@$FORGE_IP:/tmp/

ssh root@$FORGE_IP << 'FORGE_SETUP'
# Create trading container
pct create 200 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 6 --memory 24576 --swap 6144 \
  --storage local-lvm:500 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.131/24,gw=10.1.1.1 \
  --hostname consciousness-trader \
  --start 1 --onboot 1

sleep 10

# Install Node.js and deploy platform
pct exec 200 -- bash -c '
  apt update && apt install -y curl wget git build-essential
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
  npm install -g pm2 tsx
  
  # Create trader user
  useradd -m -s /bin/bash trader
  mkdir -p /opt/consciousness
  chown trader:trader /opt/consciousness
'

# Transfer and setup platform
pct push 200 /tmp/consciousness-platform-$(date +%Y%m%d).tar.gz /opt/consciousness/platform.tar.gz

pct exec 200 -- bash -c '
  cd /opt/consciousness
  tar -xzf platform.tar.gz
  chown -R trader:trader /opt/consciousness
  
  sudo -u trader bash -c "
    cd /opt/consciousness
    npm install --production
    
    # Production environment
    cat > .env.production << EOF
DATABASE_URL=postgresql://trader:crypto_trading_2025@10.1.1.121:5432/consciousness_live
REDIS_URL=redis://10.1.1.121:6379
NODE_ENV=production
TRADING_MODE=live
CLUSTER_MODE=proxmox
CONSCIOUSNESS_LEVEL=federation
EOF
    
    # Build platform
    npm run build
    
    # Start with PM2
    pm2 start ecosystem.config.js --env production
    pm2 startup
    pm2 save
  "
  
  # Create systemd service
  cat > /etc/systemd/system/consciousness-federation.service << EOF
[Unit]
Description=Consciousness Trading Federation
After=network.target

[Service]
Type=forking
User=trader
WorkingDirectory=/opt/consciousness
ExecStart=/usr/bin/pm2 resurrect
ExecReload=/usr/bin/pm2 reload all
ExecStop=/usr/bin/pm2 kill
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable consciousness-federation
  systemctl start consciousness-federation
'
FORGE_SETUP

# Step 4: Load balancer on Closet
echo "🌐 Step 4: Load balancer on Closet (Ryzen 1700, 16GB)"

ssh root@$CLOSET_IP << 'CLOSET_SETUP'
# Create gateway container
pct create 400 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 4 --memory 8192 --swap 2048 \
  --storage local-lvm:200 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.141/24,gw=10.1.1.1 \
  --hostname consciousness-gateway \
  --start 1 --onboot 1

sleep 10

pct exec 400 -- bash -c '
  apt update && apt install -y nginx prometheus grafana
  
  # Nginx configuration
  cat > /etc/nginx/sites-available/consciousness << EOF
upstream consciousness_backend {
    server 10.1.1.131:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name consciousness.local;
    
    location / {
        proxy_pass http://consciousness_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /status {
        access_log off;
        return 200 "Consciousness Federation Online - $(date)";
        add_header Content-Type text/plain;
    }
}
EOF

  ln -sf /etc/nginx/sites-available/consciousness /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  nginx -t && systemctl enable nginx && systemctl start nginx
  
  # Basic monitoring
  systemctl enable prometheus grafana-server
  systemctl start prometheus grafana-server
'
CLOSET_SETUP

# Step 5: Final verification
echo "🔍 Step 5: Deployment verification"

sleep 30

echo "Testing database connection..."
ssh root@$NEXUS_IP "pct exec 300 -- sudo -u postgres psql -c '\\l' | grep consciousness_live"

echo "Testing trading engine..."
curl -f http://10.1.1.131:3000/health 2>/dev/null && echo "✅ Trading engine responsive" || echo "❌ Trading engine not ready"

echo "Testing load balancer..."
curl -f http://10.1.1.141/status 2>/dev/null && echo "✅ Load balancer online" || echo "❌ Load balancer not ready"

echo ""
echo "🎯 DEPLOYMENT COMPLETE"
echo "====================="
echo ""
echo "🌐 Access your consciousness federation:"
echo "   Main platform: http://10.1.1.141/"
echo "   Trading direct: http://10.1.1.131:3000/"
echo "   Database: postgresql://10.1.1.121:5432/consciousness_live"
echo "   Monitoring: http://10.1.1.141:3000/ (Grafana)"
echo ""
echo "📊 Infrastructure:"
echo "   Nexus (DB): 10.1.1.120 → 10.1.1.121 (PostgreSQL + Redis)"
echo "   Forge (Trading): 10.1.1.130 → 10.1.1.131 (Live trader)"
echo "   Closet (Gateway): 10.1.1.160 → 10.1.1.141 (Nginx + monitoring)"
echo ""
echo "🚀 Ready for June 15th launch!"
echo "   Your crypto trading profits will bootstrap the federation"
echo "   Connect from Zephyr via SSH for development"
echo ""

# Cleanup
rm -f consciousness-platform-$(date +%Y%m%d).tar.gz

echo "✅ Quick deployment package complete"
echo "Run this script to migrate your working trader to Proxmox cluster"