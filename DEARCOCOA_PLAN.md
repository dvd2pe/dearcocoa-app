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
| Mirror memex integrale | `dvd2pe/memex` (mirror di memex-lab/memex @ `d541b1b5`, 40 tag, main incluso) — riferimento UI/UX per M12 |
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

**Da NON usare nel codice (licenze)**: CikeSeven/jotsy (GPL-3.0),
lollipopkit/llmbox (GPL-3.0), dshukertjr/spot (LGPL, stale), mitchkoko/moonbase-template (Firebase),
Coffiie/discord_open (Serverpod).

**AGGIORNAMENTO 18/11 (sera) — decisione cliente**: memex-lab/memex (GPL-3.0) è ora autorizzato a copia diretta
del codice ("copia pure, non mi interessa licenza" — verbatim, tracciato qui). Il cliente ha valutato la UI attuale
negativa e vuole widget UI/UX in stile memex. Nota tecnica per onestà: il codice combinato sarà di fatto
derivato GPL se ridistribuito; per uso interno/demo del cliente è irrilevante. Memex passa da "non usare" a
riferimento primario UI/UX (vedi sezione 10). Il repo privato `dvd2pe/dearcocoa` (base memex, R1-R5) torna
utile come riferimento di integrazione già compilato.

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
- [ ] **M12 — Integrazione UI/UX memex (DECISIONI RICEVUTE → vedi sezione 11)**: base = vecchio repo
  memex-based R1-R5 riusato in nuovo repo pubblico `dvd2pe/dearcocoa-mobile`; strategia C, look memex full,
  tutte le schermate, foto+voce, 13 insight cards, biometric lock, release v0.3.0

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
- 18/11 (sera): cliente autorizza esplicitamente copia codice da memex (GPL-3.0) — vedi sezione 4.

## 10. Valutazione memex per integrazione UI/UX (18/11, sera)

**Sorgente**: mirror `dvd2pe/memex` @ `d541b1b5` (memex-lab/memex, 843 star, attivo, GPL-3.0, Flutter).
Locale: `/home/z/my-project/memex` (clone di lavoro) + `/home/z/my-project/memex-mirror.git` (bare).
Precedente repo privato `dvd2pe/dearcocoa` (base memex, APK v1.0.39-demo) = riferimento integrazione già compilato.

**Cosa è memex**: journal AI local-first — capture di frammenti (testo, foto, voce) organizzati da un
sistema multi-agente in "timeline cards" strutturate + knowledge base + insights + AI companion.
Stack: provider + go_router + drift (sqlite locale) + BYO LLM (OpenAI/Claude/Gemini/DeepSeek/Ollama,
nessun server). 473 file Dart, ~227k LOC. NO social/community (differenza chiave: DearCocoa ha
community/chat/eventi/mood social via Supabase — memex no → i punti di forza si complementano).

**Design system memex** (`lib/ui/core/themes/`):
- `app_colors.dart`: primary indigo `#5B6CFF`, bg `#F7F8FA`, card bianco, testo `#0A0A0A`/`#4A5565`/`#99A1AF`,
  tab attivo `#1F1F1F`, semantic `#10B981`/`#F59E0B`/`#F43F5E`, gradient avatar a 12 stop
- `app_text_styles.dart`: **Inter** (body) + **Bricolage Grotesque** (brand title) + PingFang SC (CJK),
  scala tipografica completa display→body con height/letterSpacing curati
- `app_shadows.dart` + `app_theme.dart`: ThemeData completo light/dark da seed indigo
- Font **bundled offline** (`google_fonts/` TTF, niente fetch runtime)

**Componenti UI copiabili ad alto valore** (path mirror):
1. **Sistema timeline cards** (`ui/core/cards/templates/`): 20+ template in 5 famiglie —
   entities (link/person/place/transaction/spec_sheet), quantifiable (**mood**/metric/progress/rating),
   temporal (event/task/routine/duration/procedure), textual (quote/snippet/article/conversation/compact/insight_summary),
   visual (gallery/snapshot/video/canvas) + `timeline_theme.dart` + `classic_card.dart`
2. **Insight cards grafiche** (`ui/insight/widgets/insight_cards/`): 13 chart cards su fl_chart —
   bar, bubble, composition, contrast, highlight, map, progress, radar, route_map, summary, timeline, trend
3. **Main screen UX** (`ui/main_screen/widgets/`): `radial_menu` (menu radiale di capture), `ai_core_button`,
   `main_bottom_bar`, `action_center_sheet`, `clipboard_preview_card`, `quick_recording_transcript` (voce→testo rapido)
4. **Chat agent** (`ui/chat/widgets/`): agent_chat_dialog, open_super_agent_dialog, chat_history_screen
5. **Extra**: share_poster_decorator + share_preview_dialog (condivisione come poster), app_lock (biometria
   local_auth), character_avatar/dicebear_avatar, calendar_screen, demo_overlay, searchable_dropdown,
   adaptive_icon, detail_page_layout
6. **Feature capture** assenti in DearCocoa: foto allegati (wechat_assets_picker/photo_manager), registrazione
   voce (record + audioplayers), health/pedometer, flutter_map + location, quick_actions (long-press icona),
   share_handler (share intent in app)

**Difficoltà integrazione (media, non banale)**: memex = provider + view_models + drift; DearCocoa =
DiaryVault arch + supabase_flutter + quill vendored. I widget copiano bene MA la maggior parte dipende da
view_models/provider memex → serve adattare al nostro state. Nuove dipendenze pub.dev da aggiungere:
fl_chart, google_fonts, record, image_picker, photo_manager/wechat_assets_picker, local_auth, quick_actions,
flutter_markdown, share_handler (tutte MIT/BSD salvo diverso indicato in pubspec).

**Strategie proposte al cliente**:
- **A — Restyle token (fast, ~1-2 giorni)**: adotta AppColors/Inter/Bricolage/shadows/scala tipografica su
  TUTTE le schermate esistenti (DiaryVault theme overrides). Zero rischio architetturale, cambia il look ma
  non i pattern di interazione
- **B — Restyle + widget chiave (~3-5 giorni)**: A + radial_menu/ai_core_button/bottom bar memex sul main,
  capture foto+voce nelle note, insight cards (subset 4-6 chart) per mood/reflections, share poster.
  Massimo valore visivo/funzionale per effort — CONSIGLIATA
- **C — Feature profonde (2-3+ settimane)**: B + knowledge base memex, agent system con skills, health,
  maps, calendar. Alto rischio conflitto con Supabase/social esistenti; capire bene il costo prima

**Decisioni richieste (7 domande poste al cliente)**: strategia A/B/C; identità visiva (look memex completo
vs colori DearCocoa su componenti memex); schermate prioritarie; scope capture (foto/voce); scope insight
cards; biometric lock; se tagliare release v0.3.0 subito dopo.

## 11. Decisioni cliente 18/11 sera + roadmap M12 (base memex)

**Risposte alle 7 domande**:
- Strategia: **C — Feature deep**
- Identità visiva: **look memex full** (indigo #5B6CFF, bg #F7F8FA, Inter + Bricolage Grotesque, ombre)
- Schermate: **tutte** (Home/Journal, Community/Chat, Hub/Insights, Mood)
- Capture: **foto + voce**
- Insight cards: **set completo** (13)
- Biometric lock: **sì**
- Release: **v0.3.0** appena integrazione verde
- Remark verbatim: "Copia 1:1 l'interfaccia memex, l'unica cosa che mi spaventa è l'integrazione ai,
  precedentemente in generale rimanevamo molto stuck e non vorrei rimanere stuck, se qualcosa non riesci
  dopo due tentativi, ti blocchi e mi dici soluzioni, se bypassarla o altro, mi domandi. Per me importante
  è portare memex come base, implementare tutte le features di diaryvault + memex assieme (leggi i repo,
  tutte le funzionalità le teniamo (ie localizzazione)) ma se non comportano problemi e non clashano"

**REGOLE OPERATIVE fissate dal cliente**:
1. **ANTI-STUCK**: qualcosa fallisce dopo 2 tentativi → STOP, presentare opzioni (fix/bypass) e CHIEDERE
2. **APK sempre `--release`, MAI debug** (richiesta esplicita 18/11)
3. Feature DiaryVault+memex si tengono TUTTE salvo clash; l10n resta (18 lingue memex), default demo EN

**RILIEVO CHIAVE**: il vecchio repo privato `dvd2pe/dearcocoa` è GIÀ "memex come base + feature DiaryVault"
(R1-R5 completati 17/11: base compilata analyze 0 err/1073 test, rename dearcocoa, Supabase
community/gruppi/eventi realtime, mood+reminder+TTS, APK demo 255.8MB release firmato). Il remark del
cliente descrive esattamente quello stato → **si riusa quella base**, non si riparte dal mirror pulito.

**Copertura già pronta nella base R1-R5** (nessuna riscrittura): UI memex 1:1 (radial menu, timeline cards
20+, insight cards 13 su fl_chart, knowledge base, agenti+skills BYO-LLM 17 provider, app lock biometrico,
capture foto+voce, health, maps, calendar, 18 lingue, character AI companion) + backend completo (13 tabelle
+RLS+storage+realtime+trigger, seed 5 utenti demo, edge function ai-reflection) + DemoLoginScreen 5 account
one-tap + mood/reminder/TTS.

**Toolchain switch (importante)**: base memex richiede Flutter 3.35.5 / JDK 21 / AGP 8.11.1 / NDK 27.3 /
CMake 3.22.1 — NON la toolchain pinnata DiaryVault (3.32.0). I workflow del vecchio repo la gestiscono
(fix R5: free disk ~25GB, NDK install, CMake tarball Kitware + cmake.dir, desugaring).

**Roadmap M12**:
- [~] **M12.1** — Repo pubblico `dvd2pe/dearcocoa-mobile` CREATO e build APK release VERDE (2 run
  success, keystore release da secrets, artifact `dearcocoa-release-apk`). Push protection: risolta
  redigendo credenziali OAuth Google di memex (Gemini OAuth via dart-define, flusso API-key intatto).
  CI: analyze OK con `--no-fatal-infos --no-fatal-warnings` (allineato upstream). Test: 15 fallimenti
  stale da rename R2 → fix batch (canali com.memexlab.memex→app.dearcocoa.mobile, migration 19→20,
  l10n Memex→DearCocoa, finder subclass-safe per .icon) → ridotti a 6: agent_background_status (4,
  input costruito da distinigere da aspettative ARB), backup_restore (1), early_update (1, timing).
  ⚠️ STALLA per regola anti-stuck (2 tentativi): opzioni proposte al cliente (gate known-failures /
  deep-dive / gate analyze-only)
- [ ] **M12.2** — Reset schema Supabase progetto "Dear Cocoa" (`sukxerupxdctdnegghwa`) →
  backend/supabase del vecchio repo (13 tabelle + seed demo + storage + realtime publication);
  SUPABASE_URL/ANON_KEY via dart-define nel build; default demo EN
- [ ] **M12.3** — Edge Function `ai-reflection` deploy (in attesa OPENAI_API_KEY dal cliente — M3-OPENAI;
  Edge Function supporta AI_BASE_URL per provider compatibili)
- [ ] **M12.4** — Release **v0.3.0-dearcocoa**: APK release firmati (flavor global, split-per-abi
  arm64/armv7/x86_64), verifica firma v2/v3; appId `app.dearcocoa.mobile` ≠ dearcocoa-app → installabile
  a fianco, disinstallare la vecchia v1.0.39-demo (demo keystore diverso)
- [ ] **M12.5** — Demo assets refresh: screenshot tutte le schermate + video stile Loom dalla base memex
  (dispositivo EN)
- [ ] **Backlog** — APK size: 255MB fat → split-per-abi (-60% circa), pruning modelli sherpa_onnx inutilizzati

**Stato linee di codice**:
- `dvd2pe/dearcocoa-app` (DiaryVault-based, release v0.2.0): CONGELATA come fallback/demo parallela
- `dvd2pe/dearcocoa` (privato, memex-based R1-R5): origine, resta privato (contiene reference/ con repo
  senza licenza + job posting del cliente)
- `dvd2pe/dearcocoa-mobile` (pubblico, memex-based): **NUOVA LINEA PRIMARIA** per CI/CD e release
