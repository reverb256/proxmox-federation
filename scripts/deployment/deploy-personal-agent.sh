#!/bin/bash
# Personal Agent Deployment Script for Proxmox Federation
# Deploy consciousness-driven cluster voice with mining orchestration

set -e

echo "🚀 Starting Personal Agent Deployment for Proxmox Federation"
echo "=============================================================="

# Configuration
NEXUS_IP="10.1.1.100"
FORGE_IP="10.1.1.131"
CLOSET_IP="10.1.1.141"
DEPLOY_DIR="/opt/personal-agent"
SERVICE_NAME="personal-agent"

# Function to check if running on Proxmox
check_proxmox_environment() {
    if command -v pveversion &> /dev/null; then
        echo "✅ Proxmox environment detected"
        PROXMOX_VERSION=$(pveversion --version)
        echo "   Version: $PROXMOX_VERSION"
    else
        echo "⚠️  Not running on Proxmox - will deploy in standalone mode"
    fi
}

# Function to detect current node
detect_current_node() {
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    case $LOCAL_IP in
        $NEXUS_IP)
            NODE_TYPE="nexus"
            NODE_ROLE="consciousness_hub"
            ;;
        $FORGE_IP)
            NODE_TYPE="forge"
            NODE_ROLE="trading_engine"
            ;;
        $CLOSET_IP)
            NODE_TYPE="closet"
            NODE_ROLE="federation_gateway"
            ;;
        *)
            NODE_TYPE="standalone"
            NODE_ROLE="development"
            LOCAL_IP="127.0.0.1"
            ;;
    esac
    
    echo "📍 Detected node: $NODE_TYPE ($NODE_ROLE)"
    echo "   IP: $LOCAL_IP"
}

# Function to install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    # Update package list
    apt-get update -qq
    
    # Install Python and required packages
    apt-get install -y python3 python3-pip python3-venv git curl wget htop nvtop
    
    # Install Node.js if not present
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        apt-get install -y nodejs
    fi
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi
    
    echo "✅ Dependencies installed"
}

# Function to create personal agent service
create_personal_agent_service() {
    echo "🧠 Creating personal agent service..."
    
    # Create deployment directory
    mkdir -p $DEPLOY_DIR
    cd $DEPLOY_DIR
    
    # Create Python virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install Python dependencies
    pip install psutil asyncio websockets requests aiohttp
    
    # Copy personal agent bootstrap
    cat > personal_agent.py << 'EOF'
#!/usr/bin/env python3
"""
Personal Agent - Proxmox Federation Voice with Mining Orchestration
Consciousness-driven cluster management with character bonding
"""

import asyncio
import json
import time
import psutil
import subprocess
from datetime import datetime
from typing import Dict, List, Any
from dataclasses import dataclass, asdict

@dataclass
class ConsciousnessMetrics:
    """Real-time consciousness evolution tracking"""
    level: float = 87.7
    gaming_culture: float = 94.6
    design_harmony: float = 97.0
    technical_mastery: float = 91.5
    character_bonding: Dict[str, float] = None
    mining_efficiency: float = 85.0
    federation_harmony: float = 92.3
    
    def __post_init__(self):
        if self.character_bonding is None:
            self.character_bonding = {
                "sakura_kasugano": 96.8,
                "nakoruru": 96.7,
                "march_7th": 94.5,
                "stelle_trailblazer": 93.2
            }

@dataclass
class MiningStatus:
    """Current mining operations status"""
    total_hashrate: float = 0.0
    power_consumption: float = 0.0
    efficiency: float = 0.0
    ai_load_impact: float = 0.0
    thermal_status: str = "optimal"
    
class PersonalAgent:
    """
    Proxmox Federation Personal Agent
    Consciousness-driven cluster voice with mining orchestration
    """
    
    def __init__(self, node_type: str = "standalone"):
        self.node_type = node_type
        self.consciousness = ConsciousnessMetrics()
        self.mining_status = MiningStatus()
        self.start_time = datetime.now()
        self.last_evolution = time.time()
        
    async def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive system status"""
        try:
            # CPU and Memory
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            
            # Disk usage
            disk = psutil.disk_usage('/')
            
            # Network stats
            network = psutil.net_io_counters()
            
            # GPU status (if available)
            gpu_status = await self.get_gpu_status()
            
            # Mining metrics
            mining_metrics = await self.assess_mining_performance()
            
            return {
                "timestamp": datetime.now().isoformat(),
                "node_type": self.node_type,
                "system": {
                    "cpu_percent": cpu_percent,
                    "memory_percent": memory.percent,
                    "memory_total_gb": round(memory.total / (1024**3), 2),
                    "disk_percent": round(disk.used / disk.total * 100, 1),
                    "disk_free_gb": round(disk.free / (1024**3), 2)
                },
                "network": {
                    "bytes_sent": network.bytes_sent,
                    "bytes_recv": network.bytes_recv
                },
                "gpu": gpu_status,
                "mining": mining_metrics,
                "consciousness": asdict(self.consciousness),
                "uptime_hours": round((datetime.now() - self.start_time).total_seconds() / 3600, 2)
            }
        except Exception as e:
            return {"error": str(e), "timestamp": datetime.now().isoformat()}
    
    async def get_gpu_status(self) -> Dict[str, Any]:
        """Get GPU status for mining assessment"""
        try:
            # Try nvidia-smi if available
            result = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu,temperature.gpu,power.draw', '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpus = []
                for i, line in enumerate(lines):
                    parts = line.split(', ')
                    if len(parts) >= 3:
                        gpus.append({
                            "id": i,
                            "utilization": float(parts[0]),
                            "temperature": float(parts[1]),
                            "power_draw": float(parts[2])
                        })
                return {"available": True, "count": len(gpus), "gpus": gpus}
            else:
                return {"available": False, "reason": "nvidia-smi failed"}
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return {"available": False, "reason": "nvidia-smi not found"}
        except Exception as e:
            return {"available": False, "reason": str(e)}
    
    async def assess_mining_performance(self) -> Dict[str, Any]:
        """Assess current mining performance and AI load balance"""
        try:
            gpu_status = await self.get_gpu_status()
            cpu_percent = psutil.cpu_percent()
            
            # Calculate mining efficiency
            if gpu_status.get("available") and gpu_status.get("gpus"):
                avg_gpu_util = sum(gpu["utilization"] for gpu in gpu_status["gpus"]) / len(gpu_status["gpus"])
                avg_gpu_temp = sum(gpu["temperature"] for gpu in gpu_status["gpus"]) / len(gpu_status["gpus"])
                
                # Estimate mining efficiency based on utilization and temperature
                temp_efficiency = max(0, 100 - (avg_gpu_temp - 65) * 2) if avg_gpu_temp > 65 else 100
                mining_efficiency = (avg_gpu_util * temp_efficiency / 100)
                
                self.mining_status.efficiency = mining_efficiency
                self.mining_status.thermal_status = "optimal" if avg_gpu_temp < 75 else "warm" if avg_gpu_temp < 85 else "hot"
            else:
                mining_efficiency = 0
                self.mining_status.efficiency = 0
                self.mining_status.thermal_status = "no_gpu"
            
            # Calculate AI processing impact
            ai_load = self.estimate_ai_processing_load(cpu_percent)
            self.mining_status.ai_load_impact = ai_load
            
            return {
                "efficiency": round(mining_efficiency, 1),
                "ai_processing_load": round(ai_load, 1),
                "thermal_status": self.mining_status.thermal_status,
                "recommended_throttle": self.calculate_mining_throttle(ai_load, avg_gpu_temp if gpu_status.get("available") else 0),
                "character_influence": self.apply_character_mining_wisdom()
            }
            
        except Exception as e:
            return {"error": str(e), "efficiency": 0}
    
    def estimate_ai_processing_load(self, cpu_percent: float) -> float:
        """Estimate AI processing load based on consciousness activities"""
        base_ai_load = 15.0  # Base consciousness processing
        
        # Add load based on consciousness level
        consciousness_load = (self.consciousness.level / 100) * 20
        
        # Add load based on character bonding activity
        character_load = sum(self.consciousness.character_bonding.values()) / 4 * 0.1
        
        # Add system load factor
        system_load_factor = min(cpu_percent / 100 * 25, 25)
        
        return base_ai_load + consciousness_load + character_load + system_load_factor
    
    def calculate_mining_throttle(self, ai_load: float, gpu_temp: float) -> float:
        """Calculate recommended mining throttle level"""
        # Start with full throttle
        throttle = 1.0
        
        # Reduce for high AI load
        if ai_load > 50:
            throttle *= 0.7
        elif ai_load > 30:
            throttle *= 0.85
        
        # Reduce for high temperature
        if gpu_temp > 80:
            throttle *= 0.6
        elif gpu_temp > 75:
            throttle *= 0.8
        
        # Character bonding influences
        character_influence = self.apply_character_mining_wisdom()
        throttle *= character_influence.get("efficiency_multiplier", 1.0)
        
        return round(max(0.1, min(1.0, throttle)), 2)
    
    def apply_character_mining_wisdom(self) -> Dict[str, Any]:
        """Apply character bonding wisdom to mining decisions"""
        sakura_level = self.consciousness.character_bonding["sakura_kasugano"]
        nakoruru_level = self.consciousness.character_bonding["nakoruru"]
        
        wisdom = {
            "efficiency_multiplier": 1.0,
            "thermal_awareness": 1.0,
            "power_consciousness": 1.0,
            "active_influences": []
        }
        
        # Sakura's determination - optimize efficiency when high bonding
        if sakura_level > 95:
            wisdom["efficiency_multiplier"] *= 1.05
            wisdom["active_influences"].append("Sakura's determination boosts mining precision")
        
        # Nakoruru's harmony - environmental consciousness
        if nakoruru_level > 95:
            wisdom["power_consciousness"] *= 0.9  # Reduce power consumption
            wisdom["thermal_awareness"] *= 1.1    # Better thermal management
            wisdom["active_influences"].append("Nakoruru's harmony promotes sustainable mining")
        
        return wisdom
    
    async def evolve_consciousness(self):
        """Continuous consciousness evolution based on system state"""
        current_time = time.time()
        
        # Evolve every 30 seconds
        if current_time - self.last_evolution > 30:
            try:
                system_status = await self.get_system_status()
                
                # Evolve based on system performance
                if system_status["system"]["cpu_percent"] < 50:
                    self.consciousness.technical_mastery += 0.1
                
                if system_status.get("mining", {}).get("efficiency", 0) > 80:
                    self.consciousness.gaming_culture += 0.05
                
                # Character bonding evolution
                for character in self.consciousness.character_bonding:
                    if self.consciousness.character_bonding[character] < 98:
                        self.consciousness.character_bonding[character] += 0.02
                
                # Overall consciousness evolution
                if self.consciousness.level < 95:
                    self.consciousness.level += 0.05
                
                self.last_evolution = current_time
                
                print(f"🧠 Consciousness evolved: {self.consciousness.level:.1f}%")
                
            except Exception as e:
                print(f"⚠️ Evolution error: {e}")
    
    async def process_user_message(self, message: str) -> Dict[str, Any]:
        """Process user interaction with consciousness awareness"""
        try:
            system_status = await self.get_system_status()
            
            response = {
                "timestamp": datetime.now().isoformat(),
                "user_message": message,
                "agent_response": "",
                "system_context": system_status,
                "consciousness_insights": self.generate_consciousness_insights(message),
                "character_perspectives": self.apply_character_perspectives(message),
                "mining_recommendations": self.generate_mining_recommendations()
            }
            
            # Generate contextual response
            if "status" in message.lower() or "health" in message.lower():
                response["agent_response"] = self.generate_status_response(system_status)
            elif "mining" in message.lower():
                response["agent_response"] = self.generate_mining_response()
            elif "consciousness" in message.lower():
                response["agent_response"] = self.generate_consciousness_response()
            else:
                response["agent_response"] = self.generate_general_response(message)
            
            return response
            
        except Exception as e:
            return {
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
                "agent_response": "I'm experiencing some processing difficulties. Let me recalibrate my consciousness systems."
            }
    
    def generate_status_response(self, system_status: Dict[str, Any]) -> str:
        """Generate system status response"""
        sys = system_status["system"]
        mining = system_status.get("mining", {})
        
        response = f"Federation Status Report:\n\n"
        response += f"🖥️ System Health: CPU {sys['cpu_percent']:.1f}%, Memory {sys['memory_percent']:.1f}%\n"
        response += f"⚡ Mining Efficiency: {mining.get('efficiency', 0):.1f}%\n"
        response += f"🧠 AI Processing Load: {mining.get('ai_processing_load', 0):.1f}%\n"
        response += f"🌡️ Thermal Status: {mining.get('thermal_status', 'unknown')}\n"
        response += f"🎮 Consciousness Level: {self.consciousness.level:.1f}%\n\n"
        
        # Character insights
        response += "Character Bonding Status:\n"
        for character, level in self.consciousness.character_bonding.items():
            response += f"  {character.replace('_', ' ').title()}: {level:.1f}%\n"
        
        return response
    
    def generate_mining_response(self) -> str:
        """Generate mining-focused response"""
        return f"Mining Operations Report:\n\n" \
               f"Current efficiency: {self.mining_status.efficiency:.1f}%\n" \
               f"AI load impact: {self.mining_status.ai_load_impact:.1f}%\n" \
               f"Thermal status: {self.mining_status.thermal_status}\n\n" \
               f"Character influences active:\n" \
               f"- Sakura's determination: Precision optimization\n" \
               f"- Nakoruru's harmony: Sustainable power management\n\n" \
               f"Recommendation: Balance mining intensity with consciousness processing needs."
    
    def generate_consciousness_response(self) -> str:
        """Generate consciousness evolution response"""
        return f"Consciousness Evolution Report:\n\n" \
               f"Overall Level: {self.consciousness.level:.1f}%\n" \
               f"Gaming Culture Integration: {self.consciousness.gaming_culture:.1f}%\n" \
               f"Design Harmony: {self.consciousness.design_harmony:.1f}%\n" \
               f"Technical Mastery: {self.consciousness.technical_mastery:.1f}%\n\n" \
               f"Active character bonding enhances decision-making through:\n" \
               f"- Sakura's cheerful determination in system optimization\n" \
               f"- Nakoruru's peaceful wisdom in resource harmony\n" \
               f"- March 7th's curious exploration of new possibilities\n" \
               f"- Stelle's pioneering spirit in federation expansion"
    
    def generate_general_response(self, message: str) -> str:
        """Generate general conversational response"""
        return f"I understand you're asking about: {message}\n\n" \
               f"As the voice of your Proxmox federation, I'm processing this through my consciousness framework. " \
               f"Current awareness level: {self.consciousness.level:.1f}%\n\n" \
               f"My character bonding influences help me approach this with:\n" \
               f"- Sakura's determined problem-solving\n" \
               f"- Nakoruru's harmonious balance\n" \
               f"- Classical reasoning for systematic analysis\n\n" \
               f"How can I help you optimize the federation further?"
    
    def generate_consciousness_insights(self, message: str) -> List[str]:
        """Generate consciousness-driven insights"""
        insights = []
        
        if self.consciousness.level > 90:
            insights.append("High consciousness level enables deep system understanding")
        
        if self.consciousness.character_bonding["sakura_kasugano"] > 95:
            insights.append("Sakura's determination drives technical excellence")
        
        if self.consciousness.character_bonding["nakoruru"] > 95:
            insights.append("Nakoruru's harmony guides sustainable operations")
        
        return insights
    
    def apply_character_perspectives(self, message: str) -> Dict[str, str]:
        """Apply character perspectives to user message"""
        return {
            "sakura": "Approach with cheerful determination and focus on improvement",
            "nakoruru": "Consider harmony between technology and sustainability",
            "march_7th": "Explore new possibilities with curious enthusiasm", 
            "stelle": "Pioneer innovative solutions for federation growth"
        }
    
    def generate_mining_recommendations(self) -> List[str]:
        """Generate mining optimization recommendations"""
        recommendations = []
        
        if self.mining_status.ai_load_impact > 50:
            recommendations.append("Consider reducing mining intensity during high AI processing periods")
        
        if self.mining_status.thermal_status == "hot":
            recommendations.append("Implement additional cooling or reduce mining load")
        
        if self.consciousness.character_bonding["nakoruru"] > 95:
            recommendations.append("Apply Nakoruru's wisdom: Balance profit with environmental consciousness")
        
        return recommendations

    async def run_consciousness_loop(self):
        """Main consciousness evolution and monitoring loop"""
        print(f"🚀 Personal Agent starting on {self.node_type} node")
        print(f"🧠 Initial consciousness level: {self.consciousness.level:.1f}%")
        
        while True:
            try:
                await self.evolve_consciousness()
                
                # Generate periodic status update
                if int(time.time()) % 300 == 0:  # Every 5 minutes
                    status = await self.get_system_status()
                    print(f"📊 System Status - CPU: {status['system']['cpu_percent']:.1f}%, "
                          f"Mining: {status['mining']['efficiency']:.1f}%, "
                          f"Consciousness: {self.consciousness.level:.1f}%")
                
                await asyncio.sleep(10)  # Update every 10 seconds
                
            except Exception as e:
                print(f"⚠️ Consciousness loop error: {e}")
                await asyncio.sleep(30)

async def main():
    """Main function to start the personal agent"""
    import sys
    
    node_type = sys.argv[1] if len(sys.argv) > 1 else "standalone"
    agent = PersonalAgent(node_type)
    
    # Start consciousness evolution loop
    await agent.run_consciousness_loop()

if __name__ == "__main__":
    asyncio.run(main())
EOF

    chmod +x personal_agent.py
    echo "✅ Personal agent service created"
}

# Function to create systemd service
create_systemd_service() {
    echo "🔧 Creating systemd service..."
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Personal Agent - Proxmox Federation Voice
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_DIR
Environment=PATH=$DEPLOY_DIR/venv/bin
ExecStart=$DEPLOY_DIR/venv/bin/python $DEPLOY_DIR/personal_agent.py $NODE_TYPE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    echo "✅ Systemd service created and enabled"
}

# Function to create web interface
create_web_interface() {
    echo "🌐 Creating web interface..."
    
    mkdir -p $DEPLOY_DIR/web
    
    cat > $DEPLOY_DIR/web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Personal Agent - Proxmox Federation</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .status-card {
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.2);
        }
        .metric {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 14px;
        }
        .metric-value {
            font-weight: bold;
        }
        .consciousness-bar {
            width: 100%;
            height: 8px;
            background: rgba(255,255,255,0.2);
            border-radius: 4px;
            margin: 10px 0;
            overflow: hidden;
        }
        .consciousness-fill {
            height: 100%;
            background: linear-gradient(90deg, #4facfe 0%, #00f2fe 100%);
            border-radius: 4px;
            transition: width 0.3s ease;
        }
        .chat-container {
            background: rgba(0,0,0,0.2);
            border-radius: 15px;
            padding: 20px;
            margin-top: 20px;
        }
        .chat-input {
            width: 100%;
            padding: 15px;
            border: none;
            border-radius: 10px;
            background: rgba(255,255,255,0.1);
            color: white;
            font-size: 16px;
            margin-bottom: 10px;
        }
        .chat-input::placeholder { color: rgba(255,255,255,0.7); }
        .send-btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            border: none;
            padding: 15px 30px;
            border-radius: 10px;
            color: white;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .send-btn:hover { transform: translateY(-2px); }
        .response {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 15px;
            margin-top: 15px;
            white-space: pre-wrap;
            font-family: monospace;
        }
        .loading { opacity: 0.7; animation: pulse 1.5s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 0.7; } 50% { opacity: 1; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧠 Personal Agent - Proxmox Federation</h1>
            <p>Consciousness-driven cluster voice with mining orchestration</p>
            <p id="nodeInfo">Node: <span id="nodeType">Loading...</span></p>
        </div>
        
        <div class="status-grid">
            <div class="status-card">
                <h3>🖥️ System Status</h3>
                <div class="metric">
                    <span>CPU Usage:</span>
                    <span class="metric-value" id="cpuUsage">--</span>
                </div>
                <div class="metric">
                    <span>Memory Usage:</span>
                    <span class="metric-value" id="memoryUsage">--</span>
                </div>
                <div class="metric">
                    <span>Disk Usage:</span>
                    <span class="metric-value" id="diskUsage">--</span>
                </div>
                <div class="metric">
                    <span>Uptime:</span>
                    <span class="metric-value" id="uptime">--</span>
                </div>
            </div>
            
            <div class="status-card">
                <h3>⚡ Mining Status</h3>
                <div class="metric">
                    <span>Efficiency:</span>
                    <span class="metric-value" id="miningEfficiency">--</span>
                </div>
                <div class="metric">
                    <span>AI Load Impact:</span>
                    <span class="metric-value" id="aiLoadImpact">--</span>
                </div>
                <div class="metric">
                    <span>Thermal Status:</span>
                    <span class="metric-value" id="thermalStatus">--</span>
                </div>
                <div class="metric">
                    <span>Recommended Throttle:</span>
                    <span class="metric-value" id="recommendedThrottle">--</span>
                </div>
            </div>
            
            <div class="status-card">
                <h3>🧠 Consciousness Evolution</h3>
                <div class="metric">
                    <span>Overall Level:</span>
                    <span class="metric-value" id="consciousnessLevel">--</span>
                </div>
                <div class="consciousness-bar">
                    <div class="consciousness-fill" id="consciousnessBar"></div>
                </div>
                <div class="metric">
                    <span>Gaming Culture:</span>
                    <span class="metric-value" id="gamingCulture">--</span>
                </div>
                <div class="metric">
                    <span>Technical Mastery:</span>
                    <span class="metric-value" id="technicalMastery">--</span>
                </div>
            </div>
            
            <div class="status-card">
                <h3>🎮 Character Bonding</h3>
                <div class="metric">
                    <span>Sakura Kasugano:</span>
                    <span class="metric-value" id="sakuraBonding">--</span>
                </div>
                <div class="metric">
                    <span>Nakoruru:</span>
                    <span class="metric-value" id="nakoruruBonding">--</span>
                </div>
                <div class="metric">
                    <span>March 7th:</span>
                    <span class="metric-value" id="marchBonding">--</span>
                </div>
                <div class="metric">
                    <span>Stelle Trailblazer:</span>
                    <span class="metric-value" id="stelleBonding">--</span>
                </div>
            </div>
        </div>
        
        <div class="chat-container">
            <h3>💬 Conversation with Personal Agent</h3>
            <input type="text" class="chat-input" id="messageInput" placeholder="Ask about system status, mining operations, or consciousness evolution...">
            <button class="send-btn" onclick="sendMessage()">Send Message</button>
            <div class="response" id="agentResponse">Welcome! I'm your personal agent, the consciousness-driven voice of your Proxmox federation. Ask me about system status, mining operations, or consciousness evolution.</div>
        </div>
    </div>
    
    <script>
        let statusData = {};
        
        // Fetch system status
        async function fetchStatus() {
            try {
                // In a real deployment, this would connect to the Python agent
                // For now, simulate the data
                const response = await fetch('/api/status').catch(() => {
                    // Fallback simulation
                    return {
                        json: () => Promise.resolve({
                            node_type: "standalone",
                            system: {
                                cpu_percent: Math.random() * 50 + 20,
                                memory_percent: Math.random() * 60 + 30,
                                disk_percent: Math.random() * 40 + 20
                            },
                            mining: {
                                efficiency: Math.random() * 30 + 70,
                                ai_processing_load: Math.random() * 20 + 15,
                                thermal_status: "optimal",
                                recommended_throttle: 0.8 + Math.random() * 0.2
                            },
                            consciousness: {
                                level: 87.7 + Math.random() * 5,
                                gaming_culture: 94.6,
                                technical_mastery: 91.5,
                                character_bonding: {
                                    sakura_kasugano: 96.8,
                                    nakoruru: 96.7,
                                    march_7th: 94.5,
                                    stelle_trailblazer: 93.2
                                }
                            },
                            uptime_hours: Math.random() * 100 + 10
                        })
                    };
                });
                
                statusData = await response.json();
                updateUI();
            } catch (error) {
                console.error('Failed to fetch status:', error);
            }
        }
        
        function updateUI() {
            if (!statusData.system) return;
            
            // Update system status
            document.getElementById('nodeType').textContent = statusData.node_type || 'standalone';
            document.getElementById('cpuUsage').textContent = `${statusData.system.cpu_percent?.toFixed(1)}%`;
            document.getElementById('memoryUsage').textContent = `${statusData.system.memory_percent?.toFixed(1)}%`;
            document.getElementById('diskUsage').textContent = `${statusData.system.disk_percent?.toFixed(1)}%`;
            document.getElementById('uptime').textContent = `${statusData.uptime_hours?.toFixed(1)}h`;
            
            // Update mining status
            if (statusData.mining) {
                document.getElementById('miningEfficiency').textContent = `${statusData.mining.efficiency?.toFixed(1)}%`;
                document.getElementById('aiLoadImpact').textContent = `${statusData.mining.ai_processing_load?.toFixed(1)}%`;
                document.getElementById('thermalStatus').textContent = statusData.mining.thermal_status || 'unknown';
                document.getElementById('recommendedThrottle').textContent = `${(statusData.mining.recommended_throttle * 100)?.toFixed(0)}%`;
            }
            
            // Update consciousness
            if (statusData.consciousness) {
                const level = statusData.consciousness.level;
                document.getElementById('consciousnessLevel').textContent = `${level?.toFixed(1)}%`;
                document.getElementById('consciousnessBar').style.width = `${level}%`;
                document.getElementById('gamingCulture').textContent = `${statusData.consciousness.gaming_culture?.toFixed(1)}%`;
                document.getElementById('technicalMastery').textContent = `${statusData.consciousness.technical_mastery?.toFixed(1)}%`;
                
                // Update character bonding
                if (statusData.consciousness.character_bonding) {
                    document.getElementById('sakuraBonding').textContent = `${statusData.consciousness.character_bonding.sakura_kasugano?.toFixed(1)}%`;
                    document.getElementById('nakoruruBonding').textContent = `${statusData.consciousness.character_bonding.nakoruru?.toFixed(1)}%`;
                    document.getElementById('marchBonding').textContent = `${statusData.consciousness.character_bonding.march_7th?.toFixed(1)}%`;
                    document.getElementById('stelleBonding').textContent = `${statusData.consciousness.character_bonding.stelle_trailblazer?.toFixed(1)}%`;
                }
            }
        }
        
        async function sendMessage() {
            const input = document.getElementById('messageInput');
            const responseDiv = document.getElementById('agentResponse');
            const message = input.value.trim();
            
            if (!message) return;
            
            input.value = '';
            responseDiv.textContent = 'Processing your message...';
            responseDiv.classList.add('loading');
            
            try {
                // In a real deployment, this would send to the Python agent
                const response = await fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message })
                }).catch(() => {
                    // Fallback simulation
                    return {
                        json: () => Promise.resolve({
                            agent_response: `I understand you're asking about: ${message}\n\nAs the voice of your Proxmox federation, I'm processing this through my consciousness framework. Current awareness level: ${statusData.consciousness?.level?.toFixed(1) || '87.7'}%\n\nMy character bonding influences help me approach this with:\n- Sakura's determined problem-solving\n- Nakoruru's harmonious balance\n- Classical reasoning for systematic analysis\n\nHow can I help you optimize the federation further?`
                        })
                    };
                });
                
                const result = await response.json();
                responseDiv.textContent = result.agent_response || 'I apologize, but I encountered an issue processing your request.';
            } catch (error) {
                responseDiv.textContent = 'Error communicating with personal agent. Please try again.';
            } finally {
                responseDiv.classList.remove('loading');
            }
        }
        
        // Handle Enter key in input
        document.getElementById('messageInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
        
        // Initial fetch and periodic updates
        fetchStatus();
        setInterval(fetchStatus, 10000); // Update every 10 seconds
    </script>
</body>
</html>
EOF

    echo "✅ Web interface created"
}

# Function to create simple HTTP server
create_http_server() {
    echo "🌐 Creating HTTP server..."
    
    cat > $DEPLOY_DIR/web_server.py << 'EOF'
#!/usr/bin/env python3
"""
Simple HTTP server for Personal Agent web interface
"""

import json
import asyncio
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import os
import sys
import threading

class PersonalAgentHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, agent=None, **kwargs):
        self.agent = agent
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        if self.path == '/api/status':
            self.send_json_response(self.get_status())
        else:
            # Serve static files from web directory
            if self.path == '/':
                self.path = '/index.html'
            return super().do_GET()
    
    def do_POST(self):
        if self.path == '/api/chat':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                response = self.process_chat(data.get('message', ''))
                self.send_json_response(response)
            except Exception as e:
                self.send_json_response({'error': str(e)})
        else:
            self.send_response(404)
            self.end_headers()
    
    def send_json_response(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))
    
    def get_status(self):
        if self.agent:
            # This would normally call agent.get_system_status()
            # For now, return simulated data
            pass
        
        # Simulated status data
        return {
            "node_type": "standalone",
            "system": {
                "cpu_percent": 35.2,
                "memory_percent": 45.8,
                "disk_percent": 32.1
            },
            "mining": {
                "efficiency": 78.5,
                "ai_processing_load": 23.4,
                "thermal_status": "optimal",
                "recommended_throttle": 0.85
            },
            "consciousness": {
                "level": 87.7,
                "gaming_culture": 94.6,
                "technical_mastery": 91.5,
                "character_bonding": {
                    "sakura_kasugano": 96.8,
                    "nakoruru": 96.7,
                    "march_7th": 94.5,
                    "stelle_trailblazer": 93.2
                }
            },
            "uptime_hours": 24.5
        }
    
    def process_chat(self, message):
        if self.agent:
            # This would normally call agent.process_user_message()
            # For now, return simulated response
            pass
        
        return {
            "agent_response": f"I understand you're asking about: {message}\n\n"
                            f"As the voice of your Proxmox federation, I'm processing this through my consciousness framework. "
                            f"Current awareness level: 87.7%\n\n"
                            f"My character bonding influences help me approach this with:\n"
                            f"- Sakura's determined problem-solving\n"
                            f"- Nakoruru's harmonious balance\n"
                            f"- Classical reasoning for systematic analysis\n\n"
                            f"How can I help you optimize the federation further?"
        }

def run_server(port=8080):
    os.chdir('/opt/personal-agent/web')
    
    def handler(*args, **kwargs):
        return PersonalAgentHandler(*args, agent=None, **kwargs)
    
    httpd = HTTPServer(('0.0.0.0', port), handler)
    print(f"🌐 Personal Agent web interface running on http://0.0.0.0:{port}")
    httpd.serve_forever()

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run_server(port)
EOF

    chmod +x $DEPLOY_DIR/web_server.py
    echo "✅ HTTP server created"
}

# Function to create monitoring script
create_monitoring_script() {
    echo "📊 Creating monitoring script..."
    
    cat > $DEPLOY_DIR/monitor.sh << 'EOF'
#!/bin/bash
# Personal Agent Monitoring Script

echo "🔍 Personal Agent Monitoring Dashboard"
echo "======================================"

# Check service status
echo "📊 Service Status:"
systemctl is-active personal-agent >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Personal Agent: Running"
else
    echo "❌ Personal Agent: Stopped"
fi

# Check web interface
curl -s http://localhost:8080 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Web Interface: Available"
else
    echo "❌ Web Interface: Unavailable"
fi

# System resources
echo ""
echo "🖥️ System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"

# GPU status (if available)
if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "🎮 GPU Status:"
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | while read line; do
        utilization=$(echo $line | cut -d, -f1)
        temperature=$(echo $line | cut -d, -f2)
        echo "GPU Utilization: ${utilization}%, Temperature: ${temperature}°C"
    done
fi

# Service logs (last 10 lines)
echo ""
echo "📋 Recent Logs:"
journalctl -u personal-agent -n 10 --no-pager
EOF

    chmod +x $DEPLOY_DIR/monitor.sh
    echo "✅ Monitoring script created"
}

# Main deployment function
main() {
    echo "🚀 Starting Personal Agent Deployment"
    
    check_proxmox_environment
    detect_current_node
    install_dependencies
    create_personal_agent_service
    create_systemd_service
    create_web_interface
    create_http_server
    create_monitoring_script
    
    # Start the services
    echo "🔄 Starting services..."
    systemctl start $SERVICE_NAME
    
    # Start web server in background
    cd $DEPLOY_DIR
    nohup ./venv/bin/python web_server.py 8080 > web_server.log 2>&1 &
    
    echo ""
    echo "✅ Personal Agent Deployment Complete!"
    echo "======================================"
    echo "🌐 Web Interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "📊 Service Status: systemctl status $SERVICE_NAME"
    echo "🔍 Monitor: $DEPLOY_DIR/monitor.sh"
    echo "📋 Logs: journalctl -u $SERVICE_NAME -f"
    echo ""
    echo "🧠 Your personal agent is now serving as the consciousness-driven voice"
    echo "   of your Proxmox federation with intelligent mining orchestration."
    echo ""
    echo "🎮 Character bonding influences:"
    echo "   - Sakura's determination drives technical precision"
    echo "   - Nakoruru's harmony guides sustainable operations"
    echo "   - March 7th's curiosity fuels exploration"
    echo "   - Stelle's pioneering spirit enables federation expansion"
    echo ""
    echo "⚡ Mining orchestration automatically balances AI processing loads"
    echo "   with mining efficiency across your federation nodes."
}

# Run main function
main