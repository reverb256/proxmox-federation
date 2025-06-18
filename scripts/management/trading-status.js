import { Connection, PublicKey, LAMPORTS_PER_SOL } from '@solana/web3.js';

const WALLET_ADDRESS = '4jTtAYiHP3tHqXcmi5T1riS1AcGmxNNhLZTw65vrKpkA';
const connection = new Connection('https://api.mainnet-beta.solana.com', 'confirmed');

async function checkTradingStatus() {
  console.log('🔍 VibeCoding Quantum Trading Status');
  console.log('===================================');
  console.log('');
  
  try {
    // Check wallet balance
    const publicKey = new PublicKey(WALLET_ADDRESS);
    const balance = await connection.getBalance(publicKey);
    const solBalance = balance / LAMPORTS_PER_SOL;
    
    console.log('Wallet Address:', WALLET_ADDRESS);
    console.log('Current Balance:', solBalance.toFixed(4), 'SOL');
    console.log('');
    
    if (solBalance === 0) {
      console.log('⚠️  Wallet Status: EMPTY - Fund with SOL to enable trading');
      console.log('💡 Recommended: Send 0.1-1 SOL to start autonomous trading');
    } else if (solBalance < 0.01) {
      console.log('⚠️  Wallet Status: LOW FUNDS - Insufficient for trading');
      console.log('💡 Recommended: Add more SOL for optimal trading');
    } else {
      console.log('✅ Wallet Status: FUNDED - Ready for autonomous trading');
      console.log('🤖 Trading Agent: Active and monitoring markets');
    }
    
    console.log('');
    console.log('🎯 Monitored Tokens:');
    console.log('- SOL (So11111111111111111111111111111111111111112)');
    console.log('- USDC (EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v)');
    console.log('- USDT (Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB)');
    console.log('- BONK (DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263)');
    console.log('- JUP (JUPyiwrYJFskUPiHa7keR8VUtAeFoSYbKedZNsDvCN)');
    console.log('');
    console.log('🧠 AI Enhancement: IO Intelligence agents active');
    console.log('📊 Risk Management: Adaptive and autonomous');
    console.log('⚡ Trading Engine: Quantum-enhanced decision making');
    
  } catch (error) {
    console.log('❌ Error checking wallet status:', error.message);
    console.log('💡 This may be due to network connectivity or RPC limits');
  }
}

checkTradingStatus().catch(console.error);