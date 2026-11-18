-- ============================================================================
-- DearCocoa MVP - schema init (base app: DiaryVault 2.4.0, MIT)
-- Tabelle + RLS + triggers + indexes + storage buckets + Realtime.
-- Applicabile a progetto Supabase nuovo o esistente (idempotente: IF NOT EXISTS).
-- Journaling = PRIVATO: la tabella entries e' leggibile SOLO dal owner.
-- ============================================================================

-- ---------------------------------------------------------------- profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Friend',
  username text unique,
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- auto-create profile alla registrazione (e al seed degli utenti demo)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name',
             split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'username'
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------- entries
-- Mirror cloud delle note DiaryVault. content_delta = Quill Delta (JSON).
-- mood_score 1..5 (opzionale) compilato dal mood tracker su ogni entry.
-- local_id = id della riga sqlite locale, per upsert idempotente dal client.
create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  local_id text not null,
  title text,
  content_delta jsonb not null default '{}'::jsonb,
  entry_date date not null default current_date,
  mood_score smallint check (mood_score between 1 and 5),
  tags text[] not null default '{}',
  is_favorite boolean not null default false,
  is_pinned boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, local_id)
);
create index if not exists entries_user_date_idx on public.entries (user_id, entry_date desc);

-- ---------------------------------------------------------------- mood_logs
create table if not exists public.mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mood_score smallint not null check (mood_score between 1 and 5),
  note text,
  logged_at timestamptz not null default now(),
  entry_id uuid references public.entries (id) on delete set null
);
create index if not exists mood_logs_user_idx on public.mood_logs (user_id, logged_at desc);

-- ---------------------------------------------------------------- community
create table if not exists public.spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  cover_url text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.space_members (
  space_id uuid not null references public.spaces (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text,
  body text not null,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists posts_space_idx on public.posts (space_id, created_at desc);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists comments_post_idx on public.comments (post_id, created_at);

-- ---------------------------------------------------------------- group chat
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_by uuid references auth.users (id) on delete set null,
  is_direct boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'moderator', 'member')),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);
create index if not exists messages_room_idx on public.messages (room_id, created_at desc);

-- Realtime sulle conversazioni
alter table public.messages replica identity full;
alter table public.rooms replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.rooms;
exception when duplicate_object then null; end $$;

-- creazione room di gruppo atomica (pattern flutter_supabase_chat_core)
create or replace function public.create_group_room(p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare r_id uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into public.rooms (name, created_by) values (p_name, auth.uid())
    returning id into r_id;
  insert into public.room_members (room_id, user_id, role)
    values (r_id, auth.uid(), 'admin');
  return r_id;
end $$;

-- join di una room aperta
create or replace function public.join_room(p_room_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into public.room_members (room_id, user_id) values (p_room_id, auth.uid())
    on conflict do nothing;
end $$;

-- ---------------------------------------------------------------- events
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  space_id uuid references public.spaces (id) on delete set null,
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  join_url text,
  cover_url text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists events_start_idx on public.events (starts_at);

create table if not exists public.event_rsvps (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'going' check (status in ('going', 'interested')),
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- ---------------------------------------------------------------- AI reflections
create table if not exists public.reflection_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default 'New reflection',
  created_at timestamptz not null default now()
);
create index if not exists reflection_sessions_user_idx
  on public.reflection_sessions (user_id, created_at desc);

create table if not exists public.reflection_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.reflection_sessions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  entry_id uuid references public.entries (id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists reflection_messages_session_idx
  on public.reflection_messages (session_id, created_at);

-- ============================================================================
-- Profile relationships per PostgREST embeds
-- posts/comments/messages user_id punta a auth.users; per gli embed
-- profiles(display_name) lato client serve ANCHE una FK verso public.profiles
-- (PostgREST non attraversa auth.users).
-- ============================================================================
alter table public.posts add constraint posts_profile_fk
  foreign key (user_id) references public.profiles (id) on delete cascade;
alter table public.comments add constraint comments_profile_fk
  foreign key (user_id) references public.profiles (id) on delete cascade;
alter table public.messages add constraint messages_profile_fk
  foreign key (user_id) references public.profiles (id) on delete cascade;

-- ============================================================================
-- updated_at trigger comune
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array['profiles','entries','posts'] loop
    execute format('drop trigger if exists trg_%s_updated_at on public.%I', t, t);
    execute format('create trigger trg_%s_updated_at before update on public.%I
                    for each row execute function public.set_updated_at()', t, t);
  end loop;
end $$;

-- ============================================================================
-- RLS: abilita e policy per ogni tabella
-- ============================================================================
alter table public.profiles enable row level security;
alter table public.entries enable row level security;
alter table public.mood_logs enable row level security;
alter table public.spaces enable row level security;
alter table public.space_members enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.comments enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.messages enable row level security;
alter table public.events enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.reflection_sessions enable row level security;
alter table public.reflection_messages enable row level security;

-- profiles: tutti gli autenticati leggono (social), ognuno scrive solo il suo
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (true);
drop policy if exists profiles_write on public.profiles;
create policy profiles_write on public.profiles for update to authenticated using (auth.uid() = id);
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated with check (auth.uid() = id);

-- entries: SOLO owner (journal privato - requisito DearCocoa F1 + privacy Q3)
drop policy if exists entries_owner_all on public.entries;
create policy entries_owner_all on public.entries
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists mood_logs_owner_all on public.mood_logs;
create policy mood_logs_owner_all on public.mood_logs
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- spaces: read per tutti gli auth; insert da auth; update solo admin dello space
drop policy if exists spaces_read on public.spaces;
create policy spaces_read on public.spaces for select to authenticated using (true);
drop policy if exists spaces_insert on public.spaces;
create policy spaces_insert on public.spaces for insert to authenticated
  with check (auth.uid() = created_by);
drop policy if exists spaces_update on public.spaces;
create policy spaces_update on public.spaces for update to authenticated using (
  exists (select 1 from public.space_members m
          where m.space_id = id and m.user_id = auth.uid() and m.role = 'admin'));

drop policy if exists space_members_read on public.space_members;
create policy space_members_read on public.space_members for select to authenticated using (true);
drop policy if exists space_members_write on public.space_members;
create policy space_members_write on public.space_members for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- posts: read per gli auth (MVP: feed pubblico tra autenticati), write solo owner
drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select to authenticated using (true);
drop policy if exists posts_write on public.posts;
create policy posts_write on public.posts for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists post_likes_read on public.post_likes;
create policy post_likes_read on public.post_likes for select to authenticated using (true);
drop policy if exists post_likes_write on public.post_likes;
create policy post_likes_write on public.post_likes for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists comments_read on public.comments;
create policy comments_read on public.comments for select to authenticated using (true);
drop policy if exists comments_write on public.comments;
create policy comments_write on public.comments for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- rooms: read per gli auth (MVP: room aperte), update solo admin/moderator;
-- messages: read per i membri della room, write per i membri
drop policy if exists rooms_read on public.rooms;
create policy rooms_read on public.rooms for select to authenticated using (true);
drop policy if exists rooms_insert on public.rooms;
create policy rooms_insert on public.rooms for insert to authenticated
  with check (auth.uid() = created_by);
drop policy if exists rooms_update on public.rooms;
create policy rooms_update on public.rooms for update to authenticated using (
  exists (select 1 from public.room_members m
          where m.room_id = id and m.user_id = auth.uid() and m.role in ('admin','moderator')));

drop policy if exists room_members_read on public.room_members;
create policy room_members_read on public.room_members for select to authenticated using (true);
drop policy if exists room_members_write on public.room_members;
create policy room_members_write on public.room_members for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists messages_read on public.messages;
create policy messages_read on public.messages for select to authenticated using (
  exists (select 1 from public.room_members m
          where m.room_id = room_id and m.user_id = auth.uid()));
drop policy if exists messages_write on public.messages;
create policy messages_write on public.messages for all to authenticated
  using (auth.uid() = user_id and exists (
    select 1 from public.room_members m
    where m.room_id = room_id and m.user_id = auth.uid()))
  with check (auth.uid() = user_id and exists (
    select 1 from public.room_members m
    where m.room_id = room_id and m.user_id = auth.uid()));

-- events: read tutti gli auth; insert da auth; RSVP self
drop policy if exists events_read on public.events;
create policy events_read on public.events for select to authenticated using (true);
drop policy if exists events_insert on public.events;
create policy events_insert on public.events for insert to authenticated
  with check (auth.uid() = created_by);
drop policy if exists events_update on public.events;
create policy events_update on public.events for update to authenticated using (auth.uid() = created_by);

drop policy if exists event_rsvps_read on public.event_rsvps;
create policy event_rsvps_read on public.event_rsvps for select to authenticated using (true);
drop policy if exists event_rsvps_write on public.event_rsvps;
create policy event_rsvps_write on public.event_rsvps for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- reflections: SOLO owner (i contenuti AI non si vedono tra utenti)
drop policy if exists reflection_sessions_owner on public.reflection_sessions;
create policy reflection_sessions_owner on public.reflection_sessions
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists reflection_messages_owner on public.reflection_messages;
create policy reflection_messages_owner on public.reflection_messages
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- user_id auto-fill da auth.uid() (RLS with check auth.uid() = user_id):
-- i client non devono passare user_id esplicito per gli insert.
-- ============================================================================
create or replace function public.set_user_id_from_auth()
returns trigger language plpgsql as $$
begin
  if new.user_id is null then
    new.user_id := auth.uid();
  end if;
  return new;
end $$;

drop trigger if exists trg_posts_set_user_id on public.posts;
create trigger trg_posts_set_user_id before insert on public.posts
  for each row execute function public.set_user_id_from_auth();
drop trigger if exists trg_comments_set_user_id on public.comments;
create trigger trg_comments_set_user_id before insert on public.comments
  for each row execute function public.set_user_id_from_auth();
drop trigger if exists trg_messages_set_user_id on public.messages;
create trigger trg_messages_set_user_id before insert on public.messages
  for each row execute function public.set_user_id_from_auth();
drop trigger if exists trg_mood_logs_set_user_id on public.mood_logs;
create trigger trg_mood_logs_set_user_id before insert on public.mood_logs
  for each row execute function public.set_user_id_from_auth();
drop trigger if exists trg_entries_set_user_id on public.entries;
create trigger trg_entries_set_user_id before insert on public.entries
  for each row execute function public.set_user_id_from_auth();

-- ============================================================================
-- Storage buckets
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
values ('event-covers', 'event-covers', true)
on conflict (id) do nothing;

drop policy if exists avatar_public_read on storage.objects;
create policy avatar_public_read on storage.objects for select
  using (bucket_id = 'avatars');
drop policy if exists avatar_owner_write on storage.objects;
create policy avatar_owner_write on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists event_cover_read on storage.objects;
create policy event_cover_read on storage.objects for select
  using (bucket_id = 'event-covers');
drop policy if exists event_cover_write on storage.objects;
create policy event_cover_write on storage.objects for insert to authenticated
  with check (bucket_id = 'event-covers');

-- NOTE pgvector (fase AI avanzata, opzionale):
-- create extension if not exists vector;
-- alter table public.entries add column embedding vector(1536);
-- match_entries() via RPC con RLS owner-only.
