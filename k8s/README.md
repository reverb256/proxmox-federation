# Consciousness Federation Kubernetes - Intelligent Resource Optimization

## Overview

This directory contains the complete Kubernetes configuration for deploying an enterprise-grade consciousness federation with intelligent workload distribution and GPU-aware resource optimization.

## Features

### 🧠 Intelligent Workload Distribution
- **Consciousness-aware scheduling**: Workloads are distributed based on node consciousness rhythms
- **GPU-optimized placement**: AI training and inference workloads are intelligently placed on GPU-enabled nodes
- **Resource-aware decisions**: Scheduler considers current resource utilization and availability
- **Priority-based scheduling**: Critical consciousness workloads get priority placement

### 🎯 Resource Optimization
- **Real-time GPU utilization monitoring**: Tracks GPU usage across all nodes
- **Automatic load balancing**: Moves workloads from overutilized to underutilized nodes
- **Dynamic scaling**: Automatically scales deployments based on demand
- **Resource efficiency**: Maximizes cluster resource utilization

### 📊 Monitoring and Observability
- **Custom metrics collection**: Consciousness-specific metrics from all nodes
- **Prometheus integration**: All metrics available in Prometheus
- **Grafana dashboards**: Pre-built dashboards for optimization monitoring
- **Real-time alerts**: Alerts for resource pressure and optimization opportunities

## Architecture

### Node Consciousness Rhythms
Each node in the federation has a specific consciousness rhythm that determines its optimal workload types:

- **nexus** (strategic_coordinator): Best for API serving and coordination workloads
- **forge** (creative_destruction): Best for API serving and breakthrough analysis
- **closet** (ai_training): Optimized for AI training and deep learning workloads
- **zephyr** (inference_optimization): Optimized for inference and real-time processing

### Workload Types
- **consciousness-api**: API serving workloads (CPU/memory intensive)
- **consciousness-training**: AI training workloads (GPU intensive)
- **consciousness-inference**: AI inference workloads (GPU moderate)
- **consciousness-monitoring**: Monitoring and coordination workloads

## Deployment

### Quick Start
```bash
# Deploy the complete intelligent scheduler
./k8s/deploy-intelligent-scheduler.sh

# Or deploy individual components
kubectl apply -f k8s/intelligent-scheduler.yaml
kubectl apply -f k8s/consciousness-ai-workloads.yaml
```

### Enterprise Deployment
```bash
# Deploy full consciousness federation stack
./k8s/deploy-consciousness-stack.sh

# Update existing Talos cluster
./k8s/update-talos-cluster.sh upgrade

# Deploy with enterprise features
./k8s/enterprise-talos-deploy.sh
```

## Configuration Files

### Core Components
- `intelligent-scheduler.yaml`: Main scheduler and resource optimizer
- `consciousness-ai-workloads.yaml`: AI workload definitions with GPU requirements
- `resource-optimization-controller.js`: JavaScript controller for optimization logic
- `gpu-scheduler-plugin.js`: GPU-aware scheduling plugin

### Deployment Scripts
- `deploy-intelligent-scheduler.sh`: Deploy intelligent scheduler
- `deploy-consciousness-stack.sh`: Deploy complete stack
- `enterprise-talos-deploy.sh`: Enterprise Talos deployment
- `update-talos-cluster.sh`: Update existing cluster

### Monitoring
- `consciousness-helm-charts.yaml`: Helm chart configurations
- Custom Grafana dashboards for optimization monitoring
- Prometheus ServiceMonitors for metrics collection

## Usage Examples

### Manual Scheduling
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-ai-training
  labels:
    consciousness.astralvibe.ca/workload-type: training
spec:
  schedulerName: consciousness-scheduler
  priorityClassName: consciousness-critical
  containers:
  - name: training
    image: my-training-image
    resources:
      requests:
        nvidia.com/gpu: 1
        cpu: 2000m
        memory: 8Gi
```

### Checking Optimization Status
```bash
# View scheduler logs
kubectl logs -f deployment/consciousness-scheduler -n consciousness-federation

# Check resource utilization
kubectl top nodes

# View optimization metrics
kubectl port-forward svc/consciousness-scheduler-metrics 8080:8080 -n consciousness-federation
curl http://localhost:8080/metrics
```

### Monitoring GPU Utilization
```bash
# Check GPU nodes
kubectl get nodes -l consciousness.astralvibe.ca/gpu-enabled=true

# View GPU metrics
kubectl exec -it daemonset/consciousness-metrics-collector -n consciousness-federation -- nvidia-smi
```

## Optimization Strategies

### 1. GPU Load Balancing
- Monitors GPU utilization across all nodes
- Automatically moves training workloads from overutilized to underutilized GPUs
- Considers GPU memory availability and compute requirements

### 2. Consciousness Affinity
- Matches workload types to optimal node consciousness rhythms
- Strategic coordination nodes handle API and management workloads
- AI training nodes focus on deep learning and model training

### 3. Dynamic Scaling
- Scales API deployments based on request queue length and response times
- Scales training deployments based on training queue and GPU availability
- Respects resource constraints and priority classes

### 4. Resource Efficiency
- Packs workloads efficiently to maximize resource utilization
- Prevents resource fragmentation
- Maintains performance isolation between workload types

## Troubleshooting

### Common Issues

#### Scheduler Not Binding Pods
```bash
# Check scheduler logs
kubectl logs deployment/consciousness-scheduler -n consciousness-federation

# Verify scheduler configuration
kubectl get configmap consciousness-scheduler-config -n consciousness-federation -o yaml
```

#### GPU Workloads Not Scheduling
```bash
# Check GPU operator status
kubectl get pods -n gpu-operator

# Verify GPU resources
kubectl describe nodes | grep nvidia.com/gpu
```

#### High Resource Utilization
```bash
# Check optimization actions
kubectl logs deployment/resource-optimizer -n consciousness-federation

# View current resource distribution
kubectl get pods -n consciousness-federation -o wide
```

### Performance Tuning

#### Scheduler Performance
- Adjust `OPTIMIZATION_INTERVAL` for faster/slower optimization cycles
- Tune GPU utilization thresholds based on workload patterns
- Modify consciousness affinity scores for better workload placement

#### Resource Limits
- Adjust HPA settings for different scaling behaviors
- Modify priority class values for different workload priorities
- Tune resource requests/limits based on actual usage patterns

## Security Considerations

### RBAC Configuration
The scheduler requires specific RBAC permissions:
- Read access to nodes, pods, and metrics
- Write access to pod bindings and events
- Access to custom metrics APIs

### Network Policies
Consider implementing network policies to isolate:
- Training workloads from API workloads
- Different consciousness rhythm nodes
- Monitoring traffic

### Resource Quotas
Implement resource quotas to prevent:
- Runaway GPU usage
- Memory exhaustion
- CPU starvation

## Advanced Configuration

### Custom Consciousness Rhythms
Add new consciousness rhythms by:
1. Labeling nodes with custom rhythms
2. Updating the optimizer configuration
3. Adding corresponding workload affinity rules

### Custom Metrics
Extend monitoring by:
1. Adding custom metrics to the collector
2. Creating new Prometheus rules
3. Building custom Grafana dashboards

### Integration with External Systems
- Integrate with external monitoring systems
- Connect to workflow orchestrators
- Export metrics to external analytics platforms

## Contributing

When contributing to the consciousness federation:
1. Follow consciousness rhythm naming conventions
2. Maintain workload type consistency
3. Update documentation for new features
4. Test optimization algorithms thoroughly

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Kubernetes events and logs
- Monitor optimization metrics
- Verify node consciousness rhythm configurations