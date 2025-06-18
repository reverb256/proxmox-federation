#!/usr/bin/env node

/**
 * Static Deployment Fix Script
 * Moves build files from dist/public to dist root for static deployment
 * Adds SPA routing configuration and optimizations
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

console.log('🔧 Fixing static deployment structure...');

try {
  const publicPath = path.join(__dirname, 'dist', 'public');
  const distPath = path.join(__dirname, 'dist');

  // Check if dist/public exists
  if (fs.existsSync(publicPath)) {
    console.log('📁 Moving files from dist/public to dist root...');
    
    // Get all files and directories in dist/public
    const items = fs.readdirSync(publicPath);
    
    for (const item of items) {
      const sourcePath = path.join(publicPath, item);
      const destPath = path.join(distPath, item);
      
      // Remove destination if it exists
      if (fs.existsSync(destPath)) {
        if (fs.statSync(destPath).isDirectory()) {
          fs.rmSync(destPath, { recursive: true, force: true });
        } else {
          fs.unlinkSync(destPath);
        }
      }
      
      // Move file or directory
      if (fs.statSync(sourcePath).isDirectory()) {
        fs.cpSync(sourcePath, destPath, { recursive: true });
      } else {
        fs.copyFileSync(sourcePath, destPath);
      }
    }
    
    // Remove the now-empty public directory
    fs.rmSync(publicPath, { recursive: true, force: true });
    console.log('✅ Files moved successfully from dist/public to dist');
  } else {
    console.log('ℹ️ No dist/public directory found, files already in correct location');
  }

  // Create _redirects file for SPA routing (Netlify/Vercel style)
  const redirectsContent = '/*    /index.html   200\n';
  fs.writeFileSync(path.join(distPath, '_redirects'), redirectsContent);
  console.log('📄 Created _redirects file for SPA routing');

  // Create vercel.json for Vercel deployments
  const vercelConfig = {
    "rewrites": [
      {
        "source": "/(.*)",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/(.*)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "/index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=0, must-revalidate"
          }
        ]
      }
    ]
  };
  fs.writeFileSync(path.join(distPath, 'vercel.json'), JSON.stringify(vercelConfig, null, 2));
  console.log('📄 Created vercel.json for Vercel deployments');

  // Create 404.html that redirects to index.html for GitHub Pages
  const githubPagesRedirect = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Quantum AI Trading Platform</title>
  <script type="text/javascript">
    // GitHub Pages SPA redirect
    var pathSegmentsToKeep = 0;
    var l = window.location;
    l.replace(
      l.protocol + '//' + l.hostname + (l.port ? ':' + l.port : '') +
      l.pathname.split('/').slice(0, 1 + pathSegmentsToKeep).join('/') + '/?/' +
      l.pathname.slice(1).split('/').slice(pathSegmentsToKeep).join('/').replace(/&/g, '~and~') +
      (l.search ? '&' + l.search.slice(1).replace(/&/g, '~and~') : '') +
      l.hash
    );
  </script>
</head>
<body>
</body>
</html>`;
  fs.writeFileSync(path.join(distPath, '404.html'), githubPagesRedirect);
  console.log('📄 Created 404.html for GitHub Pages SPA routing');

  // Update index.html to handle SPA routing
  const indexPath = path.join(distPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    let indexContent = fs.readFileSync(indexPath, 'utf8');
    
    // Add SPA routing script to handle GitHub Pages redirects
    const spaScript = `
  <script type="text/javascript">
    // GitHub Pages SPA redirect handling
    (function(l) {
      if (l.search[1] === '/' ) {
        var decoded = l.search.slice(1).split('&').map(function(s) { 
          return s.replace(/~and~/g, '&')
        }).join('?');
        window.history.replaceState(null, null,
            l.pathname.slice(0, -1) + decoded + l.hash
        );
      }
    }(window.location))
  </script>`;
    
    // Insert the script before the closing head tag
    if (indexContent.includes('</head>')) {
      indexContent = indexContent.replace('</head>', spaScript + '\n</head>');
      fs.writeFileSync(indexPath, indexContent);
      console.log('📄 Updated index.html with SPA routing support');
    }
  }

  // Create deployment status file
  const deploymentInfo = {
    timestamp: new Date().toISOString(),
    structure: 'static',
    spa_routing: true,
    platforms: ['netlify', 'vercel', 'github-pages', 'cloudflare-pages'],
    files_moved: fs.existsSync(path.join(__dirname, 'dist', 'public')) ? false : true
  };
  fs.writeFileSync(path.join(distPath, 'deployment-info.json'), JSON.stringify(deploymentInfo, null, 2));

  console.log('🎉 Static deployment structure fixed successfully!');
  console.log('📋 Deployment ready for:');
  console.log('   - Netlify (uses _redirects)');
  console.log('   - Vercel (uses vercel.json)');
  console.log('   - GitHub Pages (uses 404.html)');
  console.log('   - Cloudflare Pages (uses _redirects)');
  console.log('');
  console.log('✅ All files are now in the dist/ root directory');
  console.log('✅ SPA routing configured for all major platforms');

} catch (error) {
  console.error('❌ Error fixing deployment structure:', error);
  process.exit(1);
}