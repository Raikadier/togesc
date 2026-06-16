# Consulta metricas agregadas (vistas metrics_daily y metrics_csat_daily en Supabase).
# Requiere: npx supabase login + SUPABASE_ACCESS_TOKEN

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "Metricas ultimos 7 dias (metrics_daily)..." -ForegroundColor Cyan
npx supabase link --project-ref puetlvcsrntwweuxinee
npx supabase db execute --sql "select * from public.metrics_daily where day >= current_date - interval '7 days' limit 50;"

Write-Host ""
Write-Host "CSAT ultimos 30 dias (metrics_csat_daily)..." -ForegroundColor Cyan
npx supabase db execute --sql "select * from public.metrics_csat_daily where day >= current_date - interval '30 days' limit 30;"
