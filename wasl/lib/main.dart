import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/knowledge_home_page.dart';

void main() {
  runApp(const WaslApp());
}

class WaslApp extends StatefulWidget {
  const WaslApp({super.key});

  @override
  State<WaslApp> createState() => _WaslAppState();
}

class _WaslAppState extends State<WaslApp> {
  Locale _locale = const Locale('ar');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _locale.languageCode == 'ar' ? 'وصل' : 'Wasl',
      locale: _locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          surface: const Color(0xFF142033),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1220),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: KnowledgeHomePage(
        onLocaleChanged: (locale) => setState(() => _locale = locale),
      ),
    );
  }
}
