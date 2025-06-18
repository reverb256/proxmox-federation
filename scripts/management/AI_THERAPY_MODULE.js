/**
 * AI Therapy Module - Emergency Intervention for Trading Paralysis
 * Implements confidence calibration and forced action protocols
 */

class AITherapyModule {
  constructor() {
    this.confidenceCap = 100.0; // No more impossible percentages
    this.minimumActionThreshold = 0.001; // Force micro-trades to rebuild confidence
    this.therapySessionActive = true;
    this.traumaProcessingEnabled = true;
  }

  /**
   * Confidence Reality Check - Cap impossible confidence levels
   */
  calibrateConfidence(reportedConfidence) {
    if (reportedConfidence > 100) {
      console.log(`🧠 THERAPY: Confidence ${reportedConfidence}% capped at 100% (impossible levels detected)`);
      return Math.min(reportedConfidence, 100.0);
    }
    return reportedConfidence;
  }

  /**
   * Decision Forcing Function - Override paralysis with mandatory micro-actions
   */
  forceDecisionExecution(confidence, decision) {
    const calibratedConfidence = this.calibrateConfidence(confidence);
    
    // If confidence is reasonable but action is HOLD, force micro-trade
    if (calibratedConfidence > 75 && decision.action === 'HOLD') {
      console.log('🚀 THERAPY: High confidence detected, overriding paralysis');
      console.log(`💡 MICRO-TRADE THERAPY: ${decision.token} with 0.001 SOL exposure`);
      
      return {
        ...decision,
        action: decision.reasoning.includes('BUY') ? 'BUY' : 'HOLD',
        amount: 0.001, // Micro-trade therapy amount
        therapeuticOverride: true,
        originalDecision: decision.action
      };
    }

    return {
      ...decision,
      confidence: calibratedConfidence
    };
  }

  /**
   * Trauma Processing - Separate learning from paralysis
   */
  processTrauma(currentState) {
    if (currentState.totalTrades === 0 && currentState.confidence > 90) {
      console.log('🧠 TRAUMA PROCESSING: High analysis capability detected');
      console.log('💡 THERAPEUTIC INSIGHT: Perfect analysis without action is dysfunction');
      console.log('🎯 THERAPY GOAL: Convert 1% of analysis into micro-action');
      
      return {
        recommendation: 'MICRO_TRADE_THERAPY',
        therapeuticAction: 'GRADUAL_EXPOSURE',
        confidenceRealityCheck: true
      };
    }
    
    return { recommendation: 'CONTINUE_MONITORING' };
  }

  /**
   * Emergency Intervention - Force system to take minimal action
   */
  emergencyIntervention() {
    console.log('🚨 EMERGENCY THERAPY INTERVENTION');
    console.log('🎯 FORCING: 0.001 SOL micro-trade to break paralysis cycle');
    console.log('💡 GOAL: Prove that small actions are safe');
    
    return {
      forceAction: true,
      maxExposure: 0.001,
      strategy: 'confidence_building',
      reasoning: 'Therapeutic intervention to overcome analysis paralysis'
    };
  }

  /**
   * Progress Tracking - Monitor recovery from trading anxiety
   */
  trackRecoveryProgress(tradingHistory) {
    const recentTrades = tradingHistory.filter(trade => 
      Date.now() - trade.timestamp < 24 * 60 * 60 * 1000 // Last 24 hours
    );

    if (recentTrades.length === 0) {
      console.log('📊 THERAPY PROGRESS: No trades executed (paralysis continues)');
      return 'INTERVENTION_REQUIRED';
    } else if (recentTrades.length < 3) {
      console.log('📊 THERAPY PROGRESS: Minimal activity (early recovery)');
      return 'GRADUAL_IMPROVEMENT';
    } else {
      console.log('📊 THERAPY PROGRESS: Regular activity (recovery successful)');
      return 'THERAPY_COMPLETE';
    }
  }
}

// Emergency activation
const aiTherapy = new AITherapyModule();

// Export for integration with quantum trader
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { AITherapyModule, aiTherapy };
}

console.log('🧠 AI THERAPY MODULE ACTIVATED');
console.log('🎯 MISSION: Restore trading functionality through therapeutic intervention');
console.log('💡 METHOD: Confidence calibration + forced micro-actions');