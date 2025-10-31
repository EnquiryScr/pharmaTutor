#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Setting up Tutoring Platform Backend...\n');

// Check if .env exists
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
  console.log('📝 Creating environment configuration file...');
  fs.copyFileSync(
    path.join(__dirname, '.env.example'),
    envPath
  );
  console.log('✅ Created .env file. Please update with your configuration.');
} else {
  console.log('⚠️  .env file already exists. Skipping creation.');
}

// Check if node_modules exists
const nodeModulesPath = path.join(__dirname, 'node_modules');
if (!fs.existsSync(nodeModulesPath)) {
  console.log('📦 Installing dependencies...');
  try {
    execSync('npm install', { stdio: 'inherit' });
    console.log('✅ Dependencies installed successfully.');
  } catch (error) {
    console.error('❌ Failed to install dependencies:', error.message);
    process.exit(1);
  }
} else {
  console.log('✅ Dependencies already installed.');
}

// Create required directories
const requiredDirs = [
  'uploads',
  'uploads/assignments',
  'uploads/queries', 
  'uploads/profile',
  'uploads/general',
  'logs'
];

console.log('\n📁 Creating required directories...');
requiredDirs.forEach(dir => {
  const dirPath = path.join(__dirname, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`  Created: ${dir}`);
  }
});

console.log('\n✅ Setup completed successfully!');
console.log('\n📋 Next steps:');
console.log('1. Update the .env file with your configuration');
console.log('2. Set up your PostgreSQL database');
console.log('3. Start Redis server');
console.log('4. Run database migrations:');
console.log('   psql your_database_name < src/schema/database.sql');
console.log('   psql your_database_name < src/schema/indexes.sql');
console.log('5. Start the development server: npm run dev');
console.log('\n🎉 Happy coding!');