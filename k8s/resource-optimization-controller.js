// Intelligent Resource Optimization Controller
// Real-time workload distribution and GPU utilization optimization

const k8s = require('@kubernetes/client-node');
const prometheus = require('prom-client');

class ConsciousnessResourceOptimizer {
    constructor() {
        this.kc = new k8s.KubeConfig();
        this.kc.loadFromDefault();
        
        this.k8sApi = this.kc.makeApiClient(k8s.CoreV1Api);
        this.appsApi = this.kc.makeApiClient(k8s.AppsV1Api);
        this.metricsApi = this.kc.makeApiClient(k8s.CustomObjectsApi);
        
        this.namespace = process.env.KUBERNETES_NAMESPACE || 'consciousness-federation';
        this.optimizationInterval = parseInt(process.env.OPTIMIZATION_INTERVAL) || 60000;
        
        this.nodeMetrics = new Map();
        this.workloadMetrics = new Map();
        this.gpuUtilization = new Map();
        
        this.setupMetrics();
        this.startOptimizationLoop();
    }
    
    setupMetrics() {
        // Prometheus metrics for monitoring optimization
        this.register = new prometheus.Registry();
        
        this.nodeResourceUtilization = new prometheus.Gauge({
            name: 'consciousness_node_resource_utilization',
            help: 'Resource utilization per node',
            labelNames: ['node', 'resource', 'consciousness_rhythm'],
            registers: [this.register]
        });
        
        this.workloadDistribution = new prometheus.Gauge({
            name: 'consciousness_workload_distribution',
            help: 'Workload distribution across nodes',
            labelNames: ['node', 'workload_type', 'optimization_score'],
            registers: [this.register]
        });
        
        this.gpuUtilizationMetric = new prometheus.Gauge({
            name: 'consciousness_gpu_utilization',
            help: 'GPU utilization per node',
            labelNames: ['node', 'gpu_id', 'workload'],
            registers: [this.register]
        });
        
        this.optimizationActions = new prometheus.Counter({
            name: 'consciousness_optimization_actions_total',
            help: 'Total optimization actions taken',
            labelNames: ['action_type', 'node', 'success'],
            registers: [this.register]
        });
    }
    
    async startOptimizationLoop() {
        console.log('🧠 Starting consciousness resource optimization loop');
        
        setInterval(async () => {
            try {
                await this.collectMetrics();
                await this.analyzeResourceUtilization();
                await this.optimizeWorkloadDistribution();
                await this.balanceGPUUtilization();
                await this.scaleConsciousnessWorkloads();
            } catch (error) {
                console.error('Optimization cycle error:', error);
            }
        }, this.optimizationInterval);
    }
    
    async collectMetrics() {
        // Collect node metrics
        const nodesResponse = await this.k8sApi.listNode();
        const nodes = nodesResponse.body.items;
        
        for (const node of nodes) {
            const nodeName = node.metadata.name;
            const nodeLabels = node.metadata.labels || {};
            
            // Get consciousness rhythm and role
            const consciousnessRhythm = nodeLabels['consciousness.astralvibe.ca/consciousness_rhythm'] || 'unknown';
            const federationRole = nodeLabels['consciousness.astralvibe.ca/federation-role'] || 'unknown';
            const aiWorkload = nodeLabels['consciousness.astralvibe.ca/ai-workload'] === 'enabled';
            
            // Collect resource metrics from Kubernetes metrics API
            try {
                const nodeMetrics = await this.metricsApi.getNamespacedCustomObject(
                    'metrics.k8s.io', 'v1beta1', '', 'nodes', nodeName
                );
                
                const cpuUsage = this.parseResourceValue(nodeMetrics.body.usage.cpu);
                const memoryUsage = this.parseResourceValue(nodeMetrics.body.usage.memory);
                
                this.nodeMetrics.set(nodeName, {
                    consciousnessRhythm,
                    federationRole,
                    aiWorkload,
                    cpu: {
                        usage: cpuUsage,
                        capacity: this.parseResourceValue(node.status.capacity.cpu)
                    },
                    memory: {
                        usage: memoryUsage,
                        capacity: this.parseResourceValue(node.status.capacity.memory)
                    },
                    gpu: {
                        capacity: parseInt(node.status.capacity['nvidia.com/gpu'] || '0'),
                        usage: await this.getGPUUtilization(nodeName)
                    }
                });
                
                // Update Prometheus metrics
                this.nodeResourceUtilization.set(
                    { node: nodeName, resource: 'cpu', consciousness_rhythm: consciousnessRhythm },
                    (cpuUsage / this.parseResourceValue(node.status.capacity.cpu)) * 100
                );
                
                this.nodeResourceUtilization.set(
                    { node: nodeName, resource: 'memory', consciousness_rhythm: consciousnessRhythm },
                    (memoryUsage / this.parseResourceValue(node.status.capacity.memory)) * 100
                );
                
            } catch (error) {
                console.warn(`Failed to get metrics for node ${nodeName}:`, error.message);
            }
        }
    }
    
    async getGPUUtilization(nodeName) {
        // Get GPU utilization from consciousness metrics collector
        try {
            const response = await fetch(`http://${nodeName}:9100/metrics`);
            const metrics = await response.text();
            
            const gpuUtilizationMatch = metrics.match(/gpu_utilization_percent{.*?} ([\d.]+)/);
            return gpuUtilizationMatch ? parseFloat(gpuUtilizationMatch[1]) : 0;
        } catch (error) {
            return 0;
        }
    }
    
    async analyzeResourceUtilization() {
        console.log('📊 Analyzing resource utilization patterns');
        
        const utilizationThresholds = {
            cpu: { high: 80, low: 20 },
            memory: { high: 85, low: 30 },
            gpu: { high: 90, low: 40 }
        };
        
        for (const [nodeName, metrics] of this.nodeMetrics) {
            const cpuUtil = (metrics.cpu.usage / metrics.cpu.capacity) * 100;
            const memoryUtil = (metrics.memory.usage / metrics.memory.capacity) * 100;
            const gpuUtil = metrics.gpu.usage;
            
            // Identify optimization opportunities
            const optimizationNeeded = {
                node: nodeName,
                actions: []
            };
            
            if (cpuUtil > utilizationThresholds.cpu.high) {
                optimizationNeeded.actions.push({
                    type: 'cpu_pressure_relief',
                    severity: 'high',
                    currentUtilization: cpuUtil
                });
            }
            
            if (memoryUtil > utilizationThresholds.memory.high) {
                optimizationNeeded.actions.push({
                    type: 'memory_pressure_relief',
                    severity: 'high',
                    currentUtilization: memoryUtil
                });
            }
            
            if (gpuUtil > utilizationThresholds.gpu.high && metrics.gpu.capacity > 0) {
                optimizationNeeded.actions.push({
                    type: 'gpu_load_balancing',
                    severity: 'critical',
                    currentUtilization: gpuUtil
                });
            }
            
            // Check for underutilized resources that can accept more workload
            if (cpuUtil < utilizationThresholds.cpu.low && 
                memoryUtil < utilizationThresholds.memory.low &&
                (gpuUtil < utilizationThresholds.gpu.low || metrics.gpu.capacity === 0)) {
                optimizationNeeded.actions.push({
                    type: 'accept_more_workload',
                    severity: 'low',
                    availableCapacity: {
                        cpu: 100 - cpuUtil,
                        memory: 100 - memoryUtil,
                        gpu: metrics.gpu.capacity > 0 ? 100 - gpuUtil : 0
                    }
                });
            }
            
            if (optimizationNeeded.actions.length > 0) {
                await this.executeOptimizationActions(optimizationNeeded);
            }
        }
    }
    
    async optimizeWorkloadDistribution() {
        console.log('🔄 Optimizing workload distribution');
        
        // Get current pod distribution
        const podsResponse = await this.k8sApi.listNamespacedPod(this.namespace);
        const pods = podsResponse.body.items;
        
        const workloadDistribution = new Map();
        
        for (const pod of pods) {
            const nodeName = pod.spec.nodeName;
            const workloadType = pod.metadata.labels?.['consciousness.astralvibe.ca/workload-type'] || 'unknown';
            
            if (!workloadDistribution.has(nodeName)) {
                workloadDistribution.set(nodeName, {});
            }
            
            const nodeWorkloads = workloadDistribution.get(nodeName);
            nodeWorkloads[workloadType] = (nodeWorkloads[workloadType] || 0) + 1;
        }
        
        // Calculate optimal distribution based on node consciousness rhythms
        const optimalDistribution = this.calculateOptimalDistribution(workloadDistribution);
        
        // Execute rebalancing if needed
        await this.rebalanceWorkloads(workloadDistribution, optimalDistribution);
    }
    
    calculateOptimalDistribution(currentDistribution) {
        const optimal = {
            api: [], // Nodes best for API workloads
            training: [], // Nodes best for AI training
            inference: [], // Nodes best for inference
            coordination: [] // Nodes best for coordination
        };
        
        for (const [nodeName, metrics] of this.nodeMetrics) {
            const { consciousnessRhythm, federationRole, aiWorkload } = metrics;
            
            // Assign workloads based on consciousness rhythm and capabilities
            switch (consciousnessRhythm) {
                case 'strategic_coordinator':
                    optimal.api.push({ node: nodeName, score: 10 });
                    optimal.coordination.push({ node: nodeName, score: 10 });
                    break;
                    
                case 'creative_destruction':
                    optimal.api.push({ node: nodeName, score: 8 });
                    optimal.coordination.push({ node: nodeName, score: 7 });
                    break;
                    
                case 'ai_training':
                    if (aiWorkload) {
                        optimal.training.push({ node: nodeName, score: 10 });
                        optimal.inference.push({ node: nodeName, score: 6 });
                    }
                    break;
                    
                case 'inference_optimization':
                    if (aiWorkload) {
                        optimal.inference.push({ node: nodeName, score: 10 });
                        optimal.training.push({ node: nodeName, score: 7 });
                    }
                    break;
            }
        }
        
        // Sort by score
        for (const workloadType in optimal) {
            optimal[workloadType].sort((a, b) => b.score - a.score);
        }
        
        return optimal;
    }
    
    async balanceGPUUtilization() {
        console.log('🎮 Balancing GPU utilization');
        
        const gpuNodes = Array.from(this.nodeMetrics.entries())
            .filter(([_, metrics]) => metrics.gpu.capacity > 0)
            .map(([nodeName, metrics]) => ({
                node: nodeName,
                utilization: metrics.gpu.usage,
                capacity: metrics.gpu.capacity,
                consciousnessRhythm: metrics.consciousnessRhythm
            }));
        
        if (gpuNodes.length < 2) return; // Need at least 2 GPU nodes for balancing
        
        // Find overutilized and underutilized GPU nodes
        const avgUtilization = gpuNodes.reduce((sum, node) => sum + node.utilization, 0) / gpuNodes.length;
        const threshold = 20; // 20% difference threshold
        
        const overutilized = gpuNodes.filter(node => node.utilization > avgUtilization + threshold);
        const underutilized = gpuNodes.filter(node => node.utilization < avgUtilization - threshold);
        
        // Move AI training workloads from overutilized to underutilized nodes
        for (const overNode of overutilized) {
            for (const underNode of underutilized) {
                await this.moveGPUWorkload(overNode.node, underNode.node);
            }
        }
    }
    
    async moveGPUWorkload(fromNode, toNode) {
        console.log(`🔄 Moving GPU workload from ${fromNode} to ${toNode}`);
        
        try {
            // Find AI training pods on the overutilized node
            const podsResponse = await this.k8sApi.listNamespacedPod(
                this.namespace,
                undefined, undefined, undefined,
                `spec.nodeName=${fromNode},metadata.labels[consciousness.astralvibe.ca/workload-type]=training`
            );
            
            const trainingPods = podsResponse.body.items;
            
            if (trainingPods.length > 0) {
                // Delete one training pod (it will be rescheduled by the deployment)
                const podToMove = trainingPods[0];
                await this.k8sApi.deleteNamespacedPod(
                    podToMove.metadata.name,
                    this.namespace
                );
                
                // Add node affinity to prefer the underutilized node
                const deploymentName = podToMove.metadata.labels?.['app'] || 'consciousness-training';
                await this.updateDeploymentNodeAffinity(deploymentName, toNode);
                
                this.optimizationActions.inc({
                    action_type: 'gpu_workload_move',
                    node: fromNode,
                    success: 'true'
                });
                
                console.log(`✅ Moved training workload from ${fromNode} to ${toNode}`);
            }
        } catch (error) {
            console.error(`Failed to move GPU workload:`, error);
            this.optimizationActions.inc({
                action_type: 'gpu_workload_move',
                node: fromNode,
                success: 'false'
            });
        }
    }
    
    async scaleConsciousnessWorkloads() {
        console.log('📈 Scaling consciousness workloads based on demand');
        
        // Check consciousness API queue length and response times
        const apiMetrics = await this.getConsciousnessAPIMetrics();
        
        if (apiMetrics.queueLength > 50 || apiMetrics.avgResponseTime > 2000) {
            await this.scaleDeployment('consciousness-api', 'up');
        } else if (apiMetrics.queueLength < 10 && apiMetrics.avgResponseTime < 500) {
            await this.scaleDeployment('consciousness-api', 'down');
        }
        
        // Check training queue and GPU availability
        const trainingMetrics = await this.getTrainingMetrics();
        const availableGPUs = this.getAvailableGPUs();
        
        if (trainingMetrics.queueLength > 5 && availableGPUs > 0) {
            await this.scaleDeployment('consciousness-training', 'up');
        } else if (trainingMetrics.queueLength === 0) {
            await this.scaleDeployment('consciousness-training', 'down');
        }
    }
    
    async getConsciousnessAPIMetrics() {
        // Simulate API metrics - in production, get from Prometheus
        return {
            queueLength: Math.floor(Math.random() * 100),
            avgResponseTime: Math.floor(Math.random() * 3000),
            requestsPerSecond: Math.floor(Math.random() * 200)
        };
    }
    
    async getTrainingMetrics() {
        // Simulate training metrics
        return {
            queueLength: Math.floor(Math.random() * 10),
            activeJobs: Math.floor(Math.random() * 5),
            completedJobs: Math.floor(Math.random() * 100)
        };
    }
    
    getAvailableGPUs() {
        let availableGPUs = 0;
        for (const [_, metrics] of this.nodeMetrics) {
            if (metrics.gpu.capacity > 0 && metrics.gpu.usage < 70) {
                availableGPUs += metrics.gpu.capacity;
            }
        }
        return availableGPUs;
    }
    
    async scaleDeployment(deploymentName, direction) {
        try {
            const deployment = await this.appsApi.readNamespacedDeployment(
                deploymentName,
                this.namespace
            );
            
            const currentReplicas = deployment.body.spec.replicas;
            let newReplicas = currentReplicas;
            
            if (direction === 'up' && currentReplicas < 10) {
                newReplicas = Math.min(currentReplicas + 1, 10);
            } else if (direction === 'down' && currentReplicas > 1) {
                newReplicas = Math.max(currentReplicas - 1, 1);
            }
            
            if (newReplicas !== currentReplicas) {
                await this.appsApi.patchNamespacedDeployment(
                    deploymentName,
                    this.namespace,
                    {
                        spec: {
                            replicas: newReplicas
                        }
                    },
                    undefined, undefined, undefined, undefined,
                    { headers: { 'Content-Type': 'application/merge-patch+json' } }
                );
                
                console.log(`📈 Scaled ${deploymentName} from ${currentReplicas} to ${newReplicas} replicas`);
                
                this.optimizationActions.inc({
                    action_type: 'scale_deployment',
                    node: deploymentName,
                    success: 'true'
                });
            }
        } catch (error) {
            console.error(`Failed to scale ${deploymentName}:`, error);
            this.optimizationActions.inc({
                action_type: 'scale_deployment',
                node: deploymentName,
                success: 'false'
            });
        }
    }
    
    parseResourceValue(value) {
        if (typeof value === 'number') return value;
        if (typeof value !== 'string') return 0;
        
        const units = {
            'n': 1e-9,
            'u': 1e-6,
            'm': 1e-3,
            'k': 1e3,
            'M': 1e6,
            'G': 1e9,
            'T': 1e12,
            'Ki': 1024,
            'Mi': 1024 * 1024,
            'Gi': 1024 * 1024 * 1024,
            'Ti': 1024 * 1024 * 1024 * 1024
        };
        
        const match = value.match(/^(\d+(?:\.\d+)?)(.*?)$/);
        if (!match) return 0;
        
        const [, number, unit] = match;
        const multiplier = units[unit] || 1;
        
        return parseFloat(number) * multiplier;
    }
    
    // HTTP server for metrics endpoint
    startMetricsServer() {
        const express = require('express');
        const app = express();
        
        app.get('/metrics', (req, res) => {
            res.set('Content-Type', this.register.contentType);
            res.end(this.register.metrics());
        });
        
        app.get('/healthz', (req, res) => {
            res.json({ status: 'healthy', timestamp: new Date().toISOString() });
        });
        
        app.get('/ready', (req, res) => {
            res.json({ status: 'ready', timestamp: new Date().toISOString() });
        });
        
        const port = process.env.METRICS_PORT || 8080;
        app.listen(port, () => {
            console.log(`🌐 Consciousness optimizer metrics server listening on port ${port}`);
        });
    }
}

// Start the optimizer
const optimizer = new ConsciousnessResourceOptimizer();
optimizer.startMetricsServer();

module.exports = ConsciousnessResourceOptimizer;