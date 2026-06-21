# Repara el historial de migraciones cuando remoto y local divergen.
# Ejecutar desde la raiz del repo tras `npx supabase login` y `supabase link`.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "Enlazando proyecto..." -ForegroundColor Cyan
npx supabase link --project-ref puetlvcsrntwweuxinee

Write-Host "Marcando migraciones huerfanas del remoto como reverted..." -ForegroundColor Cyan
npx supabase migration repair --status reverted `
  20260615192734 `
  20260616012948 `
  20260616013047 `
  20260616013050 `
  20260616013051

Write-Host "Marcando migraciones locales como applied..." -ForegroundColor Cyan
npx supabase migration repair --status applied `
  20260614000000 `
  20260615000000 `
  20260616000000 `
  20260617000000 `
  20260618000000 `
  20260620000000

Write-Host "Estado final:" -ForegroundColor Cyan
npx supabase migration list --linked

Write-Host "Listo." -ForegroundColor Green
