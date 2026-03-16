import 'package:flutter_riverpod/flutter_riverpod.dart';

class InAppNotification {
  final int medId;
  final String title;
  final String body;
  final String time;

  InAppNotification({
    required this.medId,
    required this.title,
    required this.body,
    required this.time,
  });
}

class InAppNotificationNotifier extends StateNotifier<InAppNotification?> {
  InAppNotificationNotifier() : super(null);

  void show(InAppNotification notification) {
    state = notification;
    // Auto dismiss after 7 seconds
    Future.delayed(const Duration(seconds: 7), () {
      if (state == notification) {
        state = null;
      }
    });
  }

  void dismiss() {
    state = null;
  }
}

final inAppNotificationProvider = StateNotifierProvider<InAppNotificationNotifier, InAppNotification?>((ref) {
  return InAppNotificationNotifier();
});
