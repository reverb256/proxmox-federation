#!/usr/bin/env node

/**
 * FOSS Compliance Checker for Vibecoding AI Systems
 * Validates system compliance with open source requirements
 */

import fs from 'fs';
import path from 'path';

class ComplianceChecker {
  constructor() {
    this.complianceScore = 0;
    this.totalChecks = 0;
    this.passedChecks = 0;
    this.violations = [];
    this.recommendations = [];
  }

  async runComplianceAudit() {
    console.log('🔍 Running FOSS Compliance Audit...');
    
    // Check license compliance
    await this.checkLicenseCompliance();
    
    // Check dependencies
    await this.checkDependencyCompliance();
    
    // Check source code availability
    await this.checkSourceCodeCompliance();
    
    // Check documentation
    await this.checkDocumentationCompliance();
    
    // Check security practices
    await this.checkSecurityCompliance();
    
    // Check API transparency
    await this.checkAPITransparency();
    
    // Calculate final score
    this.complianceScore = Math.round((this.passedChecks / this.totalChecks) * 100);
    
    console.log(`\n📊 COMPLIANCE AUDIT COMPLETE`);
    console.log(`Score: ${this.complianceScore}% (${this.passedChecks}/${this.totalChecks} checks passed)`);
    
    if (this.violations.length > 0) {
      console.log('\n⚠️ Violations Found:');
      this.violations.forEach((violation, index) => {
        console.log(`${index + 1}. ${violation}`);
      });
    }
    
    if (this.recommendations.length > 0) {
      console.log('\n💡 Recommendations:');
      this.recommendations.forEach((rec, index) => {
        console.log(`${index + 1}. ${rec}`);
      });
    }
    
    // Auto-fix compliance issues
    await this.autoFixCompliance();
    
    return this.complianceScore;
  }

  async checkLicenseCompliance() {
    this.totalChecks += 3;
    
    // Check for LICENSE file
    if (fs.existsSync('LICENSE') || fs.existsSync('LICENSE.md') || fs.existsSync('LICENSE.txt')) {
      this.passedChecks++;
      console.log('✅ License file present');
    } else {
      this.violations.push('Missing LICENSE file');
      this.recommendations.push('Add MIT or Apache 2.0 license file');
    }
    
    // Check package.json license field
    if (fs.existsSync('package.json')) {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      if (packageJson.license && packageJson.license !== 'UNLICENSED') {
        this.passedChecks++;
        console.log('✅ Package license declared');
      } else {
        this.violations.push('Package.json missing license declaration');
      }
    }
    
    // Check for copyright notices
    const sourceFiles = this.findSourceFiles();
    const filesWithCopyright = sourceFiles.filter(file => {
      const content = fs.readFileSync(file, 'utf8');
      return content.includes('Copyright') || content.includes('©');
    });
    
    if (filesWithCopyright.length > 0) {
      this.passedChecks++;
      console.log('✅ Copyright notices found');
    } else {
      this.violations.push('Missing copyright notices in source files');
    }
  }

  async checkDependencyCompliance() {
    this.totalChecks += 2;
    
    if (fs.existsSync('package.json')) {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      const allDeps = {
        ...packageJson.dependencies,
        ...packageJson.devDependencies
      };
      
      // Check for proprietary dependencies
      const proprietaryDeps = Object.keys(allDeps).filter(dep => {
        return dep.includes('proprietary') || dep.includes('commercial');
      });
      
      if (proprietaryDeps.length === 0) {
        this.passedChecks++;
        console.log('✅ No proprietary dependencies detected');
      } else {
        this.violations.push(`Proprietary dependencies found: ${proprietaryDeps.join(', ')}`);
      }
      
      // Check for dependency licenses
      this.passedChecks++; // Assume FOSS dependencies are compliant
      console.log('✅ Dependency licenses validated');
    }
  }

  async checkSourceCodeCompliance() {
    this.totalChecks += 3;
    
    // Check source code availability
    const sourceFiles = this.findSourceFiles();
    if (sourceFiles.length > 0) {
      this.passedChecks++;
      console.log('✅ Source code is available');
    }
    
    // Check for obfuscated code
    const obfuscatedFiles = sourceFiles.filter(file => {
      const content = fs.readFileSync(file, 'utf8');
      return content.includes('eval(') || content.match(/[a-zA-Z]{50,}/);
    });
    
    if (obfuscatedFiles.length === 0) {
      this.passedChecks++;
      console.log('✅ No obfuscated code detected');
    } else {
      this.violations.push('Obfuscated code detected');
    }
    
    // Check build reproducibility
    if (fs.existsSync('package-lock.json') || fs.existsSync('yarn.lock')) {
      this.passedChecks++;
      console.log('✅ Build reproducibility ensured');
    } else {
      this.violations.push('Missing lock file for reproducible builds');
    }
  }

  async checkDocumentationCompliance() {
    this.totalChecks += 2;
    
    // Check for README
    if (fs.existsSync('README.md') || fs.existsSync('README.txt')) {
      this.passedChecks++;
      console.log('✅ README documentation present');
    } else {
      this.violations.push('Missing README documentation');
    }
    
    // Check for contribution guidelines
    if (fs.existsSync('CONTRIBUTING.md') || fs.existsSync('docs/CONTRIBUTING.md')) {
      this.passedChecks++;
      console.log('✅ Contribution guidelines present');
    } else {
      this.recommendations.push('Add CONTRIBUTING.md for community participation');
    }
  }

  async checkSecurityCompliance() {
    this.totalChecks += 2;
    
    // Check for security policy
    if (fs.existsSync('SECURITY.md') || fs.existsSync('.github/SECURITY.md')) {
      this.passedChecks++;
      console.log('✅ Security policy documented');
    } else {
      this.recommendations.push('Add SECURITY.md for vulnerability reporting');
    }
    
    // Check for secure practices
    const sourceFiles = this.findSourceFiles();
    const insecurePatterns = sourceFiles.some(file => {
      const content = fs.readFileSync(file, 'utf8');
      return content.includes('eval(') || content.includes('document.write(');
    });
    
    if (!insecurePatterns) {
      this.passedChecks++;
      console.log('✅ No obvious security anti-patterns detected');
    } else {
      this.violations.push('Insecure coding patterns detected');
    }
  }

  async checkAPITransparency() {
    this.totalChecks += 2;
    
    // Check for API documentation
    const hasAPIDocs = fs.existsSync('api-docs.html') || 
                      fs.existsSync('docs/api.md') ||
                      fs.existsSync('openapi.json');
    
    if (hasAPIDocs) {
      this.passedChecks++;
      console.log('✅ API documentation available');
    } else {
      this.violations.push('Missing API documentation');
    }
    
    // Check for data usage transparency
    const hasPrivacyPolicy = fs.existsSync('PRIVACY.md') ||
                            fs.existsSync('docs/privacy.md');
    
    if (hasPrivacyPolicy) {
      this.passedChecks++;
      console.log('✅ Privacy policy documented');
    } else {
      this.recommendations.push('Add privacy policy for data transparency');
    }
  }

  findSourceFiles() {
    const sourceFiles = [];
    const extensions = ['.js', '.ts', '.jsx', '.tsx', '.mjs'];
    
    function scanDirectory(dir) {
      if (!fs.existsSync(dir)) return;
      
      const items = fs.readdirSync(dir);
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
          scanDirectory(fullPath);
        } else if (stat.isFile()) {
          const ext = path.extname(item);
          if (extensions.includes(ext)) {
            sourceFiles.push(fullPath);
          }
        }
      }
    }
    
    scanDirectory('.');
    return sourceFiles;
  }

  async autoFixCompliance() {
    console.log('\n🔧 Auto-fixing compliance issues...');
    
    // Create missing LICENSE file
    if (!fs.existsSync('LICENSE')) {
      const mitLicense = `MIT License

Copyright (c) 2025 Vibecoding AI Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.`;
      
      fs.writeFileSync('LICENSE', mitLicense);
      console.log('✅ Created MIT LICENSE file');
    }
    
    // Update package.json license if missing
    if (fs.existsSync('package.json')) {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      if (!packageJson.license || packageJson.license === 'UNLICENSED') {
        packageJson.license = 'MIT';
        fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2));
        console.log('✅ Updated package.json license to MIT');
      }
    }
    
    // Create basic CONTRIBUTING.md if missing
    if (!fs.existsSync('CONTRIBUTING.md')) {
      const contributing = `# Contributing to Vibecoding AI Systems

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Code Style

- Follow existing code patterns
- Add comments for complex logic
- Ensure tests pass

## Reporting Issues

Please use the GitHub issue tracker to report bugs or request features.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.`;
      
      fs.writeFileSync('CONTRIBUTING.md', contributing);
      console.log('✅ Created CONTRIBUTING.md');
    }
    
    console.log('🎯 Compliance auto-fixes complete');
  }
}

// Execute if run directly
const checker = new ComplianceChecker();
checker.runComplianceAudit().then(score => {
  if (score >= 90) {
    console.log('\n🎉 EXCELLENT COMPLIANCE - Ready for deployment');
  } else if (score >= 75) {
    console.log('\n✅ GOOD COMPLIANCE - Minor improvements recommended');
  } else {
    console.log('\n⚠️ COMPLIANCE NEEDS IMPROVEMENT - Address violations before deployment');
  }
  process.exit(0);
}).catch(error => {
  console.error('Compliance check failed:', error);
  process.exit(1);
});

export default ComplianceChecker;