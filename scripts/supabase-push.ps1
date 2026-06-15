# Aplica migraciones SQL al proyecto Supabase remoto "togesc".
# Requisitos: npx supabase login (una vez) y SUPABASE_ACCESS_TOKEN o sesion CLI.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $Root

Write-Host "Enlazando proyecto puetlvcsrntwweuxinee..."
npx supabase link --project-ref puetlvcsrntwweuxinee

Write-Host "Aplicando migraciones..."
npx supabase db push

Write-Host "Listo."
