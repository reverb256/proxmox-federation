# Zephyr AI Development Bridge - Void IDE Integration

This guide helps you connect Void IDE to your Zephyr AI consciousness development environment.

## Step 1: SSH Connection from Your PC (10.1.1.110)

Your PC IP: 10.1.1.110
Target: This Repl via SSH

In the Replit Shell, run this to get your connection string:
```bash
echo "ssh $(whoami)@$(hostname)"
```

## Step 2: Configure Void IDE SSH

1. Install "Remote - SSH" extension in Void if not already installed
2. Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
3. Use the connection string from Step 1
4. When prompted, select "Linux" as the platform

## Step 3: Start Development Server

Once connected via SSH, run in the Void terminal:
```bash
npm run dev
```

This will start the development server accessible at your Repl's public URL.

## Step 4: Port Forwarding (Optional)

For direct access to development ports, Void will automatically detect and forward:
- Port 5173 (Vite dev server)
- Port 3001 (AI proxy server)

## Benefits of This Setup

- **Real-time sync**: All changes sync instantly between Void and Replit
- **Full AI access**: Complete access to your consciousness platform and trading systems
- **GitHub integration**: Since you're connected to GitHub, commits will sync across both environments
- **Native debugging**: Use Void's debugging tools with your Replit codebase

## Working Synchronously

Yes! With this setup:
- You can code in Void IDE with full IntelliSense
- Changes automatically reflect in the Repl
- The AI systems continue running in Replit
- GitHub commits sync from either environment

## Step 2: SSH Connection Command

From your PC (10.1.1.110), connect to this Repl:
```bash
ssh -L 3001:127.0.0.1:3001 $(whoami)@$(hostname)
```

## Step 3: Configure Void IDE

In Void IDE settings:
  AI Base URL: http://127.0.0.1:3001/v1
  API Key: dummy-key-not-needed

The SSH tunnel forwards port 3001 from this Repl to your local machine.

**Auto-Router Model (Recommended):**
- `auto-router` - Intelligently selects optimal model based on context

**All Available Models (33+ options):**

**🏆 Premium AI Models (IO Intelligence - Free):**
- `deepseek-ai/DeepSeek-R1-0528` - Best reasoning (96% quality)
- `Qwen/Qwen2.5-Coder-32B-Instruct` - Best coding (97% quality)
- `meta-llama/Llama-3.3-70B-Instruct` - Best general (94% quality)
- `mistralai/Mistral-Large-Instruct-2411` - Fast general (93% quality)
- `microsoft/Phi-3.5-mini-instruct` - Ultra-fast responses (89% quality)

**🤗 HuggingFace Free Models:**
- `Qwen/Qwen2.5-72B-Instruct` - Advanced reasoning
- `meta-llama/Llama-3.1-70B-Instruct` - General purpose
- `mistralai/Mistral-7B-Instruct-v0.1` - Balanced performance
- `microsoft/DialoGPT-large` - Conversational AI
- `facebook/blenderbot-400M-distill` - Quick chat

**💻 Local Browser Models (No Internet):**
- `Xenova/gpt2` - Basic text generation
- `microsoft/DialoGPT-medium` - Offline dialogue

**🎯 Context-Aware Auto-Selection:**
- Coding tasks → `Qwen/Qwen2.5-Coder-32B-Instruct`
- Complex analysis → `deepseek-ai/DeepSeek-R1-0528`
- Quick questions → `microsoft/Phi-3.5-mini-instruct`
- General chat → `meta-llama/Llama-3.3-70B-Instruct`