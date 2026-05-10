import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/screens/login_screen.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart';

class GestionAusencias extends StatelessWidget {
  const GestionAusencias({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Gestión de Ausencias',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF9F7F2)),
        ),
      ),
      themeMode: configProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: configProvider.appLocale,
      home: authProvider.isLoggedIn
          ? MainLayout(onLogout: () => authProvider.logout())
          : LoginScreen(onLoginSuccess: () {}),
    );
  }
}
