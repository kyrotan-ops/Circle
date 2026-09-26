-- Run this once in Supabase: Dashboard -> SQL Editor -> New query -> paste all -> Run

create table if not exists profiles (
  id uuid primary key,
  display_name text not null,
  created_at timestamptz default now()
);

create table if not exists rooms (
  code text primary key,
  game text not null,
  host_id uuid not null,
  status text not null default 'lobby',
  players jsonb not null default '[]',
  state jsonb not null default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists leaderboard (
  game text not null,
  player_id uuid not null,
  player_name text not null,
  score int not null default 0,
  primary key (game, player_id)
);

create table if not exists telepathy_secrets (
  room_code text not null,
  impostor_id uuid not null,
  word text not null,
  primary key (room_code, impostor_id)
);

alter table telepathy_secrets enable row level security;

-- Only the impostor who wrote it can ever read it back -- real privacy,
-- enforced by the database itself, not just hidden in the UI.
create policy "impostor reads own word" on telepathy_secrets for select using (auth.uid() = impostor_id);
create policy "impostor writes own word" on telepathy_secrets for insert with check (auth.uid() = impostor_id);

alter table profiles enable row level security;
alter table rooms enable row level security;
alter table leaderboard enable row level security;

-- Simple, open policies for a small trusted circle (classmates only have the
-- link, not the DB credentials) -- can be tightened later if needed.
create policy "read profiles" on profiles for select using (true);
create policy "write own profile" on profiles for insert with check (auth.uid() = id);
create policy "update own profile" on profiles for update using (auth.uid() = id);

create policy "read rooms" on rooms for select using (true);
create policy "create rooms" on rooms for insert with check (true);
create policy "update rooms" on rooms for update using (true);

create policy "read leaderboard" on leaderboard for select using (true);
create policy "create leaderboard rows" on leaderboard for insert with check (true);
create policy "update leaderboard rows" on leaderboard for update using (true);

-- Turn on realtime sync for room updates (host/guest live state)
alter publication supabase_realtime add table rooms;
