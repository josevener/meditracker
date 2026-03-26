import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/auth/auth_provider.dart';
import 'package:medtrack_mobile/modules/settings/settings_screen.dart';
import 'package:medtrack_mobile/core/navigation/navigation_provider.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final email = authState.email ?? 'User';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    void navigateTo(int index) {
      ref.read(navigationProvider.notifier).setIndex(index);
      Navigator.pop(context);
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.pink.shade600,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade600,
                ),
              ),
            ),
            accountName: const Text(
              'Welcome back!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.today, color: Colors.pink),
            title: const Text('Daily Status'),
            onTap: () => navigateTo(0),
          ),
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.pink),
            title: const Text('My Medications'),
            onTap: () => navigateTo(1),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.pink),
            title: const Text('Calendar'),
            onTap: () => navigateTo(2),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.pink),
            title: const Text('Settings'),
            onTap: () => navigateTo(3),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
