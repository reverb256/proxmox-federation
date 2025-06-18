# Complete Deployment Guide - Consciousness Control Center

## Overview
This guide provides comprehensive deployment instructions for the Consciousness Control Center, a professional AI orchestration platform with Talos/K8s integration, RAG capabilities, agentic framework, and complete infrastructure automation.

## Prerequisites

### System Requirements
- **Operating System**: Linux (Ubuntu 20.04+, CentOS 8+, or RHEL 8+)
- **CPU**: 4+ cores (8+ recommended for production)
- **Memory**: 8GB+ RAM (16GB+ recommended for production)
- **Storage**: 100GB+ available disk space
- **Network**: Stable internet connection for provider APIs
- **Docker**: Version 20.10+ with Docker Compose

### Optional Components
- **NVIDIA GPU**: For accelerated AI inference (RTX 4090, A100, etc.)
- **Proxmox VE**: Version 7.0+ for Talos/K8s cluster provisioning
- **Shared Storage**: NFS, Ceph, or similar for cluster storage

## Quick Start Deployment

### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/your-org/consciousness-control-center.git
cd consciousness-control-center/proxmox-federation

# Verify project structure
ls -la
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Essential Environment Variables:**
```bash
# Core AI Services
VLLM_URL=http://vllm:8000
SD_URL=http://stable-diffusion:5000
TTS_URL=http://tts:5002
STT_URL=http://stt:5003
EMBED_URL=http://embeddings:5004

# API Keys for Premium Providers
OPENAI_API_KEY=your_openai_key_here
HUGGINGFACE_API_KEY=your_huggingface_key_here
INTELLIGENCE_IO_API_KEY=your_intelligence_io_key_here
OPENROUTER_API_KEY=your_openrouter_key_here
REPLICATE_API_TOKEN=your_replicate_token_here

# Fallback Provider URLs (comma-separated)
VLLM_FALLBACK_URLS=http://backup-vllm:8000
SD_FALLBACK_URLS=http://backup-sd:5000
TTS_FALLBACK_URLS=http://backup-tts:5002

# Proxmox Configuration (if using)
PROXMOX_HOST=your-proxmox-host.local
PROXMOX_USER=root@pam
PROXMOX_PASSWORD=your_secure_password
PROXMOX_VERIFY_SSL=false

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_DB=consciousness_db
POSTGRES_USER=consciousness_user
POSTGRES_PASSWORD=your_secure_db_password

# Security Configuration
SECRET_KEY=your_secret_key_here
JWT_SECRET=your_jwt_secret_here
ENCRYPT_KEY=your_encryption_key_here
```

### 3. Service Deployment
```bash
# Build and start all services
docker-compose up -d --build

# Monitor deployment progress
docker-compose logs -f gateway

# Verify all services are running
docker-compose ps
```

### 4. Health Verification
```bash
# Test basic connectivity
curl http://localhost:8080/
curl http://localhost:8080/v1/models

# Test AI chat completion
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-8b",
    "messages": [{"role": "user", "content": "Hello, test message"}],
    "max_tokens": 100
  }'

# Test RAG capabilities
curl -X POST http://localhost:8080/v1/rag/qa \
  -H "Content-Type: application/json" \
  -d '{
    "document": "The Consciousness Control Center is an AI orchestration platform.",
    "question": "What is the Consciousness Control Center?"
  }'

# Test Talos/K8s orchestration
curl -X POST http://localhost:8080/v1/orchestrate/talos_k8s/cluster/create \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_config": {
      "name": "test-cluster",
      "nodes": 3
    }
  }'
```

## Production Deployment

### 1. Infrastructure Preparation

#### Hardware Setup
- **Control Plane**: 8+ cores, 32GB+ RAM, 500GB SSD
- **AI Processing**: NVIDIA GPU with 16GB+ VRAM
- **Database**: Dedicated storage with backup capability
- **Network**: 10Gbps+ internal networking

#### Security Hardening
```bash
# Generate SSL certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/private.key \
  -out ssl/certificate.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=consciousness.local"

# Configure firewall
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP
ufw allow 443/tcp    # HTTPS
ufw allow 8080/tcp   # API Gateway
ufw enable

# Set secure file permissions
chmod 600 .env
chmod 600 ssl/private.key
```

### 2. High Availability Configuration

#### Load Balancer Setup
```yaml
# docker-compose.ha.yml
version: '3.8'
services:
  nginx-lb:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx-lb.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - gateway-1
      - gateway-2
      - gateway-3

  gateway-1:
    build: .
    environment:
      - INSTANCE_ID=gateway-1
      - POSTGRES_HOST=postgres-primary

  gateway-2:
    build: .
    environment:
      - INSTANCE_ID=gateway-2
      - POSTGRES_HOST=postgres-primary

  gateway-3:
    build: .
    environment:
      - INSTANCE_ID=gateway-3
      - POSTGRES_HOST=postgres-primary
```

#### Database Clustering
```yaml
# PostgreSQL HA setup
postgres-primary:
  image: postgres:15
  environment:
    POSTGRES_REPLICATION_MODE: master
    POSTGRES_REPLICATION_USER: replicator
    POSTGRES_REPLICATION_PASSWORD: secure_replica_password
  volumes:
    - postgres-primary-data:/var/lib/postgresql/data

postgres-secondary:
  image: postgres:15
  environment:
    POSTGRES_REPLICATION_MODE: slave
    POSTGRES_MASTER_HOST: postgres-primary
    POSTGRES_REPLICATION_USER: replicator
    POSTGRES_REPLICATION_PASSWORD: secure_replica_password
  volumes:
    - postgres-secondary-data:/var/lib/postgresql/data
```

### 3. GPU Acceleration Setup

#### NVIDIA GPU Support
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

#### GPU-Enabled Services
```yaml
# docker-compose.gpu.yml
services:
  vllm:
    image: vllm/vllm-openai:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=0
      - VLLM_MODEL=meta-llama/Llama-2-7b-chat-hf
      - VLLM_HOST=0.0.0.0
      - VLLM_PORT=8000
```

### 4. Monitoring and Observability

#### Prometheus Configuration
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'consciousness-gateway'
    static_configs:
      - targets: ['gateway:8080']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'nvidia-exporter'
    static_configs:
      - targets: ['nvidia-exporter:9835']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

#### Grafana Dashboard Setup
```bash
# Import pre-configured dashboards
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/dashboards/consciousness-overview.json

curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/dashboards/ai-performance.json
```

### 5. Backup and Recovery

#### Automated Backup Script
```bash
#!/bin/bash
# scripts/backup-system.sh

BACKUP_DIR="/backups/consciousness"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup database
docker exec postgres pg_dump -U consciousness_user consciousness_db | \
  gzip > "${BACKUP_DIR}/database_${TIMESTAMP}.sql.gz"

# Backup configuration
tar -czf "${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz" \
  .env \
  docker-compose*.yml \
  nginx/ \
  monitoring/ \
  ssl/

# Backup application data
docker run --rm -v consciousness_app_data:/data -v "${BACKUP_DIR}:/backup" \
  alpine tar czf "/backup/appdata_${TIMESTAMP}.tar.gz" -C /data .

# Clean old backups
find "${BACKUP_DIR}" -name "*.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: ${TIMESTAMP}"
```

#### Recovery Procedures
```bash
#!/bin/bash
# scripts/restore-system.sh

BACKUP_FILE="$1"
BACKUP_DIR="/backups/consciousness"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup_timestamp>"
  echo "Available backups:"
  ls -la "${BACKUP_DIR}"
  exit 1
fi

# Stop services
docker-compose down

# Restore database
gunzip < "${BACKUP_DIR}/database_${BACKUP_FILE}.sql.gz" | \
  docker exec -i postgres psql -U consciousness_user consciousness_db

# Restore configuration
tar -xzf "${BACKUP_DIR}/config_${BACKUP_FILE}.tar.gz"

# Restore application data
docker run --rm -v consciousness_app_data:/data -v "${BACKUP_DIR}:/backup" \
  alpine tar xzf "/backup/appdata_${BACKUP_FILE}.tar.gz" -C /data

# Restart services
docker-compose up -d

echo "System restored from backup: ${BACKUP_FILE}"
```

## Advanced Configurations

### 1. Talos/K8s Integration

#### Talos Cluster Configuration
```yaml
# talos/cluster-config.yaml
machine:
  type: controlplane
  network:
    hostname: talos-cp-1
    interfaces:
      - interface: eth0
        dhcp: true
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:v1.6.0

cluster:
  name: consciousness-cluster
  controlPlane:
    endpoint: https://10.0.0.10:6443
  network:
    dnsDomain: cluster.local
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
  token: your-cluster-token-here
  secretboxEncryptionSecret: your-encryption-secret-here
  ca:
    crt: LS0tLS1CRUdJTi... # Your cluster CA certificate
    key: LS0tLS1CRUdJTi... # Your cluster CA key
```

#### Kubernetes Manifests
```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: consciousness
  labels:
    name: consciousness

---
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-gateway
  namespace: consciousness
spec:
  replicas: 3
  selector:
    matchLabels:
      app: consciousness-gateway
  template:
    metadata:
      labels:
        app: consciousness-gateway
    spec:
      containers:
      - name: gateway
        image: consciousness/gateway:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: consciousness-secrets
              key: database-url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: consciousness-secrets
              key: openai-api-key
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

---
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: consciousness-gateway-service
  namespace: consciousness
spec:
  selector:
    app: consciousness-gateway
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

### 2. External Integrations

#### Open WebUI Integration
```yaml
# docker-compose.openwebui.yml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3000:8080"
    environment:
      - OPENAI_API_BASE_URL=http://gateway:8080/v1
      - OPENAI_API_KEY=consciousness-api-key
      - WEBUI_NAME=Consciousness Control Center
      - WEBUI_AUTH=false
    volumes:
      - open-webui-data:/app/backend/data
    depends_on:
      - gateway
    networks:
      - consciousness-network

volumes:
  open-webui-data:

networks:
  consciousness-network:
    external: true
```

#### Proxmox Integration Script
```bash
#!/bin/bash
# scripts/setup-proxmox-integration.sh

# Configure Proxmox connection
PROXMOX_HOST="${PROXMOX_HOST:-proxmox.local}"
PROXMOX_USER="${PROXMOX_USER:-root@pam}"
PROXMOX_PASSWORD="${PROXMOX_PASSWORD}"

# Test connection
curl -k -d "username=${PROXMOX_USER}&password=${PROXMOX_PASSWORD}" \
  "https://${PROXMOX_HOST}:8006/api2/json/access/ticket"

if [ $? -eq 0 ]; then
  echo "Proxmox connection successful"
  
  # Create VM template for Talos
  echo "Setting up Talos VM template..."
  # Add Talos template creation logic here
  
else
  echo "Failed to connect to Proxmox"
  exit 1
fi
```

## Troubleshooting

### Common Issues

#### 1. Services Won't Start
```bash
# Check system resources
free -h
df -h
docker system df

# Check Docker daemon
sudo systemctl status docker
sudo systemctl restart docker

# Check service logs
docker-compose logs gateway
docker-compose logs postgres
docker-compose logs vllm

# Rebuild if necessary
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### 2. API Connection Issues
```bash
# Test network connectivity
ping gateway
telnet gateway 8080

# Check firewall rules
sudo ufw status
sudo iptables -L

# Verify service endpoints
curl -v http://localhost:8080/health
curl -v http://localhost:8080/v1/models
```

#### 3. GPU Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi
cat /proc/driver/nvidia/version

# Verify Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check container GPU access
docker exec vllm nvidia-smi
docker exec vllm python -c "import torch; print(torch.cuda.is_available())"
```

#### 4. Database Connection Issues
```bash
# Check database status
docker exec postgres pg_isready

# Test connection
docker exec postgres psql -U consciousness_user -d consciousness_db -c "SELECT version();"

# Check database logs
docker-compose logs postgres

# Reset database if needed
docker-compose stop postgres
docker volume rm proxmox-federation_postgres_data
docker-compose up -d postgres
```

### Performance Optimization

#### 1. System Tuning
```bash
# Kernel parameters
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
echo 'fs.file-max = 100000' >> /etc/sysctl.conf
echo 'vm.swappiness = 10' >> /etc/sysctl.conf
sysctl -p

# Docker daemon optimization
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-runtime": "nvidia"
}
EOF

sudo systemctl restart docker
```

#### 2. Database Optimization
```sql
-- PostgreSQL performance tuning
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
SELECT pg_reload_conf();

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY idx_rag_documents_embedding ON rag_documents USING gin(embedding);
CREATE INDEX CONCURRENTLY idx_agent_history_timestamp ON agent_history(created_at DESC);
```

#### 3. Application Optimization
```python
# config/performance.py
PERFORMANCE_CONFIG = {
    'worker_processes': 8,
    'worker_connections': 1000,
    'max_connections': 100,
    'connection_pool_size': 20,
    'query_timeout': 30,
    'request_timeout': 60,
    'cache_ttl': 300,
    'batch_size': 100,
    'async_workers': 4
}
```

## Maintenance

### Daily Tasks
- [ ] Monitor service health and performance
- [ ] Check log files for errors and warnings
- [ ] Verify backup completion
- [ ] Review security alerts and anomalies
- [ ] Check resource utilization

### Weekly Tasks
- [ ] Update container images
- [ ] Rotate and archive log files
- [ ] Clean up temporary files and caches
- [ ] Review performance metrics and trends
- [ ] Test failover procedures

### Monthly Tasks
- [ ] Apply security patches and updates
- [ ] Review and update capacity planning
- [ ] Conduct disaster recovery testing
- [ ] Performance optimization review
- [ ] Security audit and penetration testing

### Upgrade Procedures

#### 1. Pre-Upgrade Checklist
```bash
# Create full system backup
./scripts/backup-system.sh

# Export current configuration
docker-compose config > backup/docker-compose-backup.yml

# Test backup integrity
./scripts/test-backup.sh

# Document current system state
docker images | tee backup/images.txt
docker ps | tee backup/containers.txt
```

#### 2. Upgrade Execution
```bash
# Pull latest images
docker-compose pull

# Update services with zero downtime
docker-compose up -d --no-deps gateway
docker-compose up -d --no-deps postgres
docker-compose up -d --no-deps vllm

# Verify each service after update
./scripts/health-check.sh
```

#### 3. Post-Upgrade Verification
```bash
# Run comprehensive tests
./scripts/test-all-endpoints.sh

# Monitor logs for issues
docker-compose logs -f --tail=100

# Performance verification
./scripts/performance-test.sh

# Rollback if issues detected
if [ $? -ne 0 ]; then
  echo "Issues detected, rolling back..."
  ./scripts/rollback.sh
fi
```

---

This comprehensive deployment guide provides everything needed to deploy and maintain the Consciousness Control Center in both development and production environments. Follow the appropriate sections based on your deployment requirements and environment.
