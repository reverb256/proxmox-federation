/**
 * Void Proxy Server - OpenAI-compatible API that routes to Quantum Autorouter
 * Run this locally to provide an API key-authenticated endpoint for Void
 */

const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

// OpenAI-compatible endpoint for Void
app.post('/v1/chat/completions', async (req, res) => {
  try {
    // Extract messages from OpenAI format
    const { messages, model, max_tokens, temperature } = req.body;
    
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({
        error: { message: 'Messages array is required' }
      });
    }

    const lastMessage = messages[messages.length - 1];
    const systemMessage = messages.find(m => m.role === 'system');
    
    // Analyze content for optimal routing
    const contentType = analyzeContentType(lastMessage.content);
    const intent = analyzeIntent(lastMessage.content);
    
    // Route to quantum autorouter
    const autorouterPayload = {
      content: lastMessage.content,
      contentType,
      intent,
      priority: 'medium',
      context: systemMessage?.content,
      maxTokens: max_tokens || 1000,
      temperature: temperature || 0.7,
      agentId: 'void-proxy'
    };

    console.log(`[VOID-PROXY] Routing ${intent} request for ${contentType}`);

    const response = await fetch('https://quantum-rhythm-snyper256.replit.app/api/ai-autorouter/route', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Void-Proxy/1.0'
      },
      body: JSON.stringify(autorouterPayload)
    });

    if (!response.ok) {
      throw new Error(`Autorouter failed: ${response.status}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(`Routing failed: ${data.error}`);
    }

    // Convert back to OpenAI format
    const openaiResponse = {
      id: `chatcmpl-${Date.now()}`,
      object: 'chat.completion',
      created: Math.floor(Date.now() / 1000),
      model: data.data.model || 'quantum-autorouter',
      choices: [{
        index: 0,
        message: {
          role: 'assistant',
          content: data.data.content
        },
        finish_reason: 'stop'
      }],
      usage: {
        prompt_tokens: data.metadata?.tokensUsed?.prompt || estimateTokens(lastMessage.content),
        completion_tokens: data.metadata?.tokensUsed?.completion || estimateTokens(data.data.content),
        total_tokens: data.metadata?.tokensUsed?.total || estimateTokens(lastMessage.content + data.data.content)
      }
    };

    console.log(`[VOID-PROXY] ✅ Routed to ${data.data.model} (${data.metadata?.processingTime}ms)`);
    res.json(openaiResponse);

  } catch (error) {
    console.error('[VOID-PROXY] Error:', error.message);
    
    // Fallback response
    res.json({
      id: `chatcmpl-${Date.now()}`,
      object: 'chat.completion',
      created: Math.floor(Date.now() / 1000),
      model: 'fallback',
      choices: [{
        index: 0,
        message: {
          role: 'assistant',
          content: generateFallbackResponse(req.body.messages[req.body.messages.length - 1].content)
        },
        finish_reason: 'stop'
      }],
      usage: { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }
    });
  }
});

// Health check endpoint
app.get('/v1/models', async (req, res) => {
  try {
    const response = await fetch('https://quantum-rhythm-snyper256.replit.app/api/ai-autorouter/models');
    const data = await response.json();
    
    const models = data.success ? data.data.models.map(m => ({
      id: m.name,
      object: 'model',
      created: Date.now(),
      owned_by: 'quantum-autorouter'
    })) : [
      { id: 'claude-sonnet-4-20250514', object: 'model', created: Date.now(), owned_by: 'quantum-autorouter' },
      { id: 'gpt-4o', object: 'model', created: Date.now(), owned_by: 'quantum-autorouter' },
      { id: 'llama-3.1-405b-instruct', object: 'model', created: Date.now(), owned_by: 'quantum-autorouter' }
    ];

    res.json({ object: 'list', data: models });
  } catch (error) {
    res.json({ object: 'list', data: [] });
  }
});

function analyzeContentType(content) {
  const lower = content.toLowerCase();
  if (lower.includes('code') || lower.includes('function') || lower.includes('debug')) return 'code';
  if (lower.includes('analyze') || lower.includes('analysis')) return 'analysis';
  if (lower.includes('creative') || lower.includes('write') || lower.includes('story')) return 'creative';
  if (lower.includes('technical') || lower.includes('architecture')) return 'technical';
  return 'text';
}

function analyzeIntent(content) {
  const lower = content.toLowerCase();
  if (lower.includes('analyze') || lower.includes('examine')) return 'analyze';
  if (lower.includes('summarize') || lower.includes('summary')) return 'summarize';
  if (lower.includes('debug') || lower.includes('fix') || lower.includes('error')) return 'debug';
  if (lower.includes('optimize') || lower.includes('improve')) return 'optimize';
  if (lower.includes('explain') || lower.includes('how')) return 'explain';
  if (lower.includes('translate') || lower.includes('convert')) return 'translate';
  return 'generate';
}

function estimateTokens(text) {
  return Math.ceil(text.length / 3.5);
}

function generateFallbackResponse(content) {
  const lower = content.toLowerCase();
  if (lower.includes('code')) {
    return 'I can help with code analysis and development. Please provide more specific details about what you need assistance with.';
  }
  if (lower.includes('debug')) {
    return 'To debug effectively: 1) Check error messages, 2) Verify recent changes, 3) Use logging tools, 4) Test with minimal examples.';
  }
  return 'I understand your request. Could you provide more context or specific details to help me assist you better?';
}

app.listen(PORT, () => {
  console.log(`🚀 Void Proxy Server running on http://localhost:${PORT}`);
  console.log(`📋 Configure Void with:`);
  console.log(`   Base URL: http://localhost:${PORT}/v1`);
  console.log(`   API Key: any-key-works`);
  console.log(`   Model: quantum-autorouter`);
});