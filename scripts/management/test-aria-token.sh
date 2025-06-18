#!/bin/bash

# Quick test for Aria API token generation
echo "Testing Aria API token generation..."

# Check if user exists
if pveum user list | grep -q "aria@pve"; then
    echo "✅ User aria@pve exists"
else
    echo "❌ User aria@pve not found"
    exit 1
fi

# Test token creation with different output formats
echo "Testing token creation..."

# Method 1: JSON output
echo "Attempting JSON format..."
TOKEN_JSON=$(pveum user token add aria@pve test-token --privsep 0 --output-format json 2>&1)
echo "JSON Response: $TOKEN_JSON"

# Clean up test token
pveum user token remove aria@pve test-token 2>/dev/null || true

# Method 2: Standard output
echo "Attempting standard format..."
TOKEN_STD=$(pveum user token add aria@pve test-token2 --privsep 0 2>&1)
echo "Standard Response: $TOKEN_STD"

# Extract token from standard output
if echo "$TOKEN_STD" | grep -q "full token id"; then
    EXTRACTED_TOKEN=$(echo "$TOKEN_STD" | grep "value" | cut -d'"' -f4)
    echo "Extracted token: $EXTRACTED_TOKEN"
fi

# Clean up
pveum user token remove aria@pve test-token2 2>/dev/null || true

echo "Test complete. Use this method that works for your setup."