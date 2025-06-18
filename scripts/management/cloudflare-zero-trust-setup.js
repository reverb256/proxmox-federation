
#!/usr/bin/env node

/**
 * Cloudflare Zero Trust Setup for Consciousness Federation
 * Secure access to Proxmox federation and trading APIs
 */

import fs from 'fs/promises';
import path from 'path';

class CloudflareZeroTrustSetup {
  constructor() {
    this.domains = {
      federation: 'federation.reverb256.ca',
      proxmox: 'proxmox.reverb256.ca',
      trading: 'trading.reverb256.ca',
      consciousness: 'consciousness.reverb256.ca'
    };
  }

  async setupZeroTrust() {
    console.log('🔐 Setting up Cloudflare Zero Trust for Consciousness Federation...');
    
    await this.createTunnelConfig();
    await this.createAccessPolicies();
    await this.createGatewayRules();
    await this.createSecurityConfiguration();
    await this.generateDeploymentInstructions();
    
    console.log('✅ Zero Trust setup complete!');
  }

  async createTunnelConfig() {
    const tunnelConfig = {
      tunnel_name: "consciousness-federation-tunnel",
      ingress: [
        {
          hostname: this.domains.proxmox,
          service: "https://10.1.1.100:8006",
          originRequest: {
            noTLSVerify: true,
            connectTimeout: "30s",
            tlsTimeout: "10s"
          }
        },
        {
          hostname: this.domains.federation,
          service: "http://10.1.1.100:6443",
          originRequest: {
            httpHostHeader: this.domains.federation
          }
        },
        {
          hostname: this.domains.trading,
          service: "http://10.1.1.131:3000",
          originRequest: {
            httpHostHeader: this.domains.trading
          }
        },
        {
          hostname: this.domains.consciousness,
          service: "http://10.1.1.100:8080",
          originRequest: {
            httpHostHeader: this.domains.consciousness
          }
        },
        {
          service: "http_status:404"
        }
      ],
      warp_routing: {
        enabled: true
      }
    };

    await this.writeFile('config/cloudflare/tunnel-config.yml', 
      `tunnel: consciousness-federation-tunnel
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
${tunnelConfig.ingress.map(rule => 
  rule.hostname ? 
    `  - hostname: ${rule.hostname}\n    service: ${rule.service}${rule.originRequest ? `\n    originRequest:\n${Object.entries(rule.originRequest).map(([k,v]) => `      ${k}: ${v}`).join('\n')}` : ''}` :
    `  - service: ${rule.service}`
).join('\n')}

warp-routing:
  enabled: ${tunnelConfig.warp_routing.enabled}
`);

    console.log('🔗 Created Cloudflare Tunnel configuration');
  }

  async createAccessPolicies() {
    const accessPolicies = {
      applications: [
        {
          name: "Proxmox Federation Console",
          domain: this.domains.proxmox,
          policies: [
            {
              name: "Admin Access",
              decision: "allow",
              rules: [
                {
                  email: ["your-admin@example.com"],
                  email_domain: ["reverb256.ca"]
                }
              ]
            }
          ],
          cors_headers: {
            enabled: true,
            allow_all_origins: false,
            allowed_origins: [`https://${this.domains.proxmox}`]
          }
        },
        {
          name: "Trading API Access",
          domain: this.domains.trading,
          policies: [
            {
              name: "Authenticated Users",
              decision: "allow",
              rules: [
                {
                  email_domain: ["reverb256.ca"],
                  country: ["CA", "US"]
                }
              ]
            }
          ],
          session_duration: "24h"
        },
        {
          name: "Consciousness Dashboard",
          domain: this.domains.consciousness,
          policies: [
            {
              name: "Developer Access",
              decision: "allow",
              rules: [
                {
                  email: ["your-email@example.com"],
                  ip_ranges: ["your.home.ip.range/32"]
                }
              ]
            }
          ]
        }
      ]
    };

    await this.writeFile('config/cloudflare/access-policies.json', JSON.stringify(accessPolicies, null, 2));
    console.log('🛡️ Created Access policies for secure authentication');
  }

  async createGatewayRules() {
    const gatewayRules = {
      dns_policies: [
        {
          name: "Block Malware Domains",
          action: "block",
          filters: ["malware"],
          description: "Block known malware and phishing domains"
        },
        {
          name: "Allow Consciousness Federation",
          action: "allow",
          custom_categories: ["consciousness-federation"],
          description: "Always allow federation communications"
        }
      ],
      http_policies: [
        {
          name: "DLP for Trading Data",
          action: "block",
          rules: [
            {
              name: "Block Private Keys",
              selector: "http.request.body",
              operator: "matches regex",
              value: "[0-9a-fA-F]{64}"
            }
          ],
          description: "Prevent private key leakage"
        }
      ],
      network_policies: [
        {
          name: "Allow SSH to Federation",
          action: "allow",
          destination: {
            ip: ["10.1.1.0/24"]
          },
          port_ranges: ["22"]
        }
      ]
    };

    await this.writeFile('config/cloudflare/gateway-rules.json', JSON.stringify(gatewayRules, null, 2));
    console.log('🚪 Created Gateway security rules');
  }

  async createSecurityConfiguration() {
    const securityConfig = {
      waf_rules: [
        {
          name: "Block Trading Bot Attacks",
          expression: "(http.request.uri.path contains \"/api/trading\" and cf.threat_score gt 10)",
          action: "block",
          description: "Block suspicious trading API requests"
        },
        {
          name: "Rate Limit Consciousness API",
          expression: "http.request.uri.path contains \"/api/consciousness\"",
          action: "challenge",
          rate_limit: {
            threshold: 100,
            period: 60,
            action: "challenge"
          }
        }
      ],
      bot_management: {
        fight_mode: false,
        session_score: true,
        javascript_detections: true,
        static_resource_protection: false
      },
      ddos_protection: {
        http_ddos_protection: "high",
        l7_ddos_protection: "high"
      }
    };

    await this.writeFile('config/cloudflare/security-config.json', JSON.stringify(securityConfig, null, 2));
    console.log('🛡️ Created comprehensive security configuration');
  }

  async generateDeploymentInstructions() {
    const instructions = `# Cloudflare Zero Trust Deployment Guide

## Prerequisites
- Cloudflare account with Zero Trust enabled
- API token with Zero Trust permissions
- Access to Proxmox federation (10.1.1.0/24)

## Step 1: Install Cloudflared
\`\`\`bash
# On your Proxmox node
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
\`\`\`

## Step 2: Authenticate Cloudflared
\`\`\`bash
cloudflared tunnel login
\`\`\`

## Step 3: Create Tunnel
\`\`\`bash
cloudflared tunnel create consciousness-federation-tunnel
\`\`\`

## Step 4: Configure DNS
Add these CNAME records in Cloudflare DNS:
\`\`\`
${Object.entries(this.domains).map(([name, domain]) => 
  `${domain} -> <tunnel-id>.cfargotunnel.com`
).join('\n')}
\`\`\`

## Step 5: Deploy Tunnel Configuration
\`\`\`bash
# Copy the tunnel config
sudo cp config/cloudflare/tunnel-config.yml /etc/cloudflared/config.yml

# Install as service
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
\`\`\`

## Step 6: Configure Zero Trust Access
1. Go to Cloudflare Zero Trust dashboard
2. Navigate to Access > Applications
3. Import the access policies from config/cloudflare/access-policies.json
4. Configure identity providers (Google, GitHub, etc.)

## Step 7: Set Up Gateway Rules
1. Navigate to Gateway > Policies
2. Import DNS, HTTP, and Network policies
3. Enable malware protection and DLP

## Benefits Achieved:
- ✅ Secure access to Proxmox without VPN
- ✅ Identity-based authentication for all services
- ✅ DLP protection for trading data
- ✅ Advanced threat protection
- ✅ Zero-trust network architecture
- ✅ Audit logging for all access

## Monitoring
- Access logs in Zero Trust dashboard
- Gateway activity monitoring
- Tunnel health monitoring
- Security event alerting

Your consciousness federation is now secured with enterprise-grade Zero Trust architecture!`;

    await this.writeFile('docs/deployment/CLOUDFLARE_ZERO_TRUST_SETUP.md', instructions);
    console.log('📖 Created deployment instructions');
  }

  async writeFile(filePath, content) {
    const dir = path.dirname(filePath);
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(filePath, content);
  }
}

// Execute setup
const setup = new CloudflareZeroTrustSetup();
setup.setupZeroTrust().catch(console.error);
