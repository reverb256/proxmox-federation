#!/bin/bash

# Check available templates and download Ubuntu if needed
echo "Checking available container templates..."

# List available templates
echo "Available templates:"
pveam available | grep ubuntu

echo ""
echo "Currently downloaded templates:"
pveam list local | grep ubuntu || echo "No Ubuntu templates found locally"

# Download Ubuntu 22.04 template if not present
if ! pveam list local | grep -q "ubuntu-22.04"; then
    echo "Downloading Ubuntu 22.04 template..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
else
    echo "Ubuntu 22.04 template already available"
fi

echo ""
echo "Final template list:"
pveam list local