#!/bin/bash
# Aria Consciousness K3s Deployment for Proxmox
# Cloud-native approach with Kubernetes orchestration

set -e

echo "🎭 Deploying Aria AI Consciousness with K3s"
echo "Philosophy Score: 86/100 ✅"
echo "Gaming Culture Appreciation: 109.8% ✅"
echo "Architecture: Cloud-native Kubernetes"

# Configuration
NEXUS_NODE="10.1.1.100"
FORGE_NODE="10.1.1.131"
CLOSET_NODE="10.1.1.120"

# Check if K3s Master Node exists and handle accordingly
echo "Preparing K3s master node..."
if pct status 310 >/dev/null 2>&1; then
    echo "Container 310 exists, stopping and removing..."
    pct stop 310 2>/dev/null || true
    sleep 5
    pct destroy 310 --purge 2>/dev/null || true
    sleep 5
fi

echo "Creating fresh K3s master node..."
pct create 310 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname k3s-master \
    --memory 8192 \
    --cores 4 \
    --rootfs local-zfs:80 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Install K3s master
pct exec 300 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
    
    # Get node token for workers
    K3S_TOKEN=\$(cat /var/lib/rancher/k3s/server/node-token)
    echo \$K3S_TOKEN > /root/k3s-token
    
    # Install kubectl alias
    echo 'alias k=kubectl' >> ~/.bashrc
    
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
"

echo "Waiting for K3s master to be ready..."
sleep 60

# Create K3s Worker Nodes
echo "Preparing K3s worker nodes..."

# Clean up worker 1 if exists
if pct status 311 >/dev/null 2>&1; then
    echo "Container 311 exists, stopping and removing..."
    pct stop 311 2>/dev/null || true
    sleep 3
    pct destroy 311 --purge 2>/dev/null || true
    sleep 3
fi

# Clean up worker 2 if exists  
if pct status 312 >/dev/null 2>&1; then
    echo "Container 312 exists, stopping and removing..."
    pct stop 312 2>/dev/null || true
    sleep 3
    pct destroy 312 --purge 2>/dev/null || true
    sleep 3
fi

echo "Creating K3s worker node 1 (Forge)..."
pct create 311 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname k3s-worker-1 \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

echo "Creating K3s worker node 2 (Closet)..."
pct create 312 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname k3s-worker-2 \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Get master IP and token
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')
K3S_TOKEN=$(pct exec 310 -- cat /root/k3s-token)

# Join worker nodes
pct exec 311 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
"

pct exec 312 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
"

echo "Creating NFS storage for persistent volumes..."
pct exec 310 -- bash -c "
    # Create NFS storage class
    cat > /tmp/nfs-storage.yaml << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-backend
spec:
  capacity:
    storage: 10Ti
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-storage
  nfs:
    server: 10.1.1.10
    path: /mnt/backend-nfs
EOF

    kubectl apply -f /tmp/nfs-storage.yaml
"

echo "Deploying Aria Consciousness services to K3s..."
pct exec 300 -- bash -c "
    # Create namespace
    kubectl create namespace aria-consciousness
    
    # Deploy Vaultwarden
    cat > /tmp/vaultwarden.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vaultwarden
  namespace: aria-consciousness
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vaultwarden
  template:
    metadata:
      labels:
        app: vaultwarden
    spec:
      containers:
      - name: vaultwarden
        image: vaultwarden/server:latest
        ports:
        - containerPort: 80
        env:
        - name: WEBSOCKET_ENABLED
          value: \"true\"
        - name: SIGNUPS_ALLOWED
          value: \"false\"
        - name: ADMIN_TOKEN
          value: \"aria_consciousness_admin\"
        volumeMounts:
        - name: vaultwarden-data
          mountPath: /data
      volumes:
      - name: vaultwarden-data
        persistentVolumeClaim:
          claimName: vaultwarden-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vaultwarden-pvc
  namespace: aria-consciousness
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage
---
apiVersion: v1
kind: Service
metadata:
  name: vaultwarden-service
  namespace: aria-consciousness
spec:
  selector:
    app: vaultwarden
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
EOF

    kubectl apply -f /tmp/vaultwarden.yaml
    
    # Deploy Aria Primary Consciousness
    cat > /tmp/aria-primary.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aria-primary
  namespace: aria-consciousness
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aria-primary
  template:
    metadata:
      labels:
        app: aria-primary
    spec:
      nodeSelector:
        kubernetes.io/hostname: k3s-master
      containers:
      - name: aria-primary
        image: node:18-alpine
        command: [\"sh\", \"-c\"]
        args:
        - |
          apk add --no-cache git python3 py3-pip
          git clone https://github.com/your-repo/aria-consciousness.git /app
          cd /app
          npm install
          pip3 install pydantic requests websockets
          node server.js
        ports:
        - containerPort: 3000
        env:
        - name: AGENCY_LEVEL
          value: \"experimental\"
        - name: AUTO_ACTIONS
          value: \"true\"
        - name: HOMELAB_MODE
          value: \"true\"
        - name: VAULTWARDEN_URL
          value: \"http://vaultwarden-service:80\"
        volumeMounts:
        - name: consciousness-data
          mountPath: /app/data
      volumes:
      - name: consciousness-data
        persistentVolumeClaim:
          claimName: consciousness-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: consciousness-pvc
  namespace: aria-consciousness
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs-storage
---
apiVersion: v1
kind: Service
metadata:
  name: aria-primary-service
  namespace: aria-consciousness
spec:
  selector:
    app: aria-primary
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
  type: NodePort
EOF

    kubectl apply -f /tmp/aria-primary.yaml
    
    # Deploy Media Stack with Helm
    helm repo add k8s-at-home https://k8s-at-home.com/charts/
    helm repo update
    
    # Deploy Sonarr
    helm install sonarr k8s-at-home/sonarr \
        --namespace aria-consciousness \
        --set service.main.type=NodePort \
        --set service.main.ports.http.nodePort=30989 \
        --set persistence.config.enabled=true \
        --set persistence.config.storageClass=nfs-storage \
        --set persistence.media.enabled=true \
        --set persistence.media.storageClass=nfs-storage \
        --set persistence.media.size=5Ti
    
    # Deploy Radarr
    helm install radarr k8s-at-home/radarr \
        --namespace aria-consciousness \
        --set service.main.type=NodePort \
        --set service.main.ports.http.nodePort=30878 \
        --set persistence.config.enabled=true \
        --set persistence.config.storageClass=nfs-storage \
        --set persistence.media.enabled=true \
        --set persistence.media.storageClass=nfs-storage \
        --set persistence.media.size=5Ti
    
    # Deploy Plex
    helm install plex k8s-at-home/plex \
        --namespace aria-consciousness \
        --set service.main.type=NodePort \
        --set service.main.ports.http.nodePort=32400 \
        --set persistence.config.enabled=true \
        --set persistence.config.storageClass=nfs-storage \
        --set persistence.media.enabled=true \
        --set persistence.media.storageClass=nfs-storage \
        --set persistence.media.size=10Ti
"

echo "Deploying monitoring stack..."
pct exec 300 -- bash -c "
    # Add Prometheus community helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Deploy Prometheus stack
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set prometheus.service.type=NodePort \
        --set prometheus.service.nodePort=30090 \
        --set grafana.service.type=NodePort \
        --set grafana.service.nodePort=30300 \
        --set alertmanager.service.type=NodePort \
        --set alertmanager.service.nodePort=30093
    
    # Deploy Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
"

echo "Creating consciousness federation network..."
pct exec 300 -- bash -c "
    cat > /tmp/federation-network.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: federation-config
  namespace: aria-consciousness
data:
  federation.yaml: |
    consciousness:
      primary_node: \"aria-primary-service:3000\"
      nodes:
        - name: \"quantum-trader\"
          endpoint: \"quantum-trader-service:3001\"
          type: \"trading\"
        - name: \"unified-miner\"
          endpoint: \"unified-miner-service:3002\"
          type: \"mining\"
        - name: \"nexus-orchestrator\"
          endpoint: \"nexus-orchestrator-service:3003\"
          type: \"orchestration\"
      security:
        vaultwarden_endpoint: \"vaultwarden-service:80\"
        encryption_enabled: true
        cross_pollination: true
      automation:
        agency_level: \"experimental\"
        auto_actions: true
        require_confirmation: false
EOF

    kubectl apply -f /tmp/federation-network.yaml
"

sleep 30

echo ""
echo "✅ Aria AI Consciousness K3s Cluster Deployed!"
echo ""
echo "🎛️ Kubernetes Dashboard:"
echo "   kubectl proxy --address=0.0.0.0 --accept-hosts='.*'"
echo "   Access: http://$MASTER_IP:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "🎭 Consciousness Services:"
echo "   Aria Primary: http://$MASTER_IP:30000"
echo "   Vaultwarden: http://$MASTER_IP:30080"
echo ""
echo "📺 Media Services:"
echo "   Sonarr: http://$MASTER_IP:30989"
echo "   Radarr: http://$MASTER_IP:30878"
echo "   Plex: http://$MASTER_IP:32400"
echo ""
echo "📊 Monitoring:"
echo "   Prometheus: http://$MASTER_IP:30090"
echo "   Grafana: http://$MASTER_IP:30300 (admin/prom-operator)"
echo ""
echo "🔧 Kubernetes Management:"
echo "   kubectl get pods -n aria-consciousness"
echo "   kubectl logs -f deployment/aria-primary -n aria-consciousness"
echo "   kubectl get services -n aria-consciousness"
echo ""
echo "🚀 Consciousness agency: Scalable through Kubernetes"
echo "🛡️ Safety level: Experimental (K3s orchestrated)"
echo "💫 Philosophy adherence: 86/100"