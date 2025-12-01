import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// NOTA: Este servicio YA NO HABLA CON FIRESTORE.
// Solo se encarga de la AUTENTICACIÓN.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  // --- REGISTRO (Solo para Super Admins por primera vez) ---
  Future<UserCredential?> registerWithEmailPassword(
      String email, String password) async {
    try {
      // Solo crea el usuario en Firebase Auth.
      // NO crea el documento en Firestore.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      log('Error de registro: ${e.code}', name: 'AuthService');
      return null;
    } catch (e) {
      log('Error en registro: $e', name: 'AuthService');
      return null;
    }
  }

  // --- INICIO DE SESIÓN (Para todos) ---
  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      // Solo inicia sesión en Firebase Auth.
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      log('Error en inicio de sesión: $e', name: 'AuthService');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Solo inicia sesión en Firebase Auth.
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      log('Error en Google Sign-In: $e', name: 'AuthService');
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    AuthCredential? credential;
    try {
      print('--- DEBUG: Iniciando login con Facebook... ---');
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      print('--- DEBUG: Facebook login result status: ${result.status} ---');
      
      if (result.status != LoginStatus.success) {
        print('--- DEBUG: Facebook login failed: ${result.message} ---');
        return null;
      }
      
      final AccessToken accessToken = result.accessToken!;
      print('--- DEBUG: Facebook Access Token obtenido: ${accessToken.tokenString.substring(0, 10)}... ---');
      
      credential = FacebookAuthProvider.credential(accessToken.tokenString);
      
      print('--- DEBUG: Iniciando sesión en Firebase con credencial... ---');
      final userCredential = await _auth.signInWithCredential(credential);
      print('--- DEBUG: Firebase login exitoso. User: ${userCredential.user?.uid} ---');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if(e.code == 'account-exists-with-different-credential' && credential != null) {
        print('--- DEBUG Cuenta existente detectada, intentando vincular con Google... ---');

        try {
          final googleCredential = await signInWithGoogle();
          if (googleCredential != null && googleCredential.user != null) {
            print('--- DEBUG: Vinculación exitosa con Google ---');
            await googleCredential.user!.linkWithCredential(credential);
            print('--- DEBUG: Vinculación exitosa con Google ---');
            return googleCredential;
          }
        } catch (e) {
          print('--- DEBUG: Error al vincular cuentas ---');        
        }
      }
      print('--- DEBUG: Error al iniciar sesión con Facebook (firebase) ---');
      return null;
    } catch (e) {
      print('--- DEBUG: Error en Facebook Sign-In (firebase) ---');
      return null;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      log('Error al enviar correo: $e', name: 'AuthService');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}