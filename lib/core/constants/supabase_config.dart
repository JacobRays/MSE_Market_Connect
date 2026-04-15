class SupabaseConfig {
  // Provided at build/run time:
  // --dart-define=SUPABASE_URL=...
  // --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static void ensureInitialized() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Pass --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}

