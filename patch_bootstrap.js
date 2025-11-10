// Post-build script to disable Flutter service worker and prevent timeout errors
// Run this after: flutter build web

const fs = require('fs');
const path = require('path');

const bootstrapPath = path.join(__dirname, 'build', 'web', 'flutter_bootstrap.js');

if (!fs.existsSync(bootstrapPath)) {
  console.error('flutter_bootstrap.js not found. Make sure you run "flutter build web" first.');
  process.exit(1);
}

let content = fs.readFileSync(bootstrapPath, 'utf8');

// Remove serviceWorkerSettings from the load call
const pattern = /_flutter\.loader\.load\(\s*\{[^}]*serviceWorkerSettings[^}]*\}[^}]*\}\);/s;
const replacement = `_flutter.loader.load({
  // Service worker disabled to prevent timeout errors
});`;

if (pattern.test(content)) {
  content = content.replace(pattern, replacement);
  fs.writeFileSync(bootstrapPath, content, 'utf8');
  console.log('✓ Successfully patched flutter_bootstrap.js - service worker disabled');
} else {
  console.log('⚠ Service worker settings not found or already patched');
}

