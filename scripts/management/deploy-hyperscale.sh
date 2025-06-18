#!/bin/bash
# Automated Multi-Provider Deployment Script

echo "🚀 Starting hyperscale deployment..."

# Build optimized static assets
npm run build

# Deploy to Vercel
echo "📦 Deploying to Vercel..."
vercel --prod

# Deploy to Netlify
echo "📦 Deploying to Netlify..."
netlify deploy --prod --dir=client/dist

# Deploy to Cloudflare Pages
echo "📦 Deploying to Cloudflare Pages..."
wrangler pages publish client/dist

# Commit to GitHub (triggers Pages deployment)
echo "📦 Deploying to GitHub Pages..."
git add .
git commit -m "Automated hyperscale deployment $(date)"
git push origin main

echo "✅ Hyperscale deployment complete!"
echo "🌐 Your app is now live on 4 global CDNs"
