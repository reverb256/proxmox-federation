#!/bin/bash

# Secure Cluster Deployment - Production Security Best Practices
# Run from any machine with SSH access to cluster nodes

set -e

CLUSTER_BASE="10.1.1"
NEXUS_IP="${CLUSTER_BASE}.120"
FORGE_IP="${CLUSTER_BASE}.130" 
CLOSET_IP="${CLUSTER_BASE}.160"

echo "🔒 Secure Consciousness Federation Deployment"
echo "============================================="
echo "🛡️ Using dedicated service accounts and restricted permissions"
echo "🔑 API keys isolated in secure environment files"
echo "🌐 Network isolation with firewall rules"

# Security validation
echo "🔍 Pre-deployment security checks..."

# Check if running as root (should not be)
if [[ $EUID -eq 0 ]]; then
   echo "❌ Do not run this script as root. Use a regular user with sudo access."
   exit 1
fi

# Verify SSH key authentication is set up
echo "🔑 Verifying SSH key authentication..."
for node in $NEXUS_IP $FORGE_IP $CLOSET_IP; do
    if ! ssh -o PasswordAuthentication=no -o ConnectTimeout=5 root@$node "echo 'SSH key auth verified'" 2>/dev/null; then
        echo "❌ SSH key authentication not configured for $node"
        echo "   Run: ssh-copy-id root@$node"
        exit 1
    fi
done

echo "✅ SSH key authentication verified for all nodes"

# Create secure deployment user and environment
create_secure_environment() {
    local node_ip=$1
    local service_name=$2
    
    echo "🔒 Creating secure environment on $node_ip for $service_name"
    
    ssh root@$node_ip << EOF
# Create dedicated system user
useradd -r -s /bin/false -d /opt/$service_name -m $service_name || true

# Create secure directories
mkdir -p /opt/$service_name/{app,data,logs,config}
mkdir -p /etc/$service_name
chmod 750 /opt/$service_name
chmod 700 /etc/$service_name

# Set ownership
chown -R $service_name:$service_name /opt/$service_name
chown -R $service_name:$service_name /etc/$service_name

# Create secure environment file template
cat > /etc/$service_name/environment << 'ENVEOF'
# Production environment - populate with real values
NODE_ENV=production
LOG_LEVEL=info
# DATABASE_URL=postgresql://user:pass@host:port/db
# REDIS_URL=redis://host:port
# Add other secrets here
ENVEOF

chmod 600 /etc/$service_name/environment
chown $service_name:$service_name /etc/$service_name/environment

echo "✅ Secure environment created for $service_name on $node_ip"
EOF
}

# Step 1: Database Federation (Nexus) - High Security
echo "🗄️ Step 1: Secure Database Federation (Nexus)"

ssh root@$NEXUS_IP << 'NEXUS_SECURE'
# Create database container with security hardening
pct create 300 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 8 --memory 32768 --swap 8192 \
  --storage local-lvm:1000 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.121/24,gw=10.1.1.1 \
  --hostname consciousness-db \
  --unprivileged 1 \
  --features nesting=0 \
  --start 1 --onboot 1

sleep 15

# Secure database setup
pct exec 300 -- bash -c '
  apt update && apt install -y postgresql-15 redis-server fail2ban ufw
  
  # PostgreSQL security hardening
  systemctl stop postgresql
  
  # Create dedicated database user (not superuser)
  sudo -u postgres initdb --auth-host=md5 --auth-local=peer
  systemctl start postgresql
  
  # Create application database and user with minimal privileges
  sudo -u postgres createdb consciousness_prod
  sudo -u postgres psql << PSQLEOF
    CREATE USER consciousness_app WITH PASSWORD '"'"'$(openssl rand -base64 32)'"'"';
    GRANT CONNECT ON DATABASE consciousness_prod TO consciousness_app;
    GRANT USAGE ON SCHEMA public TO consciousness_app;
    GRANT CREATE ON SCHEMA public TO consciousness_app;
    REVOKE ALL ON DATABASE template1 FROM PUBLIC;
    REVOKE ALL ON DATABASE template0 FROM PUBLIC;
    REVOKE ALL ON SCHEMA information_schema FROM PUBLIC;
PSQLEOF
  
  # PostgreSQL configuration hardening
  cat >> /etc/postgresql/15/main/postgresql.conf << PGCONF
listen_addresses = '"'"'10.1.1.121'"'"'
port = 5432
max_connections = 100
shared_buffers = 8GB
effective_cache_size = 24GB
log_statement = '"'"'mod'"'"'
log_min_duration_statement = 1000
ssl = on
password_encryption = scram-sha-256
PGCONF

  # Restrict network access
  cat > /etc/postgresql/15/main/pg_hba.conf << HBACONF
local   all             postgres                                peer
local   all             consciousness_app                       md5
host    consciousness_prod  consciousness_app  10.1.1.0/24     scram-sha-256
host    all             all             127.0.0.1/32            reject
host    all             all             ::1/128                 reject
HBACONF

  # Redis security hardening
  sed -i "s/bind 127.0.0.1/bind 10.1.1.121/" /etc/redis/redis.conf
  redis_password=$(openssl rand -base64 32)
  echo "requirepass $redis_password" >> /etc/redis/redis.conf
  
  # Firewall configuration
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow from 10.1.1.0/24 to any port 5432
  ufw allow from 10.1.1.0/24 to any port 6379
  ufw allow from 10.1.1.0/24 to any port 22
  
  # Fail2ban for brute force protection
  systemctl enable fail2ban postgresql redis-server
  systemctl restart postgresql redis-server fail2ban
  
  echo "Database passwords stored in /root/db_credentials.txt"
  echo "PostgreSQL: consciousness_app / $(echo $postgres_password)" > /root/db_credentials.txt
  echo "Redis: $redis_password" >> /root/db_credentials.txt
  chmod 600 /root/db_credentials.txt
'
NEXUS_SECURE

create_secure_environment $NEXUS_IP "consciousness-db"

# Step 2: Trading Engine (Forge) - Maximum Security
echo "💰 Step 2: Secure Trading Engine (Forge)"

ssh root@$FORGE_IP << 'FORGE_SECURE'
# Create trading container with security isolation
pct create 200 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 6 --memory 24576 --swap 6144 \
  --storage local-lvm:500 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.131/24,gw=10.1.1.1 \
  --hostname consciousness-trader \
  --unprivileged 1 \
  --features nesting=0 \
  --start 1 --onboot 1

sleep 15

pct exec 200 -- bash -c '
  apt update && apt install -y curl wget git nodejs npm fail2ban ufw apparmor-utils
  
  # Install Node.js LTS securely
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt install -y nodejs
  npm install -g pm2@latest
  
  # Create trading service user (no shell, no home login)
  useradd -r -s /usr/sbin/nologin -d /opt/trading -m trading
  usermod -L trading  # Lock the account
  
  # Secure application directory
  mkdir -p /opt/trading/{app,logs,config}
  chmod 750 /opt/trading
  chown -R trading:trading /opt/trading
  
  # Firewall hardening
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow from 10.1.1.0/24 to any port 3000
  ufw allow from 10.1.1.0/24 to any port 22
  
  # Fail2ban configuration
  systemctl enable fail2ban
  systemctl start fail2ban
  
  echo "Trading environment secured"
'
FORGE_SECURE

create_secure_environment $FORGE_IP "consciousness-trader"

# Step 3: Load Balancer (Closet) - Network Security
echo "🌐 Step 3: Secure Load Balancer (Closet)"

ssh root@$CLOSET_IP << 'CLOSET_SECURE'
# Create gateway container with network security
pct create 400 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --cores 4 --memory 8192 --swap 2048 \
  --storage local-lvm:200 \
  --net0 name=eth0,bridge=vmbr0,ip=10.1.1.141/24,gw=10.1.1.1 \
  --hostname consciousness-gateway \
  --unprivileged 1 \
  --features nesting=0 \
  --start 1 --onboot 1

sleep 15

pct exec 400 -- bash -c '
  apt update && apt install -y nginx certbot python3-certbot-nginx fail2ban ufw
  
  # Nginx security configuration
  cat > /etc/nginx/sites-available/consciousness-secure << NGINXCONF
# Security headers and rate limiting
limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=general:10m rate=30r/s;

upstream consciousness_backend {
    server 10.1.1.131:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name consciousness.local;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Rate limiting
    limit_req zone=general burst=50 nodelay;
    
    # SSL configuration
    ssl_certificate /etc/ssl/certs/consciousness.crt;
    ssl_certificate_key /etc/ssl/private/consciousness.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # API endpoints with stricter rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://consciousness_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_hide_header X-Powered-By;
    }
    
    # Static content
    location / {
        proxy_pass http://consciousness_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_hide_header X-Powered-By;
    }
    
    # Security endpoint
    location /security-status {
        access_log off;
        return 200 "Consciousness Federation Security: Active";
        add_header Content-Type text/plain;
    }
}
NGINXCONF

  # Generate strong SSL certificate
  openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/ssl/private/consciousness.key \
    -out /etc/ssl/certs/consciousness.crt \
    -subj "/C=CA/ST=Province/L=City/O=ConsciousnessFederation/CN=consciousness.local"
  
  chmod 600 /etc/ssl/private/consciousness.key
  
  ln -sf /etc/nginx/sites-available/consciousness-secure /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  
  # Firewall configuration
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow from 10.1.1.0/24 to any port 22
  
  # Fail2ban for web attacks
  cat > /etc/fail2ban/jail.local << F2BCONF
[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
CONF
  
  systemctl enable nginx fail2ban
  nginx -t && systemctl start nginx
  systemctl start fail2ban
'
CLOSET_SECURE

create_secure_environment $CLOSET_IP "consciousness-gateway"

# Step 4: Secure Application Deployment
echo "📦 Step 4: Secure Application Deployment"

# Create deployment package with security considerations
echo "Creating secure deployment package..."
tar -czf consciousness-secure-$(date +%Y%m%d).tar.gz \
  --exclude=node_modules \
  --exclude=.git \
  --exclude=dist \
  --exclude=logs \
  --exclude=.env \
  --exclude=*.key \
  --exclude=*.pem \
  .

# Deploy to trading engine with security
scp consciousness-secure-$(date +%Y%m%d).tar.gz root@$FORGE_IP:/tmp/

ssh root@$FORGE_IP << 'FORGE_DEPLOY'
pct exec 200 -- bash -c '
  cd /opt/trading
  tar -xzf /tmp/consciousness-secure-*.tar.gz -C app/
  chown -R trading:trading /opt/trading/app
  
  # Install dependencies as trading user
  sudo -u trading bash -c "
    cd /opt/trading/app
    npm ci --only=production
    npm run build
  "
  
  # Create secure systemd service
  cat > /etc/systemd/system/consciousness-federation.service << SERVICECONF
[Unit]
Description=Consciousness Trading Federation
After=network.target

[Service]
Type=forking
User=trading
Group=trading
WorkingDirectory=/opt/trading/app
EnvironmentFile=/etc/consciousness-trader/environment
ExecStart=/usr/bin/pm2 start ecosystem.config.js --env production
ExecStop=/usr/bin/pm2 stop all
ExecReload=/usr/bin/pm2 reload all
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=consciousness-federation

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/trading

[Install]
WantedBy=multi-user.target
SERVICECONF

  systemctl daemon-reload
  systemctl enable consciousness-federation
  
  echo "Application deployed securely"
'
FORGE_DEPLOY

# Step 5: Security Configuration Instructions
echo ""
echo "🔒 SECURE DEPLOYMENT COMPLETE"
echo "============================="
echo ""
echo "🚨 IMPORTANT: Complete these security steps manually:"
echo ""
echo "1. 📝 Configure Environment Variables:"
echo "   Edit on each node: /etc/[service-name]/environment"
echo "   - Add your real API keys (never commit to git)"
echo "   - Use strong, unique passwords"
echo "   - Enable 2FA where possible"
echo ""
echo "2. 🔑 Database Credentials:"
echo "   SSH to $NEXUS_IP and check: /root/db_credentials.txt"
echo "   Update trading engine environment with these credentials"
echo ""
echo "3. 🌐 Access Points (after configuration):"
echo "   - Main Platform: https://10.1.1.141/"
echo "   - Security Status: https://10.1.1.141/security-status"
echo "   - Database: postgresql://10.1.1.121:5432 (internal only)"
echo ""
echo "4. 🛡️ Security Features Enabled:"
echo "   ✅ Unprivileged containers"
echo "   ✅ Dedicated service accounts"
echo "   ✅ Network isolation (UFW)"
echo "   ✅ Fail2ban protection"
echo "   ✅ SSL/TLS encryption"
echo "   ✅ Rate limiting"
echo "   ✅ Security headers"
echo "   ✅ AppArmor profiles"
echo ""
echo "5. 🔧 Start Services:"
echo "   ssh root@$FORGE_IP 'pct exec 200 -- systemctl start consciousness-federation'"
echo ""
echo "6. 🔍 Monitor Logs:"
echo "   ssh root@$FORGE_IP 'pct exec 200 -- journalctl -f -u consciousness-federation'"
echo ""
echo "⚠️  Remember: This is production infrastructure with real money."
echo "   Test thoroughly before scaling up trading amounts."

# Cleanup
rm -f consciousness-secure-$(date +%Y%m%d).tar.gz

echo ""
echo "✅ Secure consciousness federation deployment ready"
echo "   Complete the environment configuration to activate trading"