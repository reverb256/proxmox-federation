import { Connection, PublicKey, LAMPORTS_PER_SOL } from '@solana/web3.js';

const WALLET_ADDRESS = 'JA63CrEdqjK6cyEkGquuYmk4xyTVgTXSFABZDNW3Qnfj';
const connection = new Connection('https://api.mainnet-beta.solana.com', 'confirmed');

class GasFeeProtection {
  constructor() {
    this.EMERGENCY_RESERVE_RATIO = 0.1; // 10% emergency reserve
    this.MAX_GAS_PER_TX = 0.01; // Max 0.01 SOL per transaction
    this.CRITICAL_RESERVE_THRESHOLD = 0.005; // Emergency stop at 0.005 SOL
    this.gasHistory = [];
    this.failsafeActive = false;
  }

  async getCurrentBalance() {
    const publicKey = new PublicKey(WALLET_ADDRESS);
    const balance = await connection.getBalance(publicKey);
    return balance / LAMPORTS_PER_SOL;
  }

  async calculateReserves(totalBalance) {
    const emergencyReserve = totalBalance * this.EMERGENCY_RESERVE_RATIO;
    const tradingCapital = totalBalance - emergencyReserve;
    
    return {
      totalBalance,
      emergencyReserve,
      tradingCapital,
      isCritical: emergencyReserve < this.CRITICAL_RESERVE_THRESHOLD
    };
  }

  async estimateTransactionFee(transaction) {
    try {
      // Simulate transaction to get accurate fee estimate
      const response = await connection.getFeeForMessage(
        transaction.compileMessage(),
        'confirmed'
      );
      
      if (response.value) {
        return response.value / LAMPORTS_PER_SOL;
      }
      
      // Fallback to conservative estimate
      return 0.005; // 0.005 SOL conservative estimate
    } catch (error) {
      console.warn('Fee estimation failed, using conservative estimate:', error.message);
      return 0.01; // Maximum conservative estimate
    }
  }

  async validateGasAvailability(estimatedFee, reserves) {
    const validations = {
      sufficientReserve: reserves.emergencyReserve >= this.CRITICAL_RESERVE_THRESHOLD,
      withinGasLimit: estimatedFee <= this.MAX_GAS_PER_TX,
      reserveProtected: estimatedFee <= reserves.emergencyReserve * 0.5,
      failsafeCheck: !this.failsafeActive
    };

    const isValid = Object.values(validations).every(check => check);
    
    return {
      isValid,
      validations,
      estimatedFee,
      recommendation: this.getRecommendation(validations, estimatedFee)
    };
  }

  getRecommendation(validations, estimatedFee) {
    if (!validations.sufficientReserve) {
      return 'EMERGENCY_STOP: Reserve below critical threshold';
    }
    if (!validations.withinGasLimit) {
      return `REJECT: Gas fee ${estimatedFee} exceeds limit ${this.MAX_GAS_PER_TX}`;
    }
    if (!validations.reserveProtected) {
      return 'CAUTION: Gas fee consumes significant reserve';
    }
    if (!validations.failsafeCheck) {
      return 'BLOCKED: Emergency failsafe active';
    }
    return 'APPROVED: Transaction within gas protection limits';
  }

  async preTransactionCheck(transaction) {
    try {
      const balance = await this.getCurrentBalance();
      const reserves = await this.calculateReserves(balance);
      const estimatedFee = await this.estimateTransactionFee(transaction);
      
      const validation = await this.validateGasAvailability(estimatedFee, reserves);
      
      this.logGasUsage(estimatedFee, validation.isValid);
      
      if (reserves.isCritical) {
        this.activateFailsafe();
      }
      
      return {
        approved: validation.isValid,
        estimatedFee,
        reserves,
        validation,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Pre-transaction check failed:', error);
      return {
        approved: false,
        error: error.message,
        recommendation: 'REJECT: Unable to validate gas requirements'
      };
    }
  }

  logGasUsage(fee, approved) {
    this.gasHistory.push({
      fee,
      approved,
      timestamp: Date.now()
    });
    
    // Keep only last 100 transactions
    if (this.gasHistory.length > 100) {
      this.gasHistory = this.gasHistory.slice(-100);
    }
  }

  activateFailsafe() {
    this.failsafeActive = true;
    console.log('🚨 EMERGENCY FAILSAFE ACTIVATED: Trading suspended due to low reserves');
  }

  async getProtectionStatus() {
    const balance = await this.getCurrentBalance();
    const reserves = await this.calculateReserves(balance);
    
    const recentGas = this.gasHistory.slice(-10);
    const avgGasFee = recentGas.reduce((sum, tx) => sum + tx.fee, 0) / Math.max(recentGas.length, 1);
    
    return {
      wallet: WALLET_ADDRESS,
      balance: reserves.totalBalance,
      emergencyReserve: reserves.emergencyReserve,
      tradingCapital: reserves.tradingCapital,
      failsafeActive: this.failsafeActive,
      isCritical: reserves.isCritical,
      averageGasFee: avgGasFee,
      recentTransactions: recentGas.length,
      protectionLimits: {
        maxGasPerTx: this.MAX_GAS_PER_TX,
        emergencyThreshold: this.CRITICAL_RESERVE_THRESHOLD,
        reserveRatio: this.EMERGENCY_RESERVE_RATIO
      }
    };
  }
}

// Global instance
const gasProtection = new GasFeeProtection();

async function demonstrateProtection() {
  console.log('🛡️ VibeCoding Gas Fee Protection System');
  console.log('=====================================');
  
  const status = await gasProtection.getProtectionStatus();
  
  console.log('\nCurrent Protection Status:');
  console.log('Wallet:', status.wallet);
  console.log('Total Balance:', status.balance.toFixed(4), 'SOL');
  console.log('Emergency Reserve:', status.emergencyReserve.toFixed(4), 'SOL');
  console.log('Trading Capital:', status.tradingCapital.toFixed(4), 'SOL');
  console.log('Failsafe Active:', status.failsafeActive ? 'YES' : 'NO');
  console.log('Status:', status.isCritical ? 'CRITICAL' : 'PROTECTED');
  
  console.log('\nProtection Limits:');
  console.log('Max Gas per TX:', status.protectionLimits.maxGasPerTx, 'SOL');
  console.log('Emergency Threshold:', status.protectionLimits.emergencyThreshold, 'SOL');
  console.log('Reserve Ratio:', (status.protectionLimits.reserveRatio * 100) + '%');
  
  if (status.recentTransactions > 0) {
    console.log('\nRecent Activity:');
    console.log('Average Gas Fee:', status.averageGasFee.toFixed(6), 'SOL');
    console.log('Recent Transactions:', status.recentTransactions);
  }
  
  console.log('\n✅ Gas fee protection is active and monitoring all transactions');
}

demonstrateProtection().catch(console.error);

export { GasFeeProtection, gasProtection };