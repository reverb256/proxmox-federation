/**
 * Start Recursive Enhancement Script
 * Launches multiple rounds of AI trader improvement
 */

import { recursiveTraderEnhancement } from './server/recursive-trader-enhancement.js';
import { behavioralLearning } from './server/behavioral-learning-module.js';

async function startEnhancementDemo() {
  console.log('🚀 Starting AI Trader Recursive Enhancement Demo');
  console.log('================================================\n');

  // Simulate some trade patterns first
  console.log('📊 Generating sample trade patterns...');
  
  const sampleTrades = [
    {
      action: 'buy',
      amount: 50,
      price: 2.22,
      confidence: 0.8,
      volatility: 0.9,
      trend: 'up',
      liquidity: 0.5,
      sentiment: 0.9,
      success: false,
      pnl: -0.03,
      actualPrice: 2.15,
      executionTime: 150,
      reasoning: 'FOMO buying during high sentiment'
    },
    {
      action: 'sell',
      amount: 30,
      price: 2.20,
      confidence: 0.9,
      volatility: 0.8,
      trend: 'down',
      liquidity: 0.4,
      sentiment: 0.2,
      success: false,
      pnl: -0.02,
      actualPrice: 2.25,
      executionTime: 200,
      reasoning: 'Fear-based selling in volatile market'
    },
    {
      action: 'buy',
      amount: 75,
      price: 2.18,
      confidence: 0.7,
      volatility: 0.6,
      trend: 'sideways',
      liquidity: 0.8,
      sentiment: 0.5,
      success: true,
      pnl: 0.04,
      actualPrice: 2.22,
      executionTime: 80,
      reasoning: 'Pattern-based entry with good liquidity'
    },
    {
      action: 'sell',
      amount: 40,
      price: 2.24,
      confidence: 0.6,
      volatility: 0.7,
      trend: 'up',
      liquidity: 0.7,
      sentiment: 0.6,
      success: true,
      pnl: 0.02,
      actualPrice: 2.26,
      executionTime: 90,
      reasoning: 'Profit taking at resistance level'
    }
  ];

  // Record the sample trades
  for (const trade of sampleTrades) {
    await behavioralLearning.recordTrade(trade);
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log('✅ Sample trades recorded\n');

  // Get initial behavioral summary
  const initialSummary = behavioralLearning.getBehavioralSummary();
  console.log('📚 Initial Behavioral Learning Summary:');
  console.log(`   Patterns learned: ${initialSummary.totalPatterns}`);
  console.log(`   Trade history: ${initialSummary.totalTrades}`);
  console.log(`   Performance impact: ${initialSummary.performanceImpact}`);
  console.log(`   Top lessons: ${initialSummary.topLessons.slice(0, 2).join(', ')}\n`);

  // Start recursive enhancement
  console.log('🔄 Starting recursive enhancement cycles...\n');
  await recursiveTraderEnhancement.startRecursiveEnhancement();

  // Show final status
  const finalStatus = recursiveTraderEnhancement.getEnhancementStatus();
  console.log('\n🎯 Enhancement Complete!');
  console.log(`   Completed cycles: ${finalStatus.completedCycles}/${finalStatus.totalCycles}`);
  console.log(`   Final status: ${finalStatus.isRunning ? 'Still running' : 'Completed'}`);

  const finalSummary = behavioralLearning.getBehavioralSummary();
  console.log('\n📈 Final Performance:');
  console.log(`   Patterns learned: ${finalSummary.totalPatterns}`);
  console.log(`   Trade history: ${finalSummary.totalTrades}`);
  console.log(`   Performance impact: ${finalSummary.performanceImpact}`);
}

// Run the demo
startEnhancementDemo().catch(console.error);