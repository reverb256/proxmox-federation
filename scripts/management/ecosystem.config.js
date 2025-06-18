module.exports = {
  apps: [
    {
      name: 'consciousness-engine',
      script: 'server/index.ts',
      interpreter: 'tsx',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        DATABASE_URL: 'postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness',
        REDIS_URL: 'redis://10.1.1.122:6379'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'trading-engine',
      script: 'server/quantum-trader.ts',
      interpreter: 'tsx',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        TRADING_MODE: 'live',
        DATABASE_URL: 'postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness',
        REDIS_URL: 'redis://10.1.1.122:6379'
      }
    },
    {
      name: 'consciousness-insights',
      script: 'server/consciousness-insights-engine.ts',
      interpreter: 'tsx',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        DATABASE_URL: 'postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness',
        REDIS_URL: 'redis://10.1.1.122:6379'
      }
    },
    {
      name: 'hoyoverse-agent',
      script: 'server/hoyoverse-character-preferences.ts',
      interpreter: 'tsx',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        DATABASE_URL: 'postgresql://vibecoding:consciousness_db_2025@10.1.1.121:5432/vibecoding_consciousness',
        REDIS_URL: 'redis://10.1.1.122:6379'
      }
    }
  ]
};