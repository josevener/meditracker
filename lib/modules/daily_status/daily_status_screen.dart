import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';
import 'package:intl/intl.dart';

class DailyStatusScreen extends ConsumerWidget {
  const DailyStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationState = ref.watch(medicationListProvider);
    final todayLogsState = ref.watch(todayLogsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Column(
          children: [
            const Text("Today's Schedule"),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: medicationState.when(
        data: (meds) {
          return todayLogsState.when(
            data: (logs) {
              if (meds.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 60, color: Colors.pink.shade200),
                      const SizedBox(height: 12),
                      Text(
                        "No medications scheduled today.",
                        style: TextStyle(color: Colors.pink.shade800, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Flatten medications into individual doses/schedules for the day
              List<Map<String, dynamic>> todayItems = [];
              for (var med in meds) {
                // Count how many times this med was taken today
                final intakeCount = logs.where((l) => l.log.medicationId == med.id).length;
                final limitReached = intakeCount >= med.frequencyPerDay;

                for (var schedule in med.schedules) {
                  // Check if THIS specific schedule was already taken
                  final isAlreadyTaken = logs.any((l) => l.log.medicationId == med.id && l.log.scheduledTime == schedule.timeOfDay);

                  todayItems.add({
                    'medId': med.id,
                    'name': med.name,
                    'dosage': med.dosage,
                    'time': schedule.timeOfDay,
                    'isTaken': isAlreadyTaken,
                    'limitReached': limitReached,
                    'maxDoses': med.frequencyPerDay,
                    'currentDoses': intakeCount,
                  });
                }
              }

              // Sort by time
              todayItems.sort((a, b) => a['time'].compareTo(b['time']));

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(todayLogsProvider);
                  await ref.read(medicationListProvider.notifier).refresh();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: todayItems.length,
                  itemBuilder: (context, index) {
                    final item = todayItems[index];
                    final bool canTake = !item['isTaken'] && !item['limitReached'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: canTake ? () => _confirmIntake(context, ref, item, todayStr) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item['isTaken'] ? Colors.green.shade50 : (item['limitReached'] ? Colors.orange.shade50 : Colors.pink.shade50),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item['isTaken'] ? Icons.check_circle : (item['limitReached'] ? Icons.warning_amber : Icons.schedule),
                                    color: item['isTaken'] ? Colors.green.shade700 : (item['limitReached'] ? Colors.orange.shade700 : Colors.pink.shade700),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: item['isTaken'] ? Colors.grey : Colors.pink.shade900,
                                          decoration: item['isTaken'] ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${item['dosage'] ?? 'No dosage'} • ${item['time']}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      if (item['limitReached'] && !item['isTaken'])
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            "DAILY LIMIT REACHED",
                                            style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (item['isTaken'])
                                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 22)
                                else if (item['limitReached'])
                                  Icon(Icons.block, color: Colors.orange.shade300, size: 22)
                                else
                                  Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _confirmIntake(BuildContext context, WidgetRef ref, Map<String, dynamic> item, String todayStr) {
    ConfirmationDialog.show(
      context: context,
      title: 'Confirm Intake',
      content: 'Are you sure you want to mark ${item['name']} as taken at ${item['time']}?',
      confirmText: 'Mark Taken',
      onConfirm: () async {
        try {
          await ref.read(medicationRepositoryProvider).logIntake(
            item['medId'],
            item['time'],
            todayStr,
            'taken',
          );
          // Refresh logs
          ref.invalidate(todayLogsProvider);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item['name']} marked as taken!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.teal.shade700,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
            );
          }
        }
      },
    );
  }
}
