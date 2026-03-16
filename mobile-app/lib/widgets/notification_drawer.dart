import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:intl/intl.dart';

class NotificationDrawer extends ConsumerWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayLogsProvider);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            color: Colors.pink.shade600,
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today\'s medication logs',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No activity yet today', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isTaken = log.log.status == 'taken';
                    return ListTile(
                      leading: Icon(
                        isTaken ? Icons.check_circle : Icons.pending,
                        color: isTaken ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        log.medName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Time: ${log.log.scheduledTime} • ${isTaken ? "Taken" : "Pending"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isTaken && log.log.takenAt != null
                          ? Text(
                              DateFormat('HH:mm').format(DateTime.parse(log.log.takenAt!)),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
