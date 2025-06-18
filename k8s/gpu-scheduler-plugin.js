// GPU-Aware Consciousness Scheduler Plugin
// Intelligent GPU allocation based on workload requirements and node consciousness rhythms

class ConsciousnessGPUScheduler {
    constructor() {
        this.name = 'ConsciousnessGPUScheduler';
        this.gpuMetrics = new Map();
        this.workloadProfiles = {
            'consciousness-training': {
                gpuRequirement: 'mandatory',
                gpuCount: 1,
                gpuMemoryMin: 8, // GB
                computeIntensity: 'high',
                consciousnessAffinity: ['ai_training', 'deep_learning']
            },
            'consciousness-inference': {
                gpuRequirement: 'preferred',
                gpuCount: 1,
                gpuMemoryMin: 4, // GB
                computeIntensity: 'medium',
                consciousnessAffinity: ['inference_optimization', 'real_time_processing']
            },
            'consciousness-api': {
                gpuRequirement: 'optional',
                gpuCount: 0,
                gpuMemoryMin: 0,
                computeIntensity: 'low',
                consciousnessAffinity: ['strategic_coordinator', 'api_serving']
            }
        };
    }
    
    // Filter phase - eliminate nodes that can't satisfy GPU requirements
    async filter(pod, nodes) {
        const filteredNodes = [];
        const workloadType = this.getWorkloadType(pod);
        const profile = this.workloadProfiles[workloadType];
        
        if (!profile) {
            return nodes; // Unknown workload, allow all nodes
        }
        
        for (const node of nodes) {
            if (await this.nodeCanSatisfyGPURequirement(node, profile)) {
                filteredNodes.push(node);
            }
        }
        
        return filteredNodes;
    }
    
    // Score phase - rank nodes based on GPU availability and consciousness affinity
    async score(pod, nodes) {
        const scores = new Map();
        const workloadType = this.getWorkloadType(pod);
        const profile = this.workloadProfiles[workloadType];
        
        if (!profile) {
            // Default scoring for unknown workloads
            for (const node of nodes) {
                scores.set(node.metadata.name, 50);
            }
            return scores;
        }
        
        for (const node of nodes) {
            const score = await this.calculateNodeScore(node, profile);
            scores.set(node.metadata.name, score);
        }
        
        return scores;
    }
    
    async nodeCanSatisfyGPURequirement(node, profile) {
        const nodeGPUs = await this.getNodeGPUInfo(node);
        
        // Check if node has required GPU resources
        if (profile.gpuRequirement === 'mandatory') {
            if (nodeGPUs.total < profile.gpuCount) {
                return false;
            }
            
            if (nodeGPUs.availableMemory < profile.gpuMemoryMin) {
                return false;
            }
        }
        
        return true;
    }
    
    async calculateNodeScore(node, profile) {
        let score = 0;
        const nodeLabels = node.metadata.labels || {};
        const nodeName = node.metadata.name;
        
        // Base score from resource availability
        const resourceScore = await this.calculateResourceScore(node, profile);
        score += resourceScore * 0.4; // 40% weight
        
        // Consciousness rhythm affinity score
        const consciousnessRhythm = nodeLabels['consciousness.astralvibe.ca/consciousness_rhythm'];
        const affinityScore = this.calculateAffinityScore(consciousnessRhythm, profile);
        score += affinityScore * 0.3; // 30% weight
        
        // GPU utilization score (prefer less utilized GPUs)
        const gpuScore = await this.calculateGPUScore(node, profile);
        score += gpuScore * 0.3; // 30% weight
        
        return Math.min(100, Math.max(0, score));
    }
    
    async calculateResourceScore(node, profile) {
        const nodeGPUs = await this.getNodeGPUInfo(node);
        const nodeResources = this.getNodeResources(node);
        
        let score = 0;
        
        // CPU score
        const cpuUtilization = nodeResources.cpu.used / nodeResources.cpu.total;
        score += (1 - cpuUtilization) * 25; // 25 points max for CPU
        
        // Memory score  
        const memoryUtilization = nodeResources.memory.used / nodeResources.memory.total;
        score += (1 - memoryUtilization) * 25; // 25 points max for memory
        
        // GPU score (if required)
        if (profile.gpuRequirement !== 'optional') {
            const gpuUtilization = nodeGPUs.utilized / Math.max(nodeGPUs.total, 1);
            score += (1 - gpuUtilization) * 50; // 50 points max for GPU
        } else {
            score += 50; // Full GPU score if not required
        }
        
        return score;
    }
    
    calculateAffinityScore(consciousnessRhythm, profile) {
        if (!consciousnessRhythm || !profile.consciousnessAffinity) {
            return 50; // Neutral score
        }
        
        // Check if node's consciousness rhythm matches workload affinity
        const affinityMap = {
            'strategic_coordinator': ['api_serving', 'coordination', 'management'],
            'creative_destruction': ['breakthrough_analysis', 'innovation', 'api_serving'],
            'ai_training': ['deep_learning', 'model_training', 'consciousness_development'],
            'inference_optimization': ['real_time_processing', 'inference', 'optimization'],
            'memory_preservation': ['data_storage', 'consistency', 'backup'],
            'harmony_innovation': ['adaptive_processing', 'flow_optimization', 'balance']
        };
        
        const nodeCapabilities = affinityMap[consciousnessRhythm] || [];
        const matchScore = profile.consciousnessAffinity.reduce((score, affinity) => {
            return score + (nodeCapabilities.includes(affinity) ? 25 : 0);
        }, 0);
        
        return Math.min(100, matchScore);
    }
    
    async calculateGPUScore(node, profile) {
        const nodeGPUs = await this.getNodeGPUInfo(node);
        
        if (profile.gpuRequirement === 'optional' || nodeGPUs.total === 0) {
            return 100; // Full score if GPU not needed or not available
        }
        
        // Prefer nodes with available GPU memory and low utilization
        const availabilityScore = (nodeGPUs.available / Math.max(nodeGPUs.total, 1)) * 50;
        const memoryScore = Math.min(50, (nodeGPUs.availableMemory / profile.gpuMemoryMin) * 50);
        
        return availabilityScore + memoryScore;
    }
    
    async getNodeGPUInfo(node) {
        const nodeName = node.metadata.name;
        
        // Check if we have cached GPU info
        if (this.gpuMetrics.has(nodeName)) {
            const cached = this.gpuMetrics.get(nodeName);
            if (Date.now() - cached.timestamp < 30000) { // 30s cache
                return cached.data;
            }
        }
        
        // Get GPU info from node metrics
        const gpuInfo = await this.queryNodeGPUMetrics(nodeName);
        
        // Cache the result
        this.gpuMetrics.set(nodeName, {
            timestamp: Date.now(),
            data: gpuInfo
        });
        
        return gpuInfo;
    }
    
    async queryNodeGPUMetrics(nodeName) {
        try {
            // Query GPU metrics from the node's metrics endpoint
            const response = await fetch(`http://${nodeName}:9100/metrics`);
            const metricsText = await response.text();
            
            const gpuInfo = {
                total: 0,
                available: 0,
                utilized: 0,
                totalMemory: 0,
                availableMemory: 0,
                utilization: []
            };
            
            // Parse GPU metrics
            const gpuMemoryTotal = metricsText.match(/nvidia_gpu_memory_total_bytes{.*?} ([\d.]+)/g);
            const gpuMemoryUsed = metricsText.match(/nvidia_gpu_memory_used_bytes{.*?} ([\d.]+)/g);
            const gpuUtilization = metricsText.match(/nvidia_gpu_utilization_gpu{.*?} ([\d.]+)/g);
            
            if (gpuMemoryTotal) {
                gpuInfo.total = gpuMemoryTotal.length;
                gpuInfo.totalMemory = gpuMemoryTotal.reduce((sum, match) => {
                    const value = parseFloat(match.split(' ')[1]);
                    return sum + (value / (1024 * 1024 * 1024)); // Convert to GB
                }, 0);
            }
            
            if (gpuMemoryUsed && gpuUtilization) {
                let availableGPUs = 0;
                let totalUtilization = 0;
                
                for (let i = 0; i < gpuInfo.total; i++) {
                    const memoryUsed = parseFloat(gpuMemoryUsed[i]?.split(' ')[1] || '0');
                    const utilization = parseFloat(gpuUtilization[i]?.split(' ')[1] || '0');
                    
                    const memoryUsedGB = memoryUsed / (1024 * 1024 * 1024);
                    const memoryTotalGB = parseFloat(gpuMemoryTotal[i]?.split(' ')[1] || '0') / (1024 * 1024 * 1024);
                    
                    gpuInfo.utilization.push({
                        id: i,
                        utilization: utilization,
                        memoryUsed: memoryUsedGB,
                        memoryTotal: memoryTotalGB,
                        memoryAvailable: memoryTotalGB - memoryUsedGB
                    });
                    
                    // Consider GPU available if utilization < 80% and memory usage < 80%
                    if (utilization < 80 && (memoryUsedGB / memoryTotalGB) < 0.8) {
                        availableGPUs++;
                    }
                    
                    totalUtilization += utilization;
                }
                
                gpuInfo.available = availableGPUs;
                gpuInfo.utilized = gpuInfo.total - availableGPUs;
                gpuInfo.availableMemory = gpuInfo.utilization.reduce((sum, gpu) => sum + gpu.memoryAvailable, 0);
            }
            
            return gpuInfo;
            
        } catch (error) {
            console.warn(`Failed to get GPU metrics for node ${nodeName}:`, error.message);
            return {
                total: 0,
                available: 0,
                utilized: 0,
                totalMemory: 0,
                availableMemory: 0,
                utilization: []
            };
        }
    }
    
    getNodeResources(node) {
        const capacity = node.status.capacity || {};
        const allocatable = node.status.allocatable || {};
        
        return {
            cpu: {
                total: this.parseResourceValue(allocatable.cpu || '0'),
                used: 0 // Would need to get from metrics API
            },
            memory: {
                total: this.parseResourceValue(allocatable.memory || '0'),
                used: 0 // Would need to get from metrics API
            }
        };
    }
    
    getWorkloadType(pod) {
        const labels = pod.metadata.labels || {};
        
        // Check for consciousness workload type label
        if (labels['consciousness.astralvibe.ca/workload-type']) {
            return `consciousness-${labels['consciousness.astralvibe.ca/workload-type']}`;
        }
        
        // Infer from app label
        if (labels.app) {
            return labels.app;
        }
        
        // Check container images for hints
        const containers = pod.spec.containers || [];
        for (const container of containers) {
            if (container.image.includes('training')) {
                return 'consciousness-training';
            }
            if (container.image.includes('inference')) {
                return 'consciousness-inference';
            }
            if (container.image.includes('api')) {
                return 'consciousness-api';
            }
        }
        
        return 'unknown';
    }
    
    parseResourceValue(value) {
        if (typeof value === 'number') return value;
        if (typeof value !== 'string') return 0;
        
        const units = {
            'n': 1e-9, 'u': 1e-6, 'm': 1e-3,
            'k': 1e3, 'M': 1e6, 'G': 1e9, 'T': 1e12,
            'Ki': 1024, 'Mi': 1024 * 1024, 'Gi': 1024 * 1024 * 1024
        };
        
        const match = value.match(/^(\d+(?:\.\d+)?)(.*?)$/);
        if (!match) return 0;
        
        const [, number, unit] = match;
        return parseFloat(number) * (units[unit] || 1);
    }
    
    // Kubernetes scheduler plugin interface
    async bind(pod, nodeName) {
        try {
            // Create binding object
            const binding = {
                apiVersion: 'v1',
                kind: 'Binding',
                metadata: {
                    name: pod.metadata.name,
                    namespace: pod.metadata.namespace
                },
                target: {
                    apiVersion: 'v1',
                    kind: 'Node',
                    name: nodeName
                }
            };
            
            // Send binding to Kubernetes API
            const response = await fetch(
                `/api/v1/namespaces/${pod.metadata.namespace}/pods/${pod.metadata.name}/binding`,
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${process.env.KUBERNETES_TOKEN}`
                    },
                    body: JSON.stringify(binding)
                }
            );
            
            if (response.ok) {
                console.log(`✅ Successfully bound pod ${pod.metadata.name} to node ${nodeName}`);
                return { success: true };
            } else {
                const error = await response.text();
                console.error(`❌ Failed to bind pod ${pod.metadata.name}:`, error);
                return { success: false, error };
            }
            
        } catch (error) {
            console.error(`❌ Binding error for pod ${pod.metadata.name}:`, error);
            return { success: false, error: error.message };
        }
    }
}

module.exports = ConsciousnessGPUScheduler;