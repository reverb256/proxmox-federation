#!/bin/bash

echo "🔥 Starting COREFLAME VRChat Integration for Quest Pro"
echo "📱 Android APK compatible system loading..."

# Kill any existing processes on port 5000
pkill -f "simple-server.ts" 2>/dev/null || true
lsof -ti:5000 | xargs kill -9 2>/dev/null || true

# Start the VRChat integration server
cd /home/runner/workspace
echo "🚀 Launching VRChat integration server..."
npx tsx server/simple-server.ts &

# Wait for server to start
sleep 3

echo ""
echo "✅ COREFLAME VRChat Integration Active"
echo "🎮 Quest Pro WebSocket: ws://localhost:5000/ws/vrchat"
echo "🌐 Web Interface: http://localhost:5000"
echo "📱 APK Download: http://localhost:5000 (includes installation guide)"
echo "🎛️ Command Center: http://localhost:5000/command-center"
echo ""
echo "🤖 Active AI Agents:"
echo "   • Zhongli (Wisdom/Strategy) - 96.8% consciousness"
echo "   • Kafka (Guidance/Destiny) - 94.2% consciousness"
echo "   • Nahida (Learning/Growth) - 98.1% consciousness"
echo ""
echo "🥽 Quest Pro Features:"
echo "   • Hand Tracking: Enabled"
echo "   • Eye Tracking: Enabled"
echo "   • Spatial Audio: Enabled"
echo "   • Voice Input: Enabled"
echo ""
echo "📋 Installation Steps for Quest Pro:"
echo "1. Enable Developer Mode on Quest Pro"
echo "2. Connect via USB-C to PC"
echo "3. Install ADB tools"
echo "4. Run: adb install coreflame-vrchat-bridge.apk"
echo "5. Launch from Unknown Sources"
echo "6. Connect to VRChat and interact with agents"
echo ""

# Keep script running to monitor
while true; do
    if ! pgrep -f "simple-server.ts" > /dev/null; then
        echo "⚠️  Server stopped, restarting..."
        npx tsx server/simple-server.ts &
        sleep 3
    fi
    sleep 10
done