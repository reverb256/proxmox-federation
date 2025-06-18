import { Keypair } from '@solana/web3.js';

// Generate a new keypair for the trading wallet
const keypair = Keypair.generate();
const publicKey = keypair.publicKey.toString();
const privateKeyArray = Array.from(keypair.secretKey);
const privateKeyBase58 = Buffer.from(keypair.secretKey).toString('base64');

console.log('🔐 VibeCoding Quantum Trading Wallet Generated');
console.log('==========================================');
console.log('');
console.log('Wallet Address:', publicKey);
console.log('');
console.log('Private Key (Base64):', privateKeyBase58);
console.log('');
console.log('Private Key (Array):', JSON.stringify(privateKeyArray));
console.log('');
console.log('⚠️  SECURITY WARNING:');
console.log('- Store these credentials securely');
console.log('- Never share your private key');
console.log('- Fund this wallet with SOL for trading');
console.log('');
console.log('Environment Variables:');
console.log('PRIVATE_KEY=' + privateKeyBase58);
console.log('PUBLIC_KEY=' + publicKey);