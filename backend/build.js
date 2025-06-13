#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Starting NestJS build for Vercel...');

try {
  // Install dependencies
  console.log('Installing dependencies...');
  execSync('npm install', { stdio: 'inherit' });
  
  // Build the NestJS application
  console.log('Building NestJS application...');
  execSync('npx nest build', { stdio: 'inherit' });
  
  // Verify build output
  const distPath = path.join(__dirname, 'dist');
  if (fs.existsSync(distPath)) {
    console.log('✅ Build completed successfully');
    console.log('Build output:', fs.readdirSync(distPath));
  } else {
    throw new Error('Build failed - dist directory not found');
  }
  
} catch (error) {
  console.error('❌ Build failed:', error.message);
  process.exit(1);
}