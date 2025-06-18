/**
 * API Integration Test Script
 * Tests CMC DEX and Moralis API functionality
 */

async function testCMCDEXAPI() {
  console.log('🔍 Testing CMC DEX API...');
  
  const cmcApiKey = process.env.CMD_DEX_TOKEN;
  if (!cmcApiKey) {
    console.log('❌ CMC DEX API key not found');
    return false;
  }

  try {
    const response = await fetch('https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=SOL,USDC,RAY', {
      headers: {
        'X-CMC_PRO_API_KEY': cmcApiKey,
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      console.log(`❌ CMC API error: ${response.status} - ${response.statusText}`);
      return false;
    }

    const data = await response.json();
    console.log('✅ CMC DEX API Response:');
    console.log(JSON.stringify(data, null, 2));
    
    return true;
  } catch (error) {
    console.log(`❌ CMC DEX API error: ${error.message}`);
    return false;
  }
}

async function testMoralisAPI() {
  console.log('🔍 Testing Moralis API...');
  
  const moralisApiKey = process.env.MORALIS_TOKEN;
  if (!moralisApiKey) {
    console.log('❌ Moralis API key not found');
    return false;
  }

  try {
    // Test with SOL price endpoint
    const response = await fetch('https://deep-index.moralis.io/api/v2/erc20/So11111111111111111111111111111111111111112/price?chain=mainnet', {
      headers: {
        'X-API-Key': moralisApiKey,
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      console.log(`❌ Moralis API error: ${response.status} - ${response.statusText}`);
      const errorText = await response.text();
      console.log('Error details:', errorText);
      return false;
    }

    const data = await response.json();
    console.log('✅ Moralis API Response:');
    console.log(JSON.stringify(data, null, 2));
    
    return true;
  } catch (error) {
    console.log(`❌ Moralis API error: ${error.message}`);
    return false;
  }
}

async function runAPITests() {
  console.log('🚀 Starting API Integration Tests...');
  console.log('=====================================');
  
  const cmcResult = await testCMCDEXAPI();
  console.log('');
  
  const moralisResult = await testMoralisAPI();
  console.log('');
  
  console.log('📊 Test Results Summary:');
  console.log(`CMC DEX API: ${cmcResult ? '✅ Working' : '❌ Failed'}`);
  console.log(`Moralis API: ${moralisResult ? '✅ Working' : '❌ Failed'}`);
  
  if (cmcResult && moralisResult) {
    console.log('🎉 All API integrations working successfully!');
  } else if (cmcResult || moralisResult) {
    console.log('⚠️ Some API integrations working, others may need configuration');
  } else {
    console.log('🔧 API integrations need configuration or troubleshooting');
  }
}

// Run tests if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAPITests().catch(console.error);
}

export { testCMCDEXAPI, testMoralisAPI, runAPITests };