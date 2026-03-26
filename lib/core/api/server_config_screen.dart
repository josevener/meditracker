import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/api/server_config_provider.dart';
import 'package:medtrack_mobile/core/api/admin_pin_provider.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _pinController;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(serverConfigProvider);
    _ipController = TextEditingController(text: config.ip);
    _portController = TextEditingController(text: config.port.toString());
    _pinController = TextEditingController(text: '******'); // Default masked
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final ip = _ipController.text.trim();
      final port = int.parse(_portController.text.trim());

      // 1. Update local state
      await ref.read(serverConfigProvider.notifier).updateConfig(ip, port);
      
      // 2. Update backend config
      final configSuccess = await ref.read(systemServiceProvider).updateServerConfig(ip, port);
      if (!configSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync server config to backend'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 3. Update Admin PIN if modified
      if (_pinController.text != '******' && _pinController.text.isNotEmpty) {
        final success = await ref.read(systemServiceProvider).updateAdminPin(_pinController.text.trim());
        if (!success && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update Admin PIN'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
           return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved and synced'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backend Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure the IP address and port where your MedTrack backend is running.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Server IP',
                  hintText: 'e.g., 10.0.2.51',
                  prefixIcon: const Icon(Icons.router_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an IP address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: 'e.g., 5500',
                  prefixIcon: const Icon(Icons.settings_ethernet_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Change the Admin PIN required to access this screen.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                obscureText: _obscurePin,
                decoration: InputDecoration(
                  labelText: 'New Admin PIN',
                  hintText: 'Enter 6-digit PIN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                onTap: () {
                  if (_pinController.text == '******') {
                    _pinController.clear();
                  }
                },
                validator: (value) {
                  if (value == null || (value.isEmpty && value != '******')) {
                    return null; // Optional if not changed
                  }
                  if (value != '******' && value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('SAVE CONFIGURATION'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset to Defaults?'),
                        content: const Text('This will reset IP, Port, and local Admin PIN to factory settings.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true), 
                            child: const Text('RESET')
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(serverConfigProvider.notifier).resetToDefaults();
                      // Also attempt to reset backend PIN
                      await ref.read(systemServiceProvider).updateAdminPin('102424');
                      
                      if (mounted) {
                        final config = ref.read(serverConfigProvider);
                        _ipController.text = config.ip;
                        _portController.text = config.port.toString();
                        _pinController.text = '******';
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings reset to defaults')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  label: const Text('RESET TO DEFAULTS', style: TextStyle(color: Colors.orange)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
