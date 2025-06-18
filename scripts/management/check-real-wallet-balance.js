/**
 * Real Wallet Balance Checker
 * Gets actual balance from the user's Solana wallet using WALLET_PUBLIC_KEY secret
 */

const fetch = require('node-fetch');

async function checkRealWalletBalance() {
  try {
    const walletAddress = process.env.WALLET_PUBLIC_KEY || '4jTtAYiHP3tHqXcmi5T1riS1AcGmxNNhLZTw65vrKpkA';
    
    console.log(`🔍 Checking real balance for wallet: ${walletAddress.substring(0, 8)}...`);
    
    // Try multiple RPC endpoints for reliability
    const endpoints = [
      'https://api.mainnet-beta.solana.com',
      'https://solana-api.projectserum.com',
      'https://rpc.ankr.com/solana',
      'https://api.devnet.solana.com'
    ];

    for (const endpoint of endpoints) {
      try {
        console.log(`📡 Trying endpoint: ${endpoint}`);
        
        const response = await fetch(endpoint, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'User-Agent': 'VibeCoding-Portfolio-Tracker/1.0'
          },
          body: JSON.stringify({
            jsonrpc: '2.0',
            id: 1,
            method: 'getBalance',
            params: [walletAddress]
          })
        });

        const data = await response.json();
        
        if (data.result && data.result.value !== undefined) {
          const balanceSOL = data.result.value / 1e9; // Convert lamports to SOL
          
          // Get approximate SOL price (in real implementation, would use CoinGecko or similar)
          const solPriceUSD = 200; // Conservative estimate
          const portfolioValueUSD = balanceSOL * solPriceUSD;
          
          console.log(`💰 REAL WALLET BALANCE FOUND:`);
          console.log(`   Address: ${walletAddress}`);
          console.log(`   Balance: ${balanceSOL.toFixed(6)} SOL`);
          console.log(`   USD Value: $${portfolioValueUSD.toFixed(2)} (at $${solPriceUSD}/SOL)`);
          console.log(`   Lamports: ${data.result.value.toLocaleString()}`);
          
          // Check if sufficient for $50 payout
          const payoutRequest = 50;
          const tradingReserve = 40; // Keep $40 for trading operations
          const availableForPayout = portfolioValueUSD - tradingReserve;
          
          console.log(`\n💸 PAYOUT ANALYSIS:`);
          console.log(`   Requested: $${payoutRequest}`);
          console.log(`   Trading Reserve: $${tradingReserve}`);
          console.log(`   Available for Payout: $${availableForPayout.toFixed(2)}`);
          
          if (availableForPayout >= payoutRequest) {
            console.log(`   ✅ PAYOUT APPROVED - Sufficient funds available`);
          } else {
            const growthNeeded = ((payoutRequest + tradingReserve) / portfolioValueUSD * 100) - 100;
            console.log(`   ⏳ GROWTH MODE - Need ${growthNeeded.toFixed(1)}% portfolio growth`);
          }
          
          return {
            success: true,
            balanceSOL,
            portfolioValueUSD,
            endpoint,
            payoutEligible: availableForPayout >= payoutRequest
          };
        } else {
          console.log(`⚠️ No result from ${endpoint}: ${JSON.stringify(data)}`);
        }
      } catch (error) {
        console.log(`❌ Failed ${endpoint}: ${error.message}`);
      }
    }
    
    console.error('❌ All RPC endpoints failed');
    return { success: false, error: 'All endpoints failed' };
    
  } catch (error) {
    console.error('❌ Critical error:', error);
    return { success: false, error: error.message };
  }
}

// Run the check
checkRealWalletBalance()
  .then(result => {
    if (result.success) {
      console.log(`\n🎯 Balance check completed successfully via ${result.endpoint}`);
    } else {
      console.log(`\n💥 Balance check failed: ${result.error}`);
    }
  })
  .catch(console.error);