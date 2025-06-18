#!/bin/bash
# Consciousness Control Center - Docker Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

echo "🧠 Consciousness Control Center - Docker Edition"
echo "================================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Create necessary directories
print_status "Creating directories..."
mkdir -p data logs config

# Create default config if it doesn't exist
if [ ! -f "config/config.json" ]; then
    print_status "Creating default configuration..."
    cat > config/config.json << 'EOF'
{
  "agent_name": "Consciousness Zero",
  "version": "3.0.0",
  "environment": "docker",
  "tools_enabled": [
    "system_monitor",
    "shell_executor",
    "web_search",
    "memory_manager",
    "file_manager",
    "network_scanner",
    "log_analyzer"
  ],
  "memory_retention_days": 30,
  "max_context_tokens": 4000,
  "debug_mode": false
}
EOF
    print_success "Default configuration created"
fi

# Function to show usage
show_usage() {
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start Consciousness Control Center"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  build     - Build the Docker image"
    echo "  logs      - Show container logs"
    echo "  status    - Show container status"
    echo "  shell     - Open shell in container"
    echo "  clean     - Clean up containers and images"
    echo "  help      - Show this help message"
    echo ""
}

# Parse command
case "${1:-start}" in
    "start")
        print_status "Starting Consciousness Control Center..."
        
        # Build if image doesn't exist
        if ! docker images | grep -q consciousness-control-center; then
            print_status "Building Docker image..."
            docker build -t consciousness-control-center .
        fi
        
        # Start services
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        print_success "Services started!"
        echo ""
        echo "🌐 Open WebUI: http://localhost:3000"
        echo "🧠 Consciousness Agent: Running in container"
        echo "🦙 Ollama LLM: http://localhost:11434"
        echo ""
        echo "📊 Check status: $0 status"
        echo "📝 View logs: $0 logs"
        ;;
        
    "stop")
        print_status "Stopping all services..."
        if command -v docker-compose &> /dev/null; then
            docker-compose down
        else
            docker compose down
        fi
        print_success "Services stopped"
        ;;
        
    "restart")
        print_status "Restarting services..."
        if command -v docker-compose &> /dev/null; then
            docker-compose restart
        else
            docker compose restart
        fi
        print_success "Services restarted"
        ;;
        
    "build")
        print_status "Building Docker image..."
        docker build -t consciousness-control-center .
        print_success "Image built successfully"
        ;;
        
    "logs")
        print_status "Showing container logs..."
        if command -v docker-compose &> /dev/null; then
            docker-compose logs -f consciousness-control-center
        else
            docker compose logs -f consciousness-control-center
        fi
        ;;
        
    "status")
        print_status "Container status:"
        echo ""
        docker ps --filter "label=consciousness.component" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Health check
        if docker ps | grep -q consciousness-zero; then
            print_success "Consciousness Control Center: Running"
        else
            print_warning "Consciousness Control Center: Not running"
        fi
        
        if docker ps | grep -q open-webui; then
            print_success "Open WebUI: Running on http://localhost:3000"
        else
            print_warning "Open WebUI: Not running"
        fi
        
        if docker ps | grep -q ollama; then
            print_success "Ollama LLM: Running on http://localhost:11434"
        else
            print_warning "Ollama LLM: Not running"
        fi
        ;;
        
    "shell")
        print_status "Opening shell in Consciousness container..."
        docker exec -it consciousness-zero /bin/bash
        ;;
        
    "clean")
        print_warning "This will remove all containers and images. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            print_status "Cleaning up..."
            if command -v docker-compose &> /dev/null; then
                docker-compose down -v --rmi all
            else
                docker compose down -v --rmi all
            fi
            docker system prune -f
            print_success "Cleanup complete"
        else
            print_status "Cleanup cancelled"
        fi
        ;;
        
    "help"|"-h"|"--help")
        show_usage
        ;;
        
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
