import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _sendSupportEmail(BuildContext context, String subject) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('userEmail');

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@mylifesmartexpense.com',
        queryParameters: {
          'subject': subject,
          'body': (email != null && email.isNotEmpty) ? 'From: $email\n\n' : '',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening email client...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client. Please send email to support@mylifesmartexpense.com'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support',
          style: TextStyle(fontFamily: 'Times New Roman'),
        ),
        backgroundColor: const Color(0xFF0A6BFF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a topic below or contact us directly.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 24),
            _buildSupportCard(
              context,
              icon: Icons.bug_report,
              title: 'Report a Bug',
              description: 'Found something that\'s not working? Let us know!',
              subject: 'Bug Report - ML Smart Expense',
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.help_outline,
              title: 'General Question',
              description: 'Have a question about how to use the app?',
              subject: 'Question - ML Smart Expense',
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.account_circle,
              title: 'Account Issues',
              description: 'Problems with login, signup, or account settings?',
              subject: 'Account Issue - ML Smart Expense',
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.sync_problem,
              title: 'Sync Issues',
              description: 'Having trouble syncing your data?',
              subject: 'Sync Issue - ML Smart Expense',
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.security,
              title: 'Security & Privacy',
              description: 'Questions about security features or privacy?',
              subject: 'Security/Privacy Question - ML Smart Expense',
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF0A6BFF)),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Us Directly',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: support@mylifesmartexpense.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We typically respond within 24-48 hours.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFAQItem(
                      'How do I reset my password?',
                      'Go to the login screen and tap "Forgot Password". Enter your email address and check your inbox for the reset link.',
                    ),
                    const Divider(),
                    _buildFAQItem(
                      'How do I enable biometric lock?',
                      'Go to Settings > Security & Privacy > Biometric Lock and toggle it on. You\'ll be prompted to authenticate with your fingerprint or face.',
                    ),
                    const Divider(),
                    _buildFAQItem(
                      'How do I sync my data?',
                      'Your data is automatically synced when you\'re logged in. Make sure you have an internet connection and are signed in with your account.',
                    ),
                    const Divider(),
                    _buildFAQItem(
                      'Can I use the app offline?',
                      'Yes! You can add expenses and view your data offline. Changes will sync automatically when you\'re back online.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String subject,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _sendSupportEmail(context, subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A6BFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0A6BFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Times New Roman',
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'Times New Roman',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

