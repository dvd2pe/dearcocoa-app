import 'package:supabase_flutter/supabase_flutter.dart';

/// DearCocoa Supabase configuration.
///
/// Keys are injected at build time via --dart-define:
///   flutter build apk --flavor prod --release \
///     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
///
/// When not configured the app keeps working as plain DiaryVault (local
/// only): DearCocoa features degrade gracefully with a friendly message.
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// True when both keys were provided at build time.
bool get isSupabaseConfigured => kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;

/// Initializes Supabase. Safe to call always: it is a no-op when the keys
/// are missing, so the base DiaryVault experience is untouched.
Future<void> initSupabase() async {
  if (!isSupabaseConfigured) return;
  try {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
    // NOTE: supabase_flutter >= 2.13 renames anonKey -> publishableKey;
    // the deprecated param still works on 2.x and keeps the pubspec
    // constraint (^2.6.0) resolvable on Flutter 3.32.0.
  } catch (_) {
    // initialize() throws if already initialized (e.g. hot restart); ignore.
  }
}

/// Returns the shared SupabaseClient, or null when Supabase is not
/// configured/initialized. Callers must handle null gracefully.
SupabaseClient? get supabase {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

/// Current signed-in user id, or null.
String? get currentUserId {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

/// Simple check for DearCocoa features: true when the user can use the
/// social layer (Supabase configured AND signed in).
bool get isDearCocoaReady {
  if (!isSupabaseConfigured) return false;
  return currentUserId != null;
}
