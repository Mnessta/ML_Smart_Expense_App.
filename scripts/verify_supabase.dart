// Quick verification script for Supabase setup
// Run with: dart run scripts/verify_supabase.dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  print('\n🔍 Verifying Supabase Configuration...\n');
  
  // Check if config file exists
  final configPath = path.join('lib', 'config', 'supabase_config.dart');
  final configFile = File(configPath);
  
  if (!configFile.existsSync()) {
    print('❌ Config file not found: $configPath');
    print('   Run: flutter pub get');
    exit(1);
  }
  
  // Read config file
  final content = configFile.readAsStringSync();
  
  // Check for placeholders
  if (content.contains('YOUR_SUPABASE_URL') || 
      content.contains('YOUR_SUPABASE_ANON_KEY')) {
    print('⚠️  Configuration not updated yet!');
    print('\n📝 Next steps:');
    print('   1. Get your credentials from Supabase Dashboard → Settings → API');
    print('   2. Update lib/config/supabase_config.dart');
    print('   3. Replace YOUR_SUPABASE_URL with your Project URL');
    print('   4. Replace YOUR_SUPABASE_ANON_KEY with your anon key');
    print('\n   Example:');
    print('   static const String url = \'https://xxxxx.supabase.co\';');
    print('   static const String anonKey = \'eyJhbGc...\';');
    exit(1);
  }
  
  // Extract values (simple regex check)
  final urlMatch = RegExp(r"url = '([^']+)'").firstMatch(content);
  final keyMatch = RegExp(r"anonKey = '([^']+)'").firstMatch(content);
  
  if (urlMatch == null || keyMatch == null) {
    print('❌ Could not parse configuration values');
    exit(1);
  }
  
  final url = urlMatch.group(1)!;
  final key = keyMatch.group(1)!;
  
  // Validate format
  bool isValid = true;
  
  if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
    print('❌ Invalid Project URL format');
    print('   Expected: https://xxxxx.supabase.co');
    print('   Got: $url');
    isValid = false;
  }
  
  if (!key.startsWith('eyJ')) {
    print('❌ Invalid anon key format');
    print('   Expected: Key starting with "eyJ"');
    print('   Got: ${key.substring(0, key.length > 20 ? 20 : key.length)}...');
    isValid = false;
  }
  
  if (isValid) {
    print('✅ Configuration file looks good!');
    print('   URL: $url');
    print('   Key: ${key.substring(0, 20)}...');
    print('\n✅ Ready to test! Run: flutter run');
  } else {
    print('\n⚠️  Please fix the configuration errors above');
    exit(1);
  }
}

