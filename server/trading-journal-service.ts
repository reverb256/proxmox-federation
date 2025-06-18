/**
 * Trading Journal Service
 * Comprehensive tracking and analysis of all trading decisions and performance
 */

import { db } from './db';
import { tradingJournal, tradingStrategies, portfolioSnapshots, tradingInsights } from '../shared/trading-schema';
import { eq, desc, and, gte, lte, sql } from 'drizzle-orm';
import type { InsertTradingJournal, InsertPortfolioSnapshot, InsertTradingInsight } from '../shared/trading-schema';

export class TradingJournalService {
  
  // Record a new trade entry
  async recordTrade(tradeData: {
    action: 'buy' | 'sell' | 'hold' | 'liquidate';
    tokenSymbol: string;
    tokenAddress?: string;
    quantity: string;
    priceEntry: string;
    priceExit?: string;
    costBasis: string;
    fees: string;
    aiConfidence: string;
    consciousnessLevel: string;
    decisionReasoning: string;
    marketSentiment?: string;
    riskScore: string;
    strategy: string;
    signalSource: string;
    executionMethod: 'manual' | 'automated' | 'hybrid';
    positionSize: string;
    stopLoss?: string;
    takeProfit?: string;
    technicalIndicators?: any;
    marketCondition?: 'bullish' | 'bearish' | 'sideways' | 'volatile';
    newsImpact?: any;
    transactionHash?: string;
    isSimulated?: boolean;
  }) {
    try {
      const tradeId = `trade_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      const insertData: InsertTradingJournal = {
        tradeId,
        action: tradeData.action,
        tokenSymbol: tradeData.tokenSymbol,
        tokenAddress: tradeData.tokenAddress,
        quantity: tradeData.quantity,
        priceEntry: tradeData.priceEntry,
        priceExit: tradeData.priceExit,
        costBasis: tradeData.costBasis,
        fees: tradeData.fees,
        aiConfidence: tradeData.aiConfidence,
        consciousnessLevel: tradeData.consciousnessLevel,
        decisionReasoning: tradeData.decisionReasoning,
        marketSentiment: tradeData.marketSentiment,
        riskScore: tradeData.riskScore,
        strategy: tradeData.strategy,
        signalSource: tradeData.signalSource,
        executionMethod: tradeData.executionMethod,
        positionSize: tradeData.positionSize,
        stopLoss: tradeData.stopLoss,
        takeProfit: tradeData.takeProfit,
        technicalIndicators: tradeData.technicalIndicators,
        marketCondition: tradeData.marketCondition,
        newsImpact: tradeData.newsImpact,
        transactionHash: tradeData.transactionHash,
        isSimulated: tradeData.isSimulated || false,
        winLoss: 'open'
      };

      const [result] = await db.insert(tradingJournal).values(insertData).returning();
      
      console.log(`📝 Trade recorded: ${tradeData.action} ${tradeData.quantity} ${tradeData.tokenSymbol} at $${tradeData.priceEntry}`);
      return result;
      
    } catch (error) {
      console.error('Failed to record trade:', error);
      throw error;
    }
  }

  // Update trade with exit information
  async updateTradeExit(tradeId: string, exitData: {
    priceExit: string;
    realizedPnl: string;
    winLoss: 'win' | 'loss' | 'breakeven';
    holdingPeriod: number;
    maxDrawdown?: string;
    maxProfit?: string;
    lessons?: string;
    improvements?: string;
    emotionalState?: string;
    marketTimingScore?: string;
  }) {
    try {
      const [result] = await db
        .update(tradingJournal)
        .set({
          priceExit: exitData.priceExit,
          realizedPnl: exitData.realizedPnl,
          winLoss: exitData.winLoss,
          holdingPeriod: exitData.holdingPeriod,
          maxDrawdown: exitData.maxDrawdown,
          maxProfit: exitData.maxProfit,
          lessons: exitData.lessons,
          improvements: exitData.improvements,
          emotionalState: exitData.emotionalState,
          marketTimingScore: exitData.marketTimingScore,
          updatedAt: new Date()
        })
        .where(eq(tradingJournal.tradeId, tradeId))
        .returning();

      console.log(`📊 Trade updated: ${tradeId} - ${exitData.winLoss} with PnL: ${exitData.realizedPnl}`);
      return result;
      
    } catch (error) {
      console.error('Failed to update trade exit:', error);
      throw error;
    }
  }

  // Record portfolio snapshot
  async recordPortfolioSnapshot(snapshotData: {
    totalValueUSD: string;
    totalValueSOL: string;
    cashBalance: string;
    holdings: any;
    dailyPnl?: string;
    totalPnl?: string;
    solPrice: string;
    consciousnessLevel?: string;
    confidenceScore?: string;
  }) {
    try {
      const insertData: InsertPortfolioSnapshot = {
        totalValueUSD: snapshotData.totalValueUSD,
        totalValueSOL: snapshotData.totalValueSOL,
        cashBalance: snapshotData.cashBalance,
        holdings: snapshotData.holdings,
        dailyPnl: snapshotData.dailyPnl,
        totalPnl: snapshotData.totalPnl,
        solPrice: snapshotData.solPrice,
        consciousnessLevel: snapshotData.consciousnessLevel,
        confidenceScore: snapshotData.confidenceScore
      };

      const [result] = await db.insert(portfolioSnapshots).values(insertData).returning();
      return result;
      
    } catch (error) {
      console.error('Failed to record portfolio snapshot:', error);
      throw error;
    }
  }

  // Record trading insight
  async recordInsight(insightData: {
    category: 'pattern' | 'anomaly' | 'opportunity' | 'risk' | 'performance';
    title: string;
    description: string;
    confidence: string;
    impactScore: string;
    actionRecommendation?: string;
    timeHorizon?: 'immediate' | 'short' | 'medium' | 'long';
    relatedTrades?: any;
    marketData?: any;
  }) {
    try {
      const insertData: InsertTradingInsight = {
        category: insightData.category,
        title: insightData.title,
        description: insightData.description,
        confidence: insightData.confidence,
        impactScore: insightData.impactScore,
        actionRecommendation: insightData.actionRecommendation,
        timeHorizon: insightData.timeHorizon,
        relatedTrades: insightData.relatedTrades,
        marketData: insightData.marketData
      };

      const [result] = await db.insert(tradingInsights).values(insertData).returning();
      
      console.log(`💡 Insight recorded: ${insightData.title} (${insightData.category})`);
      return result;
      
    } catch (error) {
      console.error('Failed to record insight:', error);
      throw error;
    }
  }

  // Get trading performance analytics
  async getPerformanceAnalytics(days: number = 30) {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Get trades within period
      const trades = await db
        .select()
        .from(tradingJournal)
        .where(and(
          gte(tradingJournal.timestamp, startDate),
          eq(tradingJournal.isActive, true)
        ))
        .orderBy(desc(tradingJournal.timestamp));

      // Calculate metrics
      const totalTrades = trades.length;
      const winningTrades = trades.filter(t => t.winLoss === 'win').length;
      const losingTrades = trades.filter(t => t.winLoss === 'loss').length;
      const openTrades = trades.filter(t => t.winLoss === 'open').length;
      
      const winRate = totalTrades > 0 ? (winningTrades / (winningTrades + losingTrades)) : 0;
      
      const totalPnl = trades.reduce((sum, trade) => {
        const pnl = parseFloat(trade.realizedPnl || '0');
        return sum + pnl;
      }, 0);

      const avgTrade = totalTrades > 0 ? totalPnl / totalTrades : 0;
      
      // Get recent portfolio snapshots
      const portfolioHistory = await db
        .select()
        .from(portfolioSnapshots)
        .where(gte(portfolioSnapshots.timestamp, startDate))
        .orderBy(desc(portfolioSnapshots.timestamp))
        .limit(30);

      // Calculate portfolio growth
      const portfolioGrowth = portfolioHistory.length >= 2 
        ? ((parseFloat(portfolioHistory[0].totalValueUSD) - parseFloat(portfolioHistory[portfolioHistory.length - 1].totalValueUSD)) / parseFloat(portfolioHistory[portfolioHistory.length - 1].totalValueUSD)) * 100
        : 0;

      return {
        period: `${days} days`,
        totalTrades,
        winningTrades,
        losingTrades,
        openTrades,
        winRate: Math.round(winRate * 100),
        totalPnlUSD: totalPnl.toFixed(2),
        avgTradeUSD: avgTrade.toFixed(2),
        portfolioGrowthPercent: portfolioGrowth.toFixed(2),
        currentPortfolioValue: portfolioHistory[0]?.totalValueUSD || '0',
        trades: trades.slice(0, 10), // Last 10 trades
        portfolioHistory: portfolioHistory.slice(0, 7) // Last 7 snapshots
      };
      
    } catch (error) {
      console.error('Failed to get performance analytics:', error);
      throw error;
    }
  }

  // Get strategy performance
  async getStrategyPerformance() {
    try {
      const strategyStats = await db
        .select({
          strategy: tradingJournal.strategy,
          totalTrades: sql<number>`count(*)`,
          winRate: sql<number>`round(avg(case when ${tradingJournal.winLoss} = 'win' then 100 else 0 end), 2)`,
          avgPnl: sql<number>`round(avg(${tradingJournal.realizedPnl}), 4)`,
          totalPnl: sql<number>`round(sum(${tradingJournal.realizedPnl}), 4)`
        })
        .from(tradingJournal)
        .where(and(
          eq(tradingJournal.isActive, true),
          sql`${tradingJournal.winLoss} != 'open'`
        ))
        .groupBy(tradingJournal.strategy)
        .orderBy(sql`round(sum(${tradingJournal.realizedPnl}), 4) desc`);

      return strategyStats;
      
    } catch (error) {
      console.error('Failed to get strategy performance:', error);
      throw error;
    }
  }

  // Get recent insights
  async getRecentInsights(limit: number = 10) {
    try {
      const insights = await db
        .select()
        .from(tradingInsights)
        .where(eq(tradingInsights.isActive, true))
        .orderBy(desc(tradingInsights.timestamp))
        .limit(limit);

      return insights;
      
    } catch (error) {
      console.error('Failed to get recent insights:', error);
      throw error;
    }
  }

  // Get trade history with filters
  async getTradeHistory(filters: {
    strategy?: string;
    tokenSymbol?: string;
    winLoss?: 'win' | 'loss' | 'breakeven' | 'open';
    days?: number;
    limit?: number;
  } = {}) {
    try {
      let query = db.select().from(tradingJournal).where(eq(tradingJournal.isActive, true));

      if (filters.strategy) {
        query = query.where(eq(tradingJournal.strategy, filters.strategy));
      }

      if (filters.tokenSymbol) {
        query = query.where(eq(tradingJournal.tokenSymbol, filters.tokenSymbol));
      }

      if (filters.winLoss) {
        query = query.where(eq(tradingJournal.winLoss, filters.winLoss));
      }

      if (filters.days) {
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - filters.days);
        query = query.where(gte(tradingJournal.timestamp, startDate));
      }

      const trades = await query
        .orderBy(desc(tradingJournal.timestamp))
        .limit(filters.limit || 50);

      return trades;
      
    } catch (error) {
      console.error('Failed to get trade history:', error);
      throw error;
    }
  }

  // Automated portfolio snapshot (called periodically)
  async takeAutomatedSnapshot(portfolioData: {
    totalValueUSD: number;
    totalValueSOL: number;
    solPrice: number;
    holdings: any;
    consciousnessLevel?: number;
  }) {
    try {
      await this.recordPortfolioSnapshot({
        totalValueUSD: portfolioData.totalValueUSD.toString(),
        totalValueSOL: portfolioData.totalValueSOL.toString(),
        cashBalance: portfolioData.totalValueSOL.toString(),
        holdings: portfolioData.holdings,
        solPrice: portfolioData.solPrice.toString(),
        consciousnessLevel: portfolioData.consciousnessLevel?.toString()
      });

      console.log(`📸 Portfolio snapshot taken: $${portfolioData.totalValueUSD.toFixed(2)}`);
      
    } catch (error) {
      console.error('Failed to take automated snapshot:', error);
    }
  }
}

export const tradingJournalService = new TradingJournalService();