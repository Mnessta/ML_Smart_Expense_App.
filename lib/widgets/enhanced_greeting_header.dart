import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedGreetingHeader extends StatefulWidget {
  const EnhancedGreetingHeader({super.key});

  @override
  State<EnhancedGreetingHeader> createState() => _EnhancedGreetingHeaderState();
}

class _EnhancedGreetingHeaderState extends State<EnhancedGreetingHeader> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Get username for greetings (preferred), or fallback to first name from full name
    final String? displayUsername = prefs.getString('displayUsername');
    final String? fullName = prefs.getString('userName');
    final bool isGuestMode = prefs.getBool('isGuestMode') ?? false;
    
    String name = 'User';
    if (displayUsername != null && displayUsername.trim().isNotEmpty) {
      name = displayUsername.trim();
    } else if (fullName != null && fullName.trim().isNotEmpty) {
      // Extract first name from full name
      final List<String> nameParts = fullName.trim().split(' ');
      name = nameParts.first;
    } else if (isGuestMode) {
      // Default name for guest users
      name = 'Guest';
    }
    
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  String _getTimeBasedGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getTimeEmoji() {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅';
    } else if (hour < 17) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  String _getMotivationalQuote() {
    final List<String> quotes = <String>[
      'Small savings add up 💰',
      'Every penny counts 💵',
      'Track smart, save more 🎯',
      'You\'re doing great! 🚀',
      'Progress over perfection 📈',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                _getTimeBasedGreeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ) ?? const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                _getTimeEmoji(),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ) ?? const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getMotivationalQuote(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

