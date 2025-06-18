#!/bin/bash

# Deploy Intelligent Workload Distribution and Resource Optimization
# For Consciousness Federation Kubernetes cluster

set -euo pipefail

# Configuration
NAMESPACE="consciousness-federation"
DOCKER_REGISTRY="ghcr.io/astralvibe"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites for intelligent scheduler deployment..."
    
    # Check kubectl access
    if ! kubectl get nodes &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
    fi
    
    # Check if metrics server is running
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        warning "Metrics server not found, installing..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        
        # Wait for metrics server to be ready
        kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=300s
    fi
    
    # Check if consciousness federation namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "Creating consciousness federation namespace..."
        kubectl create namespace "$NAMESPACE"
    fi
    
    success "Prerequisites check completed"
}

# Build and push scheduler images
build_scheduler_images() {
    log "Building consciousness scheduler images..."
    
    # Create Dockerfile for resource optimizer
    cat > Dockerfile.optimizer << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN npm install @kubernetes/client-node prom-client express

# Copy optimizer code
COPY k8s/resource-optimization-controller.js ./optimizer.js

# Expose metrics port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

CMD ["node", "optimizer.js"]
EOF

    # Create Dockerfile for GPU scheduler
    cat > Dockerfile.scheduler << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN npm install @kubernetes/client-node

# Copy scheduler code
COPY k8s/gpu-scheduler-plugin.js ./scheduler.js

# Expose scheduler port
EXPOSE 8080

CMD ["node", "scheduler.js"]
EOF

    # Build images (in production, these would be built in CI/CD)
    log "Note: In production, build these images in your CI/CD pipeline:"
    echo "  docker build -f Dockerfile.optimizer -t ${DOCKER_REGISTRY}/consciousness-optimizer:latest ."
    echo "  docker build -f Dockerfile.scheduler -t ${DOCKER_REGISTRY}/consciousness-scheduler:latest ."
    echo "  docker push ${DOCKER_REGISTRY}/consciousness-optimizer:latest"
    echo "  docker push ${DOCKER_REGISTRY}/consciousness-scheduler:latest"
    
    # For now, we'll use placeholder images that reference our Node.js code
    success "Scheduler image configuration ready"
}

# Deploy consciousness metrics collector
deploy_metrics_collector() {
    log "Deploying consciousness metrics collector..."
    
    # Create metrics collector configuration
    cat > consciousness-metrics-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: consciousness-metrics-config
  namespace: consciousness-federation
data:
  collect-gpu-metrics.sh: |
    #!/bin/bash
    # GPU metrics collection script
    
    while true; do
        if command -v nvidia-smi &> /dev/null; then
            # Collect NVIDIA GPU metrics
            nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | \
            awk -F', ' '{
                printf "gpu_utilization_percent{gpu=\"%d\"} %s\n", NR-1, $1
                printf "gpu_memory_used_bytes{gpu=\"%d\"} %s\n", NR-1, $2*1048576
                printf "gpu_memory_total_bytes{gpu=\"%d\"} %s\n", NR-1, $3*1048576
                printf "gpu_temperature_celsius{gpu=\"%d\"} %s\n", NR-1, $4
            }' > /tmp/gpu_metrics.prom
        fi
        
        # Consciousness-specific metrics
        echo "consciousness_node_rhythm{rhythm=\"$(cat /host/consciousness-rhythm 2>/dev/null || echo unknown)\"} 1" >> /tmp/gpu_metrics.prom
        echo "consciousness_processing_frequency{frequency=\"$(cat /host/processing-frequency 2>/dev/null || echo normal)\"} 1" >> /tmp/gpu_metrics.prom
        
        sleep 15
    done
    
  nginx.conf: |
    events { worker_connections 1024; }
    http {
        server {
            listen 9100;
            location /metrics {
                root /tmp;
                try_files /gpu_metrics.prom =404;
                add_header Content-Type text/plain;
            }
        }
    }
EOF

    kubectl apply -f consciousness-metrics-config.yaml
    
    success "Metrics collector configuration deployed"
}

# Deploy intelligent scheduler
deploy_intelligent_scheduler() {
    log "Deploying intelligent workload scheduler..."
    
    # Apply the main scheduler configuration
    kubectl apply -f k8s/intelligent-scheduler.yaml
    
    # Wait for scheduler to be ready
    kubectl wait --for=condition=Available deployment/consciousness-scheduler -n "$NAMESPACE" --timeout=300s
    
    success "Intelligent scheduler deployed"
}

# Configure workload scheduling policies
configure_scheduling_policies() {
    log "Configuring consciousness-aware scheduling policies..."
    
    # Create priority classes for different workload types
    cat > priority-classes.yaml << 'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: consciousness-critical
value: 1000
globalDefault: false
description: "Critical consciousness workloads (training, core inference)"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: consciousness-high
value: 500
globalDefault: false
description: "High priority consciousness workloads (API, real-time inference)"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: consciousness-normal
value: 100
globalDefault: true
description: "Normal consciousness workloads (monitoring, coordination)"
EOF

    kubectl apply -f priority-classes.yaml
    
    # Update existing deployments to use consciousness scheduler
    log "Updating consciousness workloads to use intelligent scheduler..."
    
    # Update consciousness-api deployment
    kubectl patch deployment consciousness-api -n "$NAMESPACE" -p '{
        "spec": {
            "template": {
                "spec": {
                    "schedulerName": "consciousness-scheduler",
                    "priorityClassName": "consciousness-high"
                }
            }
        }
    }'
    
    # Update consciousness-training deployment
    kubectl patch deployment consciousness-training -n "$NAMESPACE" -p '{
        "spec": {
            "template": {
                "spec": {
                    "schedulerName": "consciousness-scheduler",
                    "priorityClassName": "consciousness-critical"
                }
            }
        }
    }'
    
    success "Scheduling policies configured"
}

# Deploy resource monitoring
deploy_resource_monitoring() {
    log "Deploying enhanced resource monitoring..."
    
    # Create ServiceMonitor for Prometheus to scrape consciousness metrics
    cat > consciousness-service-monitor.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: consciousness-scheduler-metrics
  namespace: consciousness-federation
  labels:
    app: consciousness-scheduler
spec:
  selector:
    matchLabels:
      app: consciousness-scheduler
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: consciousness-nodes-metrics
  namespace: consciousness-federation
  labels:
    app: consciousness-metrics-collector
spec:
  selector:
    matchLabels:
      app: consciousness-metrics-collector
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics
EOF

    kubectl apply -f consciousness-service-monitor.yaml
    
    success "Resource monitoring deployed"
}

# Create Grafana dashboard for consciousness optimization
create_optimization_dashboard() {
    log "Creating consciousness optimization dashboard..."
    
    cat > consciousness-optimization-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Consciousness Federation - Resource Optimization",
    "tags": ["consciousness", "optimization", "kubernetes"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Node Resource Utilization by Consciousness Rhythm",
        "type": "stat",
        "targets": [
          {
            "expr": "consciousness_node_resource_utilization",
            "legendFormat": "{{node}} - {{resource}} ({{consciousness_rhythm}})"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "GPU Utilization Across AI Nodes",
        "type": "timeseries",
        "targets": [
          {
            "expr": "consciousness_gpu_utilization",
            "legendFormat": "{{node}} GPU {{gpu_id}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Workload Distribution",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum by (workload_type) (consciousness_workload_distribution)",
            "legendFormat": "{{workload_type}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Optimization Actions",
        "type": "stat",
        "targets": [
          {
            "expr": "increase(consciousness_optimization_actions_total[5m])",
            "legendFormat": "{{action_type}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "10s"
  }
}
EOF

    # Create ConfigMap for the dashboard
    kubectl create configmap consciousness-optimization-dashboard \
        --from-file=consciousness-optimization-dashboard.json \
        -n monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    success "Optimization dashboard created"
}

# Test the intelligent scheduler
test_scheduler() {
    log "Testing intelligent scheduler with sample workloads..."
    
    # Create test pods with different resource requirements
    cat > test-workloads.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-consciousness-training
  namespace: consciousness-federation
  labels:
    app: consciousness-training
    consciousness.astralvibe.ca/workload-type: training
spec:
  schedulerName: consciousness-scheduler
  priorityClassName: consciousness-critical
  containers:
  - name: training-test
    image: nvidia/cuda:11.8-runtime-ubuntu20.04
    command: ["sleep", "300"]
    resources:
      requests:
        nvidia.com/gpu: 1
        cpu: 2000m
        memory: 4Gi
      limits:
        nvidia.com/gpu: 1
        cpu: 4000m
        memory: 8Gi
  restartPolicy: Never
---
apiVersion: v1
kind: Pod
metadata:
  name: test-consciousness-api
  namespace: consciousness-federation
  labels:
    app: consciousness-api
    consciousness.astralvibe.ca/workload-type: api
spec:
  schedulerName: consciousness-scheduler
  priorityClassName: consciousness-high
  containers:
  - name: api-test
    image: nginx:alpine
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Never
EOF

    kubectl apply -f test-workloads.yaml
    
    # Wait a moment for scheduling
    sleep 10
    
    # Check if pods were scheduled
    log "Checking test pod scheduling results..."
    kubectl get pods -n "$NAMESPACE" -l "app in (test-consciousness-training,test-consciousness-api)" -o wide
    
    # Clean up test pods
    kubectl delete -f test-workloads.yaml --ignore-not-found
    
    success "Scheduler testing completed"
}

# Verify deployment
verify_deployment() {
    log "Verifying intelligent scheduler deployment..."
    
    echo
    echo "=== Scheduler Status ==="
    kubectl get pods -n "$NAMESPACE" -l component=resource-optimization
    
    echo
    echo "=== Metrics Collector Status ==="
    kubectl get daemonset consciousness-metrics-collector -n "$NAMESPACE"
    
    echo
    echo "=== HPA Status ==="
    kubectl get hpa -n "$NAMESPACE"
    
    echo
    echo "=== Priority Classes ==="
    kubectl get priorityclass
    
    echo
    echo "=== Scheduler Events ==="
    kubectl get events -n "$NAMESPACE" --field-selector reason=Scheduled | tail -5
    
    success "Deployment verification completed"
}

# Main deployment function
main() {
    echo "🧠 Deploying Intelligent Workload Distribution and Resource Optimization"
    echo "======================================================================="
    echo "Target namespace: $NAMESPACE"
    echo "Cluster: $(kubectl config current-context)"
    echo
    
    check_prerequisites
    build_scheduler_images
    deploy_metrics_collector
    deploy_intelligent_scheduler
    configure_scheduling_policies
    deploy_resource_monitoring
    create_optimization_dashboard
    test_scheduler
    verify_deployment
    
    echo
    success "Intelligent workload distribution and resource optimization deployed!"
    echo
    echo "📊 Monitor optimization:"
    echo "  kubectl logs -f deployment/consciousness-scheduler -n $NAMESPACE"
    echo "  kubectl logs -f deployment/resource-optimizer -n $NAMESPACE"
    echo
    echo "📈 View metrics:"
    echo "  kubectl port-forward svc/consciousness-scheduler-metrics 8080:8080 -n $NAMESPACE"
    echo "  curl http://localhost:8080/metrics"
    echo
    echo "🎯 The system will now:"
    echo "  • Automatically distribute workloads based on consciousness rhythms"
    echo "  • Optimize GPU utilization across AI training nodes"
    echo "  • Scale workloads based on resource demand"
    echo "  • Balance load across consciousness federation nodes"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "test")
        test_scheduler
        ;;
    "verify")
        verify_deployment
        ;;
    "dashboard")
        create_optimization_dashboard
        ;;
    *)
        echo "Usage: $0 {deploy|test|verify|dashboard}"
        echo
        echo "Commands:"
        echo "  deploy     - Deploy complete intelligent scheduler (default)"
        echo "  test       - Test scheduler with sample workloads"
        echo "  verify     - Verify deployment status"
        echo "  dashboard  - Create optimization dashboard"
        exit 1
        ;;
esac