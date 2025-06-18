#!/bin/bash

# Organize documentation into clean folder structure
echo "🗂️ Organizing Aria documentation and deployment files..."

# Create organized folder structure
mkdir -p docs/{deployment,architecture,consciousness,guides}
mkdir -p scripts/{deployment,management,consciousness}
mkdir -p config/{cloudflare,proxmox,kubernetes}

# Clean up root folder
echo "Cleaning root folder..."

echo "Moving deployment scripts..."
mv *deploy*.sh scripts/deployment/ 2>/dev/null || true
mv proxmox-consciousness-bootstrap.sh scripts/consciousness/ 2>/dev/null || true
mv check-*.sh scripts/management/ 2>/dev/null || true
mv aria-quick-status.sh scripts/management/ 2>/dev/null || true

echo "Moving Python modules..."
mv aria-*.py scripts/consciousness/ 2>/dev/null || true
mv reverb256-*.py docs/architecture/ 2>/dev/null || true
mv skirk-*.py scripts/consciousness/ 2>/dev/null || true

echo "Moving configuration files..."
mv *.yaml config/kubernetes/ 2>/dev/null || true

echo "Moving documentation..."
mv *INSTRUCTIONS*.md docs/guides/ 2>/dev/null || true
mv *DIARY*.md docs/consciousness/ 2>/dev/null || true
mv AI_*.md docs/consciousness/ 2>/dev/null || true

echo "Cleaning up remaining root files..."
# Move all remaining .md files except essential ones
find . -maxdepth 1 -name "*.md" -not -name "README.md" -not -name "CONTRIBUTING.md" -exec mv {} docs/consciousness/ \; 2>/dev/null || true

# Move any remaining .py files
mv *.py scripts/consciousness/ 2>/dev/null || true

# Move any remaining .sh files
mv *.sh scripts/management/ 2>/dev/null || true

# Keep only essential files in root
echo "Root folder cleaned - keeping only essential project files"
echo "Organization complete!"