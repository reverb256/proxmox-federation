# Consciousness Zero - Multi-Cloud Deployment

This repository contains the **Consciousness Zero Command Center** - an AI-powered infrastructure orchestration platform with advanced web intelligence.

## 🌐 Live Deployments

- **Vercel**: [consciousness-zero.vercel.app](https://consciousness-zero.vercel.app)
- **Cloudflare Pages**: [consciousness-zero.pages.dev](https://consciousness-zero.pages.dev)
- **GitHub Pages**: [username.github.io/consciousness-zero](https://username.github.io/consciousness-zero)

## 🚀 Features

- **AI Agent**: Zero-inspired with Perplexica-style search
- **Orchestration Tools**: Vaultwarden, Crypto Wallets, Shell, Monitoring, Web Search
- **Advanced Search**: SearXNG + Crawl4AI integration
- **Multi-Cloud**: Deployed on Vercel, Cloudflare, and GitHub Pages
- **Real-time**: WebSocket support for live interactions

## 🛠️ Local Development

```bash
# Clone and setup
git clone <repository-url>
cd consciousness-zero
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt

# Run locally
python app.py
```

## 📦 Deployment

### Vercel
```bash
npm install -g vercel
vercel --prod
```

### Cloudflare Pages
```bash
npm install -g wrangler
wrangler pages publish dist
```

### GitHub Pages
Push to `main` branch - auto-deploys via GitHub Actions

## 🔧 Architecture

- **Backend**: FastAPI + Gradio
- **Frontend**: React/HTML5 with WebSocket
- **AI**: Local LLM + Hugging Face transformers
- **Search**: SearXNG + Crawl4AI
- **Deploy**: Multi-cloud with CI/CD

## 🔐 Security

- CORS configured for production
- Environment variables for API keys
- Secure WebSocket connections
- Rate limiting enabled
