// ─── Paquetes externos ───
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Data Sources ───
import 'package:gestion_ausencias/data/datasources/profesor_remote_datasource.dart';
import 'package:gestion_ausencias/data/datasources/horario_remote_datasource.dart';
import 'package:gestion_ausencias/data/datasources/asignatura_remote_datasource.dart';

// ─── Repositorios (implementaciones) ───
import 'package:gestion_ausencias/data/repositories/profesor_repository_impl.dart';
import 'package:gestion_ausencias/data/repositories/horario_repository_impl.dart';
import 'package:gestion_ausencias/data/repositories/aula_repository_impl.dart';
import 'package:gestion_ausencias/data/repositories/horario_aula_repository_impl.dart';
import 'package:gestion_ausencias/data/repositories/grupo_repository_impl.dart';
import 'package:gestion_ausencias/data/repositories/asignatura_repository_impl.dart';

// ─── Repositorios (interfaces) ───
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';
import 'package:gestion_ausencias/domain/repositories/aula_repository.dart';
import 'package:gestion_ausencias/domain/repositories/horario_aula_repository.dart';
import 'package:gestion_ausencias/domain/repositories/grupo_repository.dart';
import 'package:gestion_ausencias/domain/repositories/asignatura_repository.dart';

// ─── Casos de uso ───
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/update_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_aulas_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_grupos_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_asignaturas_usecase.dart';

// ─── Proveedores y pantallas (UI) ───
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';
import 'package:gestion_ausencias/ui/screens/login_screen.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['KEY']!,
  );

  // 3. Inicializar capa de datos
  // ignore: no_leading_underscores_for_local_identifiers
  final _supabase = Supabase.instance.client;

  final profesorDataSource = ProfesorRemoteDataSource(_supabase);
  final horarioDataSource = HorarioRemoteDataSource(_supabase);
  final asignaturaDataSource = AsignaturaRemoteDataSource(_supabase);

  final profesorRepository = ProfesorRepositoryImpl(
    remoteDataSource: profesorDataSource,
  );
  final horarioRepository = HorarioRepositoryImpl(
    remoteDataSource: horarioDataSource,
  );
  final aulaRepository = AulaRepositoryImpl(_supabase);
  final horarioAulaRepository = HorarioAulaRepositoryImpl(_supabase);
  final grupoRepository = GrupoRepositoryImpl(_supabase);
  final asignaturaRepository = AsignaturaRepositoryImpl(asignaturaDataSource);

  // 4. Ejecutar la app con inyección de dependencias
  runApp(
    MultiProvider(
      providers: [
        // ── Repositorios ──
        Provider<ProfesorRepository>.value(value: profesorRepository),
        Provider<HorarioRepository>.value(value: horarioRepository),
        Provider<AulaRepository>.value(value: aulaRepository),
        Provider<HorarioAulaRepository>.value(value: horarioAulaRepository),
        Provider<GrupoRepository>.value(value: grupoRepository),
        Provider<AsignaturaRepository>.value(value: asignaturaRepository),

        // ── Casos de uso ──
        Provider<LoginProfesorUseCase>(
          create: (_) => LoginProfesorUseCase(profesorRepository),
        ),
        Provider<RegisterProfesorUseCase>(
          create: (_) => RegisterProfesorUseCase(profesorRepository),
        ),
        Provider<GetProfesoresUseCase>(
          create: (_) => GetProfesoresUseCase(profesorRepository),
        ),
        Provider<GetHorariosUseCase>(
          create: (_) => GetHorariosUseCase(horarioRepository),
        ),
        Provider<UpdateProfesorUseCase>(
          create: (_) => UpdateProfesorUseCase(profesorRepository),
        ),
        Provider<GetAulasUseCase>(
          create: (_) => GetAulasUseCase(aulaRepository),
        ),
        Provider<GetHorarioAulaUseCase>(
          create: (_) => GetHorarioAulaUseCase(horarioAulaRepository),
        ),
        Provider<GetGruposUseCase>(
          create: (_) => GetGruposUseCase(grupoRepository),
        ),
        Provider<GetAsignaturasUseCase>(
          create: (_) => GetAsignaturasUseCase(asignaturaRepository),
        ),

        // ── Proveedores de estado ──
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            loginUseCase: context.read<LoginProfesorUseCase>(),
            registerUseCase: context.read<RegisterProfesorUseCase>(),
            repository: profesorRepository,
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
