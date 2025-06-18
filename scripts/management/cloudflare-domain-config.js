/**
 * Cloudflare Domain Configuration for Quantum AI Trading Platform
 * Portfolio: reverb256.ca
 * Trading Interface: trader.reverb256.ca
 */

class CloudflareDomainManager {
  constructor() {
    this.domains = {
      portfolio: 'reverb256.ca',
      trader: 'trader.reverb256.ca'
    };
    
    this.workerConfig = {
      name: 'quantum-ai-trading-platform',
      compatibility_date: '2024-01-01',
      compatibility_flags: ['nodejs_compat'],
      vars: {
        ENVIRONMENT: 'production',
        PORTFOLIO_DOMAIN: 'reverb256.ca',
        TRADER_DOMAIN: 'trader.reverb256.ca'
      }
    };
  }

  createWorkerScript() {
    return `
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)
  const hostname = url.hostname
  
  // Route based on subdomain
  if (hostname === 'trader.reverb256.ca') {
    return handleTraderInterface(request)
  } else if (hostname === 'reverb256.ca') {
    return handlePortfolio(request)
  }
  
  return new Response('Not Found', { status: 404 })
}

async function handlePortfolio(request) {
  const url = new URL(request.url)
  
  // Serve portfolio showcase (static site)
  if (url.pathname === '/' || url.pathname === '/index.html') {
    return new Response(getPortfolioHTML(), {
      headers: { 'Content-Type': 'text/html' }
    })
  }
  
  // API proxy for live data
  if (url.pathname.startsWith('/api/')) {
    return proxyToBackend(request)
  }
  
  return new Response('Not Found', { status: 404 })
}

async function handleTraderInterface(request) {
  const url = new URL(request.url)
  
  // Serve trading interface
  if (url.pathname === '/' || url.pathname === '/index.html') {
    return new Response(getTraderHTML(), {
      headers: { 'Content-Type': 'text/html' }
    })
  }
  
  // API proxy for trading data
  if (url.pathname.startsWith('/api/')) {
    return proxyToBackend(request)
  }
  
  return new Response('Not Found', { status: 404 })
}

async function proxyToBackend(request) {
  // Proxy to your Replit backend for live data
  const backendUrl = 'https://workspace.snyper256.repl.co'
  const url = new URL(request.url)
  const proxyUrl = backendUrl + url.pathname + url.search
  
  const response = await fetch(proxyUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body
  })
  
  return response
}

function getPortfolioHTML() {
  return \`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quantum AI Trading Platform - Portfolio Showcase</title>
    <meta name="description" content="Advanced quantum intelligence meets AI-driven blockchain trading. Real-time market analysis with psychological AI therapy orchestration.">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #e2e8f0;
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .logo { font-size: 3rem; font-weight: bold; color: #3b82f6; margin-bottom: 10px; }
        .subtitle { font-size: 1.2rem; color: #94a3b8; margin-bottom: 20px; }
        .nav-link { 
            display: inline-block; 
            padding: 12px 24px; 
            background: #3b82f6; 
            color: white; 
            text-decoration: none; 
            border-radius: 8px; 
            margin: 10px;
            font-weight: 600;
        }
        .nav-link:hover { background: #2563eb; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 24px; margin-top: 40px; }
        .card { 
            background: rgba(30, 41, 59, 0.8);
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 28px;
            backdrop-filter: blur(10px);
        }
        .card h3 { color: #3b82f6; margin-bottom: 16px; font-size: 1.3rem; }
        .metric { display: flex; justify-content: space-between; margin-bottom: 12px; }
        .metric-label { color: #94a3b8; }
        .metric-value { font-weight: 600; }
        .status-live { color: #10b981; }
        .status-error { color: #ef4444; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="logo">🚀 Quantum AI Trading Platform</h1>
            <p class="subtitle">Advanced quantum intelligence meets AI-driven blockchain trading</p>
            <p class="subtitle">Real-time market analysis with psychological AI therapy orchestration</p>
            <a href="https://trader.reverb256.ca" class="nav-link">🎯 Access Trading Interface</a>
            <a href="https://workspace.snyper256.repl.co" class="nav-link">📊 Live Demo</a>
        </div>

        <div class="grid">
            <div class="card">
                <h3>🧠 AI Psychological Framework</h3>
                <div class="metric">
                    <span class="metric-label">Therapy Sessions:</span>
                    <span class="metric-value status-live" id="therapy-sessions">Active</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Confidence Calibration:</span>
                    <span class="metric-value" id="confidence-level">85%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Decision Override:</span>
                    <span class="metric-value status-live" id="decision-system">Enabled</span>
                </div>
                <p style="margin-top: 16px; color: #94a3b8; font-size: 0.9rem;">
                    AI trader develops psychological trauma after security breach, featuring automated therapy orchestration and confidence recalibration.
                </p>
            </div>

            <div class="card">
                <h3>⚡ Real-time Market Intelligence</h3>
                <div class="metric">
                    <span class="metric-label">API Endpoints:</span>
                    <span class="metric-value status-live" id="api-status">Live</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Success Rate:</span>
                    <span class="metric-value" id="success-rate">85.7%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Data Sources:</span>
                    <span class="metric-value" id="data-sources">Solana, PumpFun</span>
                </div>
                <p style="margin-top: 16px; color: #94a3b8; font-size: 0.9rem;">
                    Intelligent load balancing across multiple RPC endpoints with health monitoring and automatic failover.
                </p>
            </div>

            <div class="card">
                <h3>🔒 Legal Compliance Engine</h3>
                <div class="metric">
                    <span class="metric-label">Compliance Score:</span>
                    <span class="metric-value status-live" id="compliance-score">100%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Violations:</span>
                    <span class="metric-value" id="violations">0/6</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Standards:</span>
                    <span class="metric-value" id="standards">EU AI Act, MiCA</span>
                </div>
                <p style="margin-top: 16px; color: #94a3b8; font-size: 0.9rem;">
                    Comprehensive compliance with EU AI Act, MiCA regulations, US AI Executive Order, and quantum security protocols.
                </p>
            </div>

            <div class="card">
                <h3>🌐 Technical Architecture</h3>
                <div class="metric">
                    <span class="metric-label">Frontend:</span>
                    <span class="metric-value">React 18 + TypeScript</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Blockchain:</span>
                    <span class="metric-value">Solana Web3.js</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Deployment:</span>
                    <span class="metric-value">Cloudflare Workers</span>
                </div>
                <p style="margin-top: 16px; color: #94a3b8; font-size: 0.9rem;">
                    Modern full-stack architecture with serverless deployment and edge computing optimization.
                </p>
            </div>
        </div>
    </div>

    <script>
        // Update live metrics
        async function updateMetrics() {
            try {
                const response = await fetch('/api/live/dashboard-stats');
                const data = await response.json();
                
                if (data.success) {
                    document.getElementById('success-rate').textContent = data.apiSuccessRate + '%';
                    document.getElementById('compliance-score').textContent = data.complianceScore + '%';
                    document.getElementById('confidence-level').textContent = data.aiConfidence + '%';
                }
            } catch (error) {
                console.log('Using static fallback data');
            }
        }
        
        updateMetrics();
        setInterval(updateMetrics, 30000);
    </script>
</body>
</html>\`;
}

function getTraderHTML() {
  return \`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Trading Interface - Live Market Analysis</title>
    <meta name="description" content="Real-time AI trading interface with quantum intelligence and psychological therapy monitoring.">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #e2e8f0;
            min-height: 100vh;
        }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { font-size: 2.5rem; font-weight: bold; color: #3b82f6; margin-bottom: 10px; }
        .nav-link { 
            display: inline-block; 
            padding: 8px 16px; 
            background: #334155; 
            color: #e2e8f0; 
            text-decoration: none; 
            border-radius: 6px; 
            margin: 5px;
            font-size: 0.9rem;
        }
        .nav-link:hover { background: #475569; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .card { 
            background: rgba(30, 41, 59, 0.8);
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 24px;
            backdrop-filter: blur(10px);
        }
        .card h3 { color: #3b82f6; margin-bottom: 16px; font-size: 1.2rem; }
        .metric { display: flex; justify-content: space-between; margin-bottom: 10px; }
        .metric-label { color: #94a3b8; font-size: 0.9rem; }
        .metric-value { font-weight: 600; font-size: 0.9rem; }
        .status-live { color: #10b981; }
        .status-error { color: #ef4444; }
        .status-warning { color: #f59e0b; }
        .loading { animation: pulse 2s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="logo">🎯 AI Trading Interface</h1>
            <a href="https://reverb256.ca" class="nav-link">← Portfolio</a>
            <a href="https://workspace.snyper256.repl.co" class="nav-link">📊 Live Demo</a>
        </div>

        <div class="grid">
            <div class="card">
                <h3>🧠 AI Trader Psychology</h3>
                <div class="metric">
                    <span class="metric-label">Therapy Status:</span>
                    <span class="metric-value status-live" id="therapy-status">Active</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Confidence:</span>
                    <span class="metric-value" id="ai-confidence">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Decision State:</span>
                    <span class="metric-value" id="decision-state">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Recovery Progress:</span>
                    <span class="metric-value" id="recovery-progress">Loading...</span>
                </div>
            </div>

            <div class="card">
                <h3>📊 Live Trading Data</h3>
                <div class="metric">
                    <span class="metric-label">Portfolio Value:</span>
                    <span class="metric-value" id="portfolio-value">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Win Rate:</span>
                    <span class="metric-value" id="win-rate">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Total Trades:</span>
                    <span class="metric-value" id="total-trades">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Max Drawdown:</span>
                    <span class="metric-value" id="max-drawdown">Loading...</span>
                </div>
            </div>

            <div class="card">
                <h3>🌐 API Intelligence</h3>
                <div class="metric">
                    <span class="metric-label">Active Endpoints:</span>
                    <span class="metric-value" id="active-endpoints">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Success Rate:</span>
                    <span class="metric-value" id="api-success-rate">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Response Time:</span>
                    <span class="metric-value" id="response-time">Loading...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Queue Length:</span>
                    <span class="metric-value" id="queue-length">Loading...</span>
                </div>
            </div>

            <div class="card">
                <h3>🔒 Security & Compliance</h3>
                <div class="metric">
                    <span class="metric-label">Compliance Score:</span>
                    <span class="metric-value status-live" id="compliance-score">100%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Wallet Security:</span>
                    <span class="metric-value status-live" id="wallet-security">Secure</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Gas Protection:</span>
                    <span class="metric-value status-live" id="gas-protection">Active</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Risk Level:</span>
                    <span class="metric-value" id="risk-level">Loading...</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        async function updateTraderMetrics() {
            try {
                const [tradingData, apiData, therapyData] = await Promise.all([
                    fetch('/api/trading-status').then(r => r.json()),
                    fetch('/api/live/api-status').then(r => r.json()),
                    fetch('/api/therapy/status').then(r => r.json())
                ]);

                // Update trading metrics
                if (tradingData.success) {
                    document.getElementById('portfolio-value').textContent = tradingData.portfolioValue + ' SOL';
                    document.getElementById('win-rate').textContent = (tradingData.winRate * 100).toFixed(1) + '%';
                    document.getElementById('total-trades').textContent = tradingData.totalTrades;
                    document.getElementById('max-drawdown').textContent = tradingData.maxDrawdown + ' SOL';
                }

                // Update API metrics
                if (apiData.success) {
                    document.getElementById('active-endpoints').textContent = apiData.healthyEndpoints + '/' + apiData.totalEndpoints;
                    document.getElementById('api-success-rate').textContent = apiData.successRate.toFixed(1) + '%';
                    document.getElementById('response-time').textContent = apiData.avgResponseTime + 'ms';
                    document.getElementById('queue-length').textContent = apiData.queueLength;
                }

                // Update therapy metrics
                if (therapyData.success) {
                    document.getElementById('ai-confidence').textContent = (therapyData.confidence * 100).toFixed(1) + '%';
                    document.getElementById('decision-state').textContent = therapyData.decisionState;
                    document.getElementById('recovery-progress').textContent = therapyData.recoveryProgress;
                }

            } catch (error) {
                console.log('API unavailable, using static display');
            }
        }

        updateTraderMetrics();
        setInterval(updateTraderMetrics, 10000);
    </script>
</body>
</html>\`;
}
`;
  }

  createCloudflareConfig() {
    return JSON.stringify({
      name: this.workerConfig.name,
      compatibility_date: this.workerConfig.compatibility_date,
      compatibility_flags: this.workerConfig.compatibility_flags,
      vars: this.workerConfig.vars,
      routes: [
        { pattern: `${this.domains.portfolio}/*`, zone_name: this.domains.portfolio },
        { pattern: `${this.domains.trader}/*`, zone_name: this.domains.portfolio }
      ]
    }, null, 2);
  }

  createDeploymentScript() {
    return `#!/bin/bash
echo "🚀 Deploying Quantum AI Trading Platform to Cloudflare..."

# Create worker script
echo "📝 Creating Cloudflare Worker..."
cat > worker.js << 'EOF'
${this.createWorkerScript()}
EOF

# Create wrangler.toml configuration
echo "⚙️ Creating Cloudflare configuration..."
cat > wrangler.toml << 'EOF'
${this.createCloudflareConfig()}
EOF

echo "✅ Deployment files created!"
echo "📋 Next steps:"
echo "1. Install wrangler: npm install -g wrangler"
echo "2. Login: wrangler login"
echo "3. Deploy: wrangler deploy"
echo ""
echo "🌐 Your domains will be:"
echo "   Portfolio: https://${this.domains.portfolio}"
echo "   Trading:   https://${this.domains.trader}"
`;
  }

  async generateDeploymentPackage() {
    const fs = require('fs');
    const path = require('path');
    
    const deployDir = 'cloudflare-deployment';
    if (!fs.existsSync(deployDir)) {
      fs.mkdirSync(deployDir);
    }

    // Write worker script
    fs.writeFileSync(
      path.join(deployDir, 'worker.js'), 
      this.createWorkerScript()
    );

    // Write configuration
    fs.writeFileSync(
      path.join(deployDir, 'wrangler.toml'), 
      this.createCloudflareConfig()
    );

    // Write deployment script
    fs.writeFileSync(
      path.join(deployDir, 'deploy.sh'), 
      this.createDeploymentScript()
    );

    // Make deploy script executable
    fs.chmodSync(path.join(deployDir, 'deploy.sh'), '755');

    console.log('✅ Cloudflare deployment package created in ./cloudflare-deployment/');
    return deployDir;
  }
}

module.exports = { CloudflareDomainManager };

// CLI usage
if (require.main === module) {
  const manager = new CloudflareDomainManager();
  manager.generateDeploymentPackage().then(dir => {
    console.log(`🚀 Deployment package ready in ${dir}/`);
    console.log('Run ./cloudflare-deployment/deploy.sh to deploy');
  });
}