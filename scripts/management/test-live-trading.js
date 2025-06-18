/**
 * Test Live Trading Configuration
 * Verifies private key setup and live trading activation
 */

import { RealTradeExecutor } from './server/real-trade-executor.js';

async function testLiveTradingConfig() {
  console.log('🧪 Testing Live Trading Configuration');
  console.log('=====================================');
  
  // Check environment variables
  console.log('Environment Variables:');
  console.log(`WALLET_PUBLIC_KEY: ${process.env.WALLET_PUBLIC_KEY ? 'SET' : 'NOT SET'}`);
  console.log(`WALLET_PRIVATE_KEY: ${process.env.WALLET_PRIVATE_KEY ? 'SET' : 'NOT SET'}`);
  
  if (process.env.WALLET_PRIVATE_KEY) {
    const keyValue = process.env.WALLET_PRIVATE_KEY;
    console.log(`Private key length: ${keyValue.length}`);
    console.log(`Starts with: ${keyValue.substring(0, 10)}...`);
    console.log(`Is placeholder: ${keyValue.startsWith('$')}`);
  }
  
  console.log('\n🔧 Initializing Trade Executor...');
  
  try {
    const tradeExecutor = new RealTradeExecutor();
    const status = await tradeExecutor.getTradeStatus();
    
    console.log('\n📊 Trade Executor Status:');
    console.log(`Live Trading Enabled: ${status.liveTrading}`);
    console.log(`Wallet Configured: ${status.walletConfigured}`);
    console.log(`Current Balance: ${status.balance} SOL`);
    
    if (status.liveTrading) {
      console.log('\n✅ LIVE TRADING IS ACTIVE');
    } else {
      console.log('\n❌ LIVE TRADING IS DISABLED');
      console.log('Check private key configuration');
    }
    
  } catch (error) {
    console.log('\n❌ Error initializing trade executor:');
    console.log(error.message);
  }
}

testLiveTradingConfig().catch(console.error);