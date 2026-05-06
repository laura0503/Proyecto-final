import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_sesion_actual_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final LoginProfesorUseCase _loginUseCase;
  final RegisterProfesorUseCase _registerUseCase;
  final GetSesionActualUseCase _getSesionActualUseCase;
  final CerrarSesionUseCase _cerrarSesionUseCase;
  final GetProfesoresUseCase _getProfesoresUseCase;
  final SupabaseClient _supabase;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '867000121620-m6vu65l321er11q0t3cifpbdsjk00tkq.apps.googleusercontent.com',
    hostedDomain: 'g.educaand.es',
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Profesor? _profesorActual;
  Profesor? get profesorActual => _profesorActual;

  bool get isLoggedIn => _profesorActual != null;
  bool get isAdmin => _profesorActual?.isAdmin ?? false;

  AuthProvider({
    required LoginProfesorUseCase loginUseCase,
    required RegisterProfesorUseCase registerUseCase,
    required GetSesionActualUseCase getSesionActualUseCase,
    required CerrarSesionUseCase cerrarSesionUseCase,
    required GetProfesoresUseCase getProfesoresUseCase,
    required SupabaseClient supabase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _getSesionActualUseCase = getSesionActualUseCase,
       _cerrarSesionUseCase = cerrarSesionUseCase,
       _getProfesoresUseCase = getProfesoresUseCase,
       _supabase = supabase {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedOut) {
        _profesorActual = null;
        notifyListeners();
        return;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Validación de dominio para seguridad
        final userEmail = session.user.email;
        if (userEmail != null && !userEmail.endsWith('@g.educaand.es')) {
          await _supabase.auth.signOut();
          _profesorActual = null;
          notifyListeners();
          return;
        }

        // Al iniciar sesión con Google (u otro), intentamos cargar el perfil del profesor
        try {
          final googleEmail = session.user.email?.toLowerCase().trim();
          final googleName = session.user.userMetadata?['full_name']?.toString().toLowerCase().trim();
          
          if (googleEmail != null) {
            final profesores = await _getProfesoresUseCase.execute();
            
            // Buscamos coincidencia
            final match = profesores.where((p) {
              final nombreProfe = p.nombre.toLowerCase().trim();
              return nombreProfe == googleEmail || 
                     nombreProfe == googleName ||
                     (googleName != null && googleName.contains(nombreProfe)) ||
                     (googleName != null && nombreProfe.contains(googleName)) ||
                     googleEmail.split('@').first == nombreProfe.split('@').first;
            }).toList();

            if (match.isNotEmpty) {
              _profesorActual = match.first;
            } else {
              // SI NO EXISTE, LO CREAMOS AUTOMÁTICAMENTE
              debugPrint("Usuario nuevo de Google: $googleEmail. Creando perfil...");
              final nuevoProfe = Profesor(
                id: "google_${session.user.id.substring(0, 8)}",
                nombre: session.user.email ?? googleName ?? "Usuario Google",
                asignatura: "Pendiente",
                curso: "General",
                foto: session.user.userMetadata?['avatar_url'] ?? "https://i.pravatar.cc/150?u=$googleEmail",
                departamento: "General",
                estadoAusente: false,
              );
              await _registerUseCase.execute(nuevoProfe);
              _profesorActual = nuevoProfe;
            }
          }
        } catch (e) {
          debugPrint("Error al sincronizar perfil tras login: $e");
        }
        notifyListeners();
      }
    });
  }

  Future<void> checkSession() async {
    // Comentamos el BYPASS para que pida login real
    /*
    try {
      final profesores = await _getProfesoresUseCase.execute();
      if (profesores.isNotEmpty) {
        _profesorActual = profesores.first;
      }
    } catch (_) {}
    */
    notifyListeners();
  }

  Future<bool> login(String nombre) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _loginUseCase.execute(nombre);
      if (success) {
        _profesorActual = await _getSesionActualUseCase.execute();
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Profesor profesor) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _registerUseCase.execute(profesor);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _cerrarSesionUseCase.execute();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _profesorActual = null;
    notifyListeners();
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Para Windows, usamos Supabase OAuth
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
        // Primero cerramos sesión por si acaso para limpiar el estado
        await _supabase.auth.signOut();
        
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.tuempresa.guardiasapp://login-callback',
          queryParams: {
            'hd': 'g.educaand.es',
            'prompt': 'select_account',
          },
        );
        return null; 
      }

      // Para otras plataformas
      await _googleSignIn.signOut(); // Limpiamos sesión previa
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null && !account.email.endsWith('@g.educaand.es')) {
        await _googleSignIn.signOut();
        debugPrint('Acceso denegado: dominio no permitido');
        return null;
      }
      
      return account;
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
