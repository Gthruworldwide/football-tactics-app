import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/player_stats_model.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth_screen.dart';
import 'presentation/matches_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceCard,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PlayerStatsAdapter());
  }
  await Hive.openBox<PlayerStatsModel>('players_box');
  final prefsBox = await Hive.openBox('user_prefs_box');
  final bool isLoggedIn = prefsBox.get('is_logged_in', defaultValue: false);

  runApp(FootballTacticsApp(isLoggedIn: isLoggedIn));
}

class FootballTacticsApp extends StatelessWidget {
  final bool isLoggedIn;
  const FootballTacticsApp({required this.isLoggedIn, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Tactics Engine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tacticalDarkTheme,
      home: isLoggedIn ? const MatchesScreen() : const AuthScreen(),
    );
  }
}
