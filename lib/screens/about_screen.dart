import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildHeader(context),
          const Divider(),
          _buildSection(
            context,
            'Version Info',
            [
              _buildInfoTile('App Version', '1.0.0'),
              _buildInfoTile('Build Number', '2024.05.19'),
              _buildInfoTile('Flutter SDK', '3.9.0'),
              _buildInfoTile('Release Date', 'May 19, 2024'),
            ],
          ),
          _buildSection(
            context,
            'Developer',
            [
              _buildActionTile(
                context,
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'theashis.world@gmail.com',
                onTap: () => _launchEmail(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.language,
                title: 'Website',
                subtitle: 'www.notebookpro.app',
                onTap: () => _launchUrl('https://www.notebookpro.app'),
              ),
              _buildActionTile(
                context,
                icon: Icons.bug_report,
                title: 'Report Bug',
                subtitle: 'Submit issues via email',
                onTap: () => _launchEmail(context, subject: 'Bug Report'),
              ),
              _buildActionTile(
                context,
                icon: Icons.lightbulb,
                title: 'Request Feature',
                subtitle: 'Suggest new features',
                onTap: () => _launchEmail(context, subject: 'Feature Request'),
              ),
            ],
          ),
          _buildSection(
            context,
            'Legal',
            [
              _buildActionTile(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.description,
                title: 'Terms of Service',
                subtitle: 'View terms and conditions',
                onTap: () => _showTermsDialog(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.article,
                title: 'Open Source Licenses',
                subtitle: 'View third-party licenses',
                onTap: () => showLicensePage(context: context),
              ),
            ],
          ),
          _buildSection(
            context,
            'Features',
            [
              _buildFeatureTile('Notes Management', '✓'),
              _buildFeatureTile('Task/Todo Lists', '✓'),
              _buildFeatureTile('Document Vault', '✓'),
              _buildFeatureTile('Storage Scanner', '✓'),
              _buildFeatureTile('PIN Security', '✓'),
              _buildFeatureTile('Encrypted Notes', '✓'),
              _buildFeatureTile('Export/Import', '✓'),
              _buildFeatureTile('Categories', '✓'),
              _buildFeatureTile('Search', '✓'),
              _buildFeatureTile('Dark Mode', '✓'),
              _buildFeatureTile('Reminder Notifications', '✓'),
              _buildFeatureTile('Cloud Backup Ready', '✓'),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2024 Notebook Pro\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.note_alt,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notebook Pro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your all-in-one productivity app\nNotes • Tasks • Documents • Vault',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFeatureTile(String title, String status) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(status, style: const TextStyle(color: Colors.green)),
    );
  }

  Future<void> _launchEmail(BuildContext context, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'theashis.world@gmail.com',
      query: subject != null ? 'subject=$subject' : null,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open email')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text('''By using Notebook Pro, you agree to:

1. Use the app for lawful purposes only
2. Not attempt to reverse engineer the app
3. Not distribute modified versions
4. Your data remains your property
5. We are not liable for data loss
6. Use at your own risk

For support, contact:
theashis.world@gmail.com'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}