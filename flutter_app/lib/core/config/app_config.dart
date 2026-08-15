/// Compile-time / dart-define configuration. Publishable keys only.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fnycwcbxorhreidhbers.supabase.co',
  );

  /// Publishable (anon) key — safe for the client. Override via --dart-define.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZueWN3Y2J4b3JocmVpZGhiZXJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNDg3MTQsImV4cCI6MjA5NTkyNDcxNH0.nGqWeqyJKH_tGRXFTc2JsvXBlq2rkDnNrbpwYUOdvdI',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nyumbasearch.com',
  );

  static const appClient = String.fromEnvironment(
    'APP_CLIENT',
    defaultValue: 'flutter',
  );

  static const oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'ke.co.nyumbasearch.app://login-callback/',
  );

  static bool get hasSupabaseKey => supabaseAnonKey.isNotEmpty;

  /// Mobile BFF root (Phase 1).
  static String get mobileApiV1 => '$apiBaseUrl/api/mobile/v1';
}
