create type if not exists recon_status as enum ('queued','running','done','error');

create table if not exists recon_jobs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  device_id text not null,
  mode text not null default 'triView',
  status recon_status not null default 'queued',
  inputs jsonb not null,
  outputs jsonb,
  error text
);

create index if not exists recon_jobs_device_time_idx on recon_jobs (device_id, created_at desc);

alter table recon_jobs enable row level security;

create policy if not exists "owner can read own jobs"
  on recon_jobs for select
  using (
    auth.uid() is null and device_id = coalesce(current_setting('request.headers', true)::jsonb->>'x-device-id','')
  );


