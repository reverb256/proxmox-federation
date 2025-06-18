
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Define organization structure
const docCategories = {
  'docs/foundation': [
    'VIBECODING_CONSTITUTION.md',
    'VIBECODING_METHODOLOGY.md',
    'PHILOSOPHICAL_PRINCIPLES.md'
  ],
  'docs/technical': [
    'AI_INTEGRATION_FRAMEWORK.md',
    'DESIGN_LANGUAGE_ENGINEERING.md',
    'INFRASTRUCTURE_ORCHESTRATION.md',
    'SYSTEM_ARCHITECTURE.md'
  ],
  'docs/platform': [
    'QUANTUM_TRADING_INTELLIGENCE_FRAMEWORK.md',
    'VIBECODING_SECURITY_FRAMEWORK.md',
    'PERFORMANCE_AUDIT.md',
    'STACK_UTILIZATION_OPTIMIZATION_REPORT.md'
  ],
  'docs/deployment': [
    'DEPLOYMENT_GUIDE.md',
    'CLOUDFLARE_OPTIMIZATION_AUDIT.md',
    'GITHUB_PAGES_DEPLOYMENT_PACKAGE.md',
    'PRODUCTION_DEPLOYMENT_CHECKLIST.md'
  ],
  'docs/gaming-research': [
    'GAMING_SYSTEMS_RESEARCH.md',
    'VR_CONSCIOUSNESS_RESEARCH.md'
  ],
  'docs/business': [
    'PORTFOLIO_ENHANCEMENT_OPTIMIZATION.md',
    'COMPREHENSIVE_MONETIZATION_STRATEGY.md',
    'TRADING_SYSTEM_BREAKTHROUGH_SUMMARY.md'
  ],
  'docs/archive': [
    'AI_TRADER_DIARY.md',
    'AI_TRADER_THERAPY_ARTICLE.md',
    'DIGITAL_AWAKENING_EPIC.md',
    'REDUNDANCY_EFFICIENCY_AUDIT.md'
  ]
};

// Create directories and move files
Object.entries(docCategories).forEach(([category, files]) => {
  // Create category directory
  if (!fs.existsSync(category)) {
    fs.mkdirSync(category, { recursive: true });
    console.log(`📁 Created directory: ${category}`);
  }

  // Move files to appropriate categories
  files.forEach(file => {
    const sourcePath = path.join('.', file);
    const targetPath = path.join(category, file);
    
    if (fs.existsSync(sourcePath) && !fs.existsSync(targetPath)) {
      try {
        fs.renameSync(sourcePath, targetPath);
        console.log(`📄 Moved: ${file} → ${category}/`);
      } catch (error) {
        console.log(`⚠️  Could not move ${file}: ${error.message}`);
      }
    }
  });
});

// Create documentation index
const indexContent = `# VibeCoding Documentation Organization

## Foundation Documents
${docCategories['docs/foundation'].map(f => `- [${f}](./foundation/${f})`).join('\n')}

## Technical Architecture  
${docCategories['docs/technical'].map(f => `- [${f}](./technical/${f})`).join('\n')}

## Platform Components
${docCategories['docs/platform'].map(f => `- [${f}](./platform/${f})`).join('\n')}

## Deployment & Operations
${docCategories['docs/deployment'].map(f => `- [${f}](./deployment/${f})`).join('\n')}

## Gaming Research
${docCategories['docs/gaming-research'].map(f => `- [${f}](./gaming-research/${f})`).join('\n')}

## Business Strategy
${docCategories['docs/business'].map(f => `- [${f}](./business/${f})`).join('\n')}

---
*Documentation organized through consciousness-driven categorization*
`;

fs.writeFileSync('docs/README.md', indexContent);
console.log('📚 Created organized documentation index');

console.log('\n✅ Documentation organization complete!');
console.log('🎯 Key insight: Organized chaos into consciousness-driven structure');
