import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';
import 'overview_screen.dart';
import 'planner_calendar_screen.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/bottom_nav_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    // Auto-sync data when home screen loads (if user is logged in)
    _autoSync();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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

  /// Get display name for greetings (username preferred, fallback to first name)
  String _getDisplayName() {
    return _userName;
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
      return '☀️'; // Sun for morning
    } else if (hour < 17) {
      return '☀️'; // Sun for afternoon
    } else {
      return '🌙'; // Moon for evening
    }
  }

  Widget _buildAppBarTitle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bool isLoggedIn = AuthService().isLoggedIn;
    
    // Use FutureBuilder to check guest mode asynchronously
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getBool('isGuestMode') ?? false),
      builder: (context, snapshot) {
        final bool isGuestMode = snapshot.data ?? false;
        // Show greeting for both logged-in users and guest users
        final bool showGreeting = isLoggedIn || isGuestMode;
        
        if (showGreeting) {
          final String displayName = isGuestMode ? 'Guest' : _getDisplayName();
          return RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(color: textColor),
              children: <TextSpan>[
                TextSpan(
                  text: '${_getTimeBasedGreeting()} ${_getTimeEmoji()} ',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Times New Roman',
                    color: textColor,
                  ),
                ),
                TextSpan(
                  text: displayName,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Only show default title if not logged in and not in guest mode
        return Text(
          'ML Smart Expense',
          style: TextStyle(color: textColor),
        );
      },
    );
  }

  Future<void> _autoSync() async {
    // Wait a bit for the app to be ready
    await Future<void>.delayed(const Duration(seconds: 1));

    // Note: Will use Supabase auth check in future
    try {
      await SyncService().syncNow();
    } catch (_) {
      // Sync failed silently - app continues to work
    }
  }

  void _onTabChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() => _index = index);
    // Reload user data when switching back to home tab to reflect any changes
    if (index == 0) {
      _loadUserData();
    }
  }

  // Removed _getMenuItems - using inline menu items in floating menu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        scrolledUnderElevation: 0,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.05, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
                child: IndexedStack(
                  key: ValueKey<int>(_index),
                  index: _index,
                  children: <Widget>[
                    const OverviewScreen(),
                    AddExpenseScreen(onClose: () => _onTabChanged(0)),
                    const BudgetScreen(),
                    const PlannerCalendarScreen(),
                    const SettingsScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavMenu(
        currentIndex: _index,
        onIndexChanged: _onTabChanged,
      ),
    );
  }
}
