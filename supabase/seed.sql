-- ============================================================================
-- DearCocoa - seed demo REALISTICO (idempotente)
-- Il progetto deve sembrare gia' usato da utenti veri: journaling, mood,
-- community, chat di gruppo, eventi, AI reflections - tutto in inglese.
--
-- 2 account primari (prefill login con switch nel client):
--   alex@dearcocoa.demo / Cocoa2026!   (Alex Rivera)
--   maya@dearcocoa.demo / Cocoa2026!   (Maya Chen)
-- 6 utenti di contorno: jordan, sofia, liam, priya, noah, emma
-- Richiede pgcrypto (default su Supabase). Eseguire DOPO 0001_init.sql.
-- ============================================================================

do $$
declare
  u_alex uuid; u_maya uuid; u_jordan uuid; u_sofia uuid;
  u_liam uuid; u_priya uuid; u_noah uuid; u_emma uuid;
  s_morning uuid; s_gratitude uuid; s_running uuid; s_anxiety uuid; s_books uuid;
  r_wins uuid; r_crew uuid; r_dm uuid;
  e_med uuid; e_10k uuid; e_toolkit uuid; e_circle uuid;
  p_sofia_club uuid; p_alex_cold uuid; p_liam_stack uuid;
  p_maya_wins uuid; p_emma_jar uuid; p_noah_three uuid;
  p_liam_10k uuid; p_jordan_shin uuid; p_alex_nohp uuid;
  p_priya_box uuid; p_anon_2am uuid; p_priya_sunday uuid;
  p_emma_habits uuid; p_sofia_poetry uuid;
  rs_alex1 uuid; rs_alex2 uuid; rs_maya1 uuid;
  d date;
begin
  -- guard idempotenza
  if exists (select 1 from auth.users where email = 'alex@dearcocoa.demo') then
    raise notice 'seed demo gia'' applicato - skip';
    return;
  end if;

  -- ---------------------------------------------------------------- utenti
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, last_sign_in_at)
  values
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'alex@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '21 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"alex_rivera","display_name":"Alex Rivera"}',
     now() - interval '21 days', now() - interval '1 hour', '', '', '', '',
     now() - interval '5 minutes'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'maya@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '19 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"maya_chen","display_name":"Maya Chen"}',
     now() - interval '19 days', now() - interval '2 hours', '', '', '', '',
     now() - interval '10 minutes'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'jordan@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '30 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"jordan_blake","display_name":"Jordan Blake"}',
     now() - interval '30 days', now() - interval '30 days', '', '', '', '',
     now() - interval '1 day'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'sofia@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '28 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"sofia_rossi","display_name":"Sofia Rossi"}',
     now() - interval '28 days', now() - interval '28 days', '', '', '', '',
     now() - interval '2 days'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'liam@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '26 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"liam_oconnor","display_name":"Liam O''Connor"}',
     now() - interval '26 days', now() - interval '26 days', '', '', '', '',
     now() - interval '3 days'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'priya@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '24 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"priya_sharma","display_name":"Priya Sharma"}',
     now() - interval '24 days', now() - interval '24 days', '', '', '', '',
     now() - interval '4 days'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'noah@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '18 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"noah_kim","display_name":"Noah Kim"}',
     now() - interval '18 days', now() - interval '18 days', '', '', '', '',
     now() - interval '6 hours'),
    ('00000000-0000-0000-0000-000000000000', gen_random_uuid(),
     'authenticated', 'authenticated', 'emma@dearcocoa.demo',
     extensions.crypt('Cocoa2026!', extensions.gen_salt('bf')),
     now() - interval '15 days',
     '{"provider":"email","providers":["email"]}',
     '{"username":"emma_fischer","display_name":"Emma Fischer"}',
     now() - interval '15 days', now() - interval '15 days', '', '', '', '',
     now() - interval '8 hours');

  select id into u_alex from auth.users where email = 'alex@dearcocoa.demo';
  select id into u_maya from auth.users where email = 'maya@dearcocoa.demo';
  select id into u_jordan from auth.users where email = 'jordan@dearcocoa.demo';
  select id into u_sofia from auth.users where email = 'sofia@dearcocoa.demo';
  select id into u_liam from auth.users where email = 'liam@dearcocoa.demo';
  select id into u_priya from auth.users where email = 'priya@dearcocoa.demo';
  select id into u_noah from auth.users where email = 'noah@dearcocoa.demo';
  select id into u_emma from auth.users where email = 'emma@dearcocoa.demo';

  -- profili: avatar + bio (il trigger handle_new_user ha creato le righe base)
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=12',
    bio = '29. Product designer. Journaling my way to better mornings.',
    updated_at = now() where id = u_alex;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=47',
    bio = 'Runner, reader, recovery advocate. Gratitude first.',
    updated_at = now() where id = u_maya;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=33',
    bio = 'Wellness dabbler. 5k every weekend, coffee always.',
    updated_at = now() where id = u_jordan;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=45',
    bio = 'Early riser in training. Rituals over routines.',
    updated_at = now() where id = u_sofia;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=15',
    bio = 'Marathon hopeful. Fuel: bananas and bad puns.',
    updated_at = now() where id = u_liam;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=31',
    bio = 'Anxiety warrior. Breathing before meetings.',
    updated_at = now() where id = u_priya;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=59',
    bio = 'Slow living enthusiast. Tea over coffee.',
    updated_at = now() where id = u_noah;
  update public.profiles set avatar_url = 'https://i.pravatar.cc/300?img=44',
    bio = 'Books, blankets, bullet journals.',
    updated_at = now() where id = u_emma;

  -- ---------------------------------------------------------------- spaces
  insert into public.spaces (name, slug, description, created_by, created_at)
  values ('Morning Rituals', 'morning-rituals',
    'Start the day slow: routines, coffee journals, tiny wins.', u_sofia,
    now() - interval '27 days')
  returning id into s_morning;
  insert into public.spaces (name, slug, description, created_by, created_at)
  values ('Gratitude Circle', 'gratitude-circle',
    'One good thing a day. Anonymous posting welcome.', u_maya,
    now() - interval '25 days')
  returning id into s_gratitude;
  insert into public.spaces (name, slug, description, created_by, created_at)
  values ('Running Buddies', 'running-buddies',
    'From couch to 10k together. Accountability runs here.', u_liam,
    now() - interval '22 days')
  returning id into s_running;
  insert into public.spaces (name, slug, description, created_by, created_at)
  values ('Anxiety & Calm', 'anxiety-calm',
    'Tools that help: breathing, grounding, journaling. No judgment.', u_priya,
    now() - interval '20 days')
  returning id into s_anxiety;
  insert into public.spaces (name, slug, description, created_by, created_at)
  values ('Book Nook', 'book-nook',
    'What we are reading and how it changes us.', u_emma,
    now() - interval '14 days')
  returning id into s_books;

  insert into public.space_members (space_id, user_id, role, joined_at)
  values
    (s_morning, u_sofia, 'admin', now() - interval '27 days'),
    (s_morning, u_alex, 'member', now() - interval '21 days'),
    (s_morning, u_liam, 'member', now() - interval '20 days'),
    (s_morning, u_noah, 'member', now() - interval '17 days'),
    (s_morning, u_maya, 'member', now() - interval '16 days'),
    (s_gratitude, u_maya, 'admin', now() - interval '25 days'),
    (s_gratitude, u_emma, 'member', now() - interval '14 days'),
    (s_gratitude, u_noah, 'member', now() - interval '13 days'),
    (s_gratitude, u_jordan, 'member', now() - interval '10 days'),
    (s_gratitude, u_sofia, 'member', now() - interval '9 days'),
    (s_running, u_liam, 'admin', now() - interval '22 days'),
    (s_running, u_jordan, 'member', now() - interval '21 days'),
    (s_running, u_alex, 'member', now() - interval '20 days'),
    (s_running, u_maya, 'member', now() - interval '15 days'),
    (s_anxiety, u_priya, 'admin', now() - interval '20 days'),
    (s_anxiety, u_maya, 'member', now() - interval '18 days'),
    (s_anxiety, u_alex, 'member', now() - interval '11 days'),
    (s_anxiety, u_noah, 'member', now() - interval '7 days'),
    (s_books, u_emma, 'admin', now() - interval '14 days'),
    (s_books, u_sofia, 'member', now() - interval '12 days'),
    (s_books, u_maya, 'member', now() - interval '8 days'),
    (s_books, u_jordan, 'member', now() - interval '5 days');

  -- ---------------------------------------------------------------- posts
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_morning, u_sofia, 'Week 3 of the 6am club',
    'Three weeks of waking up before sunrise and my journal is fuller than my inbox. The trick was preparing the coffee maker the night before. Small systems, big mornings.',
    false, now() - interval '12 days', now() - interval '12 days')
  returning id into p_sofia_club;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_morning, u_alex, 'Cold showers, weirdly into it',
    'Started with 30 seconds at the end of my shower. Day 10: I actually look forward to it. The two minutes of journaling right after are the calmest part of my day.',
    false, now() - interval '9 days', now() - interval '9 days')
  returning id into p_alex_cold;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_morning, u_liam, 'My journal-first morning stack',
    'Stretch, kettle, journal, phone. In that order. Not touching the phone until the page is full changed everything for me.',
    false, now() - interval '6 days', now() - interval '6 days')
  returning id into p_liam_stack;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_gratitude, u_maya, 'Small wins this week',
    'Anonymous because it feels silly to celebrate, but: I ran my first 8k, called my mom twice, and wrote in here every single day. Grateful for this little app.',
    true, now() - interval '8 days', now() - interval '8 days')
  returning id into p_maya_wins;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_gratitude, u_emma, 'The gratitude jar experiment',
    'I keep a jar on my desk and drop in folded notes of good moments. On hard days I open three. Today''s pick: "the barista remembered my name."',
    false, now() - interval '7 days', now() - interval '7 days')
  returning id into p_emma_jar;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_gratitude, u_noah, 'Three good things before bed',
    'Started the bedtime version of the gratitude list. Sleep has been noticeably better. Science-ish, but also magic-ish.',
    false, now() - interval '4 days', now() - interval '4 days')
  returning id into p_noah_three;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_running, u_liam, 'FIRST 10K DONE',
    '1:04:52. Legs gone. Heart full. The last two kilometers I just repeated my journal mantra: "slow is smooth, smooth is fast."',
    false, now() - interval '5 days', now() - interval '5 days')
  returning id into p_liam_10k;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_running, u_jordan, 'Shin splints, tapering this week',
    'Frustrated but smart. Swapped runs for swimming and wrote about the itch to move. Rest is training too, right?',
    false, now() - interval '3 days', now() - interval '3 days')
  returning id into p_jordan_shin;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_running, u_alex, 'A month of running without headphones',
    'No podcasts, no playlists. Just footsteps and thoughts. Journaling the ideas that show up on mile three has become my favorite thing.',
    false, now() - interval '2 days', now() - interval '2 days')
  returning id into p_alex_nohp;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_anxiety, u_priya, 'Box breathing before big meetings',
    '4 in, 4 hold, 4 out, 4 hold, four rounds. I keep a sticky note on my laptop. My journal notes before meetings have gone from "panic" to "prepared."',
    false, now() - interval '6 days', now() - interval '6 days')
  returning id into p_priya_box;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_anxiety, u_maya, 'Racing thoughts at 2am',
    'Anyone else wake up with their brain already sprinting? Started keeping the journal by my bed - brain-dump two pages, back to sleep in minutes. What works for you?',
    true, now() - interval '2 days', now() - interval '2 days')
  returning id into p_anon_2am;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_anxiety, u_priya, 'What my Sunday reset looks like',
    'Cleaning the space, planning the week, one long journal entry, and a slow walk. The walk is non-negotiable now.',
    false, now() - interval '1 day', now() - interval '1 day')
  returning id into p_priya_sunday;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_books, u_emma, 'Re-reading Atomic Habits',
    'The "never miss twice" rule saved my streak this week. Journaling about WHY I missed the first day was more useful than the streak itself.',
    false, now() - interval '3 days', now() - interval '3 days')
  returning id into p_emma_habits;
  insert into public.posts (space_id, user_id, title, body, is_anonymous, created_at, updated_at)
  values (s_books, u_sofia, 'Poetry before breakfast',
    'One poem with the morning coffee. This week: Mary Oliver. "Tell me, what is it you plan to do with your one wild and precious life?" My answer changes daily.',
    false, now() - interval '16 hours', now() - interval '16 hours')
  returning id into p_sofia_poetry;

  -- ---------------------------------------------------------------- likes
  insert into public.post_likes (post_id, user_id, created_at)
  values
    (p_sofia_club, u_maya, now() - interval '11 days'),
    (p_sofia_club, u_liam, now() - interval '10 days'),
    (p_sofia_club, u_noah, now() - interval '9 days'),
    (p_sofia_club, u_jordan, now() - interval '8 days'),
    (p_sofia_club, u_alex, now() - interval '7 days'),
    (p_alex_cold, u_noah, now() - interval '8 days'),
    (p_alex_cold, u_sofia, now() - interval '7 days'),
    (p_alex_cold, u_liam, now() - interval '6 days'),
    (p_liam_stack, u_alex, now() - interval '5 days'),
    (p_liam_stack, u_sofia, now() - interval '4 days'),
    (p_maya_wins, u_emma, now() - interval '7 days'),
    (p_maya_wins, u_priya, now() - interval '6 days'),
    (p_maya_wins, u_jordan, now() - interval '5 days'),
    (p_maya_wins, u_sofia, now() - interval '4 days'),
    (p_maya_wins, u_noah, now() - interval '3 days'),
    (p_maya_wins, u_alex, now() - interval '2 days'),
    (p_emma_jar, u_noah, now() - interval '6 days'),
    (p_emma_jar, u_maya, now() - interval '5 days'),
    (p_emma_jar, u_sofia, now() - interval '3 days'),
    (p_noah_three, u_maya, now() - interval '3 days'),
    (p_noah_three, u_emma, now() - interval '2 days'),
    (p_liam_10k, u_jordan, now() - interval '4 days'),
    (p_liam_10k, u_alex, now() - interval '4 days'),
    (p_liam_10k, u_maya, now() - interval '3 days'),
    (p_liam_10k, u_sofia, now() - interval '3 days'),
    (p_liam_10k, u_noah, now() - interval '2 days'),
    (p_liam_10k, u_emma, now() - interval '2 days'),
    (p_liam_10k, u_priya, now() - interval '1 day'),
    (p_jordan_shin, u_liam, now() - interval '2 days'),
    (p_jordan_shin, u_maya, now() - interval '2 days'),
    (p_alex_nohp, u_liam, now() - interval '1 day'),
    (p_alex_nohp, u_maya, now() - interval '1 day'),
    (p_alex_nohp, u_jordan, now() - interval '20 hours'),
    (p_priya_box, u_maya, now() - interval '5 days'),
    (p_priya_box, u_alex, now() - interval '4 days'),
    (p_priya_box, u_noah, now() - interval '2 days'),
    (p_anon_2am, u_priya, now() - interval '1 day'),
    (p_anon_2am, u_noah, now() - interval '1 day'),
    (p_priya_sunday, u_maya, now() - interval '20 hours'),
    (p_priya_sunday, u_emma, now() - interval '10 hours'),
    (p_emma_habits, u_jordan, now() - interval '2 days'),
    (p_sofia_poetry, u_alex, now() - interval '14 hours'),
    (p_sofia_poetry, u_maya, now() - interval '9 hours');

  -- ---------------------------------------------------------------- comments
  insert into public.comments (post_id, user_id, body, created_at)
  values
    (p_sofia_club, u_maya, 'Preparing the coffee maker the night before is elite discipline.', now() - interval '11 days'),
    (p_sofia_club, u_liam, 'Copying the coffee-maker trick tomorrow. Thanks Sofia!', now() - interval '10 days'),
    (p_alex_cold, u_noah, '30 seconds is exactly where I started. It grows on you.', now() - interval '8 days'),
    (p_alex_cold, u_sofia, 'The post-shower clarity is real.', now() - interval '7 days'),
    (p_maya_wins, u_emma, 'Not silly at all - these are big wins. 8k!', now() - interval '7 days'),
    (p_maya_wins, u_priya, 'Proud of you, whoever you are.', now() - interval '6 days'),
    (p_emma_jar, u_noah, 'Stealing the jar idea tonight.', now() - interval '6 days'),
    (p_noah_three, u_maya, 'Magic-ish is the correct scientific classification.', now() - interval '3 days'),
    (p_liam_10k, u_jordan, '1:04 is HUGE for a first 10k. Congrats!', now() - interval '4 days'),
    (p_liam_10k, u_alex, 'That mantra is going on my wall.', now() - interval '3 days'),
    (p_jordan_shin, u_liam, 'Rest IS training. Heal up!', now() - interval '2 days'),
    (p_jordan_shin, u_maya, 'Swimming is such a smart swap.', now() - interval '2 days'),
    (p_alex_nohp, u_liam, 'Mile-three ideas are the best ideas.', now() - interval '1 day'),
    (p_priya_box, u_maya, 'Box breathing got me through my thesis defense.', now() - interval '5 days'),
    (p_priya_box, u_alex, 'Adding the sticky note trick to my stack.', now() - interval '4 days'),
    (p_anon_2am, u_priya, 'Two-page brain dump works. You are not alone.', now() - interval '1 day'),
    (p_anon_2am, u_noah, 'Keeping the journal by the bed was a game changer for me too.', now() - interval '1 day'),
    (p_priya_sunday, u_emma, 'The slow walk is my favorite part of Sundays too.', now() - interval '8 hours'),
    (p_emma_habits, u_jordan, '"Never miss twice" has saved me so many times.', now() - interval '2 days'),
    (p_sofia_poetry, u_alex, 'Mary Oliver with coffee is peak morning ritual.', now() - interval '12 hours');

  -- ---------------------------------------------------------------- rooms
  insert into public.rooms (name, description, created_by, is_direct, created_at)
  values ('Wellness Wins', 'Share one win every time you open this chat.', u_jordan, false,
    now() - interval '18 days')
  returning id into r_wins;
  insert into public.rooms (name, description, created_by, is_direct, created_at)
  values ('Rise & Shine Crew', 'The early crew: wake-up times and morning rituals.', u_alex, false,
    now() - interval '14 days')
  returning id into r_crew;
  insert into public.rooms (name, description, created_by, is_direct, created_at)
  values ('Alex & Maya', null, u_alex, true, now() - interval '9 days')
  returning id into r_dm;

  insert into public.room_members (room_id, user_id, role, joined_at)
  values
    (r_wins, u_jordan, 'admin', now() - interval '18 days'),
    (r_wins, u_alex, 'member', now() - interval '17 days'),
    (r_wins, u_maya, 'member', now() - interval '17 days'),
    (r_wins, u_sofia, 'member', now() - interval '16 days'),
    (r_wins, u_liam, 'member', now() - interval '15 days'),
    (r_wins, u_priya, 'member', now() - interval '13 days'),
    (r_wins, u_noah, 'member', now() - interval '12 days'),
    (r_wins, u_emma, 'member', now() - interval '10 days'),
    (r_crew, u_alex, 'admin', now() - interval '14 days'),
    (r_crew, u_sofia, 'moderator', now() - interval '14 days'),
    (r_crew, u_maya, 'member', now() - interval '13 days'),
    (r_crew, u_liam, 'member', now() - interval '12 days'),
    (r_crew, u_noah, 'member', now() - interval '11 days'),
    (r_dm, u_alex, 'member', now() - interval '9 days'),
    (r_dm, u_maya, 'member', now() - interval '9 days');

  insert into public.messages (room_id, user_id, content, created_at)
  values
    (r_wins, u_jordan, 'New rule: share one win every time you open this chat. I''ll start - booked my first physio appointment in months.', now() - interval '3 days'),
    (r_wins, u_maya, 'Win: I journaled every day this week, even the messy days.', now() - interval '3 days' + interval '40 minutes'),
    (r_wins, u_alex, 'Win: ran 8k without stopping for the first time.', now() - interval '2 days'),
    (r_wins, u_sofia, 'Win: woke up at 5:50 without an alarm feeling HUMAN.', now() - interval '2 days' + interval '2 hours'),
    (r_wins, u_liam, 'Win: negative split on my tempo run.', now() - interval '2 days' + interval '5 hours'),
    (r_wins, u_emma, 'Win: said no to a meeting that could have been an email.', now() - interval '1 day'),
    (r_wins, u_priya, 'Win: used box breathing before a scary presentation. It worked.', now() - interval '1 day' + interval '3 hours'),
    (r_wins, u_noah, 'Win: 7 days of the three-good-things list.', now() - interval '1 day' + interval '6 hours'),
    (r_wins, u_jordan, 'Okay the win thread is officially my favorite thing on the internet.', now() - interval '20 hours'),
    (r_wins, u_maya, 'Win: 10k this weekend with Liam. Watch this space.', now() - interval '8 hours'),
    (r_wins, u_alex, 'I''ll be right behind you both. Literally.', now() - interval '5 hours'),
    (r_wins, u_sofia, 'Same. At the back. Waving.', now() - interval '3 hours'),
    (r_crew, u_alex, 'Created this for the early crew. Post your wake-up time and one ritual.', now() - interval '5 days'),
    (r_crew, u_sofia, '5:45. Coffee maker prep + one page journal.', now() - interval '5 days' + interval '1 hour'),
    (r_crew, u_maya, '6:00. Stretch, hydrate, journal before phone.', now() - interval '4 days'),
    (r_crew, u_liam, '5:30 (runner''s curse). Journal + oatmeal.', now() - interval '4 days' + interval '2 hours'),
    (r_crew, u_noah, '6:15. Tea first, always. Then the three good things list.', now() - interval '3 days'),
    (r_crew, u_alex, 'Update: adding a 5-minute walk after writing. Feels great.', now() - interval '2 days'),
    (r_crew, u_sofia, 'Tried the walk. Confirmed. Do it.', now() - interval '1 day'),
    (r_crew, u_maya, 'Tomorrow''s plan: sunrise journaling in the park. Who''s in?', now() - interval '6 hours'),
    (r_crew, u_liam, 'In. Bringing bananas.', now() - interval '4 hours'),
    (r_crew, u_alex, 'In. See you at the gate.', now() - interval '1 hour'),
    (r_dm, u_maya, 'Hey! Saw your post about headphone-free runs - trying that tomorrow.', now() - interval '4 days'),
    (r_dm, u_alex, 'Do it. The first 2k feels weird, then it''s magic.', now() - interval '4 days' + interval '30 minutes'),
    (r_dm, u_maya, 'It WAS magic. Wrote three pages after.', now() - interval '3 days'),
    (r_dm, u_alex, 'Told you! Want to do the Sunday 10k together?', now() - interval '3 days' + interval '1 hour'),
    (r_dm, u_maya, 'Yes. Slow and chatty pace, deal?', now() - interval '2 days'),
    (r_dm, u_alex, 'Deal. Coffee after, journal debate about the best route.', now() - interval '2 days' + interval '20 minutes'),
    (r_dm, u_maya, 'Also - the gratitude circle post from anonymous made my week. Hope they''re okay.', now() - interval '20 hours'),
    (r_dm, u_alex, '(It was Maya''s post lol)', now() - interval '6 hours'),
    (r_dm, u_maya, 'Oops. It made MY week anyway.', now() - interval '2 hours');

  -- ---------------------------------------------------------------- events
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by, created_at)
  values (s_morning, 'Guided Morning Meditation',
    'Start the day with 20 minutes of guided breathing and intention setting, led by Sofia. Bring tea.',
    (current_date + 3)::timestamptz + interval '7 hours',
    (current_date + 3)::timestamptz + interval '8 hours',
    'https://meet.jit.si/dearcocoa-morning-meditation', u_sofia, now() - interval '6 days')
  returning id into e_med;
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by, created_at)
  values (s_running, 'Sunday 10k & Coffee Meetup',
    'Community long run from the park gate, followed by coffee and journal swaps at the cafe next door. All paces welcome.',
    (current_date + 5)::timestamptz + interval '8 hours 30 minutes',
    (current_date + 5)::timestamptz + interval '11 hours',
    'https://meet.jit.si/dearcocoa-10k', u_liam, now() - interval '4 days')
  returning id into e_10k;
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by, created_at)
  values (s_anxiety, 'Anxiety Toolkit Workshop',
    'Priya shares the grounding tools from her own journey: box breathing, 5-4-3-2-1, and journaling prompts that calm the spiral.',
    (current_date + 8)::timestamptz + interval '18 hours',
    (current_date + 8)::timestamptz + interval '19 hours',
    'https://meet.jit.si/dearcocoa-anxiety-toolkit', u_priya, now() - interval '3 days')
  returning id into e_toolkit;
  insert into public.events (space_id, title, description, starts_at, ends_at, join_url, created_by, created_at)
  values (s_gratitude, 'Monthly Journaling Circle',
    'Maya hosts our monthly reflection circle. We review the month''s entries, share one gratitude, and set intentions together.',
    (current_date + 10)::timestamptz + interval '19 hours',
    (current_date + 10)::timestamptz + interval '20 hours',
    'https://meet.jit.si/dearcocoa-journal-circle', u_maya, now() - interval '2 days')
  returning id into e_circle;

  insert into public.event_rsvps (event_id, user_id, status, created_at)
  values
    (e_med, u_alex, 'going', now() - interval '5 days'),
    (e_med, u_maya, 'going', now() - interval '4 days'),
    (e_med, u_noah, 'going', now() - interval '3 days'),
    (e_med, u_liam, 'going', now() - interval '2 days'),
    (e_med, u_emma, 'interested', now() - interval '2 days'),
    (e_med, u_jordan, 'interested', now() - interval '1 day'),
    (e_10k, u_liam, 'going', now() - interval '4 days'),
    (e_10k, u_jordan, 'going', now() - interval '3 days'),
    (e_10k, u_maya, 'going', now() - interval '2 days'),
    (e_10k, u_alex, 'going', now() - interval '2 days'),
    (e_10k, u_sofia, 'interested', now() - interval '1 day'),
    (e_10k, u_noah, 'interested', now() - interval '1 day'),
    (e_toolkit, u_priya, 'going', now() - interval '3 days'),
    (e_toolkit, u_maya, 'going', now() - interval '2 days'),
    (e_toolkit, u_alex, 'going', now() - interval '1 day'),
    (e_toolkit, u_noah, 'going', now() - interval '1 day'),
    (e_toolkit, u_sofia, 'interested', now() - interval '20 hours'),
    (e_circle, u_maya, 'going', now() - interval '2 days'),
    (e_circle, u_sofia, 'going', now() - interval '1 day'),
    (e_circle, u_emma, 'going', now() - interval '1 day'),
    (e_circle, u_alex, 'going', now() - interval '18 hours'),
    (e_circle, u_jordan, 'interested', now() - interval '10 hours'),
    (e_circle, u_priya, 'interested', now() - interval '6 hours');

  -- ---------------------------------------------------------------- entries
  -- Journal privato di Alex (mirror cloud, visibile solo a lui via RLS)
  insert into public.entries (user_id, local_id, title, content_delta, entry_date, mood_score, tags, is_favorite, is_pinned, created_at, updated_at)
  values
    (u_alex, gen_random_uuid()::text, 'Starting this for real',
     '[{"insert":"Okay. New app, new me - well, same me, but with a plan. I read that people who journal for 21 days build a habit, so this is day one of twenty-one.\n\nGoals: better mornings, less doomscrolling, and actually noticing my life as it happens.\n"}]'::jsonb,
     current_date - 20, 3, '{wellbeing}', false, false, now() - interval '20 days', now() - interval '20 days'),
    (u_alex, gen_random_uuid()::text, 'Why mornings feel impossible',
     '[{"insert":"Alarm at 6:45, snoozed twice, phone first thing. By the time I''m up the morning is already someone else''s.\n\nHypothesis: the phone is the problem. Test for next week: journal before screen. Writing it down so I can''t pretend it wasn''t a plan.\n"}]'::jsonb,
     current_date - 19, 2, '{mornings,sleep}', false, false, now() - interval '19 days', now() - interval '19 days'),
    (u_alex, gen_random_uuid()::text, 'First cold shower',
     '[{"insert":"30 seconds at the end of my shower. My soul briefly left my body but came back with opinions and motivation.\n\nWoke up the rest of the morning too. Interesting.\n"}]'::jsonb,
     current_date - 17, 4, '{challenge}', false, false, now() - interval '17 days', now() - interval '17 days'),
    (u_alex, gen_random_uuid()::text, 'Notes from a no-headphone run',
     '[{"insert":"Left the earbuds at home. First kilometer was boring. Second was okay. By the third my head was full of ideas I actually wanted to keep.\n\nIdea worth keeping: the best planning I do is with my feet.\n"}]'::jsonb,
     current_date - 15, 5, '{running}', true, false, now() - interval '15 days', now() - interval '15 days'),
    (u_alex, gen_random_uuid()::text, 'The 6am experiment, day 4',
     '[{"insert":"Four days in. Prepared the coffee maker last night like Sofia suggested and getting up was almost... easy? Almost.\n\nJournal first, phone second. Streak: 4.\n"}]'::jsonb,
     current_date - 13, 3, '{mornings}', false, false, now() - interval '13 days', now() - interval '13 days'),
    (u_alex, gen_random_uuid()::text, 'A rough Tuesday, honestly',
     '[{"insert":"Work ran hot, my back hurt, and I snapped at someone who did not deserve it. Did the 6am journal anyway but it was three lines of grumbling.\n\nWriting it down helped. Tomorrow restarts at zero, and that''s the point of the practice.\n"}]'::jsonb,
     current_date - 11, 2, '{stress}', false, false, now() - interval '11 days', now() - interval '11 days'),
    (u_alex, gen_random_uuid()::text, 'Sunday reset checklist',
     '[{"insert":"Clean the desk. Plan the week in three bullets. One long journal entry. Slow walk without the phone.\n\nThe walk is the one I skip, and the one that changes the week most. Non-negotiable now.\n"}]'::jsonb,
     current_date - 9, 4, '{routines}', false, true, now() - interval '9 days', now() - interval '9 days'),
    (u_alex, gen_random_uuid()::text, 'What I noticed on mile three',
     '[{"insert":"Without headphones the run becomes a meeting with myself. Ideas show up like colleagues who finally feel heard.\n\nDecided today: Sunday 10k, chatty pace, coffee after. Booked it in my head and in the app.\n"}]'::jsonb,
     current_date - 8, 5, '{running,ideas}', false, false, now() - interval '8 days', now() - interval '8 days'),
    (u_alex, gen_random_uuid()::text, 'Coffee with Jordan and real talk',
     '[{"insert":"Jordan said something that stuck: the win is not the 10k, the win is becoming a person who trains.\n\nJournaling daily is starting to feel like that too. Not output. Identity.\n"}]'::jsonb,
     current_date - 6, 4, '{friends}', false, false, now() - interval '6 days', now() - interval '6 days'),
    (u_alex, gen_random_uuid()::text, 'Sleep experiment: no screens after 10',
     '[{"insert":"Night three of no screens after 10pm. Fell asleep faster but woke up at 5:30 wide awake.\n\nConclusion so far: my sleep debt is a lifestyle, not a schedule. Continuing anyway.\n"}]'::jsonb,
     current_date - 5, 3, '{sleep}', false, false, now() - interval '5 days', now() - interval '5 days'),
    (u_alex, gen_random_uuid()::text, 'Presentation day - and I was calm',
     '[{"insert":"Big review meeting. Used Priya''s box breathing before it, four rounds in the stairwell like a very calm bank robber.\n\nIt worked. Journal says: prepared beats lucky. Slides done the night before helped too.\n"}]'::jsonb,
     current_date - 3, 4, '{work,calm}', false, false, now() - interval '3 days', now() - interval '3 days'),
    (u_alex, gen_random_uuid()::text, '8k without stopping',
     '[{"insert":"Eight kilometers, no walk breaks, no headphones, one very good playlist that never existed.\n\nTwo months ago 5k felt like a mountain. The body keeps the score and the score is improving.\n"}]'::jsonb,
     current_date - 2, 5, '{running}', true, false, now() - interval '2 days', now() - interval '2 days'),
    (u_alex, gen_random_uuid()::text, 'Gratitude: the small edition',
     '[{"insert":"1. The barista remembered my order.\n2. Liam''s terrible puns mid-run.\n3. Twenty-one days of journaling, done tonight.\n"}]'::jsonb,
     current_date - 1, 4, '{gratitude}', false, false, now() - interval '1 day', now() - interval '1 day'),
    (u_alex, gen_random_uuid()::text, 'Preparing for the Sunday 10k',
     '[{"insert":"Easy 3k shakeout, kit laid out, water bottle filled. Chatty pace with Maya, coffee after.\n\nWin condition: finish smiling. Speed is a bonus.\n"}]'::jsonb,
     current_date, 4, '{running,plans}', false, false, now() - interval '4 hours', now() - interval '4 hours');

  -- Journal privato di Maya
  insert into public.entries (user_id, local_id, title, content_delta, entry_date, mood_score, tags, is_favorite, is_pinned, created_at, updated_at)
  values
    (u_maya, gen_random_uuid()::text, 'New journal, new chapter',
     '[{"insert":"Started DearCocoa today. The idea of a journal that is private but a community that is not... fits me well right now.\n\nWeek one goal: one entry a day, no matter how short.\n"}]'::jsonb,
     current_date - 18, 3, '{wellbeing}', false, false, now() - interval '18 days', now() - interval '18 days'),
    (u_maya, gen_random_uuid()::text, 'Therapy homework, week one',
     '[{"insert":"Homework: notice one moment of calm every day and write it down. Today''s: the first sip of tea before anyone needed anything from me.\n\nSmall. But I caught it. That''s the exercise.\n"}]'::jsonb,
     current_date - 16, 3, '{therapy,calm}', false, false, now() - interval '16 days', now() - interval '16 days'),
    (u_maya, gen_random_uuid()::text, 'Run 1 of the 10k plan',
     '[{"insert":"Week 1 of the 10k plan with the Running Buddies crew. 4k easy, legs fine, brain loud, both handled.\n\nLiam says the plan works if I do. Working on it.\n"}]'::jsonb,
     current_date - 14, 4, '{running}', false, false, now() - interval '14 days', now() - interval '14 days'),
    (u_maya, gen_random_uuid()::text, 'The anonymous post I almost didn''t write',
     '[{"insert":"Posted my small wins anonymously because celebrating myself still feels like showing off.\n\nBut the comments came in kind and fast, and nobody thought it was showing off. Maybe I don''t need the anonymous box next time. Maybe.\n"}]'::jsonb,
     current_date - 12, 4, '{community,gratitude}', false, false, now() - interval '12 days', now() - interval '12 days'),
    (u_maya, gen_random_uuid()::text, 'Book notes: the practice chapter',
     '[{"insert":"Reading in Book Nook with Emma''s group. The chapter argues practice is identity evidence: every rep is a vote for the person you claim to be.\n\nRunner? Not yet. Person who runs four times a week? Getting there.\n"}]'::jsonb,
     current_date - 10, 4, '{reading}', false, false, now() - interval '10 days', now() - interval '10 days'),
    (u_maya, gen_random_uuid()::text, 'Long run, long thoughts',
     '[{"insert":"7k in the rain because the schedule said 7k and I have decided to be the kind of person who listens to the schedule.\n\nCame home soaked, wrote three pages, felt renewed. Rain runs are journal fuel.\n"}]'::jsonb,
     current_date - 8, 5, '{running}', true, false, now() - interval '8 days', now() - interval '8 days'),
    (u_maya, gen_random_uuid()::text, 'Mom called twice this week',
     '[{"insert":"Not for anything big. Just to talk. I noticed today that those two calls are the reason this week felt light.\n\nCalling her more is not a task, it''s a shortcut to feeling okay. Keeping it.\n"}]'::jsonb,
     current_date - 6, 5, '{family,gratitude}', false, false, now() - interval '6 days', now() - interval '6 days'),
    (u_maya, gen_random_uuid()::text, 'My Sunday reset, documented',
     '[{"insert":"Cleaned the space, planned the week, one long journal entry, slow walk. Posted the ritual in Anxiety & Calm and people actually tried it.\n\nBeing useful to someone else is the strangest side effect of journaling.\n"}]'::jsonb,
     current_date - 4, 4, '{routines}', false, true, now() - interval '4 days', now() - interval '4 days'),
    (u_maya, gen_random_uuid()::text, 'Anxious morning, better afternoon',
     '[{"insert":"Woke up at 2am with the brain sprinting. Two journal pages, back to sleep. Morning started rough anyway.\n\nBox breathing after lunch flipped the day. Tools work when you actually use the tools.\n"}]'::jsonb,
     current_date - 3, 3, '{calm}', false, false, now() - interval '3 days', now() - interval '3 days'),
    (u_maya, gen_random_uuid()::text, '10k training update',
     '[{"insert":"Long run up to 9k. The last kilometer was a negotiation but I won the negotiation.\n\nSunday: the full 10k with Liam and Alex. Coffee after, journal debate on the best route.\n"}]'::jsonb,
     current_date - 2, 4, '{running}', false, false, now() - interval '2 days', now() - interval '2 days'),
    (u_maya, gen_random_uuid()::text, 'Three good things',
     '[{"insert":"1. Rain on the window during my journal time.\n2. A stranger thanked me for the Sunday reset post.\n3. Legs feel strong. Body is cooperating. Grateful.\n"}]'::jsonb,
     current_date - 1, 5, '{gratitude}', false, false, now() - interval '1 day', now() - interval '1 day'),
    (u_maya, gen_random_uuid()::text, 'Sunrise journaling plan',
     '[{"insert":"Tomorrow: sunrise journaling in the park with the early crew. Page, pen, tea in a thermos, then the run.\n\nBest mornings are built the night before. Bag packed. Alarm set. Ready.\n"}]'::jsonb,
     current_date, 4, '{running,plans}', false, false, now() - interval '3 hours', now() - interval '3 hours');

  -- ---------------------------------------------------------------- mood logs
  -- Alex: 22 check-in su ~30 giorni
  insert into public.mood_logs (user_id, mood_score, note, logged_at)
  values
    (u_alex, 3, 'Starting something new, cautiously hopeful.', now() - interval '20 days' + interval '9 hours'),
    (u_alex, 2, 'Mornings are still a fight.', now() - interval '19 days' + interval '10 hours'),
    (u_alex, 3, 'Tired but wrote anyway.', now() - interval '18 days' + interval '8 hours'),
    (u_alex, 4, 'Cold shower: bizarrely effective.', now() - interval '17 days' + interval '9 hours'),
    (u_alex, 3, 'Neutral day, decent journal.', now() - interval '16 days' + interval '12 hours'),
    (u_alex, 5, 'Best run in weeks.', now() - interval '15 days' + interval '10 hours'),
    (u_alex, 4, 'Busy but balanced.', now() - interval '14 days' + interval '11 hours'),
    (u_alex, 3, 'The 6am thing is getting easier.', now() - interval '13 days' + interval '8 hours'),
    (u_alex, 3, 'Long meetings, short patience.', now() - interval '12 days' + interval '13 hours'),
    (u_alex, 2, 'Rough Tuesday. Journal saved it.', now() - interval '11 days' + interval '9 hours'),
    (u_alex, 3, 'Reset checklist helped.', now() - interval '10 days' + interval '10 hours'),
    (u_alex, 4, 'Sunday walk without phone = peace.', now() - interval '9 days' + interval '12 hours'),
    (u_alex, 5, 'Mile three ideas are gold.', now() - interval '8 days' + interval '9 hours'),
    (u_alex, 4, 'Good coffee, better company.', now() - interval '6 days' + interval '11 hours'),
    (u_alex, 3, 'Sleep experiment night three.', now() - interval '5 days' + interval '10 hours'),
    (u_alex, 4, 'Slower day, needed it.', now() - interval '4 days' + interval '9 hours'),
    (u_alex, 4, 'Box breathing before the big meeting.', now() - interval '3 days' + interval '10 hours'),
    (u_alex, 5, '8k. No stops. Pinned that feeling.', now() - interval '2 days' + interval '10 hours'),
    (u_alex, 4, 'Gratitude list before bed.', now() - interval '1 day' + interval '12 hours'),
    (u_alex, 4, 'Shakeout run done, kit ready.', now() - interval '6 hours'),
    (u_alex, 5, 'Community stuff genuinely lifts me up.', now() - interval '2 days' + interval '18 hours'),
    (u_alex, 3, 'Back to the routine after a lazy weekend.', now() - interval '26 days' + interval '9 hours');

  -- Maya: 18 check-in su ~28 giorni
  insert into public.mood_logs (user_id, mood_score, note, logged_at)
  values
    (u_maya, 3, 'New app day. Quietly optimistic.', now() - interval '18 days' + interval '10 hours'),
    (u_maya, 3, 'Therapy homework day one.', now() - interval '16 days' + interval '9 hours'),
    (u_maya, 4, 'First run of the plan, legs fine.', now() - interval '14 days' + interval '11 hours'),
    (u_maya, 4, 'Posted the wins anonymously. Relief.', now() - interval '12 days' + interval '9 hours'),
    (u_maya, 3, 'Reading and rain. Cozy.', now() - interval '10 days' + interval '8 hours'),
    (u_maya, 5, 'Rain run + three pages written.', now() - interval '8 days' + interval '10 hours'),
    (u_maya, 5, 'Mom called twice this week.', now() - interval '6 days' + interval '12 hours'),
    (u_maya, 4, 'Sunday reset done properly.', now() - interval '4 days' + interval '11 hours'),
    (u_maya, 3, '2am brain. Journal helped.', now() - interval '3 days' + interval '8 hours'),
    (u_maya, 4, '9k long run. Negotiated with the last km.', now() - interval '2 days' + interval '10 hours'),
    (u_maya, 5, 'Three good things, easily.', now() - interval '1 day' + interval '9 hours'),
    (u_maya, 4, 'Sunrise journaling planned. Ready.', now() - interval '3 hours'),
    (u_maya, 4, 'Book Nook discussion was lovely.', now() - interval '7 days' + interval '10 hours'),
    (u_maya, 3, 'Heavy work day. Breathing helped.', now() - interval '9 days' + interval '12 hours'),
    (u_maya, 2, 'Woke up anxious. Used the tools.', now() - interval '11 days' + interval '8 hours'),
    (u_maya, 4, 'Long walk, clear head.', now() - interval '13 days' + interval '11 hours'),
    (u_maya, 3, 'Slow day. Tea counts as productivity.', now() - interval '15 days' + interval '9 hours'),
    (u_maya, 4, 'Gratitude Circle post made someone smile.', now() - interval '5 days' + interval '10 hours');

  -- ------------------------------------------------- AI reflections (storia)
  insert into public.reflection_sessions (user_id, title, created_at)
  values (u_alex, 'Reflecting on my morning routine', now() - interval '4 days')
  returning id into rs_alex1;
  insert into public.reflection_sessions (user_id, title, created_at)
  values (u_alex, 'Work stress check-in', now() - interval '1 day')
  returning id into rs_alex2;
  insert into public.reflection_sessions (user_id, title, created_at)
  values (u_maya, 'Weekly review - gratitude', now() - interval '2 days')
  returning id into rs_maya1;

  insert into public.reflection_messages (session_id, user_id, role, content, created_at)
  values
    (rs_alex1, u_alex, 'user',
     'I''ve journaled every morning for two weeks but I still feel scattered by noon. What am I missing?',
     now() - interval '4 days'),
    (rs_alex1, u_alex, 'assistant',
     'Two weeks is a real streak - nice work. Scattered afternoons usually mean the morning has inputs but no anchor. Looking at your recent entries, your best days (the 8k run, the calm presentation) all had a physical anchor before writing. Try ending your journaling with one sentence: "Today''s anchor is ___."',
     now() - interval '4 days' + interval '20 seconds'),
    (rs_alex1, u_alex, 'user', 'Yes, that would help. Can you look at my last week?',
     now() - interval '4 days' + interval '2 minutes'),
    (rs_alex1, u_alex, 'assistant',
     'From your last seven entries, three patterns stand out: you write most clearly after movement, your mood dips on days you skip the walk, and your plans improve when you name one specific goal. Tomorrow, try: 5-minute walk, then journal, then write "Today''s anchor is: the 6k easy run." Check in with me any evening and we''ll adjust.',
     now() - interval '4 days' + interval '2 minutes 20 seconds'),
    (rs_alex2, u_alex, 'user',
     'Presentation went well today but I was anxious all morning. Why the gap?',
     now() - interval '1 day'),
    (rs_alex2, u_alex, 'assistant',
     'The gap is normal: anxiety peaks before performance, then relief follows success. Your entry says you used box breathing - that is exactly the tool that narrows the gap. One prompt to explore tonight: "What was I actually afraid would happen?" Naming it often shrinks it.',
     now() - interval '1 day' + interval '30 seconds'),
    (rs_maya1, u_maya, 'user',
     'Review my week: two runs, two calls with mom, one anxious morning I recovered from.',
     now() - interval '2 days'),
    (rs_maya1, u_maya, 'assistant',
     'That is a genuinely balanced week. The recovery morning might be the most important entry - resilience is not never being anxious, it is having tools. You have three: running, breathing, and calling your mom. Which one felt most like yours this week?',
     now() - interval '2 days' + interval '25 seconds'),
    (rs_maya1, u_maya, 'user', 'Running, probably. It gives me thoughts I can use.',
     now() - interval '2 days' + interval '3 minutes'),
    (rs_maya1, u_maya, 'assistant',
     'Then protect it. Your journal shows Sunday runs turn into your best entries. Put next week''s two runs in the calendar first, before work commitments, and treat them like meetings with yourself. I''m here after each one if you want to unpack what came up.',
     now() - interval '2 days' + interval '3 minutes 20 seconds');

  raise notice 'seed realistico completato: 8 utenti, 5 spaces, 14 post, 3 room, 4 eventi, 26 entries, 40 mood logs, 3 sessioni AI';
end $$;
