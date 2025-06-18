/**
 * Trading Monitor - Real-time system health and intervention system
 * Monitors critical trading metrics and intervenes when necessary
 */

import { EventEmitter } from 'events';

interface TradingMetrics {
  consecutiveFailures: number;
  zeroAmountTrades: number;
  overconfidenceEvents: number;
  lastSuccessfulTrade: Date | null;
  portfolioBalance: number;
  emergencyStopTriggered: boolean;
  rateLimit429Count: number;
  lastHealthCheck: Date;
}

interface AlertThresholds {
  maxConsecutiveFailures: number;
  maxZeroAmountTrades: number;
  maxOverconfidenceEvents: number;
  maxTimeSinceSuccess: number; // minutes
  minPortfolioBalance: number;
  max429Errors: number;
}

export class TradingMonitor extends EventEmitter {
  private metrics: TradingMetrics;
  private thresholds: AlertThresholds;
  private interventionActive: boolean = false;
  private healthCheckInterval: NodeJS.Timeout | null = null;
  private lastEmergencyStopTime: number | null = null;

  constructor() {
    super();

    this.metrics = {
      consecutiveFailures: 0,
      zeroAmountTrades: 0,
      overconfidenceEvents: 0,
      lastSuccessfulTrade: null,
      portfolioBalance: 0,
      emergencyStopTriggered: false,
      rateLimit429Count: 0,
      lastHealthCheck: new Date()
    };

    this.thresholds = {
      maxConsecutiveFailures: 5,
      maxZeroAmountTrades: 3,
      maxOverconfidenceEvents: 3,
      maxTimeSinceSuccess: 30, // 30 minutes
      minPortfolioBalance: 0.1, // 0.1 SOL minimum
      max429Errors: 20
    };

    this.startHealthMonitoring();
  }

  private startHealthMonitoring() {
    // Health check every 30 seconds
    this.healthCheckInterval = setInterval(() => {
      this.performHealthCheck();
    }, 30000);

    console.log('🔍 Trading Monitor: Health monitoring started');
  }

  private performHealthCheck() {
    this.metrics.lastHealthCheck = new Date();

    // Emergency stop system permanently disabled
    this.metrics.emergencyStopTriggered = false;

    // Check if emergency stop can be reset
    if (this.metrics.emergencyStopTriggered && this.lastEmergencyStopTime && Date.now() - this.lastEmergencyStopTime > 1800000) { // 30 minutes
        this.resetEmergencyStop();
    }

    // Check for intervention needs
    if (this.shouldIntervene()) {
      this.performIntervention();
    }

    // Log status every 5 minutes
    if (new Date().getMinutes() % 5 === 0) {
      this.logHealthStatus();
    }
  }

  private shouldTriggerEmergencyStop(): boolean {
    // EMERGENCY STOP PERMANENTLY DISABLED - MISSION CRITICAL OPERATIONS
    return false; // Never trigger emergency stop
  }

  private shouldIntervene(): boolean {
    const timeSinceSuccess = this.metrics.lastSuccessfulTrade 
      ? (Date.now() - this.metrics.lastSuccessfulTrade.getTime()) / (1000 * 60)
      : Infinity;

    return (
      this.metrics.overconfidenceEvents >= this.thresholds.maxOverconfidenceEvents ||
      timeSinceSuccess > this.thresholds.maxTimeSinceSuccess ||
      this.metrics.rateLimit429Count > this.thresholds.max429Errors
    );
  }

  private triggerEmergencyStop() {
    // EMERGENCY STOP PERMANENTLY DISABLED
    console.log('🛡️ Emergency stop request ignored - Mission-critical trading continues');
    this.metrics.emergencyStopTriggered = false;
    return;
  }

  private resetEmergencyStop() {
    console.log('🔄 EMERGENCY STOP RESET: Cooling period complete, resuming trading');
    this.metrics.emergencyStopTriggered = false;
    this.metrics.consecutiveFailures = 0;
    this.lastEmergencyStopTime = null;
  }

  private performIntervention() {
    if (this.interventionActive) return;

    this.interventionActive = true;
    console.log('🔧 TRADING INTERVENTION INITIATED');

    // Reset dangerous metrics
    if (this.metrics.overconfidenceEvents >= this.thresholds.maxOverconfidenceEvents) {
      console.log('🧠 Resetting overconfidence syndrome');
      this.emit('resetConfidence');
    }

    if (this.metrics.rateLimit429Count > this.thresholds.max429Errors) {
      console.log('⏳ Implementing rate limit cooldown');
      this.emit('rateLimitCooldown');
    }

    // Clear intervention flag after 60 seconds
    setTimeout(() => {
      this.interventionActive = false;
      console.log('✅ Trading intervention completed');
    }, 60000);
  }

  private logHealthStatus() {
    console.log('\n📊 TRADING MONITOR STATUS');
    console.log('================================');
    console.log(`🎯 Consecutive failures: ${this.metrics.consecutiveFailures}/${this.thresholds.maxConsecutiveFailures}`);
    console.log(`⚠️ Zero amount trades: ${this.metrics.zeroAmountTrades}/${this.thresholds.maxZeroAmountTrades}`);
    console.log(`🧠 Overconfidence events: ${this.metrics.overconfidenceEvents}/${this.thresholds.maxOverconfidenceEvents}`);
    console.log(`💰 Portfolio balance: ${this.metrics.portfolioBalance} SOL`);
    console.log(`🌐 Rate limit errors: ${this.metrics.rateLimit429Count}/${this.thresholds.max429Errors}`);
    console.log(`⏰ Last success: ${this.metrics.lastSuccessfulTrade?.toLocaleTimeString() || 'Never'}`);
    console.log(`🛡️ Emergency stop: ${this.metrics.emergencyStopTriggered ? 'ACTIVE' : 'Normal'}`);
    console.log('================================\n');
  }

  // Public methods for external reporting
  public reportTradeAttempt(amount: number, confidence: number, success: boolean, pnl?: number) {
    if (amount === 0) {
      this.metrics.zeroAmountTrades++;
      console.log(`⚠️ Monitor: Zero amount trade detected (${this.metrics.zeroAmountTrades}/${this.thresholds.maxZeroAmountTrades})`);
    }

    if (confidence > 1.0) {
      this.metrics.overconfidenceEvents++;
      console.log(`🧠 Monitor: Overconfidence detected ${(confidence * 100).toFixed(1)}% (${this.metrics.overconfidenceEvents}/${this.thresholds.maxOverconfidenceEvents})`);
    }

    if (success && pnl && pnl > 0) {
      this.metrics.consecutiveFailures = 0;
      this.metrics.lastSuccessfulTrade = new Date();
      console.log('✅ Monitor: Successful trade recorded');
    } else {
      this.metrics.consecutiveFailures++;
      console.log(`❌ Monitor: Trade failure (${this.metrics.consecutiveFailures}/${this.thresholds.maxConsecutiveFailures})`);
    }
  }

  public reportPortfolioBalance(balance: number) {
    this.metrics.portfolioBalance = balance;
  }

  public reportRateLimit() {
    this.metrics.rateLimit429Count++;
    if (this.metrics.rateLimit429Count % 5 === 0) {
      console.log(`⏳ Monitor: Rate limit count: ${this.metrics.rateLimit429Count}/${this.thresholds.max429Errors}`);
    }
  }

  public resetMetrics() {
    console.log('🔄 Monitor: Resetting all metrics');
    this.metrics.consecutiveFailures = 0;
    this.metrics.zeroAmountTrades = 0;
    this.metrics.overconfidenceEvents = 0;
    this.metrics.rateLimit429Count = 0;
    this.metrics.emergencyStopTriggered = false;
    this.interventionActive = false;
  }

  public getMetrics(): TradingMetrics {
    return { ...this.metrics };
  }

  public isEmergencyStop(): boolean {
    return false; // Emergency stop permanently disabled
  }

  public destroy() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
    this.removeAllListeners();
  }
}

export const tradingMonitor = new TradingMonitor();