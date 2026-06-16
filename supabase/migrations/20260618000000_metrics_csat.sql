-- Fase 6: agregados CSAT para dashboard

create or replace view public.metrics_csat_daily as
select
  date_trunc('day', created_at at time zone 'utc')::date as day,
  count(*)::bigint as responses,
  round(avg((properties->>'rating')::numeric), 2) as avg_rating
from public.analytics_events
where event_name = 'csat_submitted'
  and properties ? 'rating'
group by 1
order by 1 desc;

grant select on public.metrics_csat_daily to authenticated;
