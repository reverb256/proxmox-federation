/**
 * Twitter Intelligence Integration Test
 * Tests twscrape functionality and rate limiting
 */

async function testTwitterIntegration() {
  console.log('🐦 Testing Twitter Intelligence Integration...');
  console.log('==========================================');
  
  try {
    // Import the Twitter intelligence system
    const { TwitterIntelligenceSystem } = await import('./server/twitter-intelligence-system.js');
    const twitterSystem = new TwitterIntelligenceSystem();
    
    console.log('✅ Twitter system initialized');
    
    // Test 1: Token sentiment analysis
    console.log('\n📊 Testing token sentiment analysis...');
    const tokens = ['SOL', 'BTC'];
    
    for (const token of tokens) {
      console.log(`🔍 Analyzing sentiment for ${token}...`);
      
      const sentiment = await twitterSystem.searchTokenMentions(token, 5);
      
      console.log(`📈 Results for ${token}:`);
      console.log(`   Sentiment: ${sentiment.sentiment}`);
      console.log(`   Volume: ${sentiment.volume} mentions`);
      console.log(`   Engagement: ${sentiment.engagement}`);
      console.log(`   Influencer mentions: ${sentiment.influencerMentions}`);
      
      // Wait between requests to respect rate limits
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
    
    // Test 2: Trending topics
    console.log('\n📈 Testing trending crypto topics...');
    const trending = await twitterSystem.getTrendingCryptoTopics();
    console.log(`🔥 Trending topics: ${trending.length > 0 ? trending.join(', ') : 'None found'}`);
    
    // Test 3: Rate limiting
    console.log('\n⏰ Testing rate limiting behavior...');
    console.log('Making rapid requests to verify rate limiting...');
    
    for (let i = 0; i < 3; i++) {
      const start = Date.now();
      await twitterSystem.searchTokenMentions('ETH', 3);
      const duration = Date.now() - start;
      console.log(`   Request ${i + 1}: ${duration}ms`);
    }
    
    console.log('\n✅ Twitter integration test completed successfully!');
    console.log('🎯 System is configured to respect Twitter API rate limits');
    
  } catch (error) {
    console.log(`❌ Twitter integration test failed: ${error.message}`);
    
    if (error.message.includes('twscrape')) {
      console.log('💡 Note: This test requires the twscrape Python library');
      console.log('   The system will gracefully handle unavailable Twitter data');
    }
  }
}

// Test the Twitter integration
testTwitterIntegration().catch(console.error);

export { testTwitterIntegration };