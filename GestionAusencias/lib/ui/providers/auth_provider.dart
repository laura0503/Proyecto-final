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
          // Buscamos si existe un profesor con el email o nombre que viene de Google
          final userEmail = session.user.email;
          if (userEmail != null) {
             final profesores = await _getProfesoresUseCase.execute();
             // Intentamos buscar por email (si tuviéramos ese campo) 
             // o por nombre si coincide con el del perfil de Google
             final googleName = session.user.userMetadata?['full_name'];
             final googleEmail = session.user.email;
             
             final match = profesores.where((p) => 
               p.nombre == googleName || 
               p.nombre == googleEmail
             ).toList();
             if (match.isNotEmpty) {
               _profesorActual = match.first;
             } else {
               // Si no existe, podríamos crearlo o dejarlo como invitado
               // Por ahora, solo notificamos
             }
          }
        } catch (e) {
          print("Error al sincronizar perfil tras login: $e");
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
      // Si es Web o Móvil, usamos el paquete google_sign_in
      // Pero para Windows Desktop, google_sign_in no es compatible oficialmente.
      // Usaremos Supabase OAuth directamente para mayor compatibilidad en PC.
      
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.tuempresa.guardiasapp://login-callback',
          queryParams: {'hd': 'g.educaand.es'},
        );
        return null; 
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      // Validación extra por seguridad
      if (account != null && !account.email.endsWith('@g.educaand.es')) {
        await _googleSignIn.signOut();
        print('Acceso denegado: dominio no permitido');
        return null;
      }
      
      return account;
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
