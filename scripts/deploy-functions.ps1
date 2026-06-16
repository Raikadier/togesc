# Despliega Edge Functions de monetizacion (Stripe + RevenueCat).
# Secrets en Supabase Dashboard > Edge Functions:
#   STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET
#   REVENUECAT_WEBHOOK_SECRET
#   SUPABASE_SERVICE_ROLE_KEY (auto en hosted)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $Root

Write-Host "Enlazando proyecto..."
npx supabase link --project-ref puetlvcsrntwweuxinee

Write-Host "Desplegando stripe-webhook..."
npx supabase functions deploy stripe-webhook --no-verify-jwt

Write-Host "Desplegando revenuecat-webhook..."
npx supabase functions deploy revenuecat-webhook --no-verify-jwt

Write-Host "Listo. Configura webhooks:"
Write-Host "  Stripe -> https://puetlvcsrntwweuxinee.supabase.co/functions/v1/stripe-webhook"
Write-Host "  RevenueCat -> https://puetlvcsrntwweuxinee.supabase.co/functions/v1/revenuecat-webhook"
