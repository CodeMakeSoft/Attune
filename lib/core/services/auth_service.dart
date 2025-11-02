import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Paso 1: iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      // Paso 2: obtener los tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Paso 3: crear credenciales para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Paso 4: autenticar con Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
