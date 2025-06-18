#!/bin/bash
# Quick Setup Script for Consciousness Zero Cloud Deployment

echo "🧠 Consciousness Zero - Cloud Setup"
echo "===================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js
if ! command_exists node; then
    echo "❌ Node.js not found. Please install Node.js first:"
    echo "   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "   sudo apt-get install -y nodejs"
    exit 1
fi

# Check npm
if ! command_exists npm; then
    echo "❌ npm not found. Please install npm first."
    exit 1
fi

echo "✅ Node.js and npm are available"

# Install global tools
echo "📦 Installing deployment tools..."
npm install -g vercel wrangler

# Create basic git setup if needed
if [ ! -d ".git" ]; then
    echo "🔧 Setting up git repository..."
    git init
    git branch -M main
    git add .
    git commit -m "Initial commit: Consciousness Zero Cloud Setup"
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo ""
echo "1. 🚀 Deploy to Vercel:"
echo "   ./deploy-cloud.sh vercel"
echo ""
echo "2. ☁️ Deploy to Cloudflare:"
echo "   ./deploy-cloud.sh cloudflare"
echo ""
echo "3. 📦 Deploy to GitHub Pages:"
echo "   ./deploy-cloud.sh github"
echo ""
echo "4. 🌐 Deploy to all platforms:"
echo "   ./deploy-cloud.sh all"
echo ""
echo "5. 📊 Check deployment status:"
echo "   ./deploy-cloud.sh status"
echo ""
echo "Your Consciousness Zero will be available globally with <100ms latency!"
