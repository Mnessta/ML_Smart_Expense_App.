import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import 'db_service.dart';
import '../utils/logger.dart';
import 'local_notification_service.dart';

class AINotificationService {
  static final AINotificationService _instance = AINotificationService._internal();
  factory AINotificationService() => _instance;
  AINotificationService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if notifications should be sent today
  Future<bool> shouldSendNotifications() async {
    try {
      // Check notification preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      final bool budgetAlertsEnabled = prefs.getBool('budgetAlertsEnabled') ?? false;
      final bool insightsEnabled = prefs.getBool('insightsEnabled') ?? false;

      // At least one notification type must be enabled
      if (!notificationsEnabled && !budgetAlertsEnabled && !insightsEnabled) {
        return false;
      }

      // Check if already sent today
      final String? lastNotificationDate = prefs.getString('lastAINotificationDate');
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      if (lastNotificationDate != null) {
        final DateTime lastDate = DateTime.parse(lastNotificationDate);
        final DateTime lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        
        if (lastDay.isAtSameMomentAs(today)) {
          // Already sent today
          return false;
        }
      }

      // Check if online
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      final bool isOnline = results.any((result) => result != ConnectivityResult.none);
      
      if (!isOnline) {
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Error checking notification status: $e', e, stackTrace);
      return false;
    }
  }

  /// Generate AI-powered notifications based on user data
  Future<List<NotificationMessage>> generateNotifications() async {
    final List<NotificationMessage> messages = <NotificationMessage>[];
    
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      final bool budgetAlertsEnabled = prefs.getBool('budgetAlertsEnabled') ?? false;
      final bool insightsEnabled = prefs.getBool('insightsEnabled') ?? false;

      final DbService dbService = DbService();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime thisMonthStart = DateTime(now.year, now.month, 1);
      final DateTime lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final DateTime lastMonthEnd = DateTime(now.year, now.month, 0);

      // Get expenses
      final List<ExpenseModel> allExpenses = await dbService.getExpenses();
      final List<ExpenseModel> thisMonthExpenses = allExpenses.where((e) {
        return e.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
               e.date.isBefore(today.add(const Duration(days: 1))) &&
               e.type == TransactionType.expense;
      }).toList();

      final List<ExpenseModel> lastMonthExpenses = allExpenses.where((e) {
        return e.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
               e.date.isBefore(lastMonthEnd.add(const Duration(days: 1))) &&
               e.type == TransactionType.expense;
      }).toList();

      final List<ExpenseModel> todayExpenses = allExpenses.where((e) {
        return e.date.isAfter(today.subtract(const Duration(days: 1))) &&
               e.date.isBefore(today.add(const Duration(days: 1))) &&
               e.type == TransactionType.expense;
      }).toList();

      // Generate budget alerts
      if (budgetAlertsEnabled) {
        final List<BudgetModel> budgets = await dbService.getBudgets(
          month: now.month,
          year: now.year,
        );

        for (final BudgetModel budget in budgets) {
          final double spent = thisMonthExpenses
              .where((e) => e.category == budget.category)
              .fold(0.0, (sum, e) => sum + e.amount);

          final double percentage = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;

          if (percentage >= 90) {
            messages.add(NotificationMessage(
              type: NotificationType.budgetAlert,
              title: 'Budget Alert ⚠️',
              message: 'You\'ve used ${percentage.toStringAsFixed(0)}% of your ${budget.category} budget. Only ${(budget.limit - spent).toStringAsFixed(2)} remaining!',
              icon: 'warning',
            ));
          } else if (percentage >= 75) {
            messages.add(NotificationMessage(
              type: NotificationType.budgetAlert,
              title: 'Budget Reminder 💰',
              message: 'You\'ve spent ${percentage.toStringAsFixed(0)}% of your ${budget.category} budget. ${(budget.limit - spent).toStringAsFixed(2)} left this month.',
              icon: 'info',
            ));
          }
        }
      }

      // Generate smart insights
      if (insightsEnabled) {
        // Spending trend analysis
        final double thisMonthTotal = thisMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final double lastMonthTotal = lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

        if (lastMonthTotal > 0) {
          final double change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
          final int daysInMonth = now.day;
          final double projectedTotal = (thisMonthTotal / daysInMonth) * 30;

          if (change < -15) {
            messages.add(NotificationMessage(
              type: NotificationType.insight,
              title: 'Great Progress! 🎉',
              message: 'You\'re spending ${change.abs().toStringAsFixed(0)}% less than last month. Keep up the excellent work!',
              icon: 'celebration',
            ));
          } else if (change > 20) {
            messages.add(NotificationMessage(
              type: NotificationType.insight,
              title: 'Spending Alert 📊',
              message: 'Your spending is ${change.toStringAsFixed(0)}% higher than last month. Consider reviewing your expenses.',
              icon: 'trending_up',
            ));
          }

          if (projectedTotal > lastMonthTotal * 1.2) {
            messages.add(NotificationMessage(
              type: NotificationType.insight,
              title: 'Monthly Forecast 📈',
              message: 'At this rate, you\'ll spend ${projectedTotal.toStringAsFixed(0)} this month, which is ${((projectedTotal - lastMonthTotal) / lastMonthTotal * 100).toStringAsFixed(0)}% more than last month.',
              icon: 'insight',
            ));
          }
        }

        // Category analysis
        final Map<String, double> categoryTotals = <String, double>{};
        for (final ExpenseModel expense in thisMonthExpenses) {
          categoryTotals[expense.category] = 
              (categoryTotals[expense.category] ?? 0) + expense.amount;
        }

        if (categoryTotals.isNotEmpty) {
          final String topCategory = categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          final double topAmount = categoryTotals[topCategory]!;
          final double totalSpending = categoryTotals.values.fold(0.0, (a, b) => a + b);
          final double percentage = (topAmount / totalSpending) * 100;

          if (percentage > 40 && thisMonthExpenses.length > 5) {
            messages.add(NotificationMessage(
              type: NotificationType.insight,
              title: 'Spending Pattern 💡',
              message: '$topCategory accounts for ${percentage.toStringAsFixed(0)}% of your spending this month. Consider diversifying your expenses.',
              icon: 'lightbulb',
            ));
          }
        }

        // Daily spending analysis
        if (todayExpenses.isNotEmpty) {
          final double todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final double avgDaily = thisMonthExpenses.isNotEmpty
              ? thisMonthExpenses.fold(0.0, (sum, e) => sum + e.amount) / now.day
              : 0;

          if (todayTotal > avgDaily * 1.5 && avgDaily > 0) {
            messages.add(NotificationMessage(
              type: NotificationType.insight,
              title: 'Today\'s Spending 📅',
              message: 'You\'ve spent ${todayTotal.toStringAsFixed(2)} today, which is ${((todayTotal / avgDaily - 1) * 100).toStringAsFixed(0)}% above your daily average.',
              icon: 'today',
            ));
          }
        }
      }

      // Generate general notifications
      if (notificationsEnabled) {
        if (thisMonthExpenses.isEmpty) {
          messages.add(NotificationMessage(
            type: NotificationType.notification,
            title: 'Welcome Back! 👋',
            message: 'Start tracking your expenses to get personalized insights and better control over your finances.',
            icon: 'welcome',
          ));
        } else if (todayExpenses.isEmpty) {
          messages.add(NotificationMessage(
            type: NotificationType.notification,
            title: 'Good Morning! ☀️',
            message: 'You haven\'t logged any expenses today. Remember to track your spending to stay on top of your budget.',
            icon: 'reminder',
          ));
        }
      }

      // Provide a gentle nudge when nothing else was generated
      if (messages.isEmpty && (notificationsEnabled || budgetAlertsEnabled || insightsEnabled)) {
        messages.add(
          NotificationMessage(
            type: NotificationType.insight,
            title: 'We\'re watching 👀',
            message: 'No alerts just yet. Keep logging expenses so we can surface smarter insights.',
            icon: 'insight',
          ),
        );
      }

      if (messages.isNotEmpty) {
        await LocalNotificationService().showNotifications(messages);
        // Mark as sent today only when we actually have something to show
        await prefs.setString('lastAINotificationDate', now.toIso8601String());
      }

      return messages;
    } catch (e, stackTrace) {
      AppLogger.e('Error generating notifications: $e', e, stackTrace);
      return messages;
    }
  }
}

enum NotificationType {
  notification,
  budgetAlert,
  insight,
}

class NotificationMessage {
  NotificationMessage({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
  });

  final NotificationType type;
  final String title;
  final String message;
  final String icon;

  IconData get iconData {
    switch (icon) {
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'celebration':
        return Icons.celebration;
      case 'trending_up':
        return Icons.trending_up;
      case 'insight':
        return Icons.insights;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'today':
        return Icons.today;
      case 'welcome':
        return Icons.waving_hand;
      case 'reminder':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budgetAlert:
        return Colors.orange;
      case NotificationType.insight:
        return Colors.blue;
      case NotificationType.notification:
        return Colors.green;
    }
  }
}

