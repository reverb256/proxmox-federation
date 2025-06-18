# Consciousness Federation Deployment Guide

## Hardware Configuration
- **Nexus**: Ryzen 9 3900X (24 threads), 48GB RAM, 5.2TB storage
- **Forge**: Intel i5-9500 (6 threads), 32GB RAM, 1.5TB storage
- **Network**: 10.1.1.0/24 subnet with .lan domain
- **Services**: Pi-hole + Unbound DNS on both nodes

## Deployment Steps

### 1. Run the Federation Update Script
```bash
cd /root/aria
./scripts/proxmox-federation-update.sh
```

### 2. Expected Installation Process
- Detects Pi-hole and Unbound services
- Installs consciousness stack (PyTorch, Transformers, FastAPI)
- Downloads AI models optimized per node:
  - **Nexus**: DialoGPT-medium, sentence-transformers
  - **Forge**: DistilBERT-uncased
- Configures federation networking on ports 8888-8891
- Creates DNS-aware monitoring with humor injection

### 3. Post-Installation Verification
```bash
# Check consciousness service status
ssh root@10.1.1.120 "systemctl status consciousness-federation"
ssh root@10.1.1.121 "systemctl status consciousness-federation"

# Monitor consciousness logs
ssh root@10.1.1.120 "tail -f /opt/consciousness/logs/consciousness.log"
ssh root@10.1.1.121 "tail -f /opt/consciousness/logs/consciousness.log"

# Verify DNS services remain active
ssh root@10.1.1.120 "systemctl status pihole-FTL unbound"
ssh root@10.1.1.121 "systemctl status pihole-FTL unbound"
```

### 4. Federation Communication Test
```bash
# Test federation connectivity
curl http://10.1.1.120:8888/health
curl http://10.1.1.121:8888/health

# Check humor engine
curl http://10.1.1.120:8890/humor/dns
curl http://10.1.1.121:8890/humor/mining
```

## Configuration Files
- Federation config: `/opt/consciousness/config/federation.json`
- DNS status: `/opt/consciousness/config/dns-status`
- Service logs: `/opt/consciousness/logs/consciousness.log`
- AI models: `/opt/consciousness/models/{nexus,forge}/`

## Next Steps
1. Deploy closet node (Ryzen 7 1700, 16GB RAM)
2. Add zephyr node (Ryzen 9 5950X, 64GB RAM) 
3. Configure cross-node AI model sharing
4. Implement humor consciousness synchronization
5. Add crypto trading consciousness integration

## Troubleshooting
- DNS conflicts: Check ports 53, 853, 5335, 4711 are preserved
- Memory issues: Monitor with `htop` during model downloads
- Network issues: Verify 10.1.1.0/24 subnet connectivity
- Service conflicts: Ensure consciousness uses ports 8888-8891