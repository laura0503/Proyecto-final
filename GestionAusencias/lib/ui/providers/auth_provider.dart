import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_sesion_actual_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final LoginProfesorUseCase _loginUseCase;
  final RegisterProfesorUseCase _registerUseCase;
  final GetSesionActualUseCase _getSesionActualUseCase;
  final CerrarSesionUseCase _cerrarSesionUseCase;
  final GetProfesoresUseCase _getProfesoresUseCase;
  final SupabaseClient _supabase;

  final FirebaseAuth _auth = FirebaseAuth.instance;
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
        final userEmail = session.user.email;
        if (userEmail != null && !userEmail.endsWith('@g.educaand.es')) {
          await _supabase.auth.signOut();
          _profesorActual = null;
          notifyListeners();
          return;
        }

        try {
          final googleEmail = session.user.email?.toLowerCase().trim();
          final googleName = session.user.userMetadata?['full_name']?.toString().toLowerCase().trim();
          
          if (googleEmail != null) {
            final profesores = await _getProfesoresUseCase.execute();

            String normName(String s) => s.toLowerCase()
                .replaceAll(RegExp(r'[áàâä]'), 'a')
                .replaceAll(RegExp(r'[éèêë]'), 'e')
                .replaceAll(RegExp(r'[íìîï]'), 'i')
                .replaceAll(RegExp(r'[óòôö]'), 'o')
                .replaceAll(RegExp(r'[úùûü]'), 'u')
                .replaceAll('ñ', 'n');

            final googleTokens = googleName != null
                ? normName(googleName)
                    .split(RegExp(r'[\s,]+'))
                    .where((t) => t.length > 3)
                    .toList()
                : <String>[];

            // Primero intentar coincidir con un profesor real (nombre sin @)
            // usando tokens del nombre completo de Google (maneja "Apellidos, Nombre")
            Profesor? profReal;
            if (googleTokens.length >= 2) {
              for (final p in profesores) {
                if (p.nombre.contains('@')) continue; // saltar perfiles de email
                final nombreNorm = normName(p.nombre);
                final hits = googleTokens.where((t) => nombreNorm.contains(t)).length;
                if (hits >= 2) { profReal = p; break; }
              }
            }

            final match = profReal != null
                ? [profReal]
                : profesores.where((p) {
                    final nombreProfe = p.nombre.toLowerCase().trim();
                    if (nombreProfe == googleEmail) return true;
                    if (googleName != null && nombreProfe == googleName) return true;
                    if (googleEmail.split('@').first == nombreProfe.split('@').first) return true;
                    return false;
                  }).toList();

            if (match.isNotEmpty) {
              _profesorActual = match.first;
            } else {
              // No crear perfil en BD — el home screen resolverá el profesor real
              // usando la columna email de la tabla profesores.
              debugPrint("Sin match para $googleEmail — creando perfil temporal en memoria");
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
    // Para desarrollo, podrías activar esto si no tienes internet:
    /*
    _profesorActual = const Profesor(
      id: 'dummy_id',
      nombre: 'Admin Local',
      asignatura: 'Informática',
      curso: '1',
      foto: '',
      departamento: 'Tecnología',
      estadoAusente: false,
      rol: 'admin',
    );
    */
    notifyListeners();
  }

  Future<bool> login(String nombre, {String? password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String email = nombre.contains('@') ? nombre : "$nombre@g.educaand.es";
      
      // Si quieres usar Firebase Auth real con contraseña:
      if (password != null) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          // Aquí buscamos al profesor en tu base de datos actual (Supabase)
          final success = await _loginUseCase.execute(email);
          if (success) {
            _profesorActual = await _getSesionActualUseCase.execute();
          }
          return success;
        }
        return false;
      } else {
        // Login "rápido" (solo nombre) que ya tenías
        final success = await _loginUseCase.execute(email);
        if (success) {
          _profesorActual = await _getSesionActualUseCase.execute();
        }
        return success;
      }
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      if (!googleUser.email.endsWith('@g.educaand.es')) {
        await _googleSignIn.signOut();
        throw 'Solo se permiten correos de @g.educaand.es';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Sincronizar con tu lógica de profesores
      if (userCredential.user != null) {
        await login(userCredential.user!.email!);
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error en Google Sign-In Firebase: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
