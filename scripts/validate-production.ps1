# Verifica checklist produccion (Fases 4-6 + post-Fase 7).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== TOGESC validate-production ===" -ForegroundColor Cyan

Push-Location "$Root\TOGESC\togesc"
flutter pub get | Out-Null
Write-Host "[1/3] flutter analyze..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }

Write-Host "[2/3] flutter test..." -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
Pop-Location

Write-Host "[3/3] Comprobaciones de repo..." -ForegroundColor Cyan
$repoChecks = @(
  @{ Path = "supabase/migrations"; Label = "Migraciones Supabase" },
  @{ Path = "scripts/repair-supabase-migrations.ps1"; Label = "Script repair migraciones" },
  @{ Path = "docs/qa_checklist.md"; Label = "Checklist QA manual" },
  @{ Path = "docs/mobile_release.md"; Label = "Guia release movil" },
  @{ Path = "TOGESC/togesc/android/key.properties.example"; Label = "Ejemplo firma Android" }
)

foreach ($c in $repoChecks) {
  $full = Join-Path $Root $c.Path
  if (Test-Path $full) {
    Write-Host "  OK  $($c.Label)" -ForegroundColor Green
  } else {
    Write-Host "  FALTA  $($c.Label) ($($c.Path))" -ForegroundColor Red
    exit 1
  }
}

$checks = @(
  "Supabase: npx supabase migration list --linked (local = remoto)",
  "Edge Functions stripe-webhook + revenuecat-webhook desplegadas",
  "GitHub Secrets: SUPABASE_*, STRIPE_*, MONETIZATION_ENABLED, SENTRY_DSN",
  "Stripe success URL: https://togesc.vercel.app/?checkout=success",
  "Sync: misma cuenta web + movil mismo SRS tras Sincronizar",
  "Pagos sandbox: Stripe test + RevenueCat sandbox",
  "QA manual: docs/qa_checklist.md (~45 min)",
  "Android release: key.properties + AAB (docs/mobile_release.md)"
)

Write-Host ""
Write-Host "Checklist manual post-deploy:" -ForegroundColor Yellow
foreach ($c in $checks) { Write-Host "  [ ] $c" }

Write-Host ""
Write-Host "Scripts utiles:" -ForegroundColor Green
Write-Host "  .\scripts\repair-supabase-migrations.ps1"
Write-Host "  .\scripts\supabase-push.ps1"
Write-Host "  .\scripts\deploy-functions.ps1"
Write-Host "  .\scripts\build-android-release.ps1"
Write-Host ""
Write-Host "validate-production: OK (automatizado)" -ForegroundColor Green
