import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> signInWithGoogle({
  required GoogleSignIn googleSignIn,
  required FirebaseAuth auth,
}) async {
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;

  if (!googleUser.email.endsWith('@g.educaand.es')) {
    await googleSignIn.signOut();
    throw 'Solo se permiten correos de @g.educaand.es';
  }

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return auth.signInWithCredential(credential);
}
