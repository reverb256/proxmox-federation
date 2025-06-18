import { pgTable, text, decimal, timestamp, integer, boolean, jsonb, uuid, index } from 'drizzle-orm/pg-core';
import { createInsertSchema, createSelectSchema } from 'drizzle-zod';
import { z } from 'zod';

export const tradingJournal = pgTable('trading_journal', {
  id: uuid('id').defaultRandom().primaryKey(),
  tradeId: text('trade_id').unique(),
  timestamp: timestamp('timestamp').defaultNow().notNull(),
  
  // Trade Details
  action: text('action', { enum: ['buy', 'sell', 'hold', 'liquidate'] }).notNull(),
  tokenSymbol: text('token_symbol').notNull(),
  tokenAddress: text('token_address'),
  quantity: decimal('quantity', { precision: 18, scale: 9 }).notNull(),
  priceEntry: decimal('price_entry', { precision: 18, scale: 9 }).notNull(),
  priceExit: decimal('price_exit', { precision: 18, scale: 9 }),
  
  // Financial Metrics
  costBasis: decimal('cost_basis', { precision: 18, scale: 9 }).notNull(),
  realizedPnl: decimal('realized_pnl', { precision: 18, scale: 9 }),
  unrealizedPnl: decimal('unrealized_pnl', { precision: 18, scale: 9 }),
  fees: decimal('fees', { precision: 18, scale: 9 }).notNull(),
  
  // AI Decision Factors
  aiConfidence: decimal('ai_confidence', { precision: 5, scale: 4 }).notNull(),
  consciousnessLevel: decimal('consciousness_level', { precision: 5, scale: 2 }).notNull(),
  decisionReasoning: text('decision_reasoning').notNull(),
  marketSentiment: decimal('market_sentiment', { precision: 5, scale: 4 }),
  riskScore: decimal('risk_score', { precision: 5, scale: 4 }).notNull(),
  
  // Technical Analysis
  technicalIndicators: jsonb('technical_indicators'),
  supportLevels: jsonb('support_levels'),
  resistanceLevels: jsonb('resistance_levels'),
  volumeAnalysis: jsonb('volume_analysis'),
  
  // Market Context
  marketCondition: text('market_condition', { enum: ['bullish', 'bearish', 'sideways', 'volatile'] }),
  newsImpact: jsonb('news_impact'),
  socialSentiment: jsonb('social_sentiment'),
  
  // Performance Tracking
  holdingPeriod: integer('holding_period_seconds'),
  maxDrawdown: decimal('max_drawdown', { precision: 5, scale: 4 }),
  maxProfit: decimal('max_profit', { precision: 5, scale: 4 }),
  winLoss: text('win_loss', { enum: ['win', 'loss', 'breakeven', 'open'] }),
  
  // Strategy Information
  strategy: text('strategy').notNull(),
  signalSource: text('signal_source').notNull(),
  executionMethod: text('execution_method', { enum: ['manual', 'automated', 'hybrid'] }).notNull(),
  
  // Risk Management
  stopLoss: decimal('stop_loss', { precision: 18, scale: 9 }),
  takeProfit: decimal('take_profit', { precision: 18, scale: 9 }),
  positionSize: decimal('position_size', { precision: 5, scale: 4 }).notNull(),
  riskRewardRatio: decimal('risk_reward_ratio', { precision: 5, scale: 2 }),
  
  // Transaction Details
  transactionHash: text('transaction_hash'),
  blockNumber: integer('block_number'),
  gasUsed: decimal('gas_used', { precision: 18, scale: 9 }),
  slippage: decimal('slippage', { precision: 5, scale: 4 }),
  
  // Learning & Improvement
  lessons: text('lessons'),
  improvements: text('improvements'),
  emotionalState: text('emotional_state'),
  marketTimingScore: decimal('market_timing_score', { precision: 5, scale: 2 }),
  
  // Status
  isActive: boolean('is_active').default(true),
  isSimulated: boolean('is_simulated').default(false),
  updatedAt: timestamp('updated_at').defaultNow()
}, (table) => ({
  timestampIdx: index('trading_journal_timestamp_idx').on(table.timestamp),
  tokenSymbolIdx: index('trading_journal_token_symbol_idx').on(table.tokenSymbol),
  strategyIdx: index('trading_journal_strategy_idx').on(table.strategy),
  winLossIdx: index('trading_journal_win_loss_idx').on(table.winLoss)
}));

export const tradingStrategies = pgTable('trading_strategies', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull().unique(),
  description: text('description').notNull(),
  category: text('category', { enum: ['momentum', 'mean_reversion', 'arbitrage', 'sentiment', 'technical', 'fundamental'] }).notNull(),
  
  // Strategy Parameters
  parameters: jsonb('parameters').notNull(),
  riskLevel: text('risk_level', { enum: ['low', 'medium', 'high', 'extreme'] }).notNull(),
  timeframe: text('timeframe', { enum: ['1m', '5m', '15m', '1h', '4h', '1d'] }).notNull(),
  
  // Performance Metrics
  totalTrades: integer('total_trades').default(0),
  winRate: decimal('win_rate', { precision: 5, scale: 4 }).default('0'),
  avgReturn: decimal('avg_return', { precision: 5, scale: 4 }).default('0'),
  sharpeRatio: decimal('sharpe_ratio', { precision: 5, scale: 4 }),
  maxDrawdown: decimal('max_drawdown', { precision: 5, scale: 4 }),
  
  // Status
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});

export const portfolioSnapshots = pgTable('portfolio_snapshots', {
  id: uuid('id').defaultRandom().primaryKey(),
  timestamp: timestamp('timestamp').defaultNow().notNull(),
  
  // Portfolio Values
  totalValueUSD: decimal('total_value_usd', { precision: 18, scale: 2 }).notNull(),
  totalValueSOL: decimal('total_value_sol', { precision: 18, scale: 9 }).notNull(),
  cashBalance: decimal('cash_balance', { precision: 18, scale: 9 }).notNull(),
  
  // Holdings
  holdings: jsonb('holdings').notNull(),
  
  // Performance Metrics
  dailyPnl: decimal('daily_pnl', { precision: 18, scale: 2 }),
  totalPnl: decimal('total_pnl', { precision: 18, scale: 2 }),
  dailyReturn: decimal('daily_return', { precision: 5, scale: 4 }),
  totalReturn: decimal('total_return', { precision: 5, scale: 4 }),
  
  // Risk Metrics
  volatility: decimal('volatility', { precision: 5, scale: 4 }),
  beta: decimal('beta', { precision: 5, scale: 4 }),
  sharpeRatio: decimal('sharpe_ratio', { precision: 5, scale: 4 }),
  
  // Market Context
  solPrice: decimal('sol_price', { precision: 18, scale: 2 }).notNull(),
  marketCondition: text('market_condition'),
  
  // AI Metrics
  consciousnessLevel: decimal('consciousness_level', { precision: 5, scale: 2 }),
  confidenceScore: decimal('confidence_score', { precision: 5, scale: 4 })
}, (table) => ({
  timestampIdx: index('portfolio_snapshots_timestamp_idx').on(table.timestamp)
}));

export const tradingInsights = pgTable('trading_insights', {
  id: uuid('id').defaultRandom().primaryKey(),
  timestamp: timestamp('timestamp').defaultNow().notNull(),
  
  // Insight Details
  category: text('category', { enum: ['pattern', 'anomaly', 'opportunity', 'risk', 'performance'] }).notNull(),
  title: text('title').notNull(),
  description: text('description').notNull(),
  confidence: decimal('confidence', { precision: 5, scale: 4 }).notNull(),
  
  // Associated Data
  relatedTrades: jsonb('related_trades'),
  marketData: jsonb('market_data'),
  technicalData: jsonb('technical_data'),
  
  // Impact Assessment
  impactScore: decimal('impact_score', { precision: 5, scale: 4 }).notNull(),
  actionRecommendation: text('action_recommendation'),
  timeHorizon: text('time_horizon', { enum: ['immediate', 'short', 'medium', 'long'] }),
  
  // Validation
  validated: boolean('validated').default(false),
  actualOutcome: text('actual_outcome'),
  accuracyScore: decimal('accuracy_score', { precision: 5, scale: 4 }),
  
  // Status
  isActive: boolean('is_active').default(true)
}, (table) => ({
  timestampIdx: index('trading_insights_timestamp_idx').on(table.timestamp),
  categoryIdx: index('trading_insights_category_idx').on(table.category)
}));

// Zod schemas for validation
export const insertTradingJournalSchema = createInsertSchema(tradingJournal);
export const selectTradingJournalSchema = createSelectSchema(tradingJournal);
export const insertTradingStrategySchema = createInsertSchema(tradingStrategies);
export const selectTradingStrategySchema = createSelectSchema(tradingStrategies);
export const insertPortfolioSnapshotSchema = createInsertSchema(portfolioSnapshots);
export const selectPortfolioSnapshotSchema = createSelectSchema(portfolioSnapshots);
export const insertTradingInsightSchema = createInsertSchema(tradingInsights);
export const selectTradingInsightSchema = createSelectSchema(tradingInsights);

// Types
export type TradingJournal = typeof tradingJournal.$inferSelect;
export type InsertTradingJournal = z.infer<typeof insertTradingJournalSchema>;
export type TradingStrategy = typeof tradingStrategies.$inferSelect;
export type InsertTradingStrategy = z.infer<typeof insertTradingStrategySchema>;
export type PortfolioSnapshot = typeof portfolioSnapshots.$inferSelect;
export type InsertPortfolioSnapshot = z.infer<typeof insertPortfolioSnapshotSchema>;
export type TradingInsight = typeof tradingInsights.$inferSelect;
export type InsertTradingInsight = z.infer<typeof insertTradingInsightSchema>;