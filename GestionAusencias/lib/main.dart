import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
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
import 'package:gestion_ausencias/domain/repositories/horario_importer_repository.dart';

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
import 'package:gestion_ausencias/domain/usecases/get_sesion_actual_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/actualizar_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/importar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/exportar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/importar_horario_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/eliminar_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_detallado_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_profesor_detallado_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_grupo_detallado_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_ocupados_usecase.dart';
import 'package:gestion_ausencias/data/services/horario_importer.dart';
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

  final supabaseUrl = dotenv.env['URL'] ?? '';
  final supabaseKey = dotenv.env['KEY'] ?? '';

  if (supabaseUrl == 'YOUR_SUPABASE_URL' || supabaseUrl.isEmpty) {
    print("❌ ERROR: No has configurado tu URL de Supabase en el archivo .env");
    // Podríamos mostrar una pantalla de error aquí, pero por ahora lanzamos un aviso claro.
  }

  // 2. Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // 3. Inicializar capa de datos
  final supabase = Supabase.instance.client;

  final profesorDataSource = ProfesorRemoteDataSource(supabase);
  final horarioDataSource = HorarioRemoteDataSource(supabase);
  final asignaturaDataSource = AsignaturaRemoteDataSource(supabase);

  final profesorRepository = ProfesorRepositoryImpl(
    remoteDataSource: profesorDataSource,
  );
  final horarioRepository = HorarioRepositoryImpl(
    remoteDataSource: horarioDataSource,
  );
  final aulaRepository = AulaRepositoryImpl(supabase);
  final horarioAulaRepository = HorarioAulaRepositoryImpl(supabase);
  final grupoRepository = GrupoRepositoryImpl(supabase);
  final asignaturaRepository = AsignaturaRepositoryImpl(asignaturaDataSource);

  final horarioImporter = HorarioImporter();

  // --- MOTOR DE INTEGRIDAD AUTOMÁTICO AL INICIAR LA APP ---
  try {
    final List<String> aulasAParchear = ['122_8.csv', '205_11.csv', '208_13.csv'];
    for (var file in aulasAParchear) {
      final path = 'assets/csv/$file';
      if (await File(path).exists()) {
        final content = await File(path).readAsString();
        await horarioImporter.subirASupabase(content);
      }
    }
    
    // Sintonía final: Purga basura y deduce departamentos automáticamente
    await horarioImporter.sincronizarTodo();
    
    print("✅ MOTOR DE INTEGRIDAD: Aulas críticas parcheadas y base de datos saneada.");
  } catch (e) {
    print("Aviso: Error en el motor de integridad inicial: $e");
  }

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
        Provider<IHorarioImporter>.value(value: horarioImporter),

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
        Provider<GetSesionActualUseCase>(
          create: (_) => GetSesionActualUseCase(profesorRepository),
        ),
        Provider<CerrarSesionUseCase>(
          create: (_) => CerrarSesionUseCase(profesorRepository),
        ),
        Provider<ActualizarProfesorUseCase>(
          create: (_) => ActualizarProfesorUseCase(profesorRepository),
        ),
        Provider<ImportarProfesoresUseCase>(
          create: (_) => ImportarProfesoresUseCase(profesorRepository),
        ),
        Provider<ExportarProfesoresUseCase>(
          create: (_) => ExportarProfesoresUseCase(profesorRepository),
        ),
        Provider<ImportarHorarioUseCase>(
          create: (_) => ImportarHorarioUseCase(horarioImporter),
        ),
        Provider<EliminarProfesorUseCase>(
          create: (_) => EliminarProfesorUseCase(profesorRepository),
        ),
        Provider<GetHorarioAulaDetalladoUseCase>(
          create: (context) => GetHorarioAulaDetalladoUseCase(context.read<HorarioAulaRepository>()),
        ),
        Provider<GetHorarioProfesorDetalladoUseCase>(
          create: (context) => GetHorarioProfesorDetalladoUseCase(context.read<HorarioAulaRepository>()),
        ),
        Provider<GetHorarioGrupoDetalladoUseCase>(
          create: (context) => GetHorarioGrupoDetalladoUseCase(context.read<HorarioAulaRepository>()),
        ),
        Provider<GetProfesoresOcupadosUseCase>(
          create: (context) => GetProfesoresOcupadosUseCase(context.read<HorarioRepository>()),
        ),

        // ── Proveedores de estado ──
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            loginUseCase: context.read<LoginProfesorUseCase>(),
            registerUseCase: context.read<RegisterProfesorUseCase>(),
            getSesionActualUseCase: context.read<GetSesionActualUseCase>(),
            cerrarSesionUseCase: context.read<CerrarSesionUseCase>(),
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
