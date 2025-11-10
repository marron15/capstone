# Post-build script to disable Flutter service worker and prevent timeout errors
# Run this after: flutter build web

$bootstrapPath = Join-Path $PSScriptRoot "build\web\flutter_bootstrap.js"

if (-not (Test-Path $bootstrapPath)) {
    Write-Host "flutter_bootstrap.js not found. Make sure you run 'flutter build web' first." -ForegroundColor Red
    exit 1
}

$content = Get-Content $bootstrapPath -Raw

# Remove serviceWorkerSettings from the load call
# Match the pattern: _flutter.loader.load({ serviceWorkerSettings: { ... } });
if ($content -match '_flutter\.loader\.load\(\s*\{[^}]*serviceWorkerSettings[^}]*\}[^}]*\}\);') {
    $content = $content -replace '_flutter\.loader\.load\(\s*\{[^}]*serviceWorkerSettings[^}]*\}[^}]*\}\);', "_flutter.loader.load({`r`n  // Service worker disabled to prevent timeout errors`r`n});"
    Set-Content $bootstrapPath -Value $content -NoNewline
    Write-Host "Successfully patched flutter_bootstrap.js - service worker disabled" -ForegroundColor Green
} else {
    Write-Host "Service worker settings not found or already patched" -ForegroundColor Yellow
}

