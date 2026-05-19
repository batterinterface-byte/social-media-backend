import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestContacts() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  static Future<bool> requestCalendar() async {
    final status = await Permission.calendarFullAccess.request();
    return status.isGranted;
  }

  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return await [
      Permission.storage,
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.notification,
      Permission.contacts,
      Permission.calendarFullAccess,
    ].request();
  }

  static Future<bool> isStorageGranted() async {
    return await Permission.storage.isGranted;
  }

  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  static Future<bool> isLocationGranted() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static Future<bool> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [Icon(icon, color: Colors.teal), const SizedBox(width: 8), Text(title)],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<void> showPermanentlyDeniedDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This permission is required for this feature. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class PermissionStatusWidget extends StatelessWidget {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const PermissionStatusWidget({
    super.key,
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: permission.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? PermissionStatus.denied;
        final isGranted = status.isGranted;

        return ListTile(
          leading: Icon(
            icon,
            color: isGranted ? Colors.green : Colors.grey,
          ),
          title: Text(title),
          subtitle: Text(
            isGranted ? 'Granted' : 'Not granted',
            style: TextStyle(
              color: isGranted ? Colors.green : Colors.orange,
            ),
          ),
          trailing: isGranted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : TextButton(
                  onPressed: onTap,
                  child: const Text('Enable'),
                ),
        );
      },
    );
  }
}