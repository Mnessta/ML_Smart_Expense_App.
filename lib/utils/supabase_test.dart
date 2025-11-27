import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_smart_expense_track/utils/logger.dart';

/// Test Supabase connection and configuration
class SupabaseTest {
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{
      'connected': false,
      'authenticated': false,
      'tablesExist': false,
      'errors': <String>[],
    };

    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Basic connection
      try {
        await supabase.from('expenses').select('count').limit(1);
        results['connected'] = true;
        results['tablesExist'] = true;
      } catch (e) {
        results['errors'].add('Connection test failed: $e');
        if (e.toString().contains('relation "expenses" does not exist')) {
          results['errors'].add('⚠️ Expenses table not found. Run supabase_schema.sql in Supabase SQL Editor');
        }
      }

      // Test 2: Authentication status
      final user = supabase.auth.currentUser;
      results['authenticated'] = user != null;
      if (user != null) {
        results['userId'] = user.id;
        results['userEmail'] = user.email;
      }

      // Test 3: Check if tables are accessible
      if (results['tablesExist'] == true) {
        try {
          // Try to query expenses table
          await supabase.from('expenses').select('id').limit(1);
        } catch (e) {
          results['errors'].add('Table access error: $e');
          if (e.toString().contains('permission denied')) {
            results['errors'].add('⚠️ RLS policies may not be set up correctly');
          }
        }
      }

    } catch (e) {
      results['errors'].add('Unexpected error: $e');
    }

    return results;
  }

  /// Print connection test results
  static Future<void> printTestResults() async {
    AppLogger.i('\n🔍 Testing Supabase Connection...\n');
    final results = await testConnection();
    
    AppLogger.i('Connection Status:');
    AppLogger.i('  ✅ Connected: ${results['connected']}');
    AppLogger.i('  ✅ Authenticated: ${results['authenticated']}');
    AppLogger.i('  ✅ Tables Exist: ${results['tablesExist']}');
    
    if (results['authenticated'] == true) {
      AppLogger.i('  👤 User ID: ${results['userId']}');
      AppLogger.i('  📧 Email: ${results['userEmail']}');
    }
    
    if ((results['errors'] as List).isNotEmpty) {
      AppLogger.e('\n❌ Errors:');
      for (final error in results['errors'] as List) {
        AppLogger.e('  - $error');
      }
    } else {
      AppLogger.i('\n✅ All tests passed!');
    }
    AppLogger.i('');
  }
}

