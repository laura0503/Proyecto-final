import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/profesor_remote_datasource.dart';
import 'data/datasources/horario_remote_datasource.dart';
import 'data/datasources/asignatura_remote_datasource.dart';
import 'data/repositories/profesor_repository_impl.dart';
import 'data/repositories/horario_repository_impl.dart';
import 'data/repositories/aula_repository_impl.dart';
import 'data/repositories/horario_aula_repository_impl.dart';
import 'data/repositories/grupo_repository_impl.dart';
import 'data/repositories/asignatura_repository_impl.dart';
import 'data/repositories/ausencia_repository_impl.dart';
import 'data/repositories/guardia_repository_impl.dart';
import 'data/repositories/sustitucion_repository_impl.dart';
import 'domain/repositories/profesor_repository.dart';
import 'domain/repositories/horario_repository.dart';
import 'domain/repositories/aula_repository.dart';
import 'domain/repositories/horario_aula_repository.dart';
import 'domain/repositories/grupo_repository.dart';
import 'domain/repositories/asignatura_repository.dart';
import 'domain/repositories/ausencia_repository.dart';
import 'domain/repositories/horario_importer_repository.dart';
import 'domain/repositories/guardia_repository.dart';
import 'domain/repositories/sustitucion_repository.dart';
import 'domain/usecases/login_profesor_usecase.dart';
import 'domain/usecases/register_profesor_usecase.dart';
import 'domain/usecases/get_profesores_usecase.dart';
import 'domain/usecases/get_horarios_usecase.dart';
import 'domain/usecases/update_profesor_usecase.dart';
import 'domain/usecases/get_aulas_usecase.dart';
import 'domain/usecases/get_horario_aula_usecase.dart';
import 'domain/usecases/get_grupos_usecase.dart';
import 'domain/usecases/get_asignaturas_usecase.dart';
import 'domain/usecases/get_sesion_actual_usecase.dart';
import 'domain/usecases/cerrar_sesion_usecase.dart';
import 'domain/usecases/actualizar_profesor_usecase.dart';
import 'domain/usecases/importar_profesores_usecase.dart';
import 'domain/usecases/exportar_profesores_usecase.dart';
import 'domain/usecases/importar_horario_usecase.dart';
import 'domain/usecases/eliminar_profesor_usecase.dart';
import 'domain/usecases/get_horario_aula_detallado_usecase.dart';
import 'domain/usecases/get_horario_profesor_detallado_usecase.dart';
import 'domain/usecases/get_horario_grupo_detallado_usecase.dart';
import 'domain/usecases/get_profesores_ocupados_usecase.dart';
import 'domain/usecases/get_ausencias_usecase.dart';
import 'domain/usecases/get_all_horarios_usecase.dart';
import 'domain/usecases/reportar_ausencia_usecase.dart';
import 'domain/usecases/eliminar_ausencia_usecase.dart';
import 'domain/usecases/get_guardias_usecase.dart';
import 'domain/usecases/guardar_guardia_usecase.dart';
import 'domain/usecases/eliminar_guardia_usecase.dart';
import 'domain/usecases/get_sustituciones_semana_usecase.dart';
import 'domain/usecases/guardar_observacion_usecase.dart';
import 'domain/usecases/actualizar_estado_guardia_usecase.dart';
import 'domain/usecases/auto_asignar_todo_usecase.dart'; // Nuevo import
import 'data/services/horario_importer.dart';
import 'data/services/supabase_service.dart';
import 'ui/providers/auth_provider.dart';
import 'ui/providers/config_provider.dart';
import 'ui/providers/notification_provider.dart';
import 'ui/providers/guardia_provider.dart';
import 'app.dart';

Widget buildApp({
  required SupabaseClient supabase,
  required HorarioImporter horarioImporter,
  required SupabaseService supabaseService,
}) {
  final profesorDs = ProfesorRemoteDataSource(supabase);
  final horarioDs = HorarioRemoteDataSource(supabase);
  final asignaturaDs = AsignaturaRemoteDataSource(supabase);

  final ProfesorRepository profesorRepo = ProfesorRepositoryImpl(remoteDataSource: profesorDs);
  final HorarioRepository horarioRepo = HorarioRepositoryImpl(remoteDataSource: horarioDs);
  final AulaRepository aulaRepo = AulaRepositoryImpl(supabase);
  final HorarioAulaRepository horarioAulaRepo = HorarioAulaRepositoryImpl(supabase);
  final GrupoRepository grupoRepo = GrupoRepositoryImpl(supabase);
  final AsignaturaRepository asignaturaRepo = AsignaturaRepositoryImpl(asignaturaDs);
  final AusenciaRepository ausenciaRepo = AusenciaRepositoryImpl(supabase);
  final GuardiaRepository guardiaRepo = GuardiaRepositoryImpl(supabase);
  final SustitucionRepository sustitucionRepo = SustitucionRepositoryImpl(supabase);

  return MultiProvider(
    providers: [
      Provider<ProfesorRepository>.value(value: profesorRepo),
      Provider<HorarioRepository>.value(value: horarioRepo),
      Provider<AulaRepository>.value(value: aulaRepo),
      Provider<HorarioAulaRepository>.value(value: horarioAulaRepo),
      Provider<GrupoRepository>.value(value: grupoRepo),
      Provider<AsignaturaRepository>.value(value: asignaturaRepo),
      Provider<AusenciaRepository>.value(value: ausenciaRepo),
      Provider<GuardiaRepository>.value(value: guardiaRepo),
      Provider<SustitucionRepository>.value(value: sustitucionRepo),
      Provider<IHorarioImporter>.value(value: horarioImporter),
      Provider<SupabaseService>.value(value: supabaseService),
      Provider<SupabaseClient>.value(value: supabase),
      Provider<LoginProfesorUseCase>(create: (_) => LoginProfesorUseCase(profesorRepo)),
      Provider<RegisterProfesorUseCase>(create: (_) => RegisterProfesorUseCase(profesorRepo)),
      Provider<GetProfesoresUseCase>(create: (_) => GetProfesoresUseCase(profesorRepo)),
      Provider<GetHorariosUseCase>(create: (_) => GetHorariosUseCase(horarioRepo)),
      Provider<UpdateProfesorUseCase>(create: (_) => UpdateProfesorUseCase(profesorRepo)),
      Provider<GetAulasUseCase>(create: (_) => GetAulasUseCase(aulaRepo)),
      Provider<GetHorarioAulaUseCase>(create: (_) => GetHorarioAulaUseCase(horarioAulaRepo)),
      Provider<GetGruposUseCase>(create: (_) => GetGruposUseCase(grupoRepo)),
      Provider<GetAsignaturasUseCase>(create: (_) => GetAsignaturasUseCase(asignaturaRepo)),
      Provider<GetSesionActualUseCase>(create: (_) => GetSesionActualUseCase(profesorRepo)),
      Provider<CerrarSesionUseCase>(create: (_) => CerrarSesionUseCase(profesorRepo)),
      Provider<ActualizarProfesorUseCase>(create: (_) => ActualizarProfesorUseCase(profesorRepo)),
      Provider<ImportarProfesoresUseCase>(create: (_) => ImportarProfesoresUseCase(profesorRepo)),
      Provider<ExportarProfesoresUseCase>(create: (_) => ExportarProfesoresUseCase(profesorRepo)),
      Provider<ImportarHorarioUseCase>(create: (_) => ImportarHorarioUseCase(horarioImporter)),
      Provider<EliminarProfesorUseCase>(create: (_) => EliminarProfesorUseCase(profesorRepo)),
      Provider<GetHorarioAulaDetalladoUseCase>(
        create: (c) => GetHorarioAulaDetalladoUseCase(c.read<HorarioAulaRepository>())),
      Provider<GetHorarioProfesorDetalladoUseCase>(
        create: (c) => GetHorarioProfesorDetalladoUseCase(c.read<HorarioAulaRepository>())),
      Provider<GetHorarioGrupoDetalladoUseCase>(
        create: (c) => GetHorarioGrupoDetalladoUseCase(c.read<HorarioAulaRepository>())),
      Provider<GetProfesoresOcupadosUseCase>(
        create: (c) => GetProfesoresOcupadosUseCase(c.read<HorarioRepository>())),
      Provider<GetAusenciasUseCase>(
        create: (c) => GetAusenciasUseCase(c.read<AusenciaRepository>())),
      Provider<ReportarAusenciaUseCase>(
        create: (c) => ReportarAusenciaUseCase(c.read<AusenciaRepository>())),
      Provider<GetAllHorariosUseCase>(
        create: (c) => GetAllHorariosUseCase(c.read<HorarioAulaRepository>())),
      Provider<EliminarAusenciaUseCase>(
        create: (c) => EliminarAusenciaUseCase(c.read<AusenciaRepository>())),
      Provider<GetGuardiasUseCase>(
        create: (c) => GetGuardiasUseCase(c.read<GuardiaRepository>())),
      Provider<GuardarGuardiaUseCase>(
        create: (c) => GuardarGuardiaUseCase(c.read<GuardiaRepository>())),
      Provider<EliminarGuardiaUseCase>(
        create: (c) => EliminarGuardiaUseCase(c.read<GuardiaRepository>())),
      Provider<GetSustitucionesSemanaUseCase>(
        create: (c) => GetSustitucionesSemanaUseCase(c.read<SustitucionRepository>())),
      Provider<GuardarObservacionUseCase>(
        create: (c) => GuardarObservacionUseCase(c.read<SustitucionRepository>())),
      Provider<ActualizarEstadoGuardiaUseCase>(
        create: (c) => ActualizarEstadoGuardiaUseCase(c.read<ProfesorRepository>())),
      Provider<AutoAsignarTodoUseCase>(
        create: (c) => AutoAsignarTodoUseCase(c.read<AusenciaRepository>())),
      ChangeNotifierProvider<AuthProvider>(
        create: (c) => AuthProvider(
          loginUseCase: c.read<LoginProfesorUseCase>(),
          registerUseCase: c.read<RegisterProfesorUseCase>(),
          getSesionActualUseCase: c.read<GetSesionActualUseCase>(),
          cerrarSesionUseCase: c.read<CerrarSesionUseCase>(),
          getProfesoresUseCase: c.read<GetProfesoresUseCase>(),
          supabase: c.read<SupabaseClient>(),
        )..checkSession(),
      ),
      ChangeNotifierProvider<ConfigProvider>(create: (_) => ConfigProvider()),
      ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
      ChangeNotifierProvider<GuardiaProvider>(
        create: (c) => GuardiaProvider(
          actualizarEstadoGuardia: c.read<ActualizarEstadoGuardiaUseCase>(),
        ),
      ),
    ],
    child: const GestionAusencias(),
  );
}
