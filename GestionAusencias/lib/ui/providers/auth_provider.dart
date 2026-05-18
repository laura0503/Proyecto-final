import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_sesion_actual_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' hide OAuthProvider;
import '../../core/utils/profesor_matcher.dart';
import 'google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final LoginProfesorUseCase _loginUseCase;
  final RegisterProfesorUseCase _registerUseCase;
  final GetSesionActualUseCase _getSesionActualUseCase;
  final CerrarSesionUseCase _cerrarSesionUseCase;
  final GetProfesoresUseCase _getProfesoresUseCase;
  final SupabaseClient _supabase;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    hostedDomain: 'g.educaand.es',
    clientId:
        '617066914619-q69p968n6v6h0g0q69p968n6v6h0g0q.apps.googleusercontent.com', // Reemplaza con tu Client ID de Firebase Web si es distinto
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
        final userEmail = session.user.email;
        if (userEmail != null && !userEmail.endsWith('@g.educaand.es')) {
          await _supabase.auth.signOut();
          _profesorActual = null;
          notifyListeners();
          return;
        }

        try {
          final googleEmail = session.user.email?.toLowerCase().trim();
          final googleName = session.user.userMetadata?['full_name']
              ?.toString()
              .toLowerCase()
              .trim();

          if (googleEmail != null) {
            final profesores = await _getProfesoresUseCase.execute();
            final matched = matchProfesorByGoogle(
              profesores,
              googleEmail,
              googleName,
            );

            if (matched != null) {
              _profesorActual = matched;
            } else {
              debugPrint(
                "Sin match para $googleEmail — creando perfil temporal en memoria",
              );
              _profesorActual = Profesor(
                id: session.user.id,
                nombre: googleEmail,
                asignatura: "",
                curso: "",
                foto: session.user.userMetadata?['avatar_url'] ?? "",
                departamento: "",
                estadoAusente: false,
              );
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
    notifyListeners();
  }

  Future<bool> login(String nombre, {String? password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String email = nombre.contains('@')
          ? nombre.toLowerCase().trim()
          : "${nombre.toLowerCase().trim()}@g.educaand.es";

      bool success = false;

      if (password != null && password.isNotEmpty) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        success = credential.user != null;
      } else {
        success = await _loginUseCase.execute(email);
      }

      if (success) {
        _profesorActual = await _getSesionActualUseCase.execute();

        if (_profesorActual == null) {
          final profesores = await _getProfesoresUseCase.execute();
          _profesorActual = profesores.cast<Profesor?>().firstWhere(
            (p) => p?.nombre.toLowerCase().trim() == email,
            orElse: () => null,
          );
        }
      }
      return _profesorActual != null;
    } catch (e) {
      debugPrint("Error en login: $e");
      return false;
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

  Future<UserCredential?> signInWithGoogleFirebase() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Si estamos en Windows Desktop, usamos Supabase porque google_sign_in no lo soporta
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb
              ? null
              : 'io.supabase.guardiasapp://login-callback/',
        );
        // En Windows el flujo es asíncrono vía deep links (manejado en main.dart)
        return null;
      }

      // Para Web y Móvil seguimos con el flujo de Firebase
      final userCredential = await signInWithGoogle(
        googleSignIn: _googleSignIn,
        auth: _auth,
      );
      if (userCredential?.user != null) {
        await login(userCredential!.user!.email!);
      }
      return userCredential;
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
