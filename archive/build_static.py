#!/usr/bin/env python3
"""
Build static version for GitHub Pages
"""

import os
import shutil
from pathlib import Path

def build_static():
    """Build static files for GitHub Pages"""
    
    # Create dist directory
    dist_dir = Path("dist")
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    dist_dir.mkdir()
    
    # Create index.html
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Consciousness Zero - Cloud Edition</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                margin: 0;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
                text-align: center;
            }
            .logo {
                font-size: 3em;
                margin-bottom: 0.5em;
            }
            .subtitle {
                font-size: 1.2em;
                opacity: 0.9;
                margin-bottom: 2em;
            }
            .deployments {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin: 2em 0;
            }
            .deployment-card {
                background: rgba(255, 255, 255, 0.1);
                padding: 20px;
                border-radius: 10px;
                backdrop-filter: blur(10px);
                transition: transform 0.3s ease;
            }
            .deployment-card:hover {
                transform: translateY(-5px);
            }
            .deployment-card h3 {
                margin-top: 0;
                color: #fff;
            }
            .deployment-link {
                display: inline-block;
                background: rgba(255, 255, 255, 0.2);
                color: white;
                text-decoration: none;
                padding: 10px 20px;
                border-radius: 5px;
                margin-top: 10px;
                transition: background 0.3s ease;
            }
            .deployment-link:hover {
                background: rgba(255, 255, 255, 0.3);
            }
            .features {
                margin: 3em 0;
                text-align: left;
            }
            .feature-list {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                list-style: none;
                padding: 0;
            }
            .feature-list li {
                background: rgba(255, 255, 255, 0.1);
                padding: 15px;
                border-radius: 8px;
                backdrop-filter: blur(5px);
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">🧠</div>
            <h1>Consciousness Zero</h1>
            <p class="subtitle">AI-Powered Multi-Cloud Infrastructure Orchestration</p>
            
            <div class="deployments">
                <div class="deployment-card">
                    <h3>🚀 Vercel</h3>
                    <p>Serverless deployment with edge optimization</p>
                    <a href="https://consciousness-zero.vercel.app" class="deployment-link">Launch on Vercel</a>
                </div>
                
                <div class="deployment-card">
                    <h3>☁️ Cloudflare Pages</h3>
                    <p>Global CDN with lightning-fast performance</p>
                    <a href="https://consciousness-zero.pages.dev" class="deployment-link">Launch on Cloudflare</a>
                </div>
                
                <div class="deployment-card">
                    <h3>📦 GitHub Pages</h3>
                    <p>Static hosting with continuous deployment</p>
                    <a href="#" class="deployment-link">Current Deployment</a>
                </div>
            </div>
            
            <div class="features">
                <h2>🛠️ Features</h2>
                <ul class="feature-list">
                    <li>🤖 AI Agent with Zero-inspired architecture</li>
                    <li>🔍 Advanced web search (SearXNG + Crawl4AI)</li>
                    <li>💰 Multi-chain crypto wallet support</li>
                    <li>🔐 Vaultwarden password management</li>
                    <li>📊 Real-time system monitoring</li>
                    <li>🌐 Global CDN deployment</li>
                    <li>⚡ Serverless auto-scaling</li>
                    <li>🔒 Enterprise security features</li>
                </ul>
            </div>
            
            <div>
                <h2>🚀 Quick Start</h2>
                <p>Choose any deployment above to start using Consciousness Zero immediately!</p>
                <p><strong>Global availability:</strong> <100ms latency worldwide</p>
            </div>
        </div>
        
        <script>
            // Add some interactivity
            document.querySelectorAll('.deployment-card').forEach(card => {
                card.addEventListener('mouseenter', () => {
                    card.style.transform = 'translateY(-5px) scale(1.02)';
                });
                card.addEventListener('mouseleave', () => {
                    card.style.transform = 'translateY(0) scale(1)';
                });
            });
        </script>
    </body>
    </html>
    """
    
    # Write index.html
    with open(dist_dir / "index.html", "w") as f:
        f.write(html_content)
    
    print("✅ Static site built successfully!")
    print("📁 Files in dist/ directory:")
    for file in dist_dir.glob("*"):
        print(f"  - {file.name}")

if __name__ == "__main__":
    build_static()
