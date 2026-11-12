import 'package:flutter/material.dart';
// 1. استيراد ملف شاشة تحليل xG
import 'presentation/xg_analytics_screen.dart';
// 2. استيراد شاشة الترتيب
import 'presentation/standings_screen.dart';
// 3. استيراد شاشة اللاعبين
import 'presentation/players_screen.dart';

void main() {
  runApp(const FootballTacticsApp());
}

class FootballTacticsApp extends StatelessWidget {
  const FootballTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Tactics Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: const Color(0xFF1E293B),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // ضع هنا عنوان IP جهاز الكمبيوتر على شبكة Wi-Fi (مثال: 192.168.1.5:8000)
  static const String _serverHost = '192.168.1.14:8000';

  // 2. قائمة الشاشات المرتبطة بالتبويبات
  late final List<Widget> _screens = [
    XgAnalyticsScreen(serverHost: _serverHost), // تبويب تحليل xG
    StandingsScreen(serverHost: _serverHost), // تبويب الترتيب
    PlayersScreen(serverHost: _serverHost), // تبويب اللاعبين
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack يحافظ على حالة التمرير والبيانات المحمّلة عند التنقل بين التبويبات
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF38BDF8).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF38BDF8)),
            label: 'تحليل xG',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF38BDF8)),
            label: 'الترتيب',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF38BDF8)),
            label: 'اللاعبون',
          ),
        ],
      ),
    );
  }
}
