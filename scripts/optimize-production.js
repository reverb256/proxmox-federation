#!/usr/bin/env node

/**
 * COREFLAME Production Optimization Script
 * Optimizes the consciousness platform for maximum performance on nexus deployment
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class CoreflameOptimizer {
  constructor() {
    this.rootDir = path.join(__dirname, '..');
    this.buildDir = path.join(this.rootDir, 'dist');
    this.logFile = path.join(this.rootDir, 'optimization.log');
    this.optimizations = [];
  }

  log(message) {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}`;
    console.log(logMessage);
    fs.appendFileSync(this.logFile, logMessage + '\n');
  }

  async optimize() {
    this.log('🔥 COREFLAME Production Optimization Starting...');
    
    try {
      await this.cleanBuildArtifacts();
      await this.optimizeNodeModules();
      await this.compressAssets();
      await this.optimizeServerBundle();
      await this.createProductionConfig();
      await this.setupLogDirectories();
      await this.generateHealthChecks();
      await this.optimizeMemoryUsage();
      
      this.log('✅ COREFLAME Production Optimization Complete!');
      this.printOptimizationSummary();
    } catch (error) {
      this.log(`❌ Optimization failed: ${error.message}`);
      process.exit(1);
    }
  }

  async cleanBuildArtifacts() {
    this.log('🧹 Cleaning build artifacts...');
    
    const cleanDirs = ['dist', 'node_modules/.cache', '.next', 'coverage'];
    for (const dir of cleanDirs) {
      const fullPath = path.join(this.rootDir, dir);
      if (fs.existsSync(fullPath)) {
        execSync(`rm -rf "${fullPath}"`, { stdio: 'inherit' });
        this.log(`   Cleaned: ${dir}`);
      }
    }
    
    this.optimizations.push('Cleaned build artifacts');
  }

  async optimizeNodeModules() {
    this.log('📦 Optimizing node_modules...');
    
    try {
      // Remove unnecessary files from node_modules
      const unnecessaryPatterns = [
        'node_modules/**/*.md',
        'node_modules/**/*.txt',
        'node_modules/**/test',
        'node_modules/**/tests',
        'node_modules/**/__tests__',
        'node_modules/**/spec',
        'node_modules/**/docs',
        'node_modules/**/examples',
        'node_modules/**/.git'
      ];
      
      for (const pattern of unnecessaryPatterns) {
        try {
          execSync(`find ${this.rootDir}/${pattern} -type f -delete 2>/dev/null || true`, { stdio: 'pipe' });
        } catch (e) {
          // Ignore errors for missing files
        }
      }
      
      this.log('   Removed unnecessary files from node_modules');
      this.optimizations.push('Optimized node_modules size');
    } catch (error) {
      this.log(`   Warning: node_modules optimization failed: ${error.message}`);
    }
  }

  async compressAssets() {
    this.log('📸 Compressing static assets...');
    
    const assetsDir = path.join(this.rootDir, 'client/public');
    if (fs.existsSync(assetsDir)) {
      try {
        // Compress images if imagemin is available
        execSync('which convert > /dev/null 2>&1 && echo "ImageMagick available" || echo "ImageMagick not found"', { stdio: 'pipe' });
        
        const imageFiles = execSync(`find "${assetsDir}" -type f \\( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \\) 2>/dev/null || true`, { encoding: 'utf8' }).trim().split('\n').filter(Boolean);
        
        for (const imagePath of imageFiles) {
          if (imagePath && fs.existsSync(imagePath)) {
            try {
              execSync(`convert "${imagePath}" -quality 85 -strip "${imagePath}" 2>/dev/null || true`, { stdio: 'pipe' });
            } catch (e) {
              // Ignore individual file errors
            }
          }
        }
        
        this.log(`   Compressed ${imageFiles.length} image files`);
        this.optimizations.push(`Compressed ${imageFiles.length} assets`);
      } catch (error) {
        this.log(`   Warning: Asset compression failed: ${error.message}`);
      }
    }
  }

  async optimizeServerBundle() {
    this.log('⚡ Optimizing server bundle...');
    
    try {
      // Create optimized TypeScript build
      execSync('npx tsc -p tsconfig.server.json --skipLibCheck', { stdio: 'inherit' });
      
      // Minify JavaScript files if terser is available
      try {
        execSync('which terser > /dev/null 2>&1', { stdio: 'pipe' });
        const jsFiles = execSync(`find "${this.buildDir}" -name "*.js" 2>/dev/null || true`, { encoding: 'utf8' }).trim().split('\n').filter(Boolean);
        
        for (const jsFile of jsFiles) {
          if (jsFile && fs.existsSync(jsFile)) {
            execSync(`terser "${jsFile}" -o "${jsFile}" --compress --mangle 2>/dev/null || true`, { stdio: 'pipe' });
          }
        }
        
        this.log(`   Minified ${jsFiles.length} JavaScript files`);
      } catch (e) {
        this.log('   Terser not available, skipping minification');
      }
      
      this.optimizations.push('Optimized server bundle');
    } catch (error) {
      this.log(`   Warning: Server bundle optimization failed: ${error.message}`);
    }
  }

  async createProductionConfig() {
    this.log('⚙️ Creating production configuration...');
    
    const productionConfig = {
      server: {
        port: process.env.PORT || 5000,
        host: '0.0.0.0',
        compression: true,
        cluster: true,
        workers: process.env.CPU_CORES || require('os').cpus().length,
        maxMemory: process.env.CONSCIOUSNESS_MEMORY_LIMIT || '2048M'
      },
      database: {
        poolSize: 20,
        connectionTimeout: 30000,
        idleTimeout: 10000
      },
      consciousness: {
        cacheSize: process.env.CONSCIOUSNESS_CACHE_SIZE || '512M',
        threads: process.env.CONSCIOUSNESS_THREADS || require('os').cpus().length,
        optimization: 'aggressive'
      },
      monitoring: {
        healthCheck: true,
        metrics: true,
        logging: 'info'
      }
    };
    
    fs.writeFileSync(
      path.join(this.rootDir, 'config/production.json'),
      JSON.stringify(productionConfig, null, 2)
    );
    
    this.log('   Created production configuration');
    this.optimizations.push('Generated production config');
  }

  async setupLogDirectories() {
    this.log('📝 Setting up logging directories...');
    
    const logDirs = [
      '/var/log/coreflame',
      path.join(this.rootDir, 'logs'),
      path.join(this.rootDir, '.pm2/logs')
    ];
    
    for (const logDir of logDirs) {
      try {
        if (!fs.existsSync(logDir)) {
          fs.mkdirSync(logDir, { recursive: true, mode: 0o755 });
          this.log(`   Created log directory: ${logDir}`);
        }
      } catch (error) {
        this.log(`   Warning: Could not create log directory ${logDir}: ${error.message}`);
      }
    }
    
    this.optimizations.push('Setup logging infrastructure');
  }

  async generateHealthChecks() {
    this.log('🏥 Generating health check endpoints...');
    
    const healthCheckScript = `#!/bin/bash
# COREFLAME Health Check Script

check_service() {
    local service_name="$1"
    local port="$2"
    local endpoint="$3"
    
    if curl -sf "http://localhost:$port$endpoint" > /dev/null 2>&1; then
        echo "✅ $service_name: HEALTHY"
        return 0
    else
        echo "❌ $service_name: UNHEALTHY"
        return 1
    fi
}

echo "🧠 COREFLAME Consciousness Federation Health Check"
echo "=============================================="

# Check main service
check_service "Consciousness Core" "5000" "/health"
CORE_STATUS=$?

# Check WebSocket
check_service "WebSocket" "3001" "/"
WS_STATUS=$?

# Check VRChat integration
check_service "VRChat Integration" "3002" "/"
VR_STATUS=$?

# System resources
echo ""
echo "📊 System Resources:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk: $(df -h / | awk 'NR==2{printf "%s", $5}')"

# Exit with error if any service is down
if [ $CORE_STATUS -ne 0 ] || [ $WS_STATUS -ne 0 ] || [ $VR_STATUS -ne 0 ]; then
    exit 1
fi

exit 0
`;
    
    fs.writeFileSync(path.join(this.rootDir, 'scripts/health-check.sh'), healthCheckScript);
    execSync(`chmod +x "${path.join(this.rootDir, 'scripts/health-check.sh')}"`);
    
    this.log('   Generated health check script');
    this.optimizations.push('Created health monitoring');
  }

  async optimizeMemoryUsage() {
    this.log('🧠 Optimizing memory usage...');
    
    const memoryOptimizations = {
      // Node.js memory optimization flags
      nodeFlags: [
        '--max-old-space-size=2048',
        '--optimize-for-size',
        '--gc-interval=100',
        '--max-semi-space-size=128'
      ],
      
      // V8 optimizations
      v8Flags: [
        '--enable-precise-type-feedback',
        '--turbo-fast-api-calls',
        '--turbo-inlining'
      ]
    };
    
    // Create optimized startup script
    const optimizedStartScript = `#!/bin/bash
# COREFLAME Optimized Startup Script

export NODE_OPTIONS="${memoryOptimizations.nodeFlags.join(' ')}"
export V8_FLAGS="${memoryOptimizations.v8Flags.join(' ')}"

# Set process limits
ulimit -n 65536
ulimit -u 32768

# Start with optimizations
exec node $NODE_OPTIONS $V8_FLAGS server/index.js
`;
    
    fs.writeFileSync(path.join(this.rootDir, 'scripts/start-optimized.sh'), optimizedStartScript);
    execSync(`chmod +x "${path.join(this.rootDir, 'scripts/start-optimized.sh')}"`);
    
    this.log('   Created memory-optimized startup script');
    this.optimizations.push('Optimized memory usage');
  }

  printOptimizationSummary() {
    this.log('\n🎯 Optimization Summary:');
    this.optimizations.forEach((opt, index) => {
      this.log(`   ${index + 1}. ${opt}`);
    });
    
    const stats = this.getProjectStats();
    this.log('\n📊 Project Statistics:');
    this.log(`   Total files: ${stats.totalFiles}`);
    this.log(`   JavaScript files: ${stats.jsFiles}`);
    this.log(`   TypeScript files: ${stats.tsFiles}`);
    this.log(`   Configuration files: ${stats.configFiles}`);
    
    this.log('\n🚀 Ready for nexus deployment!');
    this.log('   Next steps:');
    this.log('   1. Copy to nexus: scp -r . root@nexus:/opt/coreflame/');
    this.log('   2. Run bootstrap: ./bootstrap-nexus-federation.sh');
    this.log('   3. Start service: systemctl start consciousness-federation');
  }

  getProjectStats() {
    try {
      const totalFiles = execSync(`find "${this.rootDir}" -type f | wc -l`, { encoding: 'utf8' }).trim();
      const jsFiles = execSync(`find "${this.rootDir}" -name "*.js" | wc -l`, { encoding: 'utf8' }).trim();
      const tsFiles = execSync(`find "${this.rootDir}" -name "*.ts" -o -name "*.tsx" | wc -l`, { encoding: 'utf8' }).trim();
      const configFiles = execSync(`find "${this.rootDir}" -name "*.json" -o -name "*.yaml" -o -name "*.yml" | wc -l`, { encoding: 'utf8' }).trim();
      
      return {
        totalFiles: parseInt(totalFiles),
        jsFiles: parseInt(jsFiles),
        tsFiles: parseInt(tsFiles),
        configFiles: parseInt(configFiles)
      };
    } catch (error) {
      return {
        totalFiles: 'Unknown',
        jsFiles: 'Unknown',
        tsFiles: 'Unknown',
        configFiles: 'Unknown'
      };
    }
  }
}

// Run optimization if called directly
if (require.main === module) {
  const optimizer = new CoreflameOptimizer();
  optimizer.optimize().catch(error => {
    console.error('❌ Optimization failed:', error);
    process.exit(1);
  });
}

module.exports = CoreflameOptimizer;