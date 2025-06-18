#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

console.log('Fixing deployment structure...');

// Check if dist/public exists and move files to dist root
const publicPath = path.join(__dirname, 'dist', 'public');
const distPath = path.join(__dirname, 'dist');

if (fs.existsSync(publicPath)) {
  console.log('Moving files from dist/public to dist root...');
  
  const items = fs.readdirSync(publicPath);
  for (const item of items) {
    const source = path.join(publicPath, item);
    const dest = path.join(distPath, item);
    
    if (fs.existsSync(dest)) {
      fs.rmSync(dest, { recursive: true, force: true });
    }
    
    if (fs.statSync(source).isDirectory()) {
      fs.cpSync(source, dest, { recursive: true });
    } else {
      fs.copyFileSync(source, dest);
    }
  }
  
  fs.rmSync(publicPath, { recursive: true, force: true });
  console.log('Files moved successfully');
}

// Create _redirects for SPA routing
fs.writeFileSync(path.join(distPath, '_redirects'), '/*    /index.html   200\n');

// Create vercel.json
const vercelConfig = {
  "rewrites": [{"source": "/(.*)", "destination": "/index.html"}]
};
fs.writeFileSync(path.join(distPath, 'vercel.json'), JSON.stringify(vercelConfig, null, 2));

// Create 404.html for GitHub Pages
const html404 = `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Redirecting</title>
<script>
var l=window.location;
l.replace(l.protocol+'//'+l.hostname+(l.port?':'+l.port:'')+
l.pathname.split('/').slice(0,1).join('/')+'/?/'+
l.pathname.slice(1).split('/').join('/').replace(/&/g,'~and~')+
(l.search?'&'+l.search.slice(1).replace(/&/g,'~and~'):'')+l.hash);
</script></head><body></body></html>`;
fs.writeFileSync(path.join(distPath, '404.html'), html404);

console.log('Deployment configuration complete');
console.log('Ready for: Netlify, Vercel, GitHub Pages, Cloudflare Pages');