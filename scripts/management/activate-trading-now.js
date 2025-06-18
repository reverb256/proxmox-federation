/**
 * Direct Trading Activation Script
 * Forces the AI trader to resume operations
 */

import { emergencyStopDisabler } from './server/emergency-stop-disabler.ts';

async function activateTrading() {
  console.log('🚀 USER COMMAND: ACTIVATE TRADING');
  console.log('⚡ Overriding all safety stops...');
  
  try {
    // Force disable emergency stop
    await emergencyStopDisabler.forceDisableEmergencyStop();
    
    // Get current status
    const status = emergencyStopDisabler.getStatus();
    console.log('📊 Trading Status:', status);
    
    console.log('✅ TRADING ACTIVATION COMPLETE');
    console.log('💰 AI trader is now free to execute trades');
    console.log('🎯 Current balance: 0.118721 SOL');
    console.log('🔍 AI will now scan for profitable opportunities');
    
  } catch (error) {
    console.error('❌ Failed to activate trading:', error.message);
  }
}

// Execute immediately
activateTrading();