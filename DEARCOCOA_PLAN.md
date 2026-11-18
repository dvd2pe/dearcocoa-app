# DearCocoa × DiaryVault — Piano di sviluppo e documento di ripresa

> **Scopo di questo file**: se la conversazione si perde, TUTTO il contesto per riprendere lo sviluppo è qui.
> Ultimo aggiornamento: 2026-11-18 (sera). Stato: **M1-M10 + M10.5 + M2.1(pull) + M-DEMO COMPLETATI** - release **v0.2.0-dearcocoa** con APK live su Supabase, demo assets pronti (20 screenshot + video 8min).
> Progetto Supabase "Dear Cocoa" (ref `sukxerupxdctdnegghwa`, eu-central-1) collegato e POPOLATO (seed realistico inglese: 8 utenti, 5 spaces, 14 post, 20 commenti, 3 room/31 msg, 4 eventi, 26 entries, 40 mood, 3 sessioni AI).
> Score stimato: **~80/100**. Mancano: OPENAI_API_KEY (reflections live), push locale→cloud, iOS build, README finale.
> Fix schema di sessione (già applicati al DB live e alla migration): FK posts/comments/messages→profiles per embed PostgREST (PGRST200), trigger set_user_id_from_auth (RLS insert).
> Known issue upstream: todo_reminder_typing_test IME-driven fallisce (pre-esistente sul base, step test non-bloccante in CI).

---

## 1. Contesto

- **Cliente/progetto**: DearCocoa — MVP social wellness (Upwork, $20.000 fixed, estendibile a $50.000).
- **Requisiti MVP**: journaling privato, AI-powered reflections (opzionale), mood tracking,
  community spaces, group conversations, virtual events. iOS + Android. Figma prototype già pronto.
- **Decisione del cliente (dvd2pe)**: backend = **Supabase** (auth, Postgres, RLS, Realtime, Storage, Edge Functions).
- **Vincolo UI/UX (ferreo)**: la base visiva è **DiaryVault clonato**. Temi, colori, font (Google Fonts),
  componenti (`lib/core/widgets`), pattern di navigazione NON si toccano. Le nuove feature si vestono
  con i temi esistenti (`lib/app/themes/*`), riusando i widget di core quando possibile.
- **Vincolo build (ferreo)**: NESSUNA build locale in sandbox (OOM). Tutto via **GitHub Actions**
  (runner ubuntu-latest). Locale si scrive codice e si pusha; CI valida (`flutter analyze`/`test`/APK).

## 2. Punteggio di partenza del clone vs requisiti (analisi 2026-11-18)

| Area | Peso | Copertura base | Come si colma |
|---|---|---|---|
| Journaling privato | 30% | 70% | data layer su Supabase (auth+RLS), UI DiaryVault invariata |
| Mood tracking | 10% | 0% | feature `mood` nuova (schema + calendario/storico) |
| AI reflections | 15% | 0% | Edge Function `reflections` + pgvector + cronologia conversazioni |
| Community spaces | 15% | 0% | feature `community` (feed, post, like, comment, RLS) |
| Group conversations | 10% | 0% | feature `chat` (rooms realtime su Supabase) |
| Virtual events | 10% | 0% | feature `events` (listing + RSVP) |
| iOS + Android | 10% | 50% | codice Flutter già cross-platform; CI iOS `--no-codesign` |

**Base: 26/100 → target MVP: 85/90** (resto = polish, security hardening, store iOS).

## 3. Repo e credenziali (contesto operativo)

| Risorsa | Valore |
|---|---|
| Repo sviluppo (questa) | `dvd2pe/dearcocoa-app` (PUBBLICA, per Actions illimitate) — base = snapshot DiaryVault master `9816ef1` |
| Progetto precedente (SUPERATO) | `dvd2pe/dearcocoa` (privato) — base memex GPL, R1-R5, APK 255MB v1.0.39-demo. **Il 18/11 il cliente ha deciso: base = DiaryVault (MIT), UI/UX/colori/font invariati.** Il vecchio repo NON si tocca; si riusano solo i suoi doc di contesto: `REQUIREMENTS.md` (job posting verbatim + 5 domande proposal), `docs/REQUISITI_MVP.md`, `docs/SETUP_SUPABASE.md`, `backend/supabase/seed_demo.sql` (pattern creazione utenti demo auth) |
| Minuti Actions | i minuti private del piano Free sono ESAURITI → tutta la CI gira su repo pubbliche |
| Mirror upstream integrale | `dvd2pe/diaryvault` (105 branch, 28 tag, history completa) |
| Repo build APK (base DiaryVault) | `dvd2pe/diaryvault-apk` — release `2.4.0` con 3 APK firmati (v2 cert CN=DiaryVault,O=dvd2pe,C=IT, SHA-256 `55:59:48:F7:44:D8:80:BC:34:59:7C:A9:BE:48:6C:EA:24:FB:25:2D:41:DE:82:3A:69:D6:BC:BA:2C:F9:2A:23`) |
| Keystore DearCocoa (QUESTA repo) | alias `dearcocoa`, cert CN=DearCocoa,OU=Release,O=dvd2pe,C=IT, SHA-256 `B0:EA:55:A3:88:C0:55:98:F6:F1:44:19:8B:66:56:2C:06:2F:12:F9:D1:51:FC:F7:B5:F8:E8:F0:DF:B8:8E:4F`, password in Actions secrets (NON committare mai in chiaro) — nota: signature diversa dall'APK diaryvault-apk 2.4.0: disinstallare la vecchia prima di installare DearCocoa |
| Token GitHub | fornito in chat dall'utente (`ghp_…f7k6x`) — **⚠️ revocare/ruotare a fine lavori** (esposto in chat) |
| Segreti CI diaryvault-apk | `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` (keystore release già caricato) |
| Toolchain pinnata | Flutter 3.32.0 · Java 17 · Gradle 8.12 · AGP 8.7.3 · Kotlin 2.1.0 · NDK 27.0.12077973 · compileSdk 36 |
| google-services.json | placeholder (project `diaryvault-local-build`, pkg `me.sankethbk.dairyapp`) — sostituire SOLO se si attivano funzioni Firebase reali |

## 4. Repo open-source di riferimento (scelte fatte)

**Da usare/integrare**:
- [devtodollars/mvp-boilerplate](https://github.com/devtodollars/mvp-boilerplate) (MIT) — struttura monorepo Flutter+Supabase, pattern migrazioni/RLS.
- [insideapp-srl/flutter_supabase_chat_core](https://github.com/insideapp-srl/flutter_supabase_chat_core) (Apache-2.0) — room dirette/gruppo, ruoli admin/moderator, creazione via DB function. Riferimento per `features/chat`.
- [gannonh/chatgpt-pgvector](https://github.com/gannonh/chatgpt-pgvector) (MIT) — pattern Edge Function + pgvector + RLS per AI su dati privati. Riferimento per `reflections`.
- [Shangjin-Xiao/ThoughtEcho](https://github.com/Shangjin-Xiao/ThoughtEcho) (MIT) — client AI multi-provider riutilizzabile (Dart).
- [itsezlife/flutter-instagram-offline-first-clone](https://github.com/itsezlife/flutter-instagram-offline-first-clone) — ⚠️ SENZA licenza: solo riferimento concettuale schema social (feed/follow/like su Supabase), NO copia codice.
- [festappnet/festapp](https://github.com/festappnet/festapp) (MIT) — eventi: per MVP solo programmi+RSVP (niente ticketing).
- [hashirshoaeb/star_book](https://github.com/hashirshoaeb/star_book) (MIT) — UI pattern mood calendar.

**Da NON usare nel codice (licenze)**: memex-lab/memex (GPL-3.0), CikeSeven/jotsy (GPL-3.0),
lollipopkit/llmbox (GPL-3.0), dshukertjr/spot (LGPL, stale), mitchkoko/moonbase-template (Firebase),
Coffiie/discord_open (Serverpod). Ispirazione concettuale ammessa, copia no.

## 5. Architettura target

```
lib/
  core/network/supabase_client.dart      ← singleton SupabaseClient (init in main)
  features/
    auth/       (esistente, DiaryVault)  ← aggiunto data source Supabase; UI invariata
    notes/      (esistente)              ← sync su Supabase (entries + mood)
    mood/       (NUOVA)  mood tracker: modello, repo, bloc, pagina calendario/storico
    reflections/(NUOVA)  AI reflections: service → Edge Function, bloc, pagina chat-like
    community/  (NUOVA)  spaces: feed, post, like, comment (RLS)
    chat/       (NUOVA)  group rooms realtime (Supabase Realtime)
    events/     (NUOVA)  listing eventi + RSVP
    hub/        (NUOVA)  pagina "DearCocoa" che collega le nuove feature (stile DiaryVault)
supabase/
  config.toml                             ← config locale Supabase CLI
  migrations/0001_init.sql                ← schema completo + RLS + storage buckets
  seed.sql                                ← dati demo (spaces, eventi)
  functions/reflections/index.ts          ← Deno Edge Function: OpenAI + contesto utente + RLS
```

Convenzioni: clean arch come le feature esistenti (`core/data/domain/presentation`),
BLoC per lo stato, `dairy_app` package name, l10n **solo EN** per il MVP (S.current esistente),
nomi file snake_case, temi via `Theme.of(context)` (mai colori hard-coded, mai font custom nuovi).

## 6. Schema Supabase (migrations/0001_init.sql)

Tabelle (tutte con `id uuid default gen_random_uuid()`, `created_at timestamptz default now()`):
- `profiles` — 1:1 con auth.users (display_name, avatar_url, bio) · RLS: self read/write, altri read.
- `entries` — mirror del diario (user_id, title, content_json, mood_id, mood_score, entry_date, tags[])
  · RLS: **solo owner** (journal privato: mai leggibile da altri).
- `mood_logs` — log mood indipendente (user_id, mood enum 1-5, note, logged_at) · RLS owner-only.
- `spaces` — community spaces (name, description, slug, cover_url, created_by) · read tutti gli auth, write creator/admin.
- `space_members` — membership (space_id, user_id, role) · RLS membri.
- `posts` — post nei spaces (space_id, user_id, title, body, is_anonymous) · RLS: membri leggono/scrivono propri.
- `post_likes`, `comments` — interazioni · RLS membri dello space.
- `rooms` — conversazioni di gruppo (name, created_by, is_direct) + `room_members` (ruoli admin/moderator,
  duplicati bloccati) + `messages` (room_id, user_id, content, created_at) · RLS membri; Realtime ON.
- `events` — virtual events (space_id?, title, description, starts_at, ends_at, join_url, created_by) · read auth.
- `event_rsvps` — (event_id, user_id, status going/interested) · RLS self.
- `reflections` — AI reflections (user_id, entry_id?, prompt, response, model) · RLS owner-only.
- `reflection_messages` — cronologia conversazione AI (user_id, session_id, role, content) · RLS owner-only.
- Storage buckets: `avatars/` (public read), `event-covers/` (public read).
- Triggers: auto-create `profiles` su `auth.users` insert; updated_at su entries/posts.
- Index su FK e colonne di query principali. pgvector opzionale (Fase AI avanzata) su `entries.embedding`.

## 7. Milestone

- [x] M0 — Analisi gap + ricerca repo (fatta, sezione 2 e 4)
- [x] M0b — Build APK CI da clone (`dvd2pe/diaryvault-apk` release 2.4.0) ✅ verificata e firmata
- [x] M0c — Questo documento pushato nella repo di sviluppo
- [x] **M1 — Fondazione Supabase**: `supabase/migrations` + `config.toml` + `seed.sql` + Edge Function `reflections`
- [x] **M2 — Integrazione app**: `supabase_flutter` in pubspec, `core/network/supabase_client.dart`,
      init in `main.dart`, data source Supabase per auth (UI esistente invariata)
- [x] **M3 — Mood tracking**: feature completa + mood sulla nota (entry_date, mood_score) + pagina tracker
- [x] **M4 — AI reflections**: service Dart → Edge Function, pagina conversazione con storia persistita
- [x] **M5 — Community spaces**: feed + post + like + comment
- [x] **M6 — Group chat**: rooms realtime + messaggi
- [x] **M7 — Events**: listing + RSVP
- [x] **M8 — Hub + integrazione UI**: pagina hub raggiungibile da home, entry points nei temi DiaryVault
- [x] **M9 — CI**: workflow `analyze.yml` (Flutter 3.32.0, analyze+test) su push; fix errori
- [x] **M10 — Build APK CI**: release `v0.1.0-dearcocoa` con 3 APK firmati verificati (arm64/armv7/x86_64, cert CN=DearCocoa SHA-256 `B0:EA:55:...:4F`, validi al 2056). Fix storico: `/releases/latest` non restituisce le prerelease -> il workflow ora fetcha la release per tag. iOS `--no-codesign` su macos runner: ANCORA DA FARE
- [x] **M10.5 — Secrets Supabase (COMPLETATO)**: progetto "Dear Cocoa" (ref `sukxerupxdctdnegghwa`) collegato. Schema vecchio rimosso (25 tabelle superflue, buckets via Storage API), `0001_init.sql` applicato + seed realistico v2. Secrets repo `SUPABASE_URL`/`SUPABASE_ANON_KEY` settati. Release **v0.2.0-dearcocoa** (versionCode 2040) con 3 APK firmati VERIFICATI (chiavi Supabase baked nel libapp.so). Login demo verificato via REST (alex/maya OK)
- [~] **M2.1 — Sync entries (PULL fatto, PUSH da fare)**: `SupabaseEntriesPull` con lock statico + transazione sqlite (race sign-in/hub risolta: 14/14 entries di Alex pulled, idempotente per id). PUSH locale→cloud ancora da fare (upsert con local_id)
- [x] **M-DEMO — Richieste cliente 18/11 (COMPLETATO)**: app tutta inglese (`locale: const Locale('en')`), login DearCocoa prefilled + switch 2 account (Alex Rivera / Maya Chen, `Cocoa2026!`), dati demo realistici EN
- [x] **M11a — Demo assets (COMPLETATO)**: workflow `record_demo.yml` (dispatch) → emulatore Android su Actions, integration test `demo_walkthrough_test.dart` (20 schermate: welcome→guest→journal→hub sign-in→mood check-in→community like+post→chat send→event RSVP→reflections→journal synced), **20 screenshot allineati + video MP4 8min** (screenrecord su /data/local/tmp, fallback slideshow). Fix infrastruttura: AVD manuale (avdmanager hang), chmod /dev/kvm, cache Gradle (429 maven)
- [ ] **M3-OPENAI — reflections live**: quando il cliente fornisce OPENAI_API_KEY -> deploy Edge Function `supabase/functions/reflections` (via Management API o CLI) + secret runtime; la storia demo è già seedata
- [ ] **M11b — Chiusura**: README DearCocoa, doc API, checklist security (RLS reviste)

## 8. Come riprendere (checklist per il prossimo agente/utente)

1. `git clone https://github.com/dvd2pe/dearcocoa-app && cd dearcocoa-app`
2. Leggere questo file: lo stato è la sezione 7 (spuntare solo ciò che è veramente fatto).
3. Supabase: creare progetto (Settings → API → Project URL + anon/publishable key), applicare
   `supabase/migrations/*.sql` (SQL editor o `supabase db push`), poi `supabase/seed.sql`.
   Chiavi al client via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   (pattern SETUP_SUPABASE.md del progetto precedente). Demo accounts prefill: 5 utenti
   `* @dearcocoa.demo` password `Cocoa2026!` (seed idempotente, pattern del seed_demo.sql precedente).
   Edge Function runtime secret: `OPENAI_API_KEY` (+ `AI_BASE_URL` opzionale per provider alternativi).
4. App: le chiavi Supabase in dev vanno in `lib/core/network/supabase_client.dart`
   (costanti `kSupabaseUrl`, `kSupabaseAnonKey` — placeholder con configurazione via `--dart-define`).
5. Continuare dalla prima milestone non spuntata in ordine (M1 → M11).
6. Validare SEMPRE con `flutter analyze` in CI prima di considerare una milestone chiusa.
7. Build APK: riusare il workflow di `dvd2pe/diaryvault-apk` (vedi repo) con `--flavor prod --release`.

## 9. Note di licenza e ipotesi

- DiaryVault upstream: **MIT** — base libera per DearCocoa. Mantenere attribution nel README.
- Ipotesi dichiarate: MVP = 1 lingua (EN), immagini solo avatar/copertina, pagamenti assenti,
  video live eventuali in fase 2 (fuori dai $20k).
