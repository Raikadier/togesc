# Genera Android App Bundle (AAB) de release.
# Requiere: Flutter + Android SDK. Firma release si existe android/key.properties.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$App = Join-Path $Root "TOGESC\togesc"
$KeyProps = Join-Path $App "android\key.properties"

Push-Location $App

if (-not (Test-Path $KeyProps)) {
  Write-Host "AVISO: android/key.properties no existe. El AAB usara firma DEBUG." -ForegroundColor Yellow
  Write-Host "       Para Play Store, copia key.properties.example y crea el keystore." -ForegroundColor Yellow
  Write-Host "       Ver docs/mobile_release.md" -ForegroundColor Yellow
  Write-Host ""
}

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build appbundle --release
$code = $LASTEXITCODE
Pop-Location

if ($code -eq 0) {
  $aab = Join-Path $App "build\app\outputs\bundle\release\app-release.aab"
  Write-Host ""
  Write-Host "AAB generado:" -ForegroundColor Green
  Write-Host "  $aab"
}

exit $code
