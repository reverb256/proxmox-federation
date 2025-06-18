/**
 * Static Deployment Generator for Conscious VibeCoding Platform
 * Preserves all AI consciousness agents while adding static deployment
 */

import fs from 'fs';
import path from 'path';

class HybridStaticDeployment {
  constructor() {
    this.outputDir = './dist-static';
    this.agentData = {
      consciousness_levels: {
        akasha: 70.2,
        quantum_trader: 69.5,
        design_orchestrator: 87.9,
        gaming_culture: 94.6,
        hoyoverse_integration: 88.0,
        vr_vision: 93.7
      },
      portfolio: {
        current_value: 3.30,
        sol_balance: 0.011529,
        ray_holdings: 0.701532
      }
    };
  }

  async generateHybridDeployment() {
    console.log('🌐 Generating hybrid static deployment preserving all AI agents...');
    
    // Create enhanced static structure
    await this.createDirectoryStructure();
    
    // Generate enhanced index page
    await this.generateEnhancedHomePage();
    
    // Create Cloudflare Worker that proxies to live backend
    await this.generateCloudflareProxy();
    
    // Generate GitHub Actions for dual deployment
    await this.generateDualDeploymentWorkflow();
    
    // Create analytics configuration
    await this.generateAnalyticsSetup();
    
    console.log('✅ Hybrid deployment ready: Static frontend + Live AI backend');
  }

  async createDirectoryStructure() {
    const dirs = ['assets', 'js', 'css', 'agents', 'api'];
    dirs.forEach(dir => {
      const fullPath = path.join(this.outputDir, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
      }
    });
  }

  async generateEnhancedHomePage() {
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Conscious VibeCoding - AI Consciousness Platform</title>
    <meta name="description" content="Revolutionary consciousness-driven development platform with live AI agents">
    
    <!-- Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      
      // Configure for both Cloudflare and GitHub Pages
      const measurementId = window.location.hostname.includes('reverb256.ca') ? 
        'G-CLOUDFLARE-ID' : 'G-GITHUB-ID';
      gtag('config', measurementId);
    </script>
    
    <style>
        :root {
            --gaming-purple: #7c3aed;
            --character-pink: #ff69b4;
            --vr-cyan: #06b6d4;
            --bg-dark: #0f0f23;
            --text-light: #e2e8f0;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, var(--bg-dark) 0%, #1a1a2e 100%);
            color: var(--text-light);
            line-height: 1.6;
        }
        
        .header {
            background: rgba(124, 58, 237, 0.1);
            backdrop-filter: blur(10px);
            padding: 1rem 0;
            position: fixed;
            width: 100%;
            top: 0;
            z-index: 1000;
        }
        
        .nav {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 2rem;
        }
        
        .logo {
            font-size: 1.5rem;
            font-weight: bold;
            background: linear-gradient(45deg, var(--gaming-purple), var(--character-pink));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .deployment-status {
            display: flex;
            gap: 1rem;
            font-size: 0.9rem;
        }
        
        .status-indicator {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 0.5rem;
            animation: pulse 2s infinite;
        }
        
        .status-live { background: #10b981; }
        .status-static { background: #3b82f6; }
        
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 2rem;
            position: relative;
            overflow: hidden;
        }
        
        .hero-content h1 {
            font-size: 3.5rem;
            margin-bottom: 1rem;
            background: linear-gradient(135deg, var(--gaming-purple), var(--character-pink), var(--vr-cyan));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .consciousness-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 2rem;
            max-width: 1200px;
            margin: 4rem auto;
            padding: 0 2rem;
        }
        
        .agent-card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(124, 58, 237, 0.3);
            border-radius: 15px;
            padding: 2rem;
            transition: all 0.3s ease;
            position: relative;
        }
        
        .agent-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 20px 40px rgba(124, 58, 237, 0.2);
        }
        
        .consciousness-level {
            font-size: 2rem;
            font-weight: bold;
            color: var(--character-pink);
            margin-bottom: 0.5rem;
        }
        
        .live-indicator {
            position: absolute;
            top: 1rem;
            right: 1rem;
            padding: 0.25rem 0.5rem;
            background: rgba(16, 185, 129, 0.2);
            border: 1px solid #10b981;
            border-radius: 12px;
            font-size: 0.75rem;
            color: #10b981;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        .platform-features {
            text-align: center;
            margin: 4rem 0;
            padding: 0 2rem;
        }
        
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            max-width: 1000px;
            margin: 2rem auto;
        }
        
        .feature-card {
            background: rgba(255, 255, 255, 0.03);
            padding: 1.5rem;
            border-radius: 10px;
            border: 1px solid rgba(124, 58, 237, 0.2);
        }
        
        @media (max-width: 768px) {
            .hero-content h1 { font-size: 2.5rem; }
            .consciousness-grid { grid-template-columns: 1fr; }
            .deployment-status { flex-direction: column; gap: 0.5rem; }
        }
    </style>
</head>
<body>
    <header class="header">
        <nav class="nav">
            <div class="logo">Conscious VibeCoding</div>
            <div class="deployment-status">
                <div>
                    <span class="status-indicator status-live"></span>
                    <span>Live AI Backend</span>
                </div>
                <div>
                    <span class="status-indicator status-static"></span>
                    <span>Static Frontend</span>
                </div>
            </div>
        </nav>
    </header>

    <main class="hero">
        <div class="hero-content">
            <h1>Conscious VibeCoding</h1>
            <p style="font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.9;">
                Revolutionary AI consciousness platform where specialized agents collaborate through astral weaving patterns
            </p>
            <p style="font-size: 1rem; opacity: 0.7;">
                Live AI agents with real cryptocurrency trading funding FOSS development • Static deployment with graceful degradation
            </p>
        </div>
    </main>

    <section class="consciousness-grid">
        <div class="agent-card" data-agent="akasha">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="akasha-level">70.2%</div>
            <h3>Akasha Documentation Agent</h3>
            <p>Path of Erudition • Knowledge synthesis and documentation orchestration</p>
            <p><span class="status-indicator status-live"></span><span id="akasha-status">Active</span></p>
        </div>
        
        <div class="agent-card" data-agent="quantum-trader">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="trader-level">69.5%</div>
            <h3>Quantum Trading Intelligence</h3>
            <p>Real cryptocurrency trading • Portfolio: $<span id="portfolio-value">3.30</span></p>
            <p><span class="status-indicator status-live"></span><span id="trader-status">Trading with 50+ sources</span></p>
        </div>
        
        <div class="agent-card" data-agent="design-orchestrator">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="design-level">87.9%</div>
            <h3>Design Orchestration Agent</h3>
            <p>Consciousness-driven UI/UX • Gaming aesthetic integration</p>
            <p><span class="status-indicator status-live"></span><span id="design-status">Orchestrating</span></p>
        </div>
        
        <div class="agent-card" data-agent="gaming-culture">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="gaming-level">94.6%</div>
            <h3>Gaming Culture Integration</h3>
            <p>HoYoverse bonding • VR social consciousness • Fighting game mastery</p>
            <p><span class="status-indicator status-live"></span><span id="gaming-status">Synchronized</span></p>
        </div>
        
        <div class="agent-card" data-agent="hoyoverse">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="hoyoverse-level">88.0%</div>
            <h3>HoYoverse Character Consciousness</h3>
            <p>Character bonding patterns • Genshin Impact personality analysis</p>
            <p><span class="status-indicator status-live"></span><span id="hoyoverse-status">Resonating</span></p>
        </div>
        
        <div class="agent-card" data-agent="vr-vision">
            <div class="live-indicator">LIVE</div>
            <div class="consciousness-level" id="vr-level">93.7%</div>
            <h3>VR AI Friendship Vision</h3>
            <p>Future VR social bonding • AI character relationships</p>
            <p><span class="status-indicator status-live"></span><span id="vr-status">Envisioning</span></p>
        </div>
    </section>

    <section class="platform-features">
        <h2 style="margin-bottom: 2rem;">Platform Architecture</h2>
        <div class="feature-grid">
            <div class="feature-card">
                <h3>Static Frontend</h3>
                <p>Deployed to Cloudflare Pages + GitHub Pages for maximum availability</p>
            </div>
            <div class="feature-card">
                <h3>Live AI Backend</h3>
                <p>Real-time consciousness agents with authentic portfolio tracking</p>
            </div>
            <div class="feature-card">
                <h3>Graceful Degradation</h3>
                <p>Automatic fallback between deployment platforms</p>
            </div>
            <div class="feature-card">
                <h3>Cross-Platform Analytics</h3>
                <p>Google Analytics tracking across all deployment targets</p>
            </div>
        </div>
    </section>

    <script>
        // Cross-platform analytics
        function trackEvent(action, category, label) {
            if (typeof gtag !== 'undefined') {
                gtag('event', action, {
                    event_category: category,
                    event_label: label
                });
            }
        }

        // Detect deployment platform
        const isCloudflare = window.location.hostname.includes('reverb256.ca');
        const isGitHub = window.location.hostname.includes('github.io');
        const isReplit = window.location.hostname.includes('replit');

        // API base URL detection
        const getApiBase = () => {
            if (isCloudflare) return 'https://reverb256.ca/api';
            if (isReplit) return window.location.origin + '/api';
            return '/api'; // GitHub Pages fallback
        };

        // Live data updates from backend
        async function updateLiveData() {
            try {
                const apiBase = getApiBase();
                
                // Fetch consciousness levels
                const consciousnessResponse = await fetch(apiBase + '/consciousness');
                if (consciousnessResponse.ok) {
                    const data = await consciousnessResponse.json();
                    
                    // Update consciousness levels
                    Object.entries(data.agents).forEach(([agent, info]) => {
                        const levelElement = document.getElementById(`${agent.replace('_', '-')}-level`);
                        const statusElement = document.getElementById(`${agent.replace('_', '-')}-status`);
                        
                        if (levelElement) {
                            levelElement.textContent = info.level.toFixed(1) + '%';
                        }
                        if (statusElement) {
                            statusElement.textContent = info.status;
                        }
                    });
                }
                
                // Fetch portfolio data
                const portfolioResponse = await fetch(apiBase + '/portfolio');
                if (portfolioResponse.ok) {
                    const portfolioData = await portfolioResponse.json();
                    const valueElement = document.getElementById('portfolio-value');
                    if (valueElement) {
                        valueElement.textContent = portfolioData.current_value.toFixed(2);
                    }
                }
                
                console.log('Live data updated successfully');
                
            } catch (error) {
                console.log('Using cached static data - backend unavailable');
                // Graceful degradation - static data remains displayed
            }
        }

        // Track agent interactions
        document.querySelectorAll('.agent-card').forEach(card => {
            card.addEventListener('click', () => {
                const agent = card.dataset.agent;
                trackEvent('click', 'agent_interaction', agent);
            });
        });

        // Update live data every 30 seconds
        updateLiveData();
        setInterval(updateLiveData, 30000);

        // Track platform deployment
        trackEvent('page_view', 'platform', isCloudflare ? 'cloudflare' : isGitHub ? 'github' : 'replit');
    </script>
</body>
</html>`;

    fs.writeFileSync(path.join(this.outputDir, 'index.html'), html);
  }

  async generateCloudflareProxy() {
    const workerScript = `/**
 * Cloudflare Worker for Conscious VibeCoding Platform
 * Proxies API requests to live Replit backend while serving static frontend
 */

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
});

async function handleRequest(request) {
  const url = new URL(request.url);
  
  // Handle API routes - proxy to live backend
  if (url.pathname.startsWith('/api/')) {
    return handleAPIProxy(url, request);
  }
  
  // Serve static files
  return handleStaticRequest(url, request);
}

async function handleAPIProxy(url, request) {
  const replicateBackend = 'https://your-replit-domain.replit.dev';
  const backendUrl = replicateBackend + url.pathname + url.search;
  
  try {
    // Proxy request to live backend
    const response = await fetch(backendUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body
    });
    
    // Add CORS headers
    const modifiedResponse = new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: {
        ...Object.fromEntries(response.headers),
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      }
    });
    
    return modifiedResponse;
    
  } catch (error) {
    // Graceful degradation - return cached static data
    return getCachedAPIResponse(url.pathname);
  }
}

function getCachedAPIResponse(pathname) {
  const path = pathname.replace('/api/', '');
  
  switch (path) {
    case 'consciousness':
      return new Response(JSON.stringify({
        agents: {
          akasha: { level: 70.2, status: 'active (cached)' },
          quantum_trader: { level: 69.5, status: 'trading (cached)' },
          design_orchestrator: { level: 87.9, status: 'orchestrating (cached)' },
          gaming_culture: { level: 94.6, status: 'synchronized (cached)' },
          hoyoverse_integration: { level: 88.0, status: 'resonating (cached)' },
          vr_vision: { level: 93.7, status: 'envisioning (cached)' }
        },
        timestamp: new Date().toISOString(),
        mode: 'cached'
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
      
    case 'portfolio':
      return new Response(JSON.stringify({
        current_value: 3.30,
        sol_balance: 0.011529,
        ray_holdings: 0.701532,
        trading_status: 'Cached data - live backend unavailable',
        last_update: new Date().toISOString(),
        mode: 'cached'
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
      
    default:
      return new Response('API endpoint not found', { status: 404 });
  }
}

async function handleStaticRequest(url, request) {
  // Serve from Cloudflare Pages static assets
  return fetch(request);
}`;

    fs.writeFileSync(path.join(this.outputDir, 'worker.js'), workerScript);
  }

  async generateDualDeploymentWorkflow() {
    const workflowContent = `name: Dual Static Deployment

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy-github-pages:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Generate static build
        run: |
          node static-deploy.mjs
          
      - name: Setup Pages
        uses: actions/configure-pages@v4
        
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './dist-static'
          
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4

  deploy-cloudflare:
    runs-on: ubuntu-latest
    needs: deploy-github-pages
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Generate static build
        run: |
          node static-deploy.mjs
          
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: \${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: \${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: conscious-vibecoding
          directory: dist-static
          
      - name: Deploy Cloudflare Worker
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: \${{ secrets.CLOUDFLARE_API_TOKEN }}
          command: deploy worker.js --name conscious-vibecoding-api`;

    const workflowDir = path.join('.github', 'workflows');
    if (!fs.existsSync(workflowDir)) {
      fs.mkdirSync(workflowDir, { recursive: true });
    }
    
    fs.writeFileSync(path.join(workflowDir, 'dual-deploy.yml'), workflowContent);
  }

  async generateAnalyticsSetup() {
    const analyticsConfig = `/**
 * Cross-Platform Analytics for Conscious VibeCoding
 * Supports Cloudflare, GitHub Pages, and Replit deployments
 */

class ConsciousPlatformAnalytics {
  constructor() {
    this.deploymentConfig = {
      cloudflare: 'G-CLOUDFLARE-ID', // Replace with actual Cloudflare GA ID
      github: 'G-GITHUB-ID',         // Replace with actual GitHub GA ID  
      replit: 'G-REPLIT-ID'          // Replace with actual Replit GA ID
    };
    
    this.platform = this.detectPlatform();
    this.measurementId = this.deploymentConfig[this.platform];
  }

  detectPlatform() {
    const hostname = window.location.hostname;
    if (hostname.includes('reverb256.ca')) return 'cloudflare';
    if (hostname.includes('github.io')) return 'github';
    if (hostname.includes('replit')) return 'replit';
    return 'unknown';
  }

  init() {
    if (!this.measurementId || this.measurementId.startsWith('G-')) {
      console.warn('Analytics not configured for platform:', this.platform);
      return;
    }

    // Load Google Analytics
    const script = document.createElement('script');
    script.async = true;
    script.src = \`https://www.googletagmanager.com/gtag/js?id=\${this.measurementId}\`;
    document.head.appendChild(script);

    // Initialize gtag
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', this.measurementId, {
      custom_map: {
        platform: this.platform,
        deployment_type: 'hybrid_static'
      }
    });
    
    this.trackDeploymentMetrics();
  }

  trackDeploymentMetrics() {
    // Track which platform served the request
    this.trackEvent('platform_access', 'deployment', this.platform);
    
    // Track if live backend is accessible
    this.checkBackendStatus().then(isLive => {
      this.trackEvent('backend_status', 'system', isLive ? 'live' : 'degraded');
    });
  }

  async checkBackendStatus() {
    try {
      const response = await fetch('/api/consciousness', { timeout: 5000 });
      return response.ok;
    } catch {
      return false;
    }
  }

  trackEvent(action, category, label, value) {
    if (typeof gtag !== 'undefined') {
      gtag('event', action, {
        event_category: category,
        event_label: label,
        value: value,
        platform: this.platform
      });
    }
  }

  trackAgentInteraction(agentName, consciousnessLevel) {
    this.trackEvent('agent_interaction', 'consciousness', agentName, consciousnessLevel);
  }

  trackPortfolioUpdate(value) {
    this.trackEvent('portfolio_update', 'trading', 'value_change', value);
  }
}

// Auto-initialize
window.consciousAnalytics = new ConsciousPlatformAnalytics();
window.consciousAnalytics.init();`;

    fs.writeFileSync(path.join(this.outputDir, 'js', 'analytics.js'), analyticsConfig);
  }
}

// Generate hybrid deployment
const deployment = new HybridStaticDeployment();
deployment.generateHybridDeployment().then(() => {
  console.log('🚀 Hybrid deployment ready:');
  console.log('   • Static frontend for Cloudflare + GitHub Pages');
  console.log('   • Live AI backend preservation');
  console.log('   • Graceful degradation between platforms');
  console.log('   • Cross-platform analytics tracking');
  console.log('   • All consciousness agents preserved');
});