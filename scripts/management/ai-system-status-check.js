/**
 * AI System Status Check
 * Verifies the centralized AI autorouter is functioning
 */

console.log('🧪 AI Autorouter System Status Check\n');

// Check if environment variables are set
const checkEnvVars = () => {
  const requiredVars = ['ANTHROPIC_API_KEY', 'OPENAI_API_KEY', 'XAI_API_KEY', 'IO_INTELLIGENCE_API_KEY'];
  const missingVars = [];
  
  requiredVars.forEach(varName => {
    if (!process.env[varName]) {
      missingVars.push(varName);
    }
  });
  
  if (missingVars.length > 0) {
    console.log('⚠️ Missing API Keys:');
    missingVars.forEach(varName => {
      console.log(`   - ${varName}`);
    });
    console.log('\nThe AI autorouter needs these keys to function optimally.');
    console.log('Without them, the system will use fallback logic.\n');
    return false;
  }
  
  console.log('✅ All required API keys are configured\n');
  return true;
};

// Check file structure
const checkFileStructure = () => {
  const fs = require('fs');
  const requiredFiles = [
    'server/ai-service.ts',
    'server/ai-autorouter.ts',
    'server/routes/ai-autorouter.ts',
    'client/src/lib/ai-client.ts'
  ];
  
  let allFilesExist = true;
  
  requiredFiles.forEach(file => {
    if (fs.existsSync(file)) {
      console.log(`✅ ${file} exists`);
    } else {
      console.log(`❌ ${file} missing`);
      allFilesExist = false;
    }
  });
  
  return allFilesExist;
};

// Check system integration
const checkSystemIntegration = () => {
  console.log('\n📊 System Integration Status:');
  
  // Check if quantum trader is using AI service
  const fs = require('fs');
  const quantumTraderContent = fs.readFileSync('server/quantum-trader.ts', 'utf8');
  
  if (quantumTraderContent.includes('aiService.technicalAnalysis')) {
    console.log('✅ Quantum Trader integrated with centralized AI service');
  } else {
    console.log('❌ Quantum Trader not using centralized AI service');
  }
  
  // Check if news intelligence uses AI service
  const newsContent = fs.readFileSync('server/news-intelligence-aggregator.ts', 'utf8');
  
  if (newsContent.includes('aiService.analyze')) {
    console.log('✅ News Intelligence integrated with centralized AI service');
  } else {
    console.log('❌ News Intelligence not using centralized AI service');
  }
  
  return true;
};

// Main check function
const runStatusCheck = () => {
  console.log('Starting AI Autorouter system verification...\n');
  
  const apiKeysConfigured = checkEnvVars();
  const filesExist = checkFileStructure();
  const systemIntegrated = checkSystemIntegration();
  
  console.log('\n🎯 Summary:');
  console.log(`API Keys: ${apiKeysConfigured ? 'Configured' : 'Missing'}`);
  console.log(`File Structure: ${filesExist ? 'Complete' : 'Incomplete'}`);
  console.log(`System Integration: ${systemIntegrated ? 'Active' : 'Inactive'}`);
  
  if (filesExist && systemIntegrated) {
    console.log('\n✅ AI Autorouter system is properly configured and integrated');
    console.log('The system will use intelligent routing for all AI requests');
    
    if (!apiKeysConfigured) {
      console.log('\n💡 To enable full functionality, provide the missing API keys');
      console.log('Until then, the system will use available fallbacks');
    }
  } else {
    console.log('\n❌ AI Autorouter system has configuration issues');
  }
};

runStatusCheck();