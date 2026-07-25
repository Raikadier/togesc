-- Las vistas de metricas heredaban SECURITY DEFINER y saltaban RLS.
-- Con security_invoker respetan los permisos de quien consulta; el rol
-- service_role sigue viendo los agregados para el dashboard interno.
alter view public.metrics_daily set (security_invoker = true);
alter view public.metrics_csat_daily set (security_invoker = true);
