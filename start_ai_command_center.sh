#!/bin/bash
# AI Command Center Startup Script
# Launches the consciousness orchestration hub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/consciousness-ai-env"
LOG_DIR="$SCRIPT_DIR/logs"

# Create logs directory
mkdir -p "$LOG_DIR"

echo -e "${BLUE}🧠 AI Command Center - Consciousness Orchestration Hub${NC}"
echo "=================================================="

# Function to check if virtual environment exists
check_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}❌ Virtual environment not found at $VENV_DIR${NC}"
        echo -e "${YELLOW}💡 Creating virtual environment...${NC}"
        python3 -m venv "$VENV_DIR"
    fi
}

# Function to activate virtual environment
activate_venv() {
    echo -e "${BLUE}🔄 Activating virtual environment...${NC}"
    source "$VENV_DIR/bin/activate"
    echo -e "${GREEN}✅ Virtual environment activated${NC}"
}

# Function to install/update requirements
install_requirements() {
    echo -e "${BLUE}📦 Installing/updating requirements...${NC}"
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install requirements
    if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
        pip install -r "$SCRIPT_DIR/requirements.txt"
        echo -e "${GREEN}✅ Requirements installed${NC}"
    else
        echo -e "${YELLOW}⚠️ requirements.txt not found, installing basic packages...${NC}"
        pip install gradio fastapi uvicorn openai transformers torch huggingface_hub iointel
    fi
}

# Function to check environment variables
check_env() {
    echo -e "${BLUE}🔍 Checking environment configuration...${NC}"
    
    # Load .env file if it exists
    if [ -f "$SCRIPT_DIR/.env" ]; then
        echo -e "${GREEN}✅ Loading .env file${NC}"
        export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
    else
        echo -e "${YELLOW}⚠️ .env file not found${NC}"
        echo -e "${YELLOW}💡 Copy .env.example to .env and configure your API keys${NC}"
    fi
    
    # Check for required API keys
    if [ -z "$IOINTELLIGENCE_API_KEY" ]; then
        echo -e "${YELLOW}⚠️ IOINTELLIGENCE_API_KEY not set${NC}"
    else
        echo -e "${GREEN}✅ IO Intelligence API key configured${NC}"
    fi
    
    if [ -z "$HUGGINGFACE_TOKEN" ]; then
        echo -e "${YELLOW}⚠️ HUGGINGFACE_TOKEN not set${NC}"
    else
        echo -e "${GREEN}✅ Hugging Face token configured${NC}"
    fi
}

# Function to check system requirements
check_system() {
    echo -e "${BLUE}🖥️ Checking system requirements...${NC}"
    
    # Check Python version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✅ Python version: $python_version${NC}"
    
    # Check CUDA availability
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✅ NVIDIA GPU detected${NC}"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1
    else
        echo -e "${YELLOW}⚠️ NVIDIA GPU not detected (CPU mode)${NC}"
    fi
    
    # Check available memory
    total_mem=$(free -h | awk '/^Mem:/ { print $2 }')
    echo -e "${GREEN}✅ Total memory: $total_mem${NC}"
    
    # Check disk space
    disk_space=$(df -h "$SCRIPT_DIR" | awk 'NR==2 { print $4 }')
    echo -e "${GREEN}✅ Available disk space: $disk_space${NC}"
}

# Function to start the Gradio interface
start_gradio() {
    echo -e "${BLUE}🚀 Starting Gradio interface...${NC}"
    cd "$SCRIPT_DIR"
    python ai_command_center.py > "$LOG_DIR/gradio.log" 2>&1 &
    GRADIO_PID=$!
    echo $GRADIO_PID > "$LOG_DIR/gradio.pid"
    echo -e "${GREEN}✅ Gradio interface started (PID: $GRADIO_PID)${NC}"
    echo -e "${GREEN}🌐 Access at: http://localhost:7860${NC}"
}

# Function to start the FastAPI backend
start_api() {
    echo -e "${BLUE}🚀 Starting FastAPI backend...${NC}"
    cd "$SCRIPT_DIR"
    python api_backend.py > "$LOG_DIR/api.log" 2>&1 &
    API_PID=$!
    echo $API_PID > "$LOG_DIR/api.pid"
    echo -e "${GREEN}✅ FastAPI backend started (PID: $API_PID)${NC}"
    echo -e "${GREEN}🔗 API docs at: http://localhost:8000/docs${NC}"
}

# Function to show running processes
show_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    
    if [ -f "$LOG_DIR/gradio.pid" ]; then
        gradio_pid=$(cat "$LOG_DIR/gradio.pid")
        if ps -p $gradio_pid > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Gradio interface running (PID: $gradio_pid)${NC}"
        else
            echo -e "${RED}❌ Gradio interface not running${NC}"
        fi
    else
        echo -e "${RED}❌ Gradio interface not started${NC}"
    fi
    
    if [ -f "$LOG_DIR/api.pid" ]; then
        api_pid=$(cat "$LOG_DIR/api.pid")
        if ps -p $api_pid > /dev/null 2>&1; then
            echo -e "${GREEN}✅ FastAPI backend running (PID: $api_pid)${NC}"
        else
            echo -e "${RED}❌ FastAPI backend not running${NC}"
        fi
    else
        echo -e "${RED}❌ FastAPI backend not started${NC}"
    fi
}

# Function to stop services
stop_services() {
    echo -e "${BLUE}🛑 Stopping services...${NC}"
    
    if [ -f "$LOG_DIR/gradio.pid" ]; then
        gradio_pid=$(cat "$LOG_DIR/gradio.pid")
        if ps -p $gradio_pid > /dev/null 2>&1; then
            kill $gradio_pid
            echo -e "${GREEN}✅ Gradio interface stopped${NC}"
        fi
        rm -f "$LOG_DIR/gradio.pid"
    fi
    
    if [ -f "$LOG_DIR/api.pid" ]; then
        api_pid=$(cat "$LOG_DIR/api.pid")
        if ps -p $api_pid > /dev/null 2>&1; then
            kill $api_pid
            echo -e "${GREEN}✅ FastAPI backend stopped${NC}"
        fi
        rm -f "$LOG_DIR/api.pid"
    fi
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}📋 Recent logs:${NC}"
    
    if [ -f "$LOG_DIR/gradio.log" ]; then
        echo -e "${YELLOW}--- Gradio Logs ---${NC}"
        tail -n 20 "$LOG_DIR/gradio.log"
    fi
    
    if [ -f "$LOG_DIR/api.log" ]; then
        echo -e "${YELLOW}--- API Logs ---${NC}"
        tail -n 20 "$LOG_DIR/api.log"
    fi
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_venv
            activate_venv
            install_requirements
            check_env
            check_system
            echo
            start_gradio
            sleep 2
            start_api
            echo
            echo -e "${GREEN}🎉 AI Command Center started successfully!${NC}"
            echo -e "${GREEN}🌐 Gradio Interface: http://localhost:7860${NC}"
            echo -e "${GREEN}🔗 API Documentation: http://localhost:8000/docs${NC}"
            echo
            echo -e "${BLUE}💡 Use '$0 status' to check service status${NC}"
            echo -e "${BLUE}💡 Use '$0 stop' to stop all services${NC}"
            echo -e "${BLUE}💡 Use '$0 logs' to view recent logs${NC}"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            main start
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "install")
            check_venv
            activate_venv
            install_requirements
            ;;
        "update")
            activate_venv
            install_requirements
            echo -e "${GREEN}✅ Requirements updated${NC}"
            ;;
        "help")
            echo "AI Command Center - Usage:"
            echo "  $0 [start]   - Start all services (default)"
            echo "  $0 stop      - Stop all services"
            echo "  $0 restart   - Restart all services"
            echo "  $0 status    - Show service status"
            echo "  $0 logs      - Show recent logs"
            echo "  $0 install   - Install/update requirements"
            echo "  $0 update    - Update requirements only"
            echo "  $0 help      - Show this help"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Trap to cleanup on exit
trap 'echo -e "\n${YELLOW}🔄 Cleaning up...${NC}"; stop_services; exit 0' INT TERM

# Run main function
main "$@"
