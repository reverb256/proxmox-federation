
#!/usr/bin/env node

/**
 * Cloudflare + GitHub Pages Integration Setup
 * Complete configuration for reverb256.ca with DNS management
 */

import fs from 'fs/promises';
import path from 'path';

class CloudflareGitHubPagesSetup {
  constructor() {
    this.domains = {
      primary: 'reverb256.ca',
      www: 'www.reverb256.ca',
      api: 'api.reverb256.ca',
      trading: 'trading.reverb256.ca'
    };
    this.githubRepo = 'reverb256/quantum-trading-platform';
  }

  async setupComplete() {
    console.log('🌐 Setting up Cloudflare + GitHub Pages Integration...');
    
    await this.createGitHubPagesWorkflow();
    await this.createCloudflareWorker();
    await this.generateDNSConfiguration();
    await this.createCloudflarePageRules();
    await this.setupSSLConfiguration();
    await this.createDeploymentGuide();
    
    console.log('✅ Cloudflare + GitHub Pages setup complete!');
  }

  async createGitHubPagesWorkflow() {
    const workflowContent = `name: Deploy to GitHub Pages with Cloudflare

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build for GitHub Pages
        run: |
          npm run build
          # Copy for GitHub Pages
          cp -r dist/* ./
          
      - name: Setup Pages
        uses: actions/configure-pages@v4
        
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './dist'

  deploy:
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4

  deploy-cloudflare:
    runs-on: ubuntu-latest
    needs: deploy
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Deploy Cloudflare Worker
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: \${{ secrets.CLOUDFLARE_API_TOKEN }}
          command: deploy worker.js --name quantum-trading-api
          
      - name: Purge Cloudflare Cache
        run: |
          curl -X POST "https://api.cloudflare.com/client/v4/zones/\${{ secrets.CLOUDFLARE_ZONE_ID }}/purge_cache" \\
            -H "Authorization: Bearer \${{ secrets.CLOUDFLARE_API_TOKEN }}" \\
            -H "Content-Type: application/json" \\
            --data '{"purge_everything":true}'`;

    await this.writeFile('.github/workflows/cloudflare-github-pages.yml', workflowContent);
    console.log('📋 Created GitHub Pages + Cloudflare workflow');
  }

  async createCloudflareWorker() {
    const workerContent = `/**
 * Cloudflare Worker for reverb256.ca
 * Handles API routing and GitHub Pages integration
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin');
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': 'https://reverb256.ca',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400'
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { 
        status: 204, 
        headers: corsHeaders 
      });
    }

    // Route API requests
    if (url.pathname.startsWith('/api/')) {
      return await handleAPIRequest(request, env, corsHeaders);
    }

    // Route to GitHub Pages for main site
    if (url.hostname === 'reverb256.ca' || url.hostname === 'www.reverb256.ca') {
      const githubPagesURL = 'https://reverb256.github.io/quantum-trading-platform';
      const githubRequest = new Request(githubPagesURL + url.pathname, {
        method: request.method,
        headers: request.headers,
        body: request.body
      });
      
      const response = await fetch(githubRequest);
      const modifiedResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: {
          ...Object.fromEntries(response.headers),
          ...corsHeaders,
          'X-Powered-By': 'Cloudflare + GitHub Pages'
        }
      });
      
      return modifiedResponse;
    }

    return new Response('Not Found', { status: 404 });
  }
};

async function handleAPIRequest(request, env, corsHeaders) {
  const url = new URL(request.url);
  
  try {
    // Handle different API endpoints
    if (url.pathname === '/api/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        platform: 'cloudflare-worker'
      }), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      });
    }
    
    if (url.pathname === '/api/trading/status') {
      return new Response(JSON.stringify({
        trading_active: false,
        demo_mode: true,
        platform: 'github-pages'
      }), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      });
    }
    
    // Proxy to main API if available
    const apiURL = 'https://your-repl-name.replit.app' + url.pathname;
    const response = await fetch(apiURL, {
      method: request.method,
      headers: request.headers,
      body: request.body
    });
    
    return new Response(response.body, {
      status: response.status,
      headers: {
        ...Object.fromEntries(response.headers),
        ...corsHeaders
      }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'API temporarily unavailable',
      message: 'Fallback to demo mode'
    }), {
      status: 503,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      }
    });
  }
}`;

    await this.writeFile('cloudflare-worker.js', workerContent);
    console.log('⚡ Created Cloudflare Worker');
  }

  async generateDNSConfiguration() {
    const dnsConfig = {
      setup_instructions: {
        step1: "Log into Cloudflare Dashboard",
        step2: "Add reverb256.ca domain",
        step3: "Update nameservers at domain registrar",
        step4: "Configure DNS records below"
      },
      dns_records: [
        {
          type: "A",
          name: "@",
          value: "185.199.108.153",
          ttl: "Auto",
          proxied: true,
          comment: "GitHub Pages IP #1"
        },
        {
          type: "A", 
          name: "@",
          value: "185.199.109.153", 
          ttl: "Auto",
          proxied: true,
          comment: "GitHub Pages IP #2"
        },
        {
          type: "A",
          name: "@", 
          value: "185.199.110.153",
          ttl: "Auto", 
          proxied: true,
          comment: "GitHub Pages IP #3"
        },
        {
          type: "A",
          name: "@",
          value: "185.199.111.153",
          ttl: "Auto",
          proxied: true, 
          comment: "GitHub Pages IP #4"
        },
        {
          type: "CNAME",
          name: "www",
          value: "reverb256.ca",
          ttl: "Auto",
          proxied: true,
          comment: "WWW redirect to apex"
        },
        {
          type: "CNAME",
          name: "api",
          value: "reverb256.ca",
          ttl: "Auto", 
          proxied: true,
          comment: "API subdomain"
        },
        {
          type: "CNAME",
          name: "trading",
          value: "reverb256.ca",
          ttl: "Auto",
          proxied: true,
          comment: "Trading subdomain"
        }
      ],
      github_custom_domain: {
        repository_setting: "reverb256.ca",
        cname_file_content: "reverb256.ca",
        enforce_https: true
      }
    };

    await this.writeFile('config/cloudflare-dns-config.json', JSON.stringify(dnsConfig, null, 2));
    console.log('📋 Generated DNS configuration');
  }

  async createCloudflarePageRules() {
    const pageRules = {
      rules: [
        {
          url: "reverb256.ca/api/*",
          settings: {
            cache_level: "bypass",
            ssl: "strict",
            security_level: "medium"
          },
          priority: 1
        },
        {
          url: "*.reverb256.ca/*",
          settings: {
            always_use_https: "on",
            cache_level: "cache_everything",
            edge_cache_ttl: 2592000,
            browser_cache_ttl: 86400
          },
          priority: 2
        },
        {
          url: "www.reverb256.ca/*",
          settings: {
            forwarding_url: {
              url: "https://reverb256.ca/$1",
              status_code: 301
            }
          },
          priority: 3
        }
      ],
      optimization: {
        auto_minify: {
          css: true,
          html: true,
          js: true
        },
        brotli: true,
        polish: "lossless",
        mirage: true,
        rocket_loader: true
      }
    };

    await this.writeFile('config/cloudflare-page-rules.json', JSON.stringify(pageRules, null, 2));
    console.log('⚙️ Created page rules configuration');
  }

  async setupSSLConfiguration() {
    const sslConfig = {
      ssl_mode: "full_strict",
      always_use_https: true,
      hsts: {
        enabled: true,
        max_age: 31536000,
        include_subdomains: true,
        preload: true
      },
      min_tls_version: "1.2",
      automatic_https_rewrites: true,
      certificate_transparency_monitoring: true
    };

    await this.writeFile('config/cloudflare-ssl-config.json', JSON.stringify(sslConfig, null, 2));
    console.log('🔒 Created SSL configuration');
  }

  async createDeploymentGuide() {
    const guide = `# Cloudflare + GitHub Pages Setup Guide

## Prerequisites
- GitHub repository with static build
- Cloudflare account (free tier sufficient)
- Domain name (reverb256.ca)

## Step 1: GitHub Repository Setup

1. Enable GitHub Pages in repository settings
2. Set source to "GitHub Actions"
3. Add CNAME file with domain: \`reverb256.ca\`
4. Configure custom domain: \`reverb256.ca\`

## Step 2: Cloudflare Domain Setup

1. Add \`reverb256.ca\` to Cloudflare
2. Update nameservers at domain registrar to:
   - \`helena.ns.cloudflare.com\`
   - \`walt.ns.cloudflare.com\`

## Step 3: DNS Records Configuration

Add these DNS records in Cloudflare:

### A Records (GitHub Pages IPs)
\`\`\`
Type: A, Name: @, Value: 185.199.108.153, Proxied: Yes
Type: A, Name: @, Value: 185.199.109.153, Proxied: Yes  
Type: A, Name: @, Value: 185.199.110.153, Proxied: Yes
Type: A, Name: @, Value: 185.199.111.153, Proxied: Yes
\`\`\`

### CNAME Records
\`\`\`
Type: CNAME, Name: www, Value: reverb256.ca, Proxied: Yes
Type: CNAME, Name: api, Value: reverb256.ca, Proxied: Yes
Type: CNAME, Name: trading, Value: reverb256.ca, Proxied: Yes
\`\`\`

## Step 4: Cloudflare Page Rules

1. \`reverb256.ca/api/*\` - Cache Level: Bypass, SSL: Strict
2. \`*.reverb256.ca/*\` - Always Use HTTPS, Cache Everything
3. \`www.reverb256.ca/*\` - Redirect to https://reverb256.ca/$1

## Step 5: SSL/TLS Configuration

- SSL/TLS encryption mode: Full (strict)
- Always Use HTTPS: On
- HSTS: Enabled (6 months)
- Minimum TLS Version: 1.2

## Step 6: GitHub Secrets

Add these secrets to your GitHub repository:

\`\`\`
CLOUDFLARE_API_TOKEN=your_api_token
CLOUDFLARE_ZONE_ID=your_zone_id
\`\`\`

## Step 7: Worker Deployment

Deploy the Cloudflare Worker:
\`\`\`bash
npm install -g wrangler
wrangler login
wrangler deploy cloudflare-worker.js
\`\`\`

## Step 8: Verification

1. Check DNS propagation: \`dig reverb256.ca\`
2. Verify SSL: \`curl -I https://reverb256.ca\`
3. Test API routing: \`curl https://api.reverb256.ca/health\`

## Performance Optimizations

- Brotli compression: Enabled
- Auto minification: CSS, HTML, JS
- Polish: Lossless image optimization
- Rocket Loader: Async JS loading
- Browser caching: 24 hours
- Edge caching: 30 days

## Monitoring

- Cloudflare Analytics: Traffic and performance
- Core Web Vitals: Speed metrics
- Security events: Threat monitoring
- Cache hit ratio: Performance tracking

Your site will be available at:
- Primary: https://reverb256.ca
- API: https://api.reverb256.ca
- Trading: https://trading.reverb256.ca

The setup provides enterprise-grade performance with global CDN distribution while remaining on Cloudflare's free tier.`;

    await this.writeFile('docs/deployment/CLOUDFLARE_GITHUB_PAGES_SETUP.md', guide);
    console.log('📖 Created deployment guide');
  }

  async writeFile(filePath, content) {
    const dir = path.dirname(filePath);
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(filePath, content);
  }
}

// Execute setup
const setup = new CloudflareGitHubPagesSetup();
setup.setupComplete().catch(console.error);
