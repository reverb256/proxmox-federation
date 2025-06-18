#!/bin/bash

# Verify Consciousness Federation Deployment
echo "🔍 Checking deployment status..."

echo "Docker containers:"
docker ps

echo ""
echo "Testing Vaultwarden (port 8080):"
curl -s http://localhost:8080 | head -5 || echo "Vaultwarden not responding"

echo ""
echo "Testing Web Interface (port 3000):"
curl -s http://localhost:3000 || echo "Web interface not responding"

echo ""
echo "Container logs:"
echo "--- Vaultwarden logs ---"
docker logs vaultwarden --tail 10

echo ""
echo "--- Web interface logs ---"
docker logs consciousness-web --tail 10

echo ""
echo "Network connectivity:"
ip addr show | grep "inet 10.1.1"