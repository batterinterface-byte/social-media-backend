import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Data Collection',
              '''We value your privacy. This app collects minimal data necessary for functionality:

• Notes and tasks: Stored locally on your device
• Documents: File references only, no content scanning
• Preferences: Stored locally using secure storage
• No personal data is transmitted to external servers''',
            ),
            _buildSection(
              context,
              'Permissions Usage',
              '''We only use permissions when necessary:

• Storage: To save and access your files
• Camera: To capture photos for notes
• Microphone: For voice note recording
• Location: For location-based reminders
• Notifications: To send task reminders''',
            ),
            _buildSection(
              context,
              'Data Security',
              '''Your data is protected through:

• Local storage with SQLite encryption option
• PIN lock for app access
• Encrypted note content option
• Secure delete for permanent removal
• No cloud sync without user action''',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              '''We don't share your data with third parties. The app may use:

• Local file system access
• Device storage
• No advertising or analytics services''',
            ),
            _buildSection(
              context,
              'Your Rights',
              '''You have full control over your data:

• Export all data anytime
• Delete individual or all data
• Disable any permission
• Lock app with PIN
• Use privacy mode to hide content''',
            ),
            _buildSection(
              context,
              'Changes to Policy',
              '''We may update this policy periodically. 
Users will be notified of significant changes.
This policy was last updated: May 2024.''',
            ),
            _buildSection(
              context,
              'Contact Us',
              '''For privacy concerns or questions:

Email: theashis.world@gmail.com
Website: www.notebookpro.app

We respond within 24-48 hours.''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}