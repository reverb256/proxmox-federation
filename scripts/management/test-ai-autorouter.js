/**
 * AI Autorouter System Test
 * Tests the centralized AI service integration
 */

import { aiService } from './server/ai-service.js';

async function testAIAutorouterSystem() {
  console.log('🧪 Testing AI Autorouter System...\n');

  try {
    // Test 1: Basic text generation
    console.log('Test 1: Text Generation');
    const textResponse = await aiService.generate(
      'Generate a brief market analysis for cryptocurrency trading',
      {
        priority: 'medium',
        maxTokens: 200
      }
    );
    console.log('✅ Text generation successful');
    console.log(`Response length: ${textResponse.length} characters\n`);

    // Test 2: Technical analysis
    console.log('Test 2: Technical Analysis');
    const technicalAnalysis = await aiService.technicalAnalysis(
      'SOL price has increased 15% in the last 24 hours with volume spike of 300%. Current price: $180. RSI: 72. Support: $175, Resistance: $185',
      'solana_price_analysis',
      {
        priority: 'high',
        maxTokens: 300
      }
    );
    console.log('✅ Technical analysis successful');
    console.log(`Analysis length: ${technicalAnalysis.length} characters\n`);

    // Test 3: Sentiment analysis
    console.log('Test 3: Sentiment Analysis');
    const sentimentAnalysis = await aiService.analyze(
      'Bitcoin reaches new all-time high as institutional adoption surges',
      'crypto_news_sentiment',
      {
        contentType: 'analysis',
        intent: 'analyze',
        priority: 'medium'
      }
    );
    console.log('✅ Sentiment analysis successful');
    console.log(`Sentiment response length: ${sentimentAnalysis.length} characters\n`);

    // Test 4: System status check
    console.log('Test 4: System Status');
    const systemStatus = await aiService.getSystemStatus();
    console.log('✅ System status retrieved');
    console.log(`Available models: ${systemStatus.availableModels}`);
    console.log(`Total requests: ${systemStatus.totalRequests}`);
    console.log(`Success rate: ${systemStatus.successRate}%\n`);

    // Test 5: Batch processing
    console.log('Test 5: Batch Processing');
    const batchRequests = [
      {
        content: 'What is the current trend in DeFi?',
        contentType: 'analysis',
        intent: 'analyze'
      },
      {
        content: 'Explain yield farming risks',
        contentType: 'text',
        intent: 'explain'
      }
    ];
    
    const batchResults = await aiService.batch(batchRequests, true);
    console.log('✅ Batch processing successful');
    console.log(`Processed ${batchResults.length} requests in parallel\n`);

    console.log('🎉 All AI Autorouter tests passed successfully!');
    console.log('The centralized AI system is working correctly.');

  } catch (error) {
    console.error('❌ AI Autorouter test failed:', error.message);
    
    // Check if it's an API key issue
    if (error.message.includes('API key') || error.message.includes('authentication')) {
      console.log('\n💡 This appears to be an API key issue.');
      console.log('The system needs valid API keys to function:');
      console.log('- ANTHROPIC_API_KEY for Claude models');
      console.log('- OPENAI_API_KEY for GPT models');
      console.log('- XAI_API_KEY for Grok models');
      console.log('- IO_INTELLIGENCE_API_KEY for specialized trading models');
    }
  }
}

// Run the test
testAIAutorouterSystem();