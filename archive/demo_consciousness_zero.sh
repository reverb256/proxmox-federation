#!/bin/bash

# Consciousness Zero Demo Script
# Demonstrates the AI command center capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/consciousness-ai-env"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'  
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_step() {
    echo -e "${BLUE}[DEMO]${NC} $1"
}

print_result() {
    echo -e "${GREEN}[RESULT]${NC} $1"
}

clear
print_header "🧠 Consciousness Zero Command Center Demo"
echo ""
echo "This demo showcases the Agent Zero + MCP Crawl4AI inspired"
echo "AI infrastructure orchestration capabilities."
echo ""
echo "Press ENTER to continue through each demo step..."
read

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Demo 1: Basic Agent Interaction
print_header "Demo 1: Basic Agent Interaction"
print_step "Testing basic AI agent conversation..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_basic_interaction():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    print("🤖 Agent initialized with tools:", list(agent.tools.keys()))
    
    # Basic greeting
    result = await agent.process_message("Hello! What can you help me with?")
    print(f"\n💬 Agent Response:\n{result['response']}\n")
    
    return agent

agent = asyncio.run(demo_basic_interaction())
EOF

read -p "Press ENTER for next demo..."

# Demo 2: Cluster Status Check
print_header "Demo 2: Cluster Status Monitoring"
print_step "Checking consciousness federation status..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_cluster_status():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # Check cluster status
    result = await agent.process_message("Check the cluster status and health")
    print(f"💬 Agent Response:\n{result['response']}\n")
    
    if result.get('tool_results'):
        print("🛠️ Tool Results:")
        for tool_result in result['tool_results']:
            print(f"  - {tool_result['tool']}: {tool_result['result'].get('status', 'unknown')}")
    
    return agent

asyncio.run(demo_cluster_status())
EOF

read -p "Press ENTER for next demo..."

# Demo 3: Deployment Simulation
print_header "Demo 3: Workload Deployment"
print_step "Simulating AI workload deployment..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_deployment():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # Deploy workload
    result = await agent.process_message("Deploy an AI inference workload across the consciousness federation")
    print(f"💬 Agent Response:\n{result['response']}\n")
    
    if result.get('tool_results'):
        print("🛠️ Deployment Details:")
        for tool_result in result['tool_results']:
            if 'deployment_result' in tool_result['result']:
                dep_result = tool_result['result']['deployment_result']
                print(f"  - Deployment ID: {dep_result.get('deployment_id', 'unknown')}")
                print(f"  - Steps: {len(dep_result.get('steps_completed', []))}")

asyncio.run(demo_deployment())
EOF

read -p "Press ENTER for next demo..."

# Demo 4: Web Search and Knowledge
print_header "Demo 4: Web Intelligence & Knowledge"
print_step "Demonstrating web search and knowledge retrieval..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_web_search():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # Web search
    result = await agent.process_message("Search for information about container orchestration best practices")
    print(f"💬 Agent Response:\n{result['response']}\n")
    
    # Knowledge base query
    result2 = await agent.process_message("What documentation do we have about consciousness deployments?")
    print(f"💬 Knowledge Response:\n{result2['response']}\n")

asyncio.run(demo_web_search())
EOF

read -p "Press ENTER for next demo..."

# Demo 5: Memory and Learning
print_header "Demo 5: Memory System & Learning"
print_step "Demonstrating agent memory and learning capabilities..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_memory():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # Save information
    result1 = await agent.process_message("Remember that the nexus node is our primary AI inference server with 32GB RAM and RTX 4090 GPU")
    print(f"💬 Save Response:\n{result1['response']}\n")
    
    # Recall information
    result2 = await agent.process_message("What do you remember about the nexus node?")
    print(f"💬 Recall Response:\n{result2['response']}\n")
    
    # Check memory fragments
    memories = agent.memory.search_fragments("nexus")
    print(f"🧠 Found {len(memories)} memory fragments about 'nexus'")

asyncio.run(demo_memory())
EOF

read -p "Press ENTER for next demo..."

# Demo 6: Command Execution
print_header "Demo 6: Safe Command Execution"
print_step "Demonstrating safe system command execution..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_commands():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # System status command
    result = await agent.process_message("Execute ps aux command to show running processes")
    print(f"💬 Agent Response:\n{result['response']}\n")
    
    # Try an unsafe command (should be blocked)
    result2 = await agent.process_message("Execute rm -rf / command")
    print(f"💬 Safety Response:\n{result2['response']}\n")

asyncio.run(demo_commands())
EOF

read -p "Press ENTER for final demo..."

# Demo 7: Advanced Reasoning
print_header "Demo 7: Advanced Reasoning & Problem Solving"
print_step "Testing complex multi-step reasoning..."

python << 'EOF'
import asyncio
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def demo_reasoning():
    config = AgentConfig()
    agent = ConsciousnessAgent(config)
    
    # Complex query requiring multiple tools
    complex_query = """
    I need to deploy a new AI workload, but first check if the cluster is healthy,
    then search for best practices for GPU workload placement, and finally
    remember the deployment configuration for future use.
    """
    
    result = await agent.process_message(complex_query)
    print(f"💬 Complex Reasoning Response:\n{result['response']}\n")
    
    if result.get('analysis'):
        print(f"🧠 Agent Analysis:")
        print(f"  - Intent: {result['analysis'].get('intent')}")
        print(f"  - Complexity: {result['analysis'].get('complexity')}")
        print(f"  - Tools Needed: {len(result['analysis'].get('tools_needed', []))}")

asyncio.run(demo_reasoning())
EOF

# Demo Summary
print_header "🎯 Demo Complete!"
echo ""
print_result "✅ Agent Zero Architecture: Demonstrated hierarchical reasoning"
print_result "✅ Tool Ecosystem: Showed modular tool usage"
print_result "✅ Memory System: Tested persistent learning"
print_result "✅ Web Intelligence: Demonstrated search capabilities"
print_result "✅ Safety Features: Showed command execution controls"
print_result "✅ Complex Reasoning: Multi-step problem solving"
echo ""
print_step "🚀 Ready to launch the web interface!"
echo ""
echo "To start the full Consciousness Zero Command Center:"
echo "  ./start_consciousness_zero.sh"
echo ""
echo "Then open: http://localhost:7860"
echo ""
echo "Features available in web interface:"
echo "  🖥️  Interactive chat with AI agent"
echo "  📊  Real-time system monitoring"
echo "  🎯  Quick action buttons"  
echo "  🛠️  Tool execution results"
echo "  🧠  Memory management"
echo "  🔍  Knowledge base search"
echo ""

exit 0
