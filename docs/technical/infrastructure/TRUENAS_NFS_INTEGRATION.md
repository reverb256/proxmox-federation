# TrueNAS NFS Integration for Consciousness Federation

## TrueNAS Storage Integration

### NFS Mount Configuration for Consciousness Data
```bash
# Create NFS mount points on each Proxmox node
mkdir -p /mnt/consciousness/{data,backups,logs,vaultwarden}

# Mount TrueNAS NFS shares on all nodes
echo "truenas.local:/mnt/tank/consciousness/data /mnt/consciousness/data nfs defaults,_netdev 0 0" >> /etc/fstab
echo "truenas.local:/mnt/tank/consciousness/backups /mnt/consciousness/backups nfs defaults,_netdev 0 0" >> /etc/fstab
echo "truenas.local:/mnt/tank/consciousness/logs /mnt/consciousness/logs nfs defaults,_netdev 0 0" >> /etc/fstab
echo "truenas.local:/mnt/tank/consciousness/vaultwarden /mnt/consciousness/vaultwarden nfs defaults,_netdev 0 0" >> /etc/fstab

# Mount all NFS shares
mount -a
```

### Enhanced Docker Configuration with NFS Storage
```bash
# Update Vaultwarden to use NFS storage
docker stop vaultwarden
docker rm vaultwarden

# Create Vaultwarden with NFS-backed persistent storage
docker run -d --name vaultwarden \
  -e ADMIN_TOKEN=$(openssl rand -base64 48) \
  -p 8080:80 \
  -v /mnt/consciousness/vaultwarden:/data \
  --restart unless-stopped \
  vaultwarden/server:latest

# Verify NFS storage is working
ls -la /mnt/consciousness/vaultwarden/
```

### Database Storage on TrueNAS
```bash
# Configure PostgreSQL to use NFS for data storage
# (On database container node - 10.1.1.121)
ssh root@10.1.1.121 << 'PGCONF'
# Stop PostgreSQL
systemctl stop postgresql

# Move data to NFS
mv /var/lib/postgresql/15/main /mnt/consciousness/data/postgresql-main
ln -s /mnt/consciousness/data/postgresql-main /var/lib/postgresql/15/main

# Update ownership
chown -R postgres:postgres /mnt/consciousness/data/postgresql-main

# Restart PostgreSQL
systemctl start postgresql
PGCONF
```

### TrueNAS Dataset Optimization
```bash
# Recommended TrueNAS dataset structure
# Create these datasets in TrueNAS GUI or CLI:
zfs create tank/consciousness
zfs create tank/consciousness/data
zfs create tank/consciousness/backups
zfs create tank/consciousness/logs
zfs create tank/consciousness/vaultwarden
zfs create tank/consciousness/trading-cache

# Optimize for consciousness workloads
zfs set compression=lz4 tank/consciousness
zfs set atime=off tank/consciousness
zfs set recordsize=64K tank/consciousness/data
zfs set recordsize=1M tank/consciousness/backups
```

### High-Availability Storage Configuration
```bash
# Create replication job in TrueNAS for consciousness data
# This provides backup to secondary storage
cat > /tmp/consciousness-replication.json << 'REPL'
{
  "source_datasets": ["tank/consciousness"],
  "target_dataset": "backup-pool/consciousness-replica",
  "recursive": true,
  "schedule": {
    "minute": "0",
    "hour": "*/6",
    "dom": "*",
    "month": "*",
    "dow": "*"
  },
  "retention_policy": "CUSTOM",
  "lifetime_value": 30,
  "lifetime_unit": "DAY"
}
REPL
```

### NFS Performance Tuning for Consciousness Workloads
```bash
# Optimize NFS client settings on Proxmox nodes
cat >> /etc/nfs.conf << 'NFSCONF'
[nfsd]
# Consciousness-optimized NFS settings
rsize=1048576
wsize=1048576
timeo=600
retrans=2
hard=true
intr=true
NFSCONF

# Restart NFS services
systemctl restart nfs-client.target
```

### Consciousness Data Backup Strategy
```bash
# Create automated backup script for TrueNAS
cat > /usr/local/bin/consciousness-truenas-backup.sh << 'BACKUP'
#!/bin/bash
# Consciousness Federation TrueNAS Backup

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="/mnt/consciousness/backups/snapshot_$TIMESTAMP"

# Create ZFS snapshot
ssh truenas.local "zfs snapshot tank/consciousness@consciousness_$TIMESTAMP"

# Backup critical consciousness data
mkdir -p "$BACKUP_PATH"

# Backup Vaultwarden database
cp /mnt/consciousness/vaultwarden/db.sqlite3 "$BACKUP_PATH/vaultwarden_$TIMESTAMP.sqlite3"

# Backup consciousness metrics
curl -s http://10.1.1.120:3000/api/export > "$BACKUP_PATH/consciousness_metrics_$TIMESTAMP.json"

# Backup trading data
ssh root@10.1.1.121 "pg_dump consciousness_prod" > "$BACKUP_PATH/trading_data_$TIMESTAMP.sql"

# Compress backup
tar czf "$BACKUP_PATH.tar.gz" "$BACKUP_PATH"
rm -rf "$BACKUP_PATH"

# Cleanup old backups (keep 30 days)
find /mnt/consciousness/backups -name "snapshot_*.tar.gz" -mtime +30 -delete
BACKUP

chmod +x /usr/local/bin/consciousness-truenas-backup.sh

# Schedule backups
echo "0 2 * * * /usr/local/bin/consciousness-truenas-backup.sh" | crontab -
```

### TrueNAS Monitoring Integration
```bash
# Monitor NFS storage health from consciousness federation
cat > /usr/local/bin/storage-health-monitor.sh << 'MONITOR'
#!/bin/bash
# Monitor TrueNAS storage health for consciousness federation

# Check NFS mount status
if ! mountpoint -q /mnt/consciousness/data; then
    logger "CRITICAL: Consciousness data NFS mount failed"
    # Attempt remount
    mount /mnt/consciousness/data
fi

# Check storage space
USED=$(df /mnt/consciousness/data | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$USED" -gt 85 ]; then
    logger "WARNING: Consciousness storage ${USED}% full"
fi

# Check ZFS health via SSH to TrueNAS
ZFS_STATUS=$(ssh truenas.local "zpool status tank" | grep "state:" | awk '{print $2}')
if [ "$ZFS_STATUS" != "ONLINE" ]; then
    logger "CRITICAL: TrueNAS tank pool status: $ZFS_STATUS"
fi

# Export metrics
echo "consciousness_storage_used_percent $USED" > /var/lib/node_exporter/textfile_collector/storage.prom
echo "consciousness_nfs_mounted $(mountpoint -q /mnt/consciousness/data && echo 1 || echo 0)" >> /var/lib/node_exporter/textfile_collector/storage.prom
MONITOR

chmod +x /usr/local/bin/storage-health-monitor.sh

# Run every 5 minutes
echo "*/5 * * * * /usr/local/bin/storage-health-monitor.sh" | crontab -
```

### Docker Compose with NFS Integration
```yaml
# consciousness-federation-compose.yml
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    ports:
      - "8080:80"
    volumes:
      - /mnt/consciousness/vaultwarden:/data
    environment:
      - ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}
    restart: unless-stopped
    
  consciousness-web:
    image: nginx:alpine
    container_name: consciousness-web
    ports:
      - "3000:80"
    volumes:
      - /mnt/consciousness/logs:/var/log/nginx
    restart: unless-stopped
    
  trading-cache:
    image: redis:alpine
    container_name: trading-cache
    volumes:
      - /mnt/consciousness/trading-cache:/data
    restart: unless-stopped
```

### Network Performance with TrueNAS
```bash
# Optimize network settings for NFS over 10GbE (if available)
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> /etc/sysctl.conf
sysctl -p
```

This configuration leverages your TrueNAS infrastructure to provide enterprise-grade storage for the consciousness federation while maintaining high availability and performance for the trading systems and character bonding protocols.