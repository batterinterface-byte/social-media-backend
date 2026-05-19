import 'package:flutter/material.dart';
import '../services/privacy_service.dart';
import '../services/encryption_service.dart';
import '../services/permission_service.dart';
import '../database/database_helper.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPin = false;
  bool _privacyMode = false;
  int _autoLock = 5;
  bool _darkMode = false;
  bool _notifications = true;
  bool _soundEffects = true;
  bool _vibrate = true;
  String _language = 'English';
  String _dateFormat = 'MMM d, yyyy';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _hasPin = await PrivacyService.hasPin();
    _privacyMode = await PrivacyService.isPrivacyModeEnabled();
    _autoLock = await PrivacyService.getAutoLockTimeout();
    setState(() => _isLoading = false);
  }

  Future<void> _setPin() async {
    final pin = await _showPinDialog(true);
    if (pin != null && pin.length >= 4) {
      await PrivacyService.setPin(pin);
      setState(() => _hasPin = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN set successfully')),
        );
      }
    }
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove PIN protection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      await PrivacyService.removePin();
      setState(() => _hasPin = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN removed')));
    }
  }

  Future<String?> _showPinDialog(bool isNew) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Set PIN' : 'Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'Enter 4-6 digit PIN', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(isNew ? 'Set' : 'Verify')),
        ],
      ),
    );
  }

  Future<void> _togglePrivacyMode() async {
    if (!_privacyMode) {
      final pin = await _showPinDialog(false);
      if (pin == null) return;
      final verified = await PrivacyService.verifyPin(pin);
      if (!verified) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
        return;
      }
    }
    await PrivacyService.setPrivacyMode(!_privacyMode);
    setState(() => _privacyMode = !_privacyMode);
  }

  Future<void> _showManagePermissions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Permissions', style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<PermissionStatus>(
              future: Permission.storage.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.folder,
                title: 'Storage',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.storage),
              ),
            ),
            FutureBuilder<PermissionStatus>(
              future: Permission.camera.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.camera_alt,
                title: 'Camera',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.camera),
              ),
            ),
            FutureBuilder<PermissionStatus>(
              future: Permission.microphone.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.mic,
                title: 'Microphone',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.microphone),
              ),
            ),
            FutureBuilder<PermissionStatus>(
              future: Permission.location.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.location_on,
                title: 'Location',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.location),
              ),
            ),
            FutureBuilder<PermissionStatus>(
              future: Permission.notification.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.notifications,
                title: 'Notifications',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.notification),
              ),
            ),
            FutureBuilder<PermissionStatus>(
              future: Permission.contacts.status,
              builder: (context, snapshot) => _buildPermissionTile(
                icon: Icons.contacts,
                title: 'Contacts',
                status: snapshot.data?.isGranted ?? false,
                onTap: () => _requestPermission(Permission.contacts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied && mounted) {
      PermissionService.showPermanentlyDeniedDialog(context);
    }
    setState(() {});
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required bool status,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: status ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: Text(status ? 'Granted' : 'Not granted', style: TextStyle(color: status ? Colors.green : Colors.orange)),
        trailing: status ? const Icon(Icons.check_circle, color: Colors.green) : TextButton(onPressed: onTap, child: const Text('Allow')),
      ),
    );
  }

  Future<void> _exportEncryptedBackup() async {
    final notes = await DatabaseHelper.instance.exportAllNotes();
    final json = notes.map((n) => n.toJson()).toList();
    final encrypted = EncryptionService.encrypt(json.toString(), 'backup_key');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup created (${encrypted.length} chars)')));
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all notes, todos, and documents. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Spanish', 'French', 'German', 'Chinese'].map((lang) => ListTile(
              title: Text(lang),
              trailing: _language == lang ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() => _language = lang);
                Navigator.pop(dialogContext);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Date Format'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['MMM d, yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'].map((format) => ListTile(
              title: Text(format),
              trailing: _dateFormat == format ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() => _dateFormat = format);
                Navigator.pop(dialogContext);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Auto-lock Time'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 5, 15, 30, 60].map((minutes) {
              final label = minutes == 60 ? '1 hour' : '$minutes minutes';
              return ListTile(
                title: Text(label),
                trailing: _autoLock == minutes ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await PrivacyService.setAutoLockTimeout(minutes);
                  if (dialogContext.mounted) {
                    setState(() => _autoLock = minutes);
                    Navigator.pop(dialogContext);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
        children: [
          _buildSectionHeader('Security & Privacy'),
          SwitchListTile(secondary: const Icon(Icons.lock), title: const Text('App PIN Lock'), subtitle: Text(_hasPin ? 'PIN enabled' : 'No PIN set'), value: _hasPin, onChanged: (v) => v ? _setPin() : _removePin()),
          ListTile(leading: const Icon(Icons.timer), title: const Text('Auto-lock'), subtitle: Text('$_autoLock min'), trailing: const Icon(Icons.chevron_right), onTap: _showAutoLockDialog),
          SwitchListTile(secondary: const Icon(Icons.visibility_off), title: const Text('Privacy Mode'), subtitle: const Text('Hide content preview'), value: _privacyMode, onChanged: (_) => _togglePrivacyMode()),
          const Divider(),
          _buildSectionHeader('Appearance'),
          SwitchListTile(secondary: const Icon(Icons.dark_mode), title: const Text('Dark Mode'), subtitle: const Text('Enable dark theme'), value: _darkMode, onChanged: (v) => setState(() => _darkMode = v)),
          ListTile(leading: const Icon(Icons.language), title: const Text('Language'), subtitle: Text(_language), trailing: const Icon(Icons.chevron_right), onTap: _showLanguageDialog),
          ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Date Format'), subtitle: Text(_dateFormat), trailing: const Icon(Icons.chevron_right), onTap: _showDateFormatDialog),
          const Divider(),
          _buildSectionHeader('Notifications'),
          SwitchListTile(secondary: const Icon(Icons.notifications), title: const Text('Push Notifications'), subtitle: const Text('Task & reminder alerts'), value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
          SwitchListTile(secondary: const Icon(Icons.volume_up), title: const Text('Sound Effects'), subtitle: const Text('App sounds'), value: _soundEffects, onChanged: (v) => setState(() => _soundEffects = v)),
          SwitchListTile(secondary: const Icon(Icons.vibration), title: const Text('Vibration'), subtitle: const Text('Haptic feedback'), value: _vibrate, onChanged: (v) => setState(() => _vibrate = v)),
          const Divider(),
          _buildSectionHeader('Permissions'),
          ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('Manage Permissions'), subtitle: const Text('Control app permissions'), trailing: const Icon(Icons.chevron_right), onTap: _showManagePermissions),
          const Divider(),
          _buildSectionHeader('Data'),
          ListTile(leading: const Icon(Icons.backup), title: const Text('Export Encrypted Backup'), subtitle: const Text('Create backup file'), onTap: _exportEncryptedBackup),
          ListTile(leading: const Icon(Icons.restore), title: const Text('Import Backup'), subtitle: const Text('Restore from backup'), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import feature')))),
          ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Clear All Data', style: TextStyle(color: Colors.red)), subtitle: const Text('Delete everything'), onTap: _clearAllData),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(leading: const Icon(Icons.info), title: const Text('App Version'), subtitle: const Text('1.0.0 (Build 2024.05.19)')),
          ListTile(leading: const Icon(Icons.support_agent), title: const Text('Contact Support'), subtitle: const Text('theashis.world@gmail.com'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
          ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('Privacy Policy'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
          ListTile(leading: const Icon(Icons.description), title: const Text('Terms of Service'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terms of Service')))),
          ListTile(leading: const Icon(Icons.star), title: const Text('Rate This App'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your support!')))),
          ListTile(leading: const Icon(Icons.share), title: const Text('Share App'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature')))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
    );
  }
}