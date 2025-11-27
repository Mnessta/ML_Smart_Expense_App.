import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration
///
/// Loads credentials from .env file for better security
/// Copy .env.example to .env and fill in your actual credentials
/// You can find these in your Supabase dashboard: Settings → API
class SupabaseConfig {
  // Supabase Project URL loaded from .env
  static String get url {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  // Supabase anon/public key loaded from .env
  // This is safe to use in client apps
  static String get anonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // Optional: For OAuth redirects
  static String get redirectUrl {
    return dotenv.env['SUPABASE_REDIRECT_URL'] ?? 
           'io.supabase.flutter://login-callback';
  }

  /// Validate that configuration is set
  static bool get isConfigured {
    final urlValue = url;
    final anonKeyValue = anonKey;
    return urlValue.isNotEmpty &&
        anonKeyValue.isNotEmpty &&
        urlValue != 'YOUR_SUPABASE_URL' &&
        anonKeyValue != 'YOUR_SUPABASE_ANON_KEY' &&
        urlValue.contains('.supabase.co');
  }

  /// Get configuration status message
  static String get statusMessage {
    if (!isConfigured) {
      return '⚠️ Supabase not configured. Please copy .env.example to .env and update with your credentials.';
    }
    return '✅ Supabase configured';
  }
}
