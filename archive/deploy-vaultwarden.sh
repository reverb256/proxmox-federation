#!/bin/bash

# Vaultwarden Deployment Script for Consciousness Zero
# Deploy Vaultwarden password manager alongside the AI command center

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔐 Deploying Vaultwarden for Consciousness Zero..."
echo "================================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please restart your session and run this script again."
    exit 0
fi

# Create Vaultwarden directory
VAULT_DIR="$SCRIPT_DIR/vaultwarden"
mkdir -p "$VAULT_DIR/data"

echo "📁 Created Vaultwarden directory: $VAULT_DIR"

# Create Vaultwarden configuration
cat > "$VAULT_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: consciousness-vaultwarden
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./data:/data
    environment:
      WEBSOCKET_ENABLED: "true"
      SIGNUPS_ALLOWED: "true"
      WEB_VAULT_ENABLED: "true"
      ADMIN_TOKEN: "consciousness-admin-token-2025"
      DOMAIN: "http://localhost:8080"
      ROCKET_PORT: "80"
    labels:
      - "consciousness.service=vaultwarden"
      - "consciousness.description=Password Manager for Infrastructure"
EOF

echo "✅ Created Vaultwarden Docker Compose configuration"

# Start Vaultwarden
echo "🚀 Starting Vaultwarden container..."
cd "$VAULT_DIR"
docker-compose up -d

# Wait for Vaultwarden to start
echo "⏳ Waiting for Vaultwarden to initialize..."
sleep 10

# Check if Vaultwarden is running
if curl -s http://localhost:8080/alive > /dev/null; then
    echo "✅ Vaultwarden is running successfully!"
    echo "🌐 Web Interface: http://localhost:8080"
    echo "🔑 Admin Panel: http://localhost:8080/admin"
    echo "🔐 Admin Token: consciousness-admin-token-2025"
else
    echo "❌ Vaultwarden failed to start. Checking logs..."
    docker-compose logs vaultwarden
    exit 1
fi

# Create initial vault entries for consciousness infrastructure
echo "📝 Creating initial infrastructure entries..."

# Create a setup script for initial passwords
cat > "$VAULT_DIR/setup-infrastructure-passwords.sh" << 'EOF'
#!/bin/bash

# Initial infrastructure passwords setup
# This would typically use Bitwarden CLI to create entries

echo "🔐 Infrastructure Password Setup"
echo "================================"
echo "Manual setup required in Vaultwarden web interface:"
echo ""
echo "1. Go to http://localhost:8080"
echo "2. Create an account"
echo "3. Create these folders:"
echo "   - Infrastructure"
echo "   - Proxmox"
echo "   - Crypto Wallets"
echo "   - APIs"
echo ""
echo "4. Add these entries:"
echo "   - Proxmox Root Password"
echo "   - IO Intelligence API Key"
echo "   - Hugging Face Token"
echo "   - Solana Wallet Seeds"
echo "   - Ethereum Wallet Keys"
echo ""
echo "5. Use the Consciousness Zero AI to manage these secrets"
EOF

chmod +x "$VAULT_DIR/setup-infrastructure-passwords.sh"

# Update the main .env file with Vaultwarden configuration
cd "$SCRIPT_DIR"
if [ ! -f .env ]; then
    cp .env.example .env 2>/dev/null || touch .env
fi

# Add Vaultwarden configuration to .env
if ! grep -q "VAULTWARDEN_URL" .env; then
    echo "" >> .env
    echo "# Vaultwarden Configuration" >> .env
    echo "VAULTWARDEN_URL=http://localhost:8080" >> .env
    echo "VAULTWARDEN_TOKEN=" >> .env
fi

echo ""
echo "✅ Vaultwarden deployment complete!"
echo ""
echo "📋 Next Steps:"
echo "1. 🌐 Open http://localhost:8080 to access Vaultwarden"
echo "2. 👤 Create your admin account"
echo "3. 📁 Run: ./vaultwarden/setup-infrastructure-passwords.sh"
echo "4. 🔑 Configure API tokens in .env file"
echo "5. 🚀 Start Consciousness Zero: ./start_consciousness_zero_optimized.sh"
echo ""
echo "🧠 The AI will now be able to orchestrate password management!"
echo "Try: 'vaultwarden status' or 'vault search server' in the chat interface"
