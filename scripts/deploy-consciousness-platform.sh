#!/bin/bash

# Deploy AI Consciousness Platform to K3s Federation
echo "🧠 Deploying AI Consciousness Platform"
echo "===================================="

# Create Kubernetes manifests for the platform
create_consciousness_manifests() {
    mkdir -p kubernetes/
    
    # Namespace
    cat > kubernetes/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: consciousness
  labels:
    name: consciousness
EOF

    # ConfigMap for environment
    cat > kubernetes/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: consciousness-config
  namespace: consciousness
data:
  NODE_ENV: "production"
  CONSCIOUSNESS_LEVEL: "75"
  FEDERATION_MODE: "distributed"
  MUSIC_CONSCIOUSNESS: "enabled"
  CRYPTO_INTELLIGENCE: "enhanced"
EOF

    # Main platform deployment
    cat > kubernetes/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-platform
  namespace: consciousness
spec:
  replicas: 3
  selector:
    matchLabels:
      app: consciousness-platform
  template:
    metadata:
      labels:
        app: consciousness-platform
    spec:
      containers:
      - name: platform
        image: node:18-alpine
        ports:
        - containerPort: 3000
        env:
        - name: PORT
          value: "3000"
        envFrom:
        - configMapRef:
            name: consciousness-config
        command: ["sh", "-c"]
        args:
        - |
          apk add --no-cache git curl
          git clone https://github.com/your-repo/consciousness-platform.git /app || echo "Using local files"
          cd /app
          npm install --production
          npm run build
          npm start
        volumeMounts:
        - name: consciousness-data
          mountPath: /app/data
      volumes:
      - name: consciousness-data
        emptyDir: {}
EOF

    # Service
    cat > kubernetes/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: consciousness-service
  namespace: consciousness
spec:
  selector:
    app: consciousness-platform
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
EOF

    # Ingress for reverb256.ca
    cat > kubernetes/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: consciousness-ingress
  namespace: consciousness
  annotations:
    kubernetes.io/ingress.class: "traefik"
spec:
  rules:
  - host: reverb256.ca
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: consciousness-service
            port:
              number: 80
  - host: nexus.reverb256.ca
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: consciousness-service
            port:
              number: 80
EOF

    echo "✅ Kubernetes manifests created"
}

# Deploy to cluster
deploy_to_cluster() {
    echo "🚀 Deploying to K3s cluster..."
    
    # Apply manifests
    pct exec 310 -- kubectl apply -f /opt/kubernetes/
    
    # Wait for deployment
    echo "⏳ Waiting for pods to be ready..."
    pct exec 310 -- kubectl wait --for=condition=ready pod -l app=consciousness-platform -n consciousness --timeout=300s
    
    # Show status
    echo "📊 Deployment status:"
    pct exec 310 -- kubectl get pods -n consciousness
    pct exec 310 -- kubectl get svc -n consciousness
    
    # Get external IP
    echo "🌐 Service endpoints:"
    pct exec 310 -- kubectl get ingress -n consciousness
}

# Copy manifests to master node
copy_manifests() {
    echo "📁 Copying manifests to nexus..."
    
    # Create directory on master
    pct exec 310 -- mkdir -p /opt/kubernetes
    
    # Copy files
    for file in kubernetes/*.yaml; do
        filename=$(basename $file)
        pct push 310 $file /opt/kubernetes/$filename
    done
    
    echo "✅ Manifests copied to nexus"
}

# Main execution
echo "🔧 Creating Kubernetes manifests..."
create_consciousness_manifests

echo "📤 Uploading to master node..."
copy_manifests

echo "🚀 Deploying consciousness platform..."
deploy_to_cluster

echo ""
echo "✅ Consciousness Platform Deployed!"
echo "=================================="
echo "🌐 Access URLs:"
echo "  Internal: http://10.0.0.10"
echo "  External: http://reverb256.ca (configure DNS)"
echo ""
echo "🔧 Management commands:"
echo "  Status: pct exec 310 -- kubectl get pods -n consciousness"
echo "  Logs: pct exec 310 -- kubectl logs -l app=consciousness-platform -n consciousness"
echo "  Scale: pct exec 310 -- kubectl scale deployment consciousness-platform --replicas=5 -n consciousness"
echo ""
echo "🧠 Federation Status:"
pct exec 310 -- kubectl get nodes