#!/bin/bash

# Consciousness Zero Command Center Validation Script
# Validates setup and dependencies for the AI command center

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/consciousness-ai-env"

echo "🧠 Consciousness Zero Validation"
echo "=================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check virtual environment
print_status "Checking virtual environment..."
if [ -d "$VENV_DIR" ]; then
    print_success "Virtual environment found at $VENV_DIR"
else
    print_error "Virtual environment not found. Please run local-validation.sh first"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Test Python dependencies
print_status "Validating Python dependencies..."

test_import() {
    local module=$1
    local description=$2
    
    if python -c "import $module" 2>/dev/null; then
        print_success "$description is available"
        return 0
    else
        print_error "$description is NOT available"
        return 1
    fi
}

# Core dependencies
test_import "gradio" "Gradio web interface framework"
test_import "fastapi" "FastAPI web framework"
test_import "uvicorn" "Uvicorn ASGI server"
test_import "sentence_transformers" "Sentence Transformers for embeddings"
test_import "torch" "PyTorch for AI models"
test_import "transformers" "Hugging Face Transformers"

# Optional dependencies
test_import "crawl4ai" "Crawl4AI for web intelligence" || print_warning "Crawl4AI not available - web search will use fallback"
test_import "proxmoxer" "Proxmoxer for Proxmox integration" || print_warning "Proxmoxer not available - Proxmox features disabled"

# Test imports of our application
print_status "Testing Consciousness Zero imports..."
if python -c "import consciousness_zero_command_center" 2>/dev/null; then
    print_success "Consciousness Zero Command Center imports successfully"
else
    print_error "Failed to import Consciousness Zero Command Center"
    exit 1
fi

# Test basic functionality
print_status "Testing basic agent functionality..."
python << 'EOF'
import asyncio
import sys
sys.path.append('.')

from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

async def test_agent():
    try:
        config = AgentConfig()
        agent = ConsciousnessAgent(config)
        
        # Test simple message processing
        result = await agent.process_message("Hello, are you working?")
        
        if result and "response" in result:
            print("✅ Agent responds to messages")
            print(f"   Response: {result['response'][:100]}...")
        else:
            print("❌ Agent failed to respond")
            return False
        
        # Test tool availability
        if len(agent.tools) > 0:
            print(f"✅ {len(agent.tools)} tools available: {list(agent.tools.keys())}")
        else:
            print("❌ No tools available")
            return False
        
        # Test memory system
        agent.memory.save_fragment("Test validation fragment")
        results = agent.memory.search_fragments("validation")
        if results:
            print("✅ Memory system working")
        else:
            print("❌ Memory system failed")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Agent test failed: {e}")
        return False

# Run test
success = asyncio.run(test_agent())
exit(0 if success else 1)
EOF

if [ $? -eq 0 ]; then
    print_success "Agent functionality test passed"
else
    print_error "Agent functionality test failed"
    exit 1
fi

# Check system resources
print_status "Checking system resources..."

# Memory check
total_mem=$(free -m | awk 'NR==2{print $2}')
available_mem=$(free -m | awk 'NR==2{print $7}')

if [ "$total_mem" -gt 4000 ]; then
    print_success "Sufficient RAM: ${total_mem}MB total"
else
    print_warning "Low RAM: ${total_mem}MB total (recommended: 4GB+)"
fi

# CPU check
cpu_cores=$(nproc)
if [ "$cpu_cores" -ge 2 ]; then
    print_success "Sufficient CPU cores: $cpu_cores"
else
    print_warning "Limited CPU cores: $cpu_cores (recommended: 2+)"
fi

# Disk space check
disk_free=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$disk_free" -gt 5 ]; then
    print_success "Sufficient disk space: ${disk_free}GB free"
else
    print_warning "Low disk space: ${disk_free}GB free (recommended: 5GB+)"
fi

# Check for GPU (optional)
if command -v nvidia-smi &> /dev/null; then
    gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$gpu_info" ]; then
        print_success "GPU detected: $gpu_info"
    fi
else
    print_warning "No GPU detected (optional for acceleration)"
fi

# Check network connectivity
print_status "Testing network connectivity..."
if curl -s --max-time 5 https://api.intelligence.io.solutions/health &>/dev/null; then
    print_success "IO Intelligence API is reachable"
else
    print_warning "IO Intelligence API not reachable (check network/firewall)"
fi

if curl -s --max-time 5 https://huggingface.co &>/dev/null; then
    print_success "Hugging Face is reachable"
else
    print_warning "Hugging Face not reachable (check network/firewall)"
fi

# Check configuration files
print_status "Checking configuration..."
if [ -f "$SCRIPT_DIR/.env.example" ]; then
    print_success ".env.example template found"
else
    print_warning ".env.example template missing"
fi

if [ -f "$SCRIPT_DIR/.env" ]; then
    print_success ".env configuration found"
    
    # Check for API keys
    if grep -q "IO_API_KEY=your_" "$SCRIPT_DIR/.env" 2>/dev/null; then
        print_warning "IO_API_KEY not configured in .env"
    else
        print_success "IO_API_KEY appears to be configured"
    fi
    
    if grep -q "HF_TOKEN=your_" "$SCRIPT_DIR/.env" 2>/dev/null; then
        print_warning "HF_TOKEN not configured in .env"
    else
        print_success "HF_TOKEN appears to be configured"
    fi
else
    print_warning ".env configuration not found. Copy .env.example to .env and configure"
fi

# Create required directories
print_status "Creating required directories..."
mkdir -p memory knowledge logs
print_success "Required directories created"

# Check if startup script is executable
if [ -x "$SCRIPT_DIR/start_consciousness_zero.sh" ]; then
    print_success "Startup script is executable"
else
    print_warning "Making startup script executable..."
    chmod +x "$SCRIPT_DIR/start_consciousness_zero.sh"
fi

# Final summary
echo ""
echo "🎯 VALIDATION SUMMARY"
echo "===================="

print_success "✅ Virtual environment: Ready"
print_success "✅ Python dependencies: Installed" 
print_success "✅ Consciousness Zero: Functional"
print_success "✅ Agent tools: Working"
print_success "✅ Memory system: Operational"

echo ""
print_status "🚀 READY TO LAUNCH!"
echo ""
echo "To start the Consciousness Zero Command Center:"
echo "  ./start_consciousness_zero.sh"
echo ""
echo "Then open your browser to:"
echo "  http://localhost:7860"
echo ""
echo "For API documentation:"
echo "  http://localhost:7860/docs"
echo ""

exit 0
