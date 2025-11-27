import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
              'Privacy Policy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to My Life Smart Expense ("we," "our," or "us"). We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              '2. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
              '• Account Information: Email address, name, and authentication credentials\n'
              '• Financial Data: Expense records, income information, budgets, and financial transactions\n'
              '• Device Information: Device type, operating system, and app usage data\n'
              '• Biometric Data: When you enable biometric authentication, we use your device\'s biometric features (fingerprint or face recognition) for authentication purposes only. We do not store biometric data.',
            ),
            _buildSection(
              '3. How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide and maintain our expense tracking services\n'
              '• Process and manage your financial transactions\n'
              '• Send you notifications and alerts related to your expenses and budgets\n'
              '• Improve our app\'s functionality and user experience\n'
              '• Ensure app security and prevent fraud\n'
              '• Comply with legal obligations',
            ),
            _buildSection(
              '4. Data Storage and Security',
              'We take the security of your data seriously:\n\n'
              '• Your data is stored securely using industry-standard encryption\n'
              '• We use secure authentication methods, including biometric authentication when enabled\n'
              '• Financial data is stored locally on your device and synced to secure cloud servers\n'
              '• We implement appropriate technical and organizational measures to protect your personal information',
            ),
            _buildSection(
              '5. Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
              '• With your explicit consent\n'
              '• To comply with legal obligations or respond to lawful requests\n'
              '• To protect our rights, privacy, safety, or property\n'
              '• In connection with a business transfer or merger',
            ),
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Correct inaccurate or incomplete data\n'
              '• Delete your account and associated data\n'
              '• Opt-out of certain data collection practices\n'
              '• Request a copy of your data\n\n'
              'To exercise these rights, please contact us through the app\'s feedback feature or support channels.',
            ),
            _buildSection(
              '7. Third-Party Services',
              'Our app may integrate with third-party services (such as authentication providers and cloud storage services) to provide functionality. These services have their own privacy policies, and we encourage you to review them.',
            ),
            _buildSection(
              '8. Children\'s Privacy',
              'Our app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
            ),
            _buildSection(
              '9. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              '10. Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, please contact us through:\n\n'
              '• The app\'s feedback feature\n'
              '• Support channels within the app\n'
              '• Email: support@mylifesmartexpense.com',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Times New Roman',
            ),
          ),
        ],
      ),
    );
  }
}



