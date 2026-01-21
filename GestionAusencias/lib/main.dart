import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gestion_ausencias/ui/screens/login_screen.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const GestionAusencias());
}

class GestionAusencias extends StatefulWidget {
  const GestionAusencias({super.key});

  @override
  State<GestionAusencias> createState() => _GestionAusenciasState();
}

class _GestionAusenciasState extends State<GestionAusencias> {
  bool _isLoggedIn = false;
  ThemeMode _temaActual = ThemeMode.light;

  void _cambiarTema() {
    setState(() {
      _temaActual = _temaActual == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _loginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  void _logout() {
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Profesores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFFF9F7F2), // Crema
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Azul profundo
        cardColor: const Color(0xFF1E293B),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF9F7F2)), // Texto en crema
        ),
      ),
      themeMode: _temaActual,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      home: _isLoggedIn
          ? MainLayout(
              alCambiarTema: _cambiarTema,
              esModoOscuro: _temaActual == ThemeMode.dark,
              onLogout: _logout,
            )
          : LoginScreen(
              alCambiarTema: _cambiarTema,
              esModoOscuro: _temaActual == ThemeMode.dark,
              onLoginSuccess: _loginSuccess,
            ),
    );
  }
}
