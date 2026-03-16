import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/modules/auth/auth_provider.dart';
import 'package:medtrack_mobile/modules/auth/login_screen.dart';
import 'package:medtrack_mobile/modules/medications/medication_list_screen.dart';
import 'package:medtrack_mobile/modules/daily_status/daily_status_screen.dart';
import 'package:medtrack_mobile/services/notification_service.dart';
import 'package:medtrack_mobile/modules/calendar/calendar_screen.dart';
import 'package:medtrack_mobile/modules/settings/settings_screen.dart';
import 'package:medtrack_mobile/modules/settings/biometric_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: MedTrackApp(),
    ),
  );
}

class MedTrackApp extends ConsumerWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
      home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
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
  int _selectedIndex = 0;
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
    // 1. Sync data in background
    Future.microtask(() => ref.read(syncServiceProvider).sync());

    // 2. Check biometrics
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (biometricEnabled) {
      final authenticated = await ref.read(biometricServiceProvider).authenticate();
      if (authenticated) {
        setState(() => _isAuthenticated = true);
      } else {
        // If failed, we could exit or logout, but a common pattern is to keep prompting
        // or offer a 'Logout' option if they can't get in.
        // For simplicity, let's just keep authenticated as false which shows a lock screen.
      }
    } else {
      setState(() => _isAuthenticated = true);
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _handleStartup,
                child: const Text('Unlock with Biometrics'),
              ),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _selectedIndex == 3 
          ? null // Settings screen has its own AppBar
          : AppBar(
              toolbarHeight: 52,
              title: const Text('MedTrack'),
            ),
      body: _screens[_selectedIndex],
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
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
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
