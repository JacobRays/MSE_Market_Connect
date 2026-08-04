class SupabaseConfig {
  // ✅ Direct constants instead of String.fromEnvironment
  static const String supabaseUrl = 'https://lochfeqlmvmsirhddpjf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2hmZXFsbXZtc2lyaGRkcGpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzA4NTUsImV4cCI6MjA5MDcwNjg1NX0.nXdcI6kTuHzzgpnOehd3JNln5iwm3ScmfS0kCUe2P_0';

  static void ensureInitialized() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Please set supabaseUrl and supabaseAnonKey.',
      );
    }
  }
}
