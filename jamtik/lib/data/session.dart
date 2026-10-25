import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Auth, which persists and refreshes the session itself.
class Session {
  static SupabaseClient get _sb => Supabase.instance.client;

  static String? get token => _sb.auth.currentSession?.accessToken;

  /// Kept so existing code compiles; Supabase manages the token.
  static set token(String? _) {}

  static Future<String?> restore() async => token;

  /// No-op: Supabase saves the session automatically after verifyOTP.
  static Future<void> save(String value) async {}

  static Future<void> clear() => _sb.auth.signOut();

  static Future<void> expire() => _sb.auth.signOut();
}