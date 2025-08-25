-- satisfaction_4plus_rate
create or replace view v_ab_satisfaction as
select ab_bucket, date_trunc('day', ts) d,
  sum( (coalesce((props->>'rating')::int,0) >= 4)::int )::float / nullif(count(*),0) as rate
from telemetry_events
where event = 'survey_submit'
group by 1,2;

-- tri_view_pass_rate
create or replace view v_ab_tri_view as
select ab_bucket, date_trunc('day', ts) d,
  sum( (props->>'views') = '3' )::float / nullif(sum( case when event='start_capture' then 1 else 0 end ),0) as rate
from telemetry_events
where event in ('start_capture','capture_ok')
group by 1,2;

-- deformation_violation_rate
create or replace view v_ab_violation as
select ab_bucket, date_trunc('day', ts) d,
  sum( case when event in ('violation_soft','violation_hard') then 1 else 0 end )::float /
  nullif(sum( case when event='effect_applied' then 1 else 0 end ),0) as rate
from telemetry_events
where event in ('violation_soft','violation_hard','effect_applied')
group by 1,2;


