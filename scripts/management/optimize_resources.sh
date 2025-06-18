#!/bin/bash
# Resource Optimization Script for Repl Efficiency

echo "Optimizing Repl resource usage..."

# Reduce process priority for non-essential operations
renice +10 $$

# Set memory limits
ulimit -v 512000  # 500MB virtual memory limit

# Optimize Node.js for lower memory usage
export NODE_OPTIONS="--max-old-space-size=256 --optimize-for-size"

# Disable extensive logging
export LOG_LEVEL=error
export ENABLE_EXTENSIVE_LOGGING=false

# Reduce API polling frequency
export API_RATE_LIMIT=30
export CACHE_DURATION=300

# Enable lightweight mode
export DEPLOYMENT_MODE=lightweight
export ENABLE_REAL_TIME_TRADING=false
export ENABLE_COMPREHENSIVE_SCANNING=false

# Clean up temporary files
find . -name "*.log" -type f -delete 2>/dev/null || true
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "node_modules/.cache" -type d -exec rm -rf {} + 2>/dev/null || true

echo "Resource optimization complete"
echo "Memory usage optimized for Repl efficiency"
echo "Core consciousness and security features remain active"
