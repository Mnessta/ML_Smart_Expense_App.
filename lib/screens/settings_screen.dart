import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../utils/helpers.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../app_router.dart';
import 'package:go_router/go_router.dart';
import '../widgets/color_picker_dialog.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../services/security_service.dart';
import '../screens/pin_setup_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/about_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/support_screen.dart';
import '../utils/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_image_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _insightsEnabled = true;
  bool _pinEnabled = false;
  int _refreshKey = 0; // Key to force FutureBuilder rebuild

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _refreshProfile() {
    setState(() {
      _refreshKey++; // Increment key to force FutureBuilder to rebuild
    });
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _budgetAlertsEnabled = prefs.getBool('budgetAlertsEnabled') ?? true;
      _insightsEnabled = prefs.getBool('insightsEnabled') ?? true;
      _pinEnabled = prefs.getBool('pinEnabled') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('budgetAlertsEnabled', _budgetAlertsEnabled);
    await prefs.setBool('insightsEnabled', _insightsEnabled);
      await prefs.setBool('pinEnabled', _pinEnabled);
  }

  Future<void> _showLogoutDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService().signOut();
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        context.go(AppRoutes.login);
        // ignore: use_build_context_synchronously
        ErrorHandler.showSuccess(context, 'Logged out successfully');
      } catch (e) {
        // ignore: use_build_context_synchronously
        ErrorHandler.handleError(context, e);
      }
    }
  }

  Future<void> _sendFeedback() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FeedbackScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey), // Force rebuild when key changes
      future:
          Future.wait([
            AuthService().getUserDisplayName(),
            AuthService().getUserEmail(),
            SharedPreferences.getInstance().then((prefs) async {
              // Try to get from SharedPreferences first
              String? imagePath = prefs.getString('profileImagePath');
              
              // If logged in, also check Supabase user metadata for profile image URL
              if (AuthService().isLoggedIn) {
                final user = Supabase.instance.client.auth.currentUser;
                final String? profileImageUrl = ProfileImageService().getProfileImageUrlFromUser(user);
                if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                  // Prefer Supabase URL over local path
                  imagePath = profileImageUrl;
                  // Save URL to SharedPreferences for quick access
                  if (prefs.getString('profileImageUrl') != profileImageUrl) {
                    await prefs.setString('profileImageUrl', profileImageUrl);
                  }
                }
              }
              return imagePath;
            }),
          ]).then(
            (values) => {
              'name': values[0],
              'email': values[1],
              'imagePath': values[2],
            },
          ),
      builder: (context, snapshot) {
        final String userName = snapshot.data?['name'] ?? 'User';
        final String? userEmail = snapshot.data?['email'];
        final String? imagePath = snapshot.data?['imagePath'];
        final String displayEmail = userEmail ?? 'No email';
        final String avatarInitial = userName.isNotEmpty
            ? userName[0].toUpperCase()
            : 'U';
        // Check if image path exists - can be local file or URL
        ImageProvider? profileImageProvider;
        if (imagePath != null && imagePath.isNotEmpty) {
          // Check if it's a URL (from Supabase) or local file path
          if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
            // It's a URL from Supabase
            profileImageProvider = NetworkImage(imagePath);
          } else {
            // It's a local file path
            final file = File(imagePath);
            if (file.existsSync()) {
              profileImageProvider = FileImage(file);
            }
          }
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: profileImageProvider,
                      child: profileImageProvider == null
                          ? Text(
                              avatarInitial,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final bool? updated = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                        if (updated == true && mounted) {
                          // Refresh the screen to show updated data including profile photo
                          _refreshProfile();
                          await _loadPrefs();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Appearance
            _SectionHeader(title: 'Appearance'),
            Card(
              child: Column(
                children: <Widget>[
                  Consumer<ThemeProvider>(
                    builder:
                        (
                          BuildContext context,
                          ThemeProvider themeProvider,
                          Widget? child,
                        ) {
                          return ListTile(
                            leading: Icon(
                              themeProvider.themeMode == ThemeMode.dark
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                            ),
                            title: const Text('Theme'),
                            subtitle: Text(
                              themeProvider.themeMode == ThemeMode.dark
                                  ? 'Dark Mode'
                                  : 'Light Mode',
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                themeProvider.themeMode == ThemeMode.dark
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                size: 28,
                                color: themeProvider.themeMode == ThemeMode.dark
                                    ? Colors.indigo
                                    : Colors.amber,
                              ),
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                              tooltip: themeProvider.themeMode == ThemeMode.dark
                                  ? 'Switch to Light Mode ☀️'
                                  : 'Switch to Dark Mode 🌙',
                            ),
                          );
                        },
                  ),
                  const Divider(),
                  Consumer<ThemeProvider>(
                    builder:
                        (
                          BuildContext context,
                          ThemeProvider themeProvider,
                          Widget? child,
                        ) {
                          return ListTile(
                            leading: const Icon(Icons.palette),
                            title: const Text('Accent Color'),
                            subtitle: const Text('Choose your favorite color'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: themeProvider.accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[300] ?? Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            onTap: () async {
                              final Color? selectedColor =
                                  await showDialog<Color>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        ColorPickerDialog(
                                          currentColor:
                                              themeProvider.accentColor,
                                          onColorSelected: (Color color) {
                                            Navigator.of(context).pop(color);
                                          },
                                        ),
                                  );
                              if (selectedColor != null && mounted) {
                                themeProvider.setAccentColor(selectedColor);
                              }
                            },
                          );
                        },
                  ),
                  const Divider(),
                  Consumer<CurrencyProvider>(
                    builder:
                        (
                          BuildContext context,
                          CurrencyProvider currencyProvider,
                          Widget? child,
                        ) {
                          return ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: const Text('Currency'),
                            trailing: DropdownButton<String>(
                              value: currencyProvider.currency,
                              items:
                                  const <String>[
                                        'USD',
                                        'EUR',
                                        'KSH',
                                        'GBP',
                                        'INR',
                                        'NGN',
                                        'ZAR',
                                        'UGX',
                                      ]
                                      .map(
                                        (String c) => DropdownMenuItem<String>(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (String? v) {
                                if (v != null) {
                                  currencyProvider.setCurrency(v);
                                }
                              },
                            ),
                          );
                        },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Notifications
            _SectionHeader(title: 'Notifications'),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive app notifications'),
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() => _notificationsEnabled = value);
                      _savePrefs();
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.warning),
                    title: const Text('Budget Alerts'),
                    subtitle: const Text(
                      'Get notified when approaching budget limits',
                    ),
                    value: _budgetAlertsEnabled,
                    onChanged: (bool value) {
                      setState(() => _budgetAlertsEnabled = value);
                      _savePrefs();
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.lightbulb),
                    title: const Text('Smart Insights'),
                    subtitle: const Text('Receive spending insights and tips'),
                    value: _insightsEnabled,
                    onChanged: (bool value) {
                      setState(() => _insightsEnabled = value);
                      _savePrefs();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Security
            _SectionHeader(title: 'Security'),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    secondary: const Icon(Icons.lock),
                    title: const Text('PIN Protection'),
                    subtitle: const Text('Require PIN to open app'),
                    value: _pinEnabled,
                    onChanged: (bool value) async {
                      if (value) {
                        // Enable PIN - show setup screen
                        final bool? result = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const PinSetupScreen(),
                              ),
                            );
                        if (result == true && mounted) {
                          setState(() {
                            _pinEnabled = true;
                          });
                          await SecurityService().setPinEnabled(true);
                          await _savePrefs();
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN protection enabled'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        // Disable PIN - verify first
                        final bool? verified = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PinSetupScreen(isVerification: true),
                              ),
                            );
                        if (verified == true && mounted) {
                          setState(() {
                            _pinEnabled = false;
                          });
                          await SecurityService().setPinEnabled(false);
                          await _savePrefs();
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN protection disabled'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Data Management
            _SectionHeader(title: 'Data'),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync Now'),
                    subtitle: const Text('Sync data with cloud'),
                    onTap: () async {
                      try {
                        await SyncService().syncNow();
                        if (!context.mounted) return;
                        ErrorHandler.showSuccess(
                          context,
                          'Sync completed successfully',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ErrorHandler.handleError(
                          context,
                          e,
                          customMessage: 'Sync failed. Please try again.',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: const Text('Export CSV'),
                    subtitle: const Text('Export data as CSV file'),
                    onTap: () async {
                      try {
                        final List<ExpenseModel> expenses = await DbService()
                            .getExpenses();
                        if (expenses.isEmpty) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No expenses to export'),
                            ),
                          );
                          return;
                        }
                        final file = await ExportHelper.exportExpensesToCsv(
                          expenses,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('CSV saved: ${file.path}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ErrorHandler.handleError(
                          context,
                          e,
                          customMessage: 'Failed to export CSV',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Export PDF'),
                    subtitle: const Text('Export data as PDF file'),
                    onTap: () async {
                      try {
                        // Show loading indicator
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        final List<ExpenseModel> expenses = await DbService()
                            .getExpenses();
                        
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading

                        if (expenses.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No expenses to export'),
                            ),
                          );
                          return;
                        }

                        final file = await ExportHelper.exportExpensesToPdf(
                          expenses,
                        );
                        
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF saved: ${file.path}'),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {},
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading if still open
                        ErrorHandler.handleError(
                          context,
                          e,
                          customMessage: 'Failed to export PDF',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Backup to Cloud'),
                    subtitle: const Text('Upload backup to cloud (Supabase)'),
                    onTap: () async {
                      if (!context.mounted) return;

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final supabase = Supabase.instance.client;
                        final user = supabase.auth.currentUser;

                        if (user == null) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading
                          ErrorHandler.handleError(
                            context,
                            'Please login to backup data',
                            customMessage: 'Please login to backup data',
                          );
                          return;
                        }

                        // Backup expenses
                        final List<ExpenseModel> expenses = await DbService()
                            .getExpenses();
                        int expenseCount = 0;
                        for (final expense in expenses) {
                          try {
                            // Check if expense already exists in Supabase
                            final existing = await supabase
                                .from('expenses')
                                .select('id')
                                .eq('user_id', user.id)
                                .eq('amount', expense.amount)
                                .eq('category', expense.category)
                                .eq(
                                  'created_at',
                                  expense.date.toIso8601String(),
                                )
                                .maybeSingle();

                            if (existing == null) {
                              await supabase.from('expenses').insert({
                                'user_id': user.id,
                                'amount': expense.amount,
                                'category': expense.category,
                                'payment': expense.paymentMethod,
                                'note': expense.note,
                                'created_at': expense.date.toIso8601String(),
                                'updated_at': DateTime.now().toIso8601String(),
                              });
                              expenseCount++;
                            }
                          } catch (e) {
                            // Continue with other expenses if one fails
                            continue;
                          }
                        }

                        // Backup budgets
                        final DateTime now = DateTime.now();
                        final List<BudgetModel> budgets = await DbService()
                            .getBudgets(month: now.month, year: now.year);
                        int budgetCount = 0;
                        for (final budget in budgets) {
                          try {
                            final periodStart = DateTime(
                              budget.year,
                              budget.month,
                              1,
                            );
                            final periodEnd = DateTime(
                              budget.year,
                              budget.month + 1,
                              0,
                            );

                            // Check if budget already exists
                            final existing = await supabase
                                .from('budgets')
                                .select('id')
                                .eq('user_id', user.id)
                                .eq('category', budget.category)
                                .eq(
                                  'period_start',
                                  periodStart.toIso8601String().split('T')[0],
                                )
                                .maybeSingle();

                            if (existing == null) {
                              await supabase.from('budgets').insert({
                                'user_id': user.id,
                                'category': budget.category,
                                'limit_amount': budget.limit,
                                'period_start': periodStart
                                    .toIso8601String()
                                    .split('T')[0],
                                'period_end': periodEnd.toIso8601String().split(
                                  'T',
                                )[0],
                              });
                              budgetCount++;
                            }
                          } catch (e) {
                            // Continue with other budgets if one fails
                            continue;
                          }
                        }

                        // Backup finance data (if exists in HomeDashboard state, it's already in Supabase)
                        // This is handled automatically by the HomeDashboard widget

                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading

                        ErrorHandler.showSuccess(
                          context,
                          'Backup completed! Synced $expenseCount expenses and $budgetCount budgets to cloud.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading
                        ErrorHandler.handleError(
                          context,
                          e,
                          customMessage: 'Backup failed. Please try again.',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('Restore from Cloud'),
                    subtitle: const Text(
                      'Download backup from cloud (Supabase)',
                    ),
                    onTap: () async {
                      if (!context.mounted) return;

                      // Show confirmation dialog
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Restore from Cloud'),
                          content: const Text(
                            'This will restore all your data from Supabase. Existing local data may be overwritten. Continue?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Restore'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      if (!context.mounted) return;

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final supabase = Supabase.instance.client;
                        final user = supabase.auth.currentUser;

                        if (user == null) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading
                          ErrorHandler.handleError(
                            context,
                            'Please login to restore data',
                            customMessage: 'Please login to restore data',
                          );
                          return;
                        }

                        // Restore expenses
                        final expensesData = await supabase
                            .from('expenses')
                            .select()
                            .eq('user_id', user.id)
                            .order('created_at', ascending: false);

                        int expenseCount = 0;
                        for (final expenseData in expensesData) {
                          try {
                            // Convert Supabase format to ExpenseModel
                            final DateTime expenseDate = DateTime.parse(
                              expenseData['created_at'] as String,
                            );

                            final ExpenseModel expense = ExpenseModel(
                              id: 'exp_${expenseData['id']}',
                              amount: (expenseData['amount'] as num).toDouble(),
                              category: expenseData['category'] as String,
                              date: expenseDate,
                              note: expenseData['note'] as String?,
                              paymentMethod:
                                  expenseData['payment'] as String? ?? 'Cash',
                              isSynced: true,
                              type: TransactionType.expense,
                            );

                            await DbService().upsertExpense(expense);
                            expenseCount++;
                          } catch (e) {
                            // Continue with other expenses if one fails
                            continue;
                          }
                        }

                        // Restore budgets
                        final budgetsData = await supabase
                            .from('budgets')
                            .select()
                            .eq('user_id', user.id);

                        int budgetCount = 0;
                        for (final budgetData in budgetsData) {
                          try {
                            // Convert Supabase format to BudgetModel
                            final String periodStartStr =
                                budgetData['period_start'] as String;
                            final DateTime periodStart = DateTime.parse(
                              periodStartStr,
                            );
                            final int month = periodStart.month;
                            final int year = periodStart.year;

                            final BudgetModel budget = BudgetModel(
                              id: 'bud_${budgetData['id']}',
                              category: budgetData['category'] as String,
                              month: month,
                              year: year,
                              limit: (budgetData['limit_amount'] as num)
                                  .toDouble(),
                            );

                            await DbService().upsertBudget(budget);
                            budgetCount++;
                          } catch (e) {
                            // Continue with other budgets if one fails
                            continue;
                          }
                        }

                        // Restore finance data
                        final financeData = await supabase
                            .from('finance')
                            .select()
                            .eq('id', 1)
                            .maybeSingle();

                        if (financeData != null) {
                          // Finance data is already loaded by HomeDashboard widget
                          // But we can update it if needed
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading

                        ErrorHandler.showSuccess(
                          context,
                          'Restore completed! Restored $expenseCount expenses and $budgetCount budgets from cloud.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading
                        ErrorHandler.handleError(
                          context,
                          e,
                          customMessage: 'Restore failed. Please try again.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // About & Support
            _SectionHeader(title: 'About'),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('Learn more about ML Smart Expense'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.feedback),
                    title: const Text('Send Feedback'),
                    subtitle: const Text('Help us improve the app'),
                    onTap: _sendFeedback,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Support'),
                    subtitle: const Text('Get help and support'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Logout
            FilledButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
