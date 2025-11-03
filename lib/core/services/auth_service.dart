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

    // Register and SignIn with email
  Future<UserCredential?> registerWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      log('Error in register: ${e.code}', name: 'AuthService');
      return null;
    } catch (e) {
      log('Error in register: $e', name: 'AuthService');
      return null;
    }
  }
  
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      log('Error in Sign In: ${e.code}', name: 'AuthService');
      return null;
    } catch (e) {
      log('Error in Sign In: $e', name: 'AuthService');
      return null;
    }
  }

  // Forgot passwoord
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return true;
    } on FirebaseAuthException catch (e) {
      log('Error al enviar correo de restablecimiento: ${e.code}', name: 'AuthService');
      return false;
    } catch (e) {
      log('Error: $e', name: 'AuthService');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
