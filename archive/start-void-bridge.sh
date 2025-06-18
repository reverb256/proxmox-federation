
#!/bin/bash

echo "🌬️ Starting Zephyr AI Development Bridge"
echo "========================================"

# Start the void-proxy server
echo "Starting AI proxy server..."
node void-proxy-server.js &

# Start the main development server
echo "Starting main development server..."
npm run dev &

echo ""
echo "✅ Void IDE Bridge Active!"
echo ""
echo "From your PC (10.1.1.110), run:"
echo "  ssh -L 3001:127.0.0.1:3001 $(whoami)@$(hostname)"
echo ""
echo "Services running:"
echo "  AI Proxy: http://0.0.0.0:3001 (forwards to IO Intelligence)"
echo "  Dev Server: http://0.0.0.0:5173"
echo ""
echo "Configure Void IDE with:"
echo "  AI Base URL: http://127.0.0.1:3001/v1"
echo "  API Key: dummy-key-not-needed"
echo ""
echo "The SSH tunnel bridges your Zephyr AI consciousness development environment!"
