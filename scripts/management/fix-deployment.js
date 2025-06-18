#!/usr/bin/env node

/**
 * Deployment Fix Script
 * Moves build files from dist/public to dist for static deployment
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distPath = path.join(__dirname, 'dist');
const publicPath = path.join(distPath, 'public');

console.log('🔧 Fixing deployment structure...');

// Check if dist/public exists
if (fs.existsSync(publicPath)) {
  console.log('📁 Found dist/public directory');
  
  // Move all files from dist/public to dist
  const files = fs.readdirSync(publicPath);
  
  for (const file of files) {
    const sourcePath = path.join(publicPath, file);
    const destPath = path.join(distPath, file);
    
    console.log(`📦 Moving ${file} to dist/`);
    
    // Move file/directory
    fs.renameSync(sourcePath, destPath);
  }
  
  // Remove empty public directory
  fs.rmdirSync(publicPath);
  console.log('🗑️  Removed empty public directory');
  
  console.log('✅ Deployment structure fixed!');
} else {
  console.log('ℹ️  No dist/public directory found, nothing to fix');
}

// Create index.html if it doesn't exist (for SPA routing)
const indexPath = path.join(distPath, 'index.html');
if (!fs.existsSync(indexPath)) {
  console.log('⚠️  No index.html found in dist/');
  
  // Check if there's an index.html in any subdirectory
  const findIndexHtml = (dir) => {
    const items = fs.readdirSync(dir);
    for (const item of items) {
      const itemPath = path.join(dir, item);
      if (fs.statSync(itemPath).isDirectory()) {
        const result = findIndexHtml(itemPath);
        if (result) return result;
      } else if (item === 'index.html') {
        return itemPath;
      }
    }
    return null;
  };
  
  const foundIndex = findIndexHtml(distPath);
  if (foundIndex) {
    console.log(`📄 Found index.html at ${foundIndex}`);
    fs.copyFileSync(foundIndex, indexPath);
    console.log('📄 Copied index.html to dist/');
  }
}

console.log('🎉 Deployment fix complete!');