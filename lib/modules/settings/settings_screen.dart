import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/modules/settings/biometric_provider.dart';
import 'package:medtrack_mobile/modules/settings/pin_provider.dart';
import 'package:medtrack_mobile/modules/settings/pin_lock_screen.dart';
import 'package:medtrack_mobile/modules/settings/reminders_provider.dart';
import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersEnabled = ref.watch(remindersEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  secondary: const Icon(Icons.notifications_active_outlined, size: 20),
                  title: const Text('Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Get notified for medication times', style: TextStyle(fontSize: 12)),
                  value: remindersEnabled,
                  onChanged: (val) {
                    ref.read(remindersEnabledProvider.notifier).toggle(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved'), duration: Duration(seconds: 1)),
                    );
                  },
                  activeColor: Colors.pink.shade600,
                ),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, child) {
                    final biometricEnabled = ref.watch(biometricEnabledProvider);
                    return SwitchListTile(
                      dense: true,
                      secondary: const Icon(Icons.fingerprint, size: 20),
                      title: const Text('Biometric Auth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Use Fingerprint/FaceID to unlock', style: TextStyle(fontSize: 12)),
                      value: biometricEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final available = await ref.read(biometricServiceProvider).isBiometricAvailable();
                          if (!available) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Biometrics not available on this device')),
                              );
                            }
                            return;
                          }
                          // Verify biometrics once before enabling
                          final authenticated = await ref.read(biometricServiceProvider).authenticate();
                          if (authenticated) {
                            await ref.read(biometricEnabledProvider.notifier).toggle(true);
                          }
                        } else {
                          await ref.read(biometricEnabledProvider.notifier).toggle(false);
                        }
                      },
                      activeColor: Colors.pink.shade600,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Security'),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.password, size: 20),
                  title: const Text('Mandatory PIN Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('A 6-digit PIN is required for app security', style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.lock, size: 14, color: Colors.pink.shade100),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: const Text('Change PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.pink.shade200),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PinLockScreen(isSetupMode: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Spacing for bottom nav
        ],
      ),
    );
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
