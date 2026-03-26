import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/modules/medications/medication_list_screen.dart';
import 'package:medtrack_mobile/modules/daily_status/daily_status_screen.dart';
import 'package:medtrack_mobile/services/notification_service.dart';
import 'package:medtrack_mobile/modules/calendar/calendar_screen.dart';
import 'package:medtrack_mobile/modules/settings/settings_screen.dart';
import 'package:medtrack_mobile/modules/settings/biometric_provider.dart';
import 'package:medtrack_mobile/modules/settings/pin_provider.dart';
import 'package:medtrack_mobile/modules/settings/pin_lock_screen.dart';
import 'package:medtrack_mobile/widgets/notification_banner.dart';
import 'package:medtrack_mobile/widgets/notification_banner.dart';
import 'package:medtrack_mobile/widgets/notification_drawer.dart';
import 'package:medtrack_mobile/modules/onboarding/onboarding_screen.dart';
import 'package:medtrack_mobile/modules/onboarding/onboarding_provider.dart';
import 'package:medtrack_mobile/core/navigation/navigation_provider.dart';
import 'package:medtrack_mobile/core/notifications/in_app_notification_provider.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: MedTrackApp(),
    ),
  );
}

class MedTrackApp extends ConsumerStatefulWidget {
  const MedTrackApp({super.key});

  @override
  ConsumerState<MedTrackApp> createState() => _MedTrackAppState();
}

class _MedTrackAppState extends ConsumerState<MedTrackApp> {
  Timer? _dueCheckTimer;
  final Set<String> _notifiedTimes = {};

  @override
  void initState() {
    super.initState();
    _setupNotificationCallbacks();
    _startDueCheckTimer();
  }

  @override
  void dispose() {
    _dueCheckTimer?.cancel();
    super.dispose();
  }

  void _startDueCheckTimer() {
    _dueCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDueMedications();
    });
    // Check immediately on start
    _checkDueMedications();
  }

  void _checkDueMedications() {
    final medsValue = ref.read(medicationListProvider);
    medsValue.whenData((meds) {
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);
      final today = DateFormat('yyyy-MM-dd').format(now);

      for (final med in meds) {
        for (final schedule in med.schedules) {
          final notifyKey = '${med.id}_${today}_${schedule.timeOfDay}';
          if (schedule.timeOfDay == currentTime && !_notifiedTimes.contains(notifyKey)) {
            _notifiedTimes.add(notifyKey);
            ref.read(inAppNotificationProvider.notifier).show(
              InAppNotification(
                medId: med.id!,
                title: 'Medication Ready',
                body: 'It\'s time for your ${med.name} (${med.dosage ?? ""})',
                time: schedule.timeOfDay,
              ),
            );
          }
        }
      }
    });
  }

  void _setupNotificationCallbacks() {
    NotificationService.setActionCallback((medId, time, status) async {
      final repo = ref.read(medicationRepositoryProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await repo.logIntake(medId, time, today, status);
      ref.refresh(todayLogsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingCompleted = ref.watch(onboardingStatusProvider);
    final pinState = ref.watch(pinProvider);

    Widget homeWidget;
    if (onboardingCompleted == null || pinState is AsyncLoading) {
      homeWidget = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (!onboardingCompleted) {
      homeWidget = const OnboardingScreen();
    } else if (pinState.value == null) {
      // PIN is mandatory but not set
      homeWidget = const PinLockScreen(isSetupMode: true);
    } else {
      homeWidget = const HomeScreen();
    }

    return MaterialApp(
      title: 'MedTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink.shade600,
          secondary: Colors.pink.shade300,
          surface: const Color(0xFFFFF0F5), // LavenderBlush
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.pink.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 52,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 14),
          bodyMedium: TextStyle(fontSize: 13),
          labelLarge: TextStyle(fontSize: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.pink.shade600, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.pink.shade600, fontSize: 13),
        ),
      ),
      home: Stack(
        children: [
          homeWidget,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NotificationBanner(),
          ),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isAuthenticated = false;

  static const List<Widget> _screens = [
    DailyStatusScreen(),
    MedicationListScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    // 2. Security Flow - Use SettingsRepository
    final repository = ref.read(settingsRepositoryProvider);
    final biometricEnabled = await repository.isBiometricEnabled();
    final pin = await repository.getUserPin();
    final isPinEnabled = pin != null;

    if (biometricEnabled || isPinEnabled) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PinLockScreen(
              onAuthenticated: () {
                setState(() => _isAuthenticated = true);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      }
    } 
    else {
      // Neither enabled
      if (mounted) {
        setState(() => _isAuthenticated = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.pink),
              const SizedBox(height: 20),
              const Text('MedTrack is locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Authentication required to continue', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleStartup,
                child: const Text('Unlock App'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      endDrawer: const NotificationDrawer(),
      appBar: selectedIndex == 3 
          ? null // Settings screen has its own AppBar
          : AppBar(
              toolbarHeight: 60,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'MedTrack',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(navigationProvider.notifier).setIndex(index),
          selectedItemColor: Colors.pink.shade600,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.today_outlined), activeIcon: Icon(Icons.today), label: 'Today'),
            BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: 'List'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Adherence'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
