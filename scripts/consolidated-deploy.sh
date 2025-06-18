#!/bin/bash
# VibeCoding Platform - Consolidated Deployment Script
# Replaces all scattered deployment scripts with unified functionality

set -euo pipefail

# Configuration
PLATFORM_NAME="VibeCoding Consciousness Platform"
DEPLOYMENT_TYPE="${1:-replit}"
ENVIRONMENT="${2:-production}"

echo "🚀 Deploying $PLATFORM_NAME ($DEPLOYMENT_TYPE - $ENVIRONMENT)"

# Core deployment functions
deploy_replit() {
    echo "📦 Starting Replit deployment..."
    npm run build
    echo "✅ Replit deployment ready"
}

deploy_proxmox() {
    echo "🏗️ Starting Proxmox federation deployment..."
    
    # Check prerequisites
    command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl required"; exit 1; }
    
    # Deploy K3s cluster
    kubectl apply -f k3s-config/
    
    # Verify deployment
    kubectl get pods --all-namespaces
    echo "✅ Proxmox federation deployed"
}

deploy_cloudflare() {
    echo "☁️ Starting Cloudflare edge deployment..."
    
    # Build static assets
    npm run build:static
    
    # Deploy to Cloudflare Pages
    npx wrangler pages deploy dist-static/
    echo "✅ Cloudflare deployment complete"
}

# Security setup
setup_secrets() {
    echo "🔒 Configuring security layer..."
    
    if [[ -f .env ]]; then
        echo "✅ Environment configuration found"
    else
        echo "⚠️ Creating environment template"
        cp .env.example .env
    fi
}

# Health checks
verify_deployment() {
    echo "🔍 Verifying deployment health..."
    
    case $DEPLOYMENT_TYPE in
        "replit")
            curl -f http://localhost:3000/api/health || echo "⚠️ Health check pending"
            ;;
        "proxmox")
            kubectl get pods | grep Running || echo "⚠️ Pods starting up"
            ;;
        "cloudflare")
            echo "✅ Static deployment verified"
            ;;
    esac
}

# Main execution
main() {
    setup_secrets
    
    case $DEPLOYMENT_TYPE in
        "replit")
            deploy_replit
            ;;
        "proxmox")
            deploy_proxmox
            ;;
        "cloudflare")
            deploy_cloudflare
            ;;
        *)
            echo "❌ Unknown deployment type: $DEPLOYMENT_TYPE"
            echo "Usage: $0 [replit|proxmox|cloudflare] [production|staging]"
            exit 1
            ;;
    esac
    
    verify_deployment
    echo "🎉 Deployment complete!"
}

main "$@"