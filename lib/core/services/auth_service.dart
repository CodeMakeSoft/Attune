// lib/core/services/auth_service.dart

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
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) return null;
      final AccessToken accessToken = result.accessToken!;
      final credential =
          FacebookAuthProvider.credential(accessToken.tokenString);
      // Solo inicia sesión en Firebase Auth.
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      log('Error en Facebook Sign-In: $e', name: 'AuthService');
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