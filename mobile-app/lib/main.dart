import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/modules/auth/auth_provider.dart';
import 'package:medtrack_mobile/modules/auth/login_screen.dart';
import 'package:medtrack_mobile/modules/medications/medication_list_screen.dart';
import 'package:medtrack_mobile/modules/daily_status/daily_status_screen.dart';
import 'package:medtrack_mobile/services/notification_service.dart';
import 'package:medtrack_mobile/modules/calendar/calendar_screen.dart';
import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';

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

  static const List<Widget> _screens = [
    DailyStatusScreen(),
    MedicationListScreen(),
    CalendarScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncServiceProvider).sync());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: const Text('MedTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, size: 20),
            tooltip: 'Sync Data',
            onPressed: () async {
              await ref.read(syncServiceProvider).sync();
              ref.read(medicationListProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Logout',
            onPressed: () {
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
            },
          ),
        ],
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
          ],
        ),
      ),
    );
  }
}
