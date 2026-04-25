-- Enable extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";

-- Users (extends Supabase auth.users)
create table public.users_profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text not null,
  phone text unique not null,
  avatar_url text,
  risk_profile text default 'normal' check (risk_profile in ('low','normal','high')),
  mesh_relay_enabled bool default true,
  home_lat float8,
  home_lng float8,
  work_lat float8,
  work_lng float8,
  created_at timestamptz default now()
);
alter table public.users_profiles enable row level security;
create policy "Users read own profile" on public.users_profiles for select using (auth.uid() = id);
create policy "Users update own profile" on public.users_profiles for update using (auth.uid() = id);

-- Guardians
create table public.guardians (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  guardian_phone text not null,
  guardian_name text not null,
  verified bool default false,
  created_at timestamptz default now(),
  unique(user_id, guardian_phone)
);
alter table public.guardians enable row level security;
create policy "Users manage own guardians" on public.guardians 
  for all using (auth.uid() = user_id);

-- SOS Alerts
create table public.sos_alerts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  latitude float8 not null,
  longitude float8 not null,
  accuracy float4,
  battery_pct int,
  status text default 'triggered' check (status in ('triggered','resolved','false_alarm')),
  trigger_type text check (trigger_type in ('manual','power_button','gesture','tap_sequence','ai_behavioral','ai_audio','ai_kidnap')),
  origin text default 'online' check (origin in ('online','mesh')),
  resolved_at timestamptz,
  created_at timestamptz default now()
);
alter table public.sos_alerts enable row level security;
create policy "Users manage own alerts" on public.sos_alerts 
  for all using (auth.uid() = user_id);
create policy "Guardians read alerts" on public.sos_alerts 
  for select using (
    exists (
      select 1 from public.guardians g
      join public.users_profiles p on p.phone = g.guardian_phone
      where g.user_id = sos_alerts.user_id and p.id = auth.uid()
    )
  );

-- Evidence Items
create table public.evidence_items (
  id uuid default uuid_generate_v4() primary key,
  sos_id uuid references public.sos_alerts(id) on delete cascade not null,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  type text check (type in ('audio','photo','gps_log','sensor_log','location')),
  file_name text not null,
  storage_path text not null,
  encryption_key_id text,
  integrity_hash text,
  encrypted_hash text,
  file_size_bytes int,
  captured_at timestamptz default now()
);
alter table public.evidence_items enable row level security;
create policy "Users read own evidence" on public.evidence_items 
  for select using (
    exists (select 1 from public.sos_alerts s where s.id = sos_id and s.user_id = auth.uid())
  );
-- Prevent tampering: no updates or deletes allowed
create policy "No update evidence" on public.evidence_items for update using (false);
create policy "No delete evidence" on public.evidence_items for delete using (false);

-- Community Reports
create table public.community_reports (
  id uuid default uuid_generate_v4() primary key,
  reporter_id uuid references public.users_profiles(id) on delete cascade,
  lat float8 not null,
  lng float8 not null,
  category text check (category in ('harassment','theft','assault','unsafe_area','suspicious','other')),
  severity int check (severity between 1 and 5),
  description text,
  anonymous bool default false,
  verified bool default false,
  upvotes int default 0,
  reported_at timestamptz default now()
);
alter table public.community_reports enable row level security;
create policy "Anyone reads reports" on public.community_reports for select using (true);
create policy "Authenticated users file reports" on public.community_reports 
  for insert with check (auth.uid() = reporter_id);

-- Safety Scores (precomputed, updated by edge function every 5 min)
create table public.safety_scores (
  id uuid default uuid_generate_v4() primary key,
  geohash text not null unique,
  lat float8 not null,
  lng float8 not null,
  score float4 check (score between 0 and 100),
  incident_count int default 0,
  label text check (label in ('safe','moderate','dangerous')),
  computed_at timestamptz default now()
);
create index safety_scores_geohash_idx on public.safety_scores (geohash);

-- Location History (partitioned — one week retention)
create table public.location_history (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  lat float8 not null,
  lng float8 not null,
  speed float4,
  accuracy float4,
  recorded_at timestamptz default now()
);
alter table public.location_history enable row level security;
create policy "Users manage own location" on public.location_history 
  for all using (auth.uid() = user_id);
create index location_history_user_time_idx on public.location_history (user_id, recorded_at desc);

-- Safe Walk Sessions
create table public.safe_walk_sessions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  destination_lat float8,
  destination_lng float8,
  destination_name text,
  status text default 'active' check (status in ('active','completed','sos_triggered')),
  started_at timestamptz default now(),
  completed_at timestamptz
);
alter table public.safe_walk_sessions enable row level security;
create policy "Users manage own sessions" on public.safe_walk_sessions 
  for all using (auth.uid() = user_id);

-- Mesh Messages (offline relay dedup cache)
create table public.mesh_messages (
  msg_id uuid primary key,
  origin_user_id text not null,
  payload_encrypted text not null,
  msg_type text check (msg_type in ('SOS','LOCATION','ACK')),
  hops_taken int default 1,
  received_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '1 hour')
);

-- Realtime: enable for SOS alerts and location
alter publication supabase_realtime add table public.sos_alerts;
alter publication supabase_realtime add table public.location_history;

-- SOS Live Location
create table public.sos_live_location (
  id uuid primary key default uuid_generate_v4(),
  sos_id uuid references public.sos_alerts(id) on delete cascade,
  latitude numeric not null,
  longitude numeric not null,
  battery_level int,
  created_at timestamptz default now()
);
alter table public.sos_live_location enable row level security;
create policy "Anyone with link reads live location" on public.sos_live_location for select using (true);
create policy "Users manage own live location" on public.sos_live_location for all using (
  exists (select 1 from public.sos_alerts s where s.id = sos_id and s.user_id = auth.uid())
);

-- Device Tokens for Push Notifications
create table public.device_tokens (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users_profiles(id) on delete cascade not null,
  fcm_token text not null unique,
  platform text,
  last_used_at timestamptz default now()
);
alter table public.device_tokens enable row level security;
create policy "Users manage own tokens" on public.device_tokens for all using (auth.uid() = user_id);

-- Audit Log for Edges Functions
create table public.audit_log (
  id uuid default uuid_generate_v4() primary key,
  action text not null,
  details jsonb,
  created_at timestamptz default now()
);
alter table public.audit_log enable row level security;
create policy "No one modifies audit log" on public.audit_log for all using (false);

-- DB Trigger: Auto-invoke notify-guardians edge function on SOS insert
create or replace function notify_guardians_on_sos()
returns trigger as $$
begin
  perform net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/notify-guardians',
    body := json_build_object(
      'sosId', NEW.id,
      'userId', NEW.user_id,
      'lat', NEW.latitude,
      'lng', NEW.longitude,
      'triggerType', NEW.trigger_type,
      'batteryPct', NEW.battery_pct
    )::text,
    headers := json_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key'), 'Content-Type', 'application/json')::jsonb
  );
  return NEW;
end;
$$ language plpgsql;

create trigger trigger_notify_guardians_on_sos
  after insert on public.sos_alerts
  for each row execute function notify_guardians_on_sos();

-- Storage Bucket setup for Evidence
insert into storage.buckets (id, name, public) values ('evidence', 'evidence', false) on conflict do nothing;

create policy "Users upload own evidence" on storage.objects for insert
  with check (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users read own evidence" on storage.objects for select
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text);
