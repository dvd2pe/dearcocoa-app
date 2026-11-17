// ============================================================================
// DearCocoa - Edge Function: AI reflections
// ============================================================================
// Genera riflessioni AI sui contenuti del journal dell'utente, in privacy-safe:
//  - chiama l'utente con il JWT: la function usa auth.uid() e legge SOLO le
//    entries del richiedente (RLS Postgres, service_role NON usato per il read)
//  - il contesto e' limitato agli entry selezionati dall'utente (o gli ultimi N)
//  - la cronologia conversazione vive in reflection_sessions/reflection_messages
//    (RLS owner-only) e viene passata al modello come history
//
// Deploy:  supabase functions deploy reflections --no-verify-jwt=false
// Secrets: supabase secrets set OPENAI_API_KEY=sk-...
//          supabase secrets set AI_BASE_URL=https://api.openai.com/v1   (opz.)
//          supabase secrets set AI_MODEL=gpt-4o-mini                    (opz.)
//
// Request (Authorization: Bearer <access_token>):
// {
//   "sessionId": "uuid | null",          // null = nuova sessione
//   "message": "cosa noto nelle mie ultime settimane?",
//   "entryIds": ["uuid", ...],           // opzionale: entries da includere
//   "maxEntries": 5                      // default 5
// }
// Response: { "sessionId": "...", "reply": "...", "messages": [...] }
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AI_BASE_URL = Deno.env.get("AI_BASE_URL") ?? "https://api.openai.com/v1";
const AI_MODEL = Deno.env.get("AI_MODEL") ?? "gpt-4o-mini";

const SYSTEM_PROMPT = `You are DearCocoa's reflection companion.
You help the user reflect on their private journal entries with warmth and
curiosity. Never invent journal content: only use what is provided as context.
If no entries are provided, gently invite the user to write or pick entries.
Keep replies concise (max 180 words), encouraging, and end with one open
question. The user's journal content is strictly confidential: never repeat
long verbatim excerpts; refer to themes instead.`;

interface RequestBody {
  sessionId?: string | null;
  message: string;
  entryIds?: string[];
  maxEntries?: number;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "POST only" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing Authorization header" }, 401);

  // client con JWT utente: RLS Postgres garantisce che si leggano SOLO
  // le entries/reflection_messages del richiedente
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: authData } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  const user = authData?.user;
  if (!user) return json({ error: "invalid token" }, 401);

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid JSON body" }, 400);
  }
  const message = (body.message ?? "").trim();
  if (!message) return json({ error: "message is required" }, 400);

  // ---------------------------------------------------------------- sessione
  let sessionId = body.sessionId ?? null;
  if (sessionId) {
    const { data: s } = await supabase
      .from("reflection_sessions")
      .select("id")
      .eq("id", sessionId)
      .single();
    if (!s) sessionId = null;
  }
  if (!sessionId) {
    const { data: created, error: errS } = await supabase
      .from("reflection_sessions")
      .insert({ user_id: user.id, title: message.slice(0, 60) })
      .select("id")
      .single();
    if (errS) return json({ error: errS.message }, 500);
    sessionId = created!.id;
  }

  // --------------------------------------------------- contesto: le entries
  // SOLO dell'utente (RLS), selezionate dall'utente o le piu' recenti
  const maxEntries = Math.min(Math.max(body.maxEntries ?? 5, 1), 20);
  let entriesContext = "";
  if (body.entryIds?.length) {
    const { data } = await supabase
      .from("entries")
      .select("title, entry_date, content_delta, mood_score")
      .in("id", body.entryIds)
      .order("entry_date", { ascending: false })
      .limit(maxEntries);
    entriesContext = renderEntries(data ?? []);
  } else {
    const { data } = await supabase
      .from("entries")
      .select("title, entry_date, content_delta, mood_score")
      .order("entry_date", { ascending: false })
      .limit(maxEntries);
    entriesContext = renderEntries(data ?? []);
  }

  // ------------------------------------------ cronologia della conversazione
  const { data: history } = await supabase
    .from("reflection_messages")
    .select("role, content")
    .eq("session_id", sessionId)
    .order("created_at", { ascending: true })
    .limit(30);

  // ------------------------------------------------------------- chiamata AI
  const aiMessages = [
    { role: "system", content: SYSTEM_PROMPT },
    ...(entriesContext
      ? [{
          role: "system",
          content:
            `Journal context (user's own entries, confidential):\n${entriesContext}`,
        }]
      : []),
    ...(history ?? []).map((m) => ({ role: m.role, content: m.content })),
    { role: "user", content: message },
  ];

  const aiRes = await fetch(`${AI_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: AI_MODEL,
      messages: aiMessages,
      max_tokens: 400,
      temperature: 0.7,
    }),
  });
  if (!aiRes.ok) {
    return json(
      { error: `AI provider error ${aiRes.status}` },
      502,
    );
  }
  const aiJson = await aiRes.json();
  const reply: string = aiJson.choices?.[0]?.message?.content ?? "";

  // -------------------------------------- persistenza della conversazione
  // (RLS owner-only: la history resta privata dell'utente)
  const { error: errU } = await supabase
    .from("reflection_messages")
    .insert({ session_id: sessionId, user_id: user.id, role: "user", content: message });
  if (errU) return json({ error: errU.message }, 500);

  const { error: errA } = await supabase
    .from("reflection_messages")
    .insert({ session_id: sessionId, user_id: user.id, role: "assistant", content: reply });
  if (errA) return json({ error: errA.message }, 500);

  return json({ sessionId, reply });
});

function renderEntries(
  rows: { title: string | null; entry_date: string; content_delta: unknown; mood_score: number | null }[],
): string {
  return rows.map((r, i) => {
    const text = deltaToText(r.content_delta);
    const mood = r.mood_score ? ` [mood ${r.mood_score}/5]` : "";
    return `(${i + 1}) ${r.entry_date}${mood} ${r.title ?? "(untitled)"}: ${text.slice(0, 800)}`;
  }).join("\n");
}

// Quill Delta -> testo piatto (solo insert)
function deltaToText(delta: unknown): string {
  if (!delta || typeof delta !== "object") return "";
  const ops = (delta as { ops?: unknown }).ops;
  if (!Array.isArray(ops)) return "";
  return ops
    .map((op) =>
      typeof op === "object" && op !== null && "insert" in op &&
      typeof (op as { insert: unknown }).insert === "string"
        ? (op as { insert: string }).insert
        : "",
    )
    .join("")
    .replace(/\n+/g, " ")
    .trim();
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
