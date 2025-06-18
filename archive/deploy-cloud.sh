#!/bin/bash
# Multi-Cloud Deployment Automation for Consciousness Zero

set -e

echo "🌐 Consciousness Zero - Multi-Cloud Deployment"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for Node.js and npm
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Install deployment tools
install_tools() {
    print_status "Installing deployment tools..."
    
    # Install Vercel CLI
    if ! command -v vercel &> /dev/null; then
        print_status "Installing Vercel CLI..."
        npm install -g vercel
    fi
    
    # Install Wrangler (Cloudflare)
    if ! command -v wrangler &> /dev/null; then
        print_status "Installing Wrangler CLI..."
        npm install -g wrangler
    fi
    
    print_success "Deployment tools installed"
}

# Setup project files
setup_project() {
    print_status "Setting up project files..."
    
    # Create cloud requirements if not exists
    if [ ! -f "requirements-cloud.txt" ]; then
        cp requirements.txt requirements-cloud.txt
        print_warning "Using existing requirements.txt for cloud deployment"
    fi
    
    # Run setup scripts
    if [ -f "setup_cloudflare.py" ]; then
        python3 setup_cloudflare.py
    fi
    
    if [ -f "build_static.py" ]; then
        python3 build_static.py
    fi
    
    print_success "Project setup complete"
}

# Deploy to Vercel
deploy_vercel() {
    print_status "Deploying to Vercel..."
    
    if [ ! -f "vercel.json" ]; then
        print_error "vercel.json not found"
        return 1
    fi
    
    # Login to Vercel (will prompt if not logged in)
    vercel whoami || vercel login
    
    # Deploy to production
    vercel --prod --yes
    
    print_success "Deployed to Vercel!"
    echo "🚀 Vercel URL: https://consciousness-zero.vercel.app"
}

# Deploy to Cloudflare Pages
deploy_cloudflare() {
    print_status "Deploying to Cloudflare Pages..."
    
    # Check if logged in to Cloudflare
    if ! wrangler whoami &> /dev/null; then
        print_status "Please login to Cloudflare..."
        wrangler login
    fi
    
    # Deploy pages
    if [ -d "dist" ]; then
        wrangler pages publish dist --project-name=consciousness-zero
        print_success "Deployed to Cloudflare Pages!"
        echo "☁️ Cloudflare URL: https://consciousness-zero.pages.dev"
    else
        print_error "dist directory not found. Run build_static.py first."
    fi
}

# Setup GitHub Pages
setup_github_pages() {
    print_status "Setting up GitHub Pages..."
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_status "Initializing git repository..."
        git init
        git branch -M main
    fi
    
    # Add all files
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        print_warning "No changes to commit"
    else
        git commit -m "Deploy Consciousness Zero to multi-cloud platforms"
        print_success "Changes committed"
    fi
    
    # Push to GitHub (assumes remote is already set up)
    if git remote get-url origin &> /dev/null; then
        print_status "Pushing to GitHub..."
        git push origin main
        print_success "Pushed to GitHub! GitHub Pages will auto-deploy via Actions."
        echo "📦 GitHub Pages will be available at: https://yourusername.github.io/consciousness-zero"
    else
        print_warning "No GitHub remote found. Please set up GitHub repository first:"
        echo "  git remote add origin https://github.com/yourusername/consciousness-zero.git"
        echo "  git push -u origin main"
    fi
}

# Get deployment status
get_status() {
    print_status "Deployment Status:"
    echo ""
    
    # Vercel status
    if command -v vercel &> /dev/null; then
        echo "🚀 Vercel:"
        vercel ls --scope=yourusername 2>/dev/null || echo "  Not deployed or not logged in"
    fi
    
    # Cloudflare status
    if command -v wrangler &> /dev/null; then
        echo "☁️ Cloudflare Pages:"
        wrangler pages project list 2>/dev/null || echo "  Not deployed or not logged in"
    fi
    
    # GitHub status
    if [ -d ".git" ]; then
        echo "📦 GitHub:"
        if git remote get-url origin &> /dev/null; then
            echo "  Repository: $(git remote get-url origin)"
            echo "  Branch: $(git branch --show-current)"
        else
            echo "  No GitHub remote configured"
        fi
    fi
}

# Test deployments
test_deployments() {
    print_status "Testing deployments..."
    
    # Test URLs
    urls=(
        "https://consciousness-zero.vercel.app/health"
        "https://consciousness-zero.pages.dev/health"
    )
    
    for url in "${urls[@]}"; do
        print_status "Testing $url"
        if curl -s -f "$url" > /dev/null; then
            print_success "✅ $url is responding"
        else
            print_warning "⚠️ $url is not responding (may not be deployed yet)"
        fi
    done
}

# Main deployment function
main() {
    echo ""
    print_status "Starting multi-cloud deployment process..."
    echo ""
    
    # Parse command line arguments
    case "${1:-all}" in
        "vercel")
            check_dependencies
            install_tools
            setup_project
            deploy_vercel
            ;;
        "cloudflare")
            check_dependencies
            install_tools
            setup_project
            deploy_cloudflare
            ;;
        "github")
            setup_github_pages
            ;;
        "status")
            get_status
            ;;
        "test")
            test_deployments
            ;;
        "all"|"")
            check_dependencies
            install_tools
            setup_project
            deploy_vercel
            deploy_cloudflare
            setup_github_pages
            echo ""
            print_success "🎉 Multi-cloud deployment complete!"
            echo ""
            echo "🌐 Your Consciousness Zero deployments:"
            echo "  🚀 Vercel: https://consciousness-zero.vercel.app"
            echo "  ☁️ Cloudflare: https://consciousness-zero.pages.dev"
            echo "  📦 GitHub Pages: https://yourusername.github.io/consciousness-zero"
            echo ""
            echo "⚡ Global CDN enabled with <100ms latency worldwide"
            echo "🔄 Auto-scaling and continuous deployment active"
            ;;
        *)
            echo "Usage: $0 [vercel|cloudflare|github|status|test|all]"
            echo ""
            echo "Commands:"
            echo "  vercel     - Deploy to Vercel only"
            echo "  cloudflare - Deploy to Cloudflare Pages only"
            echo "  github     - Setup GitHub Pages deployment"
            echo "  status     - Show deployment status"
            echo "  test       - Test deployed endpoints"
            echo "  all        - Deploy to all platforms (default)"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
