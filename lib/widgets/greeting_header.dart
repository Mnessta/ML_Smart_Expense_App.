import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GreetingHeader extends StatefulWidget {
  const GreetingHeader({super.key});

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
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
      setState(() => _userName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hello $_userName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ) ?? const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

