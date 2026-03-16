import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/auth/auth_provider.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.email_outlined, size: 20),
                  title: const Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  subtitle: Text(
                    authState.email ?? 'Not logged in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade900,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  onTap: () => _handleLogout(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Data & Sync'),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.sync, size: 20),
                  title: const Text('Manual Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Push local changes to server', style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.pink.shade200),
                  onTap: () => _handleSync(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  secondary: const Icon(Icons.notifications_active_outlined, size: 20),
                  title: const Text('Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Get notified for medication times', style: TextStyle(fontSize: 12)),
                  value: true, // TODO: Implement persistent settings
                  onChanged: (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved'), duration: Duration(seconds: 1)),
                    );
                  },
                  activeColor: Colors.pink.shade600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Spacing for bottom nav
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    ConfirmationDialog.show(
      context: context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      confirmColor: Colors.redAccent,
      onConfirm: () {
        ref.read(authProvider.notifier).logout();
      },
    );
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data...', style: TextStyle(fontSize: 13))),
    );
    try {
      await ref.read(syncServiceProvider).sync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete!', style: TextStyle(fontSize: 13))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e', style: TextStyle(fontSize: 13))),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.pink.shade300,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
