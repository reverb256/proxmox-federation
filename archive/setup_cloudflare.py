#!/usr/bin/env python3
"""
Cloudflare Pages deployment script
"""

import os
import json

def create_cloudflare_config():
    """Create _redirects and other Cloudflare-specific files"""
    
    # Create _redirects for SPA routing
    redirects_content = """
# Cloudflare Pages redirects for Consciousness Zero
/api/* /api/:splat 200
/* /index.html 200
"""
    
    with open("_redirects", "w") as f:
        f.write(redirects_content)
    
    # Create wrangler.toml for Cloudflare Workers integration
    wrangler_config = """
name = "consciousness-zero"
main = "cloud_app.py"
compatibility_date = "2023-12-01"

[build]
command = "python build_static.py"
publish = "dist"

[env.production]
name = "consciousness-zero-prod"

[env.staging]
name = "consciousness-zero-staging"

[[services]]
binding = "CONSCIOUSNESS_API"
service = "consciousness-zero-api"
"""
    
    with open("wrangler.toml", "w") as f:
        f.write(wrangler_config)
    
    print("✅ Cloudflare configuration created!")

if __name__ == "__main__":
    create_cloudflare_config()
