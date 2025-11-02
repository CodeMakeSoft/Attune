import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // Google
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
      log('Error in Google Sign-In: $e', name: 'AuthService');
      return null;
    }
  }

  // Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        log('Facebook login failed. State: ${result.status}', name: 'AuthService');
        return null;
      }

      final AccessToken accessToken = result.accessToken!;
      final credential = FacebookAuthProvider.credential(accessToken.tokenString);

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      log('Error in Facebook Sign-In: $e', name: 'AuthService');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
