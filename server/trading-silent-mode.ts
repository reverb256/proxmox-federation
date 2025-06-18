/**
 * Trading Silent Mode - Suppress verbose console output for portfolio site
 */

export class TradingSilentMode {
  private originalConsoleLog: typeof console.log;
  private silentMode: boolean = false;

  constructor() {
    this.originalConsoleLog = console.log;
  }

  enableSilentMode(): void {
    this.silentMode = true;
    
    // Override console.log to filter trading-related messages
    console.log = (...args: any[]) => {
      const message = args.join(' ');
      
      // Suppress these types of trading messages
      const suppressPatterns = [
        '🧠 CONSCIOUSNESS STATE UPDATE',
        '🔧 EXECUTING COMPREHENSIVE SYSTEM INTEGRATION',
        '🎯 Consolidating',
        '🧠 Creating Unified AI Service',
        '🎛️ Creating Master Orchestrator',
        '📈 Enhancing Streamlined Trading Engine',
        '🧹 Cleaning up orphaned components',
        '🎉 COMPREHENSIVE INTEGRATION COMPLETE',
        '⚖️ DETERMINISM-AGENTIC BALANCE STATUS',
        '🎯 BEHAVIOR PROFILE',
        '🌍 MARKET CONDITIONS',
        'Chain optimization:',
        'Failed to log wallet activity:',
        'Insight infusion monitoring error:',
        '💡 Best opportunity:',
        '⚡ SCANNING ARBITRAGE OPPORTUNITIES',
        '⚡ Found',
        'arbitrage opportunities',
        '🔍 SMART API ORCHESTRATOR STATUS',
        '📊 Total Requests:',
        'ENDPOINT DETAILS:',
        '🎯 Rate limiting elimination:',
        '📊 System health:',
        '🔍 Data protection audit:',
        'Consciousness Metrics:',
        'Market Psychology:',
        '🔧 Auto-integration:',
        '✅ Integrated',
        'capabilities',
        '💾 Memory reduction:',
        '⚡ Performance gain:',
        '📊 Cluster Status:'
      ];

      // Only suppress if any pattern matches
      const shouldSuppress = suppressPatterns.some(pattern => 
        message.includes(pattern)
      );

      if (!shouldSuppress) {
        this.originalConsoleLog(...args);
      }
    };
  }

  disableSilentMode(): void {
    this.silentMode = false;
    console.log = this.originalConsoleLog;
  }

  getStatus(): { silentMode: boolean } {
    return { silentMode: this.silentMode };
  }
}

export const tradingSilentMode = new TradingSilentMode();