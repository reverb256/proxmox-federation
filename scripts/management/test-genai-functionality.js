/**
 * GenAI Functionality Test
 * Tests the actual AI generation capabilities
 */

async function testPollinationsImageGeneration() {
  console.log('Testing Pollinations image generation...');
  
  try {
    const prompt = 'anime girl with silver hair and golden eyes, hoyoverse style';
    const response = await fetch(`https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=512&height=512&model=flux`);
    
    if (response.ok) {
      console.log('✅ Pollinations image generation works');
      console.log('Response URL:', response.url);
      return true;
    } else {
      console.log('❌ Pollinations failed:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ Pollinations error:', error.message);
    return false;
  }
}

async function testPollinationsVoice() {
  console.log('Testing Pollinations voice synthesis...');
  
  try {
    const text = 'Hello, welcome to our AI platform!';
    const voice = 'en_female_1';
    const response = await fetch(`https://text-to-speech.pollinations.ai?text=${encodeURIComponent(text)}&voice=${voice}`);
    
    if (response.ok) {
      console.log('✅ Pollinations voice synthesis works');
      return true;
    } else {
      console.log('❌ Pollinations voice failed:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ Pollinations voice error:', error.message);
    return false;
  }
}

async function testHuggingFaceText() {
  console.log('Testing Hugging Face text generation...');
  
  try {
    const response = await fetch('https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        inputs: 'Tell me about the stars',
        parameters: { max_length: 100 }
      })
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log('✅ Hugging Face text generation works');
      console.log('Sample output:', result);
      return true;
    } else {
      console.log('❌ Hugging Face failed:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ Hugging Face error:', error.message);
    return false;
  }
}

async function testBrowserTTS() {
  console.log('Testing Browser TTS...');
  
  try {
    if ('speechSynthesis' in window) {
      console.log('✅ Browser TTS is available');
      const utterance = new SpeechSynthesisUtterance('Testing voice synthesis');
      utterance.rate = 0.8;
      utterance.pitch = 1.1;
      window.speechSynthesis.speak(utterance);
      return true;
    } else {
      console.log('❌ Browser TTS not supported');
      return false;
    }
  } catch (error) {
    console.log('❌ Browser TTS error:', error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🧪 Starting GenAI functionality tests...\n');
  
  const results = {
    pollinationsImage: await testPollinationsImageGeneration(),
    pollinationsVoice: await testPollinationsVoice(),
    huggingFaceText: await testHuggingFaceText(),
    browserTTS: await testBrowserTTS()
  };
  
  console.log('\n📊 Test Results Summary:');
  console.log('========================');
  Object.entries(results).forEach(([test, passed]) => {
    console.log(`${passed ? '✅' : '❌'} ${test}: ${passed ? 'WORKING' : 'FAILED'}`);
  });
  
  const workingCount = Object.values(results).filter(Boolean).length;
  console.log(`\n🎯 ${workingCount}/4 services working`);
  
  if (workingCount >= 2) {
    console.log('✅ GenAI system is functional with multiple working providers');
  } else {
    console.log('⚠️ Limited GenAI functionality - may need API keys or network fixes');
  }
  
  return results;
}

// Auto-run if in browser console
if (typeof window !== 'undefined') {
  runAllTests();
}