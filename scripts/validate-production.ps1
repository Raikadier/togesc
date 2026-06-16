# Verifica checklist produccion (Fases 4-6).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== TOGESC validate-production ===" -ForegroundColor Cyan

Push-Location "$Root\TOGESC\togesc"
flutter pub get | Out-Null
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Pop-Location

$checks = @(
  "Supabase migraciones en supabase/migrations/",
  "Edge Functions stripe-webhook + revenuecat-webhook",
  "GitHub Secrets: SUPABASE_*, STRIPE_*, MONETIZATION_ENABLED, SENTRY_DSN",
  "Stripe success URL: https://togesc.vercel.app/?checkout=success",
  "GitHub workflow uptime-check activo",
  "Migracion metrics_csat aplicada en Supabase",
  "Prueba sandbox: Stripe test + RevenueCat sandbox"
)

Write-Host ""
Write-Host "Checklist manual post-deploy:" -ForegroundColor Yellow
foreach ($c in $checks) { Write-Host "  [ ] $c" }

Write-Host ""
Write-Host "Scripts:" -ForegroundColor Green
Write-Host "  .\scripts\supabase-push.ps1"
Write-Host "  .\scripts\deploy-functions.ps1"
