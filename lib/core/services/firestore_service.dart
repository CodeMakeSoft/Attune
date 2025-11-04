// lib/core/services/firestore_service.dart

import 'package:attune/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth; // Renombramos
import 'dart:developer';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;

  Future<User?> getUserData() async {
    // 1. Obtener el usuario actual de Auth
    final fbAuth.User? authUser = _auth.currentUser;
    if (authUser == null) return null;

    // 2. Intentar leer el documento del usuario en Firestore (en /users/{uid})
    final userDocRef = _db.collection('users').doc(authUser.uid);
    var userDocSnapshot = await userDocRef.get();

    // 3. ¿El documento existe?
    if (userDocSnapshot.exists) {
      // 3.1 SÍ EXISTE: Es un usuario que ya ha iniciado sesión antes.
      // Devolvemos sus datos.
      log('Usuario existente encontrado.', name: 'FirestoreService');
      return User.fromFirestore(userDocSnapshot);
    } else {
      // 3.2 NO EXISTE: Es un usuario NUEVO (se acaba de registrar).
      // Buscamos una INVITACIÓN en la nueva colección.
      
      // 4. Busca en la colección 'invitations' usando el email como ID
      final invitationDocRef = _db.collection('invitations').doc(authUser.email!);
      final invitationDocSnapshot = await invitationDocRef.get();

      if (invitationDocSnapshot.exists) {
        // 4.1 ¡ENCONTRÓ UNA INVITACIÓN!
        // Esto es un Admin o User invitado.
        log('Invitación encontrada. Vinculando cuenta...', name: 'FirestoreService');
        final invitationData = invitationDocSnapshot.data()!;
        
        // Preparamos los datos del nuevo usuario
        final newUserData = {
          // Datos de la invitación
          'companyId': invitationData['companyId'],
          'role': invitationData['role'],
          // Datos de Auth
          'email': authUser.email,
          'name': authUser.displayName ?? '', // Tomamos los datos de Google/FB
          'photoUrl': authUser.photoURL,
          'status': 'active', // Activamos la cuenta
          'createdAt': FieldValue.serverTimestamp(),
          // Campos vacíos para que los llene después
          'emergencyContact': {},
        };

        // Usamos un WriteBatch para hacer dos cosas a la vez:
        final batch = _db.batch();
        
        // Operación 1: CREAR el documento de usuario en /users/{uid}
        batch.set(userDocRef, newUserData);
        
        // Operación 2: BORRAR la invitación
        batch.delete(invitationDocRef);
        
        // Ejecutamos las dos operaciones
        await batch.commit();
        
        // Volvemos a leer el documento de usuario que acabamos de crear y lo devolvemos
        userDocSnapshot = await userDocRef.get();
        return User.fromFirestore(userDocSnapshot);

      } else {
        // 4.2 NO HAY INVITACIÓN: Es un usuario 100% nuevo.
        // Este DEBE SER un Super Admin registrando su empresa.
        log('Usuario no invitado encontrado, creando perfil de Super Admin...', name: 'FirestoreService');
        
        final newUserData = {
          'email': authUser.email,
          'name': authUser.displayName ?? 'Nuevo Admin',
          'photoUrl': authUser.photoURL,
          'role': 'super_admin', // Asignamos el rol
          'companyId': '',         // ¡AÚN NO TIENE EMPRESA!
          'status': 'pending_company',
          'createdAt': FieldValue.serverTimestamp(),
          'emergencyContact': {},
        };

        await userDocRef.set(newUserData);
        
        userDocSnapshot = await userDocRef.get();
        return User.fromFirestore(userDocSnapshot);
      }
    }
  }

  // ... (tu método createCompany)
  Future<bool> createCompany({
    required String companyName,
    String? rfc,
    String? businessLine,
  }) async {
    // ... (este código está perfecto y no cambia)
    final fbAuth.User? authUser = _auth.currentUser;
    if (authUser == null) {
      log('Error: No hay usuario autenticado para crear la empresa.', name: 'FirestoreService');
      return false;
    }
    try {
      final companyRef = _db.collection('companies').doc();
      final userRef = _db.collection('users').doc(authUser.uid);
      final Map<String, dynamic> companyData = {
        'name': companyName,
        'rfc': rfc ?? '',
        'businessLine': businessLine ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': authUser.uid,
      };
      final batch = _db.batch();
      batch.set(companyRef, companyData);
      batch.update(userRef, {
        'companyId': companyRef.id,
        'status': 'active'
      });
      await batch.commit();
      log('Empresa creada y Super Admin actualizado exitosamente.', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al crear la empresa: $e', name: 'FirestoreService');
      return false;
    }
  }
}