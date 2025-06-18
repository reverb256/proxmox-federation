/**
 * Cloudflare Worker for High-Availability Static Portfolio
 * Handles routing, security headers, and fallback to GitHub Pages
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Security headers for all responses
    const securityHeaders = {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Content-Security-Policy': "default-src 'self' 'unsafe-inline' cdn.tailwindcss.com; img-src 'self' data:; font-src 'self' fonts.googleapis.com fonts.gstatic.com",
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Cache-Control': 'public, max-age=86400'
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          ...securityHeaders,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        }
      });
    }

    try {
      // Primary: Serve from Cloudflare KV storage
      const cachedResponse = await env.STATIC_ASSETS.get(url.pathname === '/' ? 'index.html' : url.pathname.slice(1));
      
      if (cachedResponse) {
        const contentType = getContentType(url.pathname);
        return new Response(cachedResponse, {
          headers: {
            ...securityHeaders,
            'Content-Type': contentType,
            'X-Served-By': 'cloudflare-primary'
          }
        });
      }

      // Fallback: Proxy to GitHub Pages
      const githubUrl = `https://reverb256.github.io${url.pathname}`;
      const githubResponse = await fetch(githubUrl, {
        headers: request.headers
      });

      if (githubResponse.ok) {
        const content = await githubResponse.text();
        
        // Cache successful responses
        ctx.waitUntil(
          env.STATIC_ASSETS.put(
            url.pathname === '/' ? 'index.html' : url.pathname.slice(1),
            content,
            { expirationTtl: 86400 }
          )
        );

        return new Response(content, {
          status: githubResponse.status,
          headers: {
            ...securityHeaders,
            'Content-Type': githubResponse.headers.get('Content-Type') || 'text/html',
            'X-Served-By': 'github-fallback'
          }
        });
      }

      // Ultimate fallback: Return portfolio HTML
      return new Response(getPortfolioHTML(), {
        headers: {
          ...securityHeaders,
          'Content-Type': 'text/html',
          'X-Served-By': 'cloudflare-fallback'
        }
      });

    } catch (error) {
      // Error fallback
      return new Response(getErrorHTML(error), {
        status: 500,
        headers: {
          ...securityHeaders,
          'Content-Type': 'text/html',
          'X-Served-By': 'cloudflare-error'
        }
      });
    }
  }
};

function getContentType(pathname) {
  const ext = pathname.split('.').pop();
  const types = {
    'html': 'text/html',
    'css': 'text/css',
    'js': 'application/javascript',
    'json': 'application/json',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon'
  };
  return types[ext] || 'text/html';
}

function getPortfolioHTML() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reverb VibeCoding - Quantum AI Trading Platform</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #16213e 100%); }
        .glow-text { text-shadow: 0 0 10px currentColor, 0 0 20px currentColor; }
    </style>
</head>
<body class="bg-black text-white min-h-screen flex items-center justify-center">
    <div class="text-center space-y-8">
        <div class="w-32 h-32 mx-auto bg-gradient-to-r from-cyan-400 to-purple-600 rounded-full flex items-center justify-center animate-pulse">
            <span class="text-4xl">⚡</span>
        </div>
        <h1 class="text-4xl font-bold bg-gradient-to-r from-cyan-400 to-purple-600 bg-clip-text text-transparent glow-text">
            REVERB VIBECODING
        </h1>
        <p class="text-xl text-gray-300">Quantum AI Trading Platform</p>
        <div class="text-cyan-400">High-Availability Mode Active</div>
    </div>
</body>
</html>`;
}

function getErrorHTML(error) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service Temporarily Unavailable</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-black text-white min-h-screen flex items-center justify-center">
    <div class="text-center space-y-6">
        <div class="text-red-500 text-6xl">⚠️</div>
        <h1 class="text-2xl font-bold">Service Temporarily Unavailable</h1>
        <p class="text-gray-400">Please try again in a few moments</p>
        <button onclick="location.reload()" class="bg-cyan-500 hover:bg-cyan-600 px-6 py-2 rounded">
            Retry
        </button>
    </div>
</body>
</html>`;
}