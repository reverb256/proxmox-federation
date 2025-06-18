import { Router } from 'express';
import { tradingJournalService } from '../trading-journal-service';
import { z } from 'zod';

const router = Router();

// Get performance analytics
router.get('/analytics', async (req, res) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const analytics = await tradingJournalService.getPerformanceAnalytics(days);
    res.json({ success: true, analytics });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to get analytics' });
  }
});

// Get strategy performance
router.get('/strategies', async (req, res) => {
  try {
    const strategies = await tradingJournalService.getStrategyPerformance();
    res.json({ success: true, strategies });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to get strategy performance' });
  }
});

// Get trade history
router.get('/trades', async (req, res) => {
  try {
    const filters = {
      strategy: req.query.strategy as string,
      tokenSymbol: req.query.token as string,
      winLoss: req.query.status as 'win' | 'loss' | 'breakeven' | 'open',
      days: parseInt(req.query.days as string),
      limit: parseInt(req.query.limit as string)
    };
    
    const trades = await tradingJournalService.getTradeHistory(filters);
    res.json({ success: true, trades });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to get trade history' });
  }
});

// Get recent insights
router.get('/insights', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const insights = await tradingJournalService.getRecentInsights(limit);
    res.json({ success: true, insights });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to get insights' });
  }
});

// Record new trade
router.post('/trade', async (req, res) => {
  try {
    const tradeSchema = z.object({
      action: z.enum(['buy', 'sell', 'hold', 'liquidate']),
      tokenSymbol: z.string(),
      tokenAddress: z.string().optional(),
      quantity: z.string(),
      priceEntry: z.string(),
      costBasis: z.string(),
      fees: z.string(),
      aiConfidence: z.string(),
      consciousnessLevel: z.string(),
      decisionReasoning: z.string(),
      riskScore: z.string(),
      strategy: z.string(),
      signalSource: z.string(),
      executionMethod: z.enum(['manual', 'automated', 'hybrid']),
      positionSize: z.string(),
      stopLoss: z.string().optional(),
      takeProfit: z.string().optional(),
      technicalIndicators: z.any().optional(),
      marketCondition: z.enum(['bullish', 'bearish', 'sideways', 'volatile']).optional(),
      transactionHash: z.string().optional(),
      isSimulated: z.boolean().optional()
    });

    const tradeData = tradeSchema.parse(req.body);
    const result = await tradingJournalService.recordTrade(tradeData);
    res.json({ success: true, trade: result });
  } catch (error) {
    res.status(400).json({ success: false, error: 'Invalid trade data' });
  }
});

// Update trade exit
router.put('/trade/:tradeId/exit', async (req, res) => {
  try {
    const exitSchema = z.object({
      priceExit: z.string(),
      realizedPnl: z.string(),
      winLoss: z.enum(['win', 'loss', 'breakeven']),
      holdingPeriod: z.number(),
      maxDrawdown: z.string().optional(),
      maxProfit: z.string().optional(),
      lessons: z.string().optional(),
      improvements: z.string().optional(),
      emotionalState: z.string().optional(),
      marketTimingScore: z.string().optional()
    });

    const exitData = exitSchema.parse(req.body);
    const result = await tradingJournalService.updateTradeExit(req.params.tradeId, exitData);
    res.json({ success: true, trade: result });
  } catch (error) {
    res.status(400).json({ success: false, error: 'Invalid exit data' });
  }
});

// Record insight
router.post('/insight', async (req, res) => {
  try {
    const insightSchema = z.object({
      category: z.enum(['pattern', 'anomaly', 'opportunity', 'risk', 'performance']),
      title: z.string(),
      description: z.string(),
      confidence: z.string(),
      impactScore: z.string(),
      actionRecommendation: z.string().optional(),
      timeHorizon: z.enum(['immediate', 'short', 'medium', 'long']).optional(),
      relatedTrades: z.any().optional(),
      marketData: z.any().optional()
    });

    const insightData = insightSchema.parse(req.body);
    const result = await tradingJournalService.recordInsight(insightData);
    res.json({ success: true, insight: result });
  } catch (error) {
    res.status(400).json({ success: false, error: 'Invalid insight data' });
  }
});

export default router;