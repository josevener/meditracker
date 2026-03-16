import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/notifications/in_app_notification_provider.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:intl/intl.dart';

class NotificationBanner extends ConsumerWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(inAppNotificationProvider);
    if (notification == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.pink.shade50, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      color: Colors.pink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        ref.read(medicationListProvider.notifier).repository.logIntake(
                          notification.medId,
                          notification.time,
                          today,
                          'taken',
                        );
                        ref.read(inAppNotificationProvider.notifier).dismiss();
                        ref.refresh(todayLogsProvider);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 24),
                          Text('TAKE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref.read(inAppNotificationProvider.notifier).dismiss(),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
