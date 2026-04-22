import 'package:flutter/material.dart';
import 'package:kawach/app/router.dart';
import 'package:kawach/core/theme/app_theme.dart';

class KawachApp extends StatelessWidget {
  const KawachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KAWACH',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
