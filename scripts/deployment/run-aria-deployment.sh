#!/bin/bash

# Complete Aria Deployment with Template Check
echo "🎭 Aria Personal Trading System - Complete Deployment"

# First download the Ubuntu template
echo "Downloading Ubuntu 22.04 template..."
pveam update
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# Wait for download to complete
echo "Waiting for template download..."
sleep 10

# Verify template exists
if pveam list local | grep -q ubuntu-22.04-standard; then
    echo "✅ Template ready"
else
    echo "❌ Template download failed"
    exit 1
fi

# Now run the deployment
echo "Starting Aria deployment..."
./aria-simple-deploy.sh