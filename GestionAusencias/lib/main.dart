import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// Domain & Data
import 'package:gestion_ausencias/data/datasources/profesor_local_datasource.dart';
import 'package:gestion_ausencias/data/datasources/profesor_remote_datasource.dart';
import 'package:gestion_ausencias/data/repositories/profesor_repository_impl.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';

// Providers & UI
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/screens/login_screen.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // 1. Load Environment Variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['KEY']!,
  );

  // 3. Initialize Data Layer
  final localDataSource = ProfesorLocalDataSource();
  final remoteDataSource = ProfesorRemoteDataSource(Supabase.instance.client);
  final repository = ProfesorRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );

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
        Provider<GetHorariosUseCase>(
          create: (_) => GetHorariosUseCase(repository),
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

class GestionAusencias extends StatelessWidget {
  const GestionAusencias({super.key});

  @override
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
          ? MainLayout(onLogout: () => authProvider.logout())
          : LoginScreen(
              onLoginSuccess: () {
                // Navigation is handled by the home property relying on authProvider state
              },
            ),
    );
  }
}
