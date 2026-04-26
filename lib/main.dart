import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MetroSheetApp()));
}

class MetroSheetApp extends StatelessWidget {
  const MetroSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E5FA8),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'MetroSheet',
      theme: ThemeData(
        fontFamily: '.SF Pro Text',
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: colorScheme.primary,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
