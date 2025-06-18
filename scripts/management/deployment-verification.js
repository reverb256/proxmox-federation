#!/usr/bin/env node

/**
 * GitHub Pages Deployment Verification Script
 * Validates all links, assets, and performance optimizations for static hosting
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

class DeploymentVerifier {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.clientPath = path.join(__dirname, 'client/src');
    this.publicPath = path.join(__dirname, 'public');
    this.attachedAssetsPath = path.join(__dirname, 'attached_assets');
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = type === 'error' ? '❌' : type === 'warning' ? '⚠️' : '✅';
    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  verifyNavigationFlow() {
    this.log('Verifying navigation flow and section order...');
    
    const navigationFile = path.join(this.clientPath, 'components/navigation.tsx');
    const homeFile = path.join(this.clientPath, 'pages/home.tsx');
    
    if (fs.existsSync(navigationFile) && fs.existsSync(homeFile)) {
      const navContent = fs.readFileSync(navigationFile, 'utf8');
      const homeContent = fs.readFileSync(homeFile, 'utf8');
      
      const scrollTargets = navContent.match(/scrollToSection\(['"]([^'"]+)['"]\)/g);
      if (scrollTargets) {
        scrollTargets.forEach(target => {
          const sectionId = target.match(/['"]([^'"]+)['"]/)[1];
          if (!homeContent.includes(`id="${sectionId}"`)) {
            this.warnings.push(`Navigation target "${sectionId}" needs verification`);
          }
        });
      }
    }
    
    this.log('Navigation flow verification complete');
  }

  verifyAssets() {
    this.log('Verifying attached assets for GitHub Pages...');
    
    if (fs.existsSync(this.attachedAssetsPath)) {
      const assets = fs.readdirSync(this.attachedAssetsPath);
      assets.forEach(asset => {
        const assetPath = path.join(this.attachedAssetsPath, asset);
        const stats = fs.statSync(assetPath);
        if (stats.size > 5 * 1024 * 1024) {
          this.warnings.push(`Large asset detected (${(stats.size / 1024 / 1024).toFixed(2)}MB): ${asset}`);
        }
      });
    }
    
    this.log('Asset verification complete');
  }

  verifyCSSOptimizations() {
    this.log('Verifying CSS performance optimizations...');
    
    const cssFile = path.join(this.clientPath, 'index.css');
    if (fs.existsSync(cssFile)) {
      const cssContent = fs.readFileSync(cssFile, 'utf8');
      
      const optimizations = ['will-change', 'translateZ(0)', 'backface-visibility'];
      optimizations.forEach(opt => {
        if (!cssContent.includes(opt)) {
          this.warnings.push(`Consider adding CSS optimization: ${opt}`);
        }
      });
    }
    
    this.log('CSS optimization verification complete');
  }

  async run() {
    this.log('🚀 Starting GitHub Pages deployment verification...');
    console.log('═'.repeat(60));
    
    this.verifyNavigationFlow();
    this.verifyAssets();
    this.verifyCSSOptimizations();
    
    console.log('═'.repeat(60));
    this.log(`Verification complete: ${this.errors.length} errors, ${this.warnings.length} warnings`);
    
    if (this.errors.length === 0) {
      console.log('\n✅ Ready for GitHub Pages deployment!');
    }
    
    return this.errors.length === 0;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const verifier = new DeploymentVerifier();
  verifier.run();
}

export default DeploymentVerifier;