#!/bin/bash

# Setup Aria Secrets Management System
echo "🔐 Setting up Aria Secrets Management"

# Install required packages
echo "Installing dependencies..."
apt update
apt install -y python3-pip curl jq

# Install Python dependencies for secrets management
pip3 install requests cryptography

# Create aria-secrets command
cat > /usr/local/bin/aria-secrets << 'EOF'
#!/usr/bin/env python3
"""
Aria Secrets Management - Secure API key storage for trading system
"""

import argparse
import json
import sys
import requests
import base64
from cryptography.fernet import Fernet
import os
from datetime import datetime

class AriaSecretsManager:
    def __init__(self):
        self.secrets_file = "/etc/aria/secrets.json"
        self.key_file = "/etc/aria/master.key"
        self.ensure_directories()
        
    def ensure_directories(self):
        """Ensure required directories exist"""
        os.makedirs("/etc/aria", exist_ok=True)
        
    def get_or_create_key(self):
        """Get or create encryption key"""
        if os.path.exists(self.key_file):
            with open(self.key_file, 'rb') as f:
                return f.read()
        else:
            key = Fernet.generate_key()
            with open(self.key_file, 'wb') as f:
                f.write(key)
            os.chmod(self.key_file, 0o600)
            return key
    
    def load_secrets(self):
        """Load encrypted secrets"""
        if not os.path.exists(self.secrets_file):
            return {}
        
        try:
            with open(self.secrets_file, 'r') as f:
                encrypted_data = json.load(f)
            
            key = self.get_or_create_key()
            fernet = Fernet(key)
            
            decrypted_secrets = {}
            for name, encrypted_value in encrypted_data.items():
                decrypted_value = fernet.decrypt(encrypted_value.encode()).decode()
                decrypted_secrets[name] = decrypted_value
            
            return decrypted_secrets
        except Exception as e:
            print(f"Error loading secrets: {e}")
            return {}
    
    def save_secrets(self, secrets):
        """Save encrypted secrets"""
        try:
            key = self.get_or_create_key()
            fernet = Fernet(key)
            
            encrypted_data = {}
            for name, value in secrets.items():
                encrypted_value = fernet.encrypt(value.encode()).decode()
                encrypted_data[name] = encrypted_value
            
            with open(self.secrets_file, 'w') as f:
                json.dump(encrypted_data, f)
            
            os.chmod(self.secrets_file, 0o600)
            return True
        except Exception as e:
            print(f"Error saving secrets: {e}")
            return False
    
    def add_secret(self, name, value):
        """Add or update a secret"""
        secrets = self.load_secrets()
        secrets[name] = value
        
        if self.save_secrets(secrets):
            print(f"✅ Secret '{name}' added successfully")
            return True
        else:
            print(f"❌ Failed to add secret '{name}'")
            return False
    
    def get_secret(self, name):
        """Get a secret value"""
        secrets = self.load_secrets()
        return secrets.get(name)
    
    def list_secrets(self):
        """List all secret names (not values)"""
        secrets = self.load_secrets()
        if not secrets:
            print("No secrets configured")
            return
        
        print("Configured secrets:")
        for name in secrets.keys():
            print(f"  - {name}")
    
    def remove_secret(self, name):
        """Remove a secret"""
        secrets = self.load_secrets()
        if name in secrets:
            del secrets[name]
            if self.save_secrets(secrets):
                print(f"✅ Secret '{name}' removed successfully")
                return True
        
        print(f"❌ Secret '{name}' not found")
        return False
    
    def add_trading_keys(self):
        """Interactive setup for trading API keys"""
        print("🎭 Aria Trading API Key Setup")
        print("This will securely store your exchange API keys")
        print()
        
        exchanges = {
            "binance": ["BINANCE_API_KEY", "BINANCE_SECRET_KEY"],
            "coinbase": ["COINBASE_API_KEY", "COINBASE_SECRET_KEY"],
            "kraken": ["KRAKEN_API_KEY", "KRAKEN_SECRET_KEY"]
        }
        
        print("Available exchanges:")
        for i, exchange in enumerate(exchanges.keys(), 1):
            print(f"  {i}. {exchange.title()}")
        
        try:
            choice = input("Select exchange (1-3): ").strip()
            exchange_names = list(exchanges.keys())
            
            if choice.isdigit() and 1 <= int(choice) <= len(exchange_names):
                exchange = exchange_names[int(choice) - 1]
                keys = exchanges[exchange]
                
                print(f"\nSetting up {exchange.title()} API keys:")
                
                for key_name in keys:
                    value = input(f"Enter {key_name}: ").strip()
                    if value:
                        self.add_secret(key_name, value)
                
                print(f"\n✅ {exchange.title()} API keys configured successfully!")
                print("Your trading system can now connect to the exchange.")
                
            else:
                print("Invalid selection")
                
        except KeyboardInterrupt:
            print("\nSetup cancelled")

def main():
    parser = argparse.ArgumentParser(description="Aria Secrets Management")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Add secret
    add_parser = subparsers.add_parser('add', help='Add a secret')
    add_parser.add_argument('name', help='Secret name')
    add_parser.add_argument('value', help='Secret value')
    
    # Get secret
    get_parser = subparsers.add_parser('get', help='Get a secret')
    get_parser.add_argument('name', help='Secret name')
    
    # List secrets
    subparsers.add_parser('list', help='List all secrets')
    
    # Remove secret
    remove_parser = subparsers.add_parser('remove', help='Remove a secret')
    remove_parser.add_argument('name', help='Secret name')
    
    # Setup trading keys
    subparsers.add_parser('setup-trading', help='Interactive trading key setup')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = AriaSecretsManager()
    
    if args.command == 'add':
        manager.add_secret(args.name, args.value)
    elif args.command == 'get':
        value = manager.get_secret(args.name)
        if value:
            print(value)
        else:
            print(f"Secret '{args.name}' not found")
            sys.exit(1)
    elif args.command == 'list':
        manager.list_secrets()
    elif args.command == 'remove':
        manager.remove_secret(args.name)
    elif args.command == 'setup-trading':
        manager.add_trading_keys()

if __name__ == "__main__":
    main()
EOF

# Make aria-secrets executable
chmod +x /usr/local/bin/aria-secrets

# Create Proxmox user for Aria
echo "Creating aria@pve user..."
pveum user add aria@pve --comment "Aria Trading System User" 2>/dev/null || echo "User aria@pve already exists"
pveum aclmod / -user aria@pve -role PVEVMAdmin

# Remove existing token if it exists
echo "Cleaning up existing API tokens..."
pveum user token remove aria@pve aria-token 2>/dev/null || echo "No existing token to remove"

# Generate new API token for aria user
echo "Generating new API token for aria@pve..."
TOKEN_INFO=$(pveum user token add aria@pve aria-token --privsep=0)
echo "$TOKEN_INFO" > /etc/aria/proxmox-token.txt
chmod 600 /etc/aria/proxmox-token.txt

echo ""
echo "🎉 Aria Secrets Management Setup Complete!"
echo ""
echo "Available commands:"
echo "  aria-secrets setup-trading    # Interactive trading key setup"
echo "  aria-secrets add <name> <value>  # Add a secret"
echo "  aria-secrets list             # List all secrets"
echo "  aria-secrets get <name>       # Get a secret value"
echo "  aria-secrets remove <name>    # Remove a secret"
echo ""
echo "Example usage:"
echo "  aria-secrets setup-trading"
echo "  aria-secrets add BINANCE_API_KEY your_api_key_here"
echo ""
echo "Your secrets are encrypted and stored securely in /etc/aria/"