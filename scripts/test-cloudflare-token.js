
#!/usr/bin/env node

/**
 * Cloudflare API Token Tester
 * Validates your new token has the required permissions
 */

const API_TOKEN = process.env.CLOUDFLARE_API_TOKEN || 'your-token-here';

async function testCloudflareToken() {
  console.log('🔐 Testing Cloudflare API Token...');
  
  const headers = {
    'Authorization': `Bearer ${API_TOKEN}`,
    'Content-Type': 'application/json'
  };

  try {
    // Test 1: Get user details
    console.log('1️⃣ Testing user access...');
    const userResponse = await fetch('https://api.cloudflare.com/client/v4/user', { headers });
    const userData = await userResponse.json();
    
    if (userData.success) {
      console.log(`✅ User access: ${userData.result.email}`);
    } else {
      console.log('❌ User access failed:', userData.errors);
      return;
    }

    // Test 2: List zones
    console.log('2️⃣ Testing zone access...');
    const zonesResponse = await fetch('https://api.cloudflare.com/client/v4/zones', { headers });
    const zonesData = await zonesResponse.json();
    
    if (zonesData.success) {
      console.log(`✅ Zone access: Found ${zonesData.result.length} zones`);
      zonesData.result.forEach(zone => {
        console.log(`  📍 ${zone.name} (${zone.id})`);
      });
    } else {
      console.log('❌ Zone access failed:', zonesData.errors);
      return;
    }

    // Test 3: Test DNS permissions on first zone
    if (zonesData.result.length > 0) {
      const zoneId = zonesData.result[0].id;
      console.log('3️⃣ Testing DNS permissions...');
      
      const dnsResponse = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`, { headers });
      const dnsData = await dnsResponse.json();
      
      if (dnsData.success) {
        console.log(`✅ DNS access: Found ${dnsData.result.length} DNS records`);
      } else {
        console.log('❌ DNS access failed:', dnsData.errors);
      }
    }

    console.log('\n🎉 Token validation complete!');
    
  } catch (error) {
    console.error('❌ Token test failed:', error.message);
  }
}

// Run if executed directly
if (require.main === module) {
  testCloudflareToken();
}

module.exports = { testCloudflareToken };
