import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Domain & Data
import 'package:gestion_ausencias/data/datasources/profesor_local_datasource.dart';
import 'package:gestion_ausencias/data/repositories/profesor_repository_impl.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';

// Providers & UI
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/screens/login_screen.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // 1. Initialize Data Layer
  final localDataSource = ProfesorLocalDataSource();
  final repository = ProfesorRepositoryImpl(localDataSource: localDataSource);

  runApp(
    MultiProvider(
      providers: [
        // Repository Injection
        Provider<ProfesorRepository>.value(value: repository),

        // Use Cases Injection
        Provider<LoginProfesorUseCase>(
          create: (_) => LoginProfesorUseCase(repository),
        ),
        Provider<RegisterProfesorUseCase>(
          create: (_) => RegisterProfesorUseCase(repository),
        ),
        Provider<GetProfesoresUseCase>(
          create: (_) => GetProfesoresUseCase(repository),
        ),

        // Logic/State Management Injection
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            loginUseCase: context.read<LoginProfesorUseCase>(),
            registerUseCase: context.read<RegisterProfesorUseCase>(),
            repository: repository,
          )..checkSession(),
        ),
        ChangeNotifierProvider<ConfigProvider>(create: (_) => ConfigProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const GestionAusencias(),
    ),
  );
}

class GestionAusencias extends StatefulWidget {
  const GestionAusencias({super.key});

  @override
  State<GestionAusencias> createState() => _GestionAusenciasState();
}

class _GestionAusenciasState extends State<GestionAusencias> {
  // Logout is now handled by AuthProvider, but we might pass a callback if needed by legacy code
  // or simply rely on AuthProvider state changes.
  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final authProvider = context.watch<AuthProvider>();

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
      themeMode: configProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: configProvider.appLocale,
      home: authProvider.isLoggedIn
          ? MainLayout(onLogout: () => _logout(context))
          : LoginScreen(
              onLoginSuccess: () {
                // Now handled by AuthProvider state, but kept for compatibility if needed.
                // Actually the redirection is done by 'home:' property listening to authProvider.isLoggedIn
              },
            ),
    );
  }
}
