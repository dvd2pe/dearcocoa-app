-- ============================================================================
-- DearCocoa - seed demo (idempotente)
-- 5 account demo (login con un tap dal client):
--   sofia@dearcocoa.demo  / Cocoa2026!
--   luca@dearcocoa.demo   / Cocoa2026!
--   giulia@dearcocoa.demo / Cocoa2026!
--   marco@dearcocoa.demo  / Cocoa2026!
--   elena@dearcocoa.demo  / Cocoa2026!
-- + 3 spaces, 2 room di gruppo con messaggi, 3 eventi, post con like/commenti.
-- Richiede pgcrypto (default attivo su Supabase). Da eseguire DOPO 0001_init.sql.
-- ============================================================================

do $$
declare
  u_sofia uuid; u_luca uuid; u_giulia uuid; u_marco uuid; u_elena uuid;
  s_morning uuid; s_circle uuid; s_events_space uuid;
  r_morning uuid; r_open uuid;
  e_moon uuid; e_breath uuid; e_write uuid;
  p1 uuid; p2 uuid;
begin
  -- ---------------------------------------------------------------- utenti
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'sofia@dearcocoa.demo', extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}',
    '{"username":"sofia_r","display_name":"Sofia Rossi"}',
    now() - interval '30 days', now() - interval '30 days', '', '', '', '',
    now() - interval '1 day')
  on conflict (email) do update set encrypted_password = excluded.encrypted_password,
      email_confirmed_at = now()
  returning id into u_sofia;
  if u_sofia is null then select id into u_sofia from auth.users where email = 'sofia@dearcocoa.demo'; end if;

  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'luca@dearcocoa.demo', extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}',
    '{"username":"luca_b","display_name":"Luca Bianchi"}',
    now() - interval '28 days', now() - interval '28 days', '', '', '', '',
    now() - interval '2 days')
  on conflict (email) do update set encrypted_password = excluded.encrypted_password,
      email_confirmed_at = now()
  returning id into u_luca;
  if u_luca is null then select id into u_luca from auth.users where email = 'luca@dearcocoa.demo'; end if;

  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'giulia@dearcocoa.demo', extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}',
    '{"username":"giulia_f","display_name":"Giulia Ferrari"}',
    now() - interval '25 days', now() - interval '25 days', '', '', '', '',
    now() - interval '3 days')
  on conflict (email) do update set encrypted_password = excluded.encrypted_password,
      email_confirmed_at = now()
  returning id into u_giulia;
  if u_giulia is null then select id into u_giulia from auth.users where email = 'giulia@dearcocoa.demo'; end if;

  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'marco@dearcocoa.demo', extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}',
    '{"username":"marco_c","display_name":"Marco Conti"}',
    now() - interval '20 days', now() - interval '20 days', '', '', '', '',
    now() - interval '4 days')
  on conflict (email) do update set encrypted_password = excluded.encrypted_password,
      email_confirmed_at = now()
  returning id into u_marco;
  if u_marco is null then select id into u_marco from auth.users where email = 'marco@dearcocoa.demo'; end if;

  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'elena@dearcocoa.demo', extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}',
    '{"username":"elena_m","display_name":"Elena Moretti"}',
    now() - interval '15 days', now() - interval '15 days', '', '', '', '',
    now() - interval '5 days')
  on conflict (email) do update set encrypted_password = excluded.encrypted_password,
      email_confirmed_at = now()
  returning id into u_elena;
  if u_elena is null then select id into u_elena from auth.users where email = 'elena@dearcocoa.demo'; end if;

  -- il trigger handle_new_user crea i profili per i NUOVI utenti; per gli
  -- utenti gia' presenti (re-seed) assicura la riga
  insert into public.profiles (id, display_name, username)
  values
    (u_sofia,  'Sofia Rossi',    'sofia_r'),
    (u_luca,   'Luca Bianchi',   'luca_b'),
    (u_giulia, 'Giulia Ferrari', 'giulia_f'),
    (u_marco,  'Marco Conti',    'marco_c'),
    (u_elena,  'Elena Moretti',  'elena_m')
  on conflict (id) do nothing;

  -- ---------------------------------------------------------------- spaces
  insert into public.spaces (id, name, slug, description, created_by)
  values (gen_random_uuid(), 'Morning Rituals', 'morning-rituals',
    'Start the day slow: routines, coffee journals, tiny wins.', u_sofia)
  returning id into s_morning;
  insert into public.spaces (id, name, slug, description, created_by)
  values (gen_random_uuid(), 'Gratitude Circle', 'gratitude-circle',
    'One good thing a day. Anonymous posting welcome.', u_giulia)
  returning id into s_circle;
  insert into public.spaces (id, name, slug, description, created_by)
  values (gen_random_uuid(), 'Workshop Notes', 'workshop-notes',
    'Materials and follow-ups from our virtual events.', u_marco)
  returning id into s_events_space;
  on conflict (slug) do nothing;

  select id into s_morning from public.spaces where slug = 'morning-rituals';
  select id into s_circle from public.spaces where slug = 'gratitude-circle';
  select id into s_events_space from public.spaces where slug = 'workshop-notes';

  insert into public.space_members (space_id, user_id, role)
  values
    (s_morning, u_sofia, 'admin'),
    (s_morning, u_luca, 'member'),
    (s_morning, u_giulia, 'member'),
    (s_circle, u_giulia, 'admin'),
    (s_circle, u_sofia, 'member'),
    (s_circle, u_elena, 'member'),
    (s_circle, u_marco, 'member'),
    (s_events_space, u_marco, 'admin'),
    (s_events_space, u_elena, 'member')
  on conflict do nothing;

  -- ---------------------------------------------------------------- posts
  insert into public.posts (space_id, user_id, title, body, is_anonymous)
  values (s_morning, u_sofia, 'My 6am experiment',
    'Day 12 of waking up before sunrise. The journal helps more than the coffee.', false)
  returning id into p1;
  insert into public.posts (space_id, user_id, title, body, is_anonymous)
  values (s_circle, u_elena, 'Today I am grateful for',
    'Small thing: my cat slept on the keyboard while I journaled.', true)
  returning id into p2;
  insert into public.posts (space_id, user_id, title, body, is_anonymous)
  values (s_circle, u_luca, 'Rough week, still counting',
    'Gratitude list felt forced today but I did it anyway. That counts, right?', false);

  insert into public.post_likes (post_id, user_id)
  values (p1, u_luca), (p1, u_giulia), (p2, u_sofia), (p2, u_marco)
  on conflict do nothing;

  insert into public.comments (post_id, user_id, body)
  values
    (p1, u_giulia, 'Twelve days is huge. What time do you go to bed?'),
    (p2, u_sofia, 'That absolutely counts.');

  -- ---------------------------------------------------------------- rooms
  insert into public.rooms (name, description, created_by)
  values ('Morning Rituals - General', 'Chat della community mattutina', u_sofia)
  returning id into r_morning;
  insert into public.rooms (name, description, created_by)
  values ('Open Circle', 'Room aperta a tutti i membri', u_giulia)
  returning id into r_open;

  insert into public.room_members (room_id, user_id, role)
  values
    (r_morning, u_sofia, 'admin'),
    (r_morning, u_luca, 'member'),
    (r_morning, u_giulia, 'moderator'),
    (r_open, u_giulia, 'admin'),
    (r_open, u_elena, 'member'),
    (r_open, u_marco, 'member');

  insert into public.messages (room_id, user_id, content)
  values
    (r_morning, u_sofia, 'Welcome! Share your morning wins here.'),
    (r_morning, u_luca, 'Today: 20 minutes of journaling before emails.'),
    (r_open, u_elena, 'Anyone joining the moon circle event this week?'),
    (r_open, u_marco, 'Yes! RSVP-ed yesterday.');

  -- ---------------------------------------------------------------- events
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by)
  values (s_events_space, 'Full Moon Journaling Circle',
    'Guided 60-minute journaling session under the full moon. Bring paper or the app.',
    now() + interval '3 days', now() + interval '4 days',
    'https://meet.jit.si/dearcocoa-moon-circle', u_marco)
  returning id into e_moon;
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by)
  values (s_morning, 'Breathwork Morning Session',
    '15-minute guided breathwork to open the day.',
    now() + interval '1 day', now() + interval '1 day' + interval '1 hour',
    'https://meet.jit.si/dearcocoa-breath', u_sofia)
  returning id into e_breath;
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by)
  values (s_circle, 'Writing Workshop: The Gratitude Ladder',
    'Structured workshop on deepening gratitude entries.',
    now() + interval '7 days', now() + interval '7 days' + interval '90 minutes',
    'https://meet.jit.si/dearcocoa-gratitude', u_giulia)
  returning id into e_write;

  insert into public.event_rsvps (event_id, user_id, status)
  values
    (e_moon, u_elena, 'going'), (e_moon, u_marco, 'going'),
    (e_moon, u_sofia, 'interested'),
    (e_breath, u_luca, 'going'), (e_breath, u_elena, 'interested'),
    (e_write, u_marco, 'going'), (e_write, u_giulia, 'going')
  on conflict do nothing;

  raise notice 'seed demo completato: 5 utenti, 3 spaces, 3 room-events, post e messaggi';
end $$;
