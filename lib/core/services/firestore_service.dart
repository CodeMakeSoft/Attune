// lib/core/services/firestore_service.dart

import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/evaluation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth; // Renombramos
import 'dart:developer';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;

  Future<User?> getUserData() async {
    final fbAuth.User? authUser = _auth.currentUser;
    if (authUser == null) return null;

    final userDocRef = _db.collection('users').doc(authUser.uid);
    var userDocSnapshot = await userDocRef.get();

    if (userDocSnapshot.exists) {
      log('Usuario existente encontrado.', name: 'FirestoreService');
      User user = User.fromFirestore(userDocSnapshot);

      // Revisar si hay invitaciones pendientes para este usuario existente
      final emailKey = authUser.email!.trim().toLowerCase();
      final invitationDocRef = _db.collection('invitations').doc(emailKey);
      final invitationDocSnapshot = await invitationDocRef.get();

      if (invitationDocSnapshot.exists) {
        log('Invitación encontrada para usuario existente. Procesando...', name: 'FirestoreService');
        final invitationData = invitationDocSnapshot.data()!;
        final newCompanyId = invitationData['companyId'];
        final newRole = invitationData['role'];

        // --- VALIDACIÓN DE LÍMITES ---
        // Super Admin: Max 20 empresas.
        // User/Admin: Max 5 empresas.
        // Nota: Usamos una lógica simple para determinar si es "Super Admin" globalmente:
        // Si tiene al menos una empresa propia, es Super Admin.
        bool isSuperAdmin = user.ownedCompanies.isNotEmpty; 
        int limit = isSuperAdmin ? 20 : 5;

        if (user.companies.length < limit) {
          final batch = _db.batch();
          
          batch.update(userDocRef, {
            'companies.$newCompanyId': newRole,
            'companyIds': FieldValue.arrayUnion([newCompanyId]),
          });
          
          batch.delete(invitationDocRef);
          await batch.commit();
          
          log('Invitación aceptada automáticamente. Nueva empresa agregada.', name: 'FirestoreService');
          
          userDocSnapshot = await userDocRef.get();
          return User.fromFirestore(userDocSnapshot);
        } else {
          log('Límite de empresas alcanzado ($limit). No se procesó la invitación.', name: 'FirestoreService');
        }
      }

      if (authUser.photoURL != null && authUser.photoURL != user.photoUrl) {
         log('Syncing photoUrl from Auth to Firestore...', name: 'FirestoreService');
         await userDocRef.update({'photoUrl': authUser.photoURL});
         // Update the local user object to reflect the change immediately
         user = user.copyWith(photoUrl: authUser.photoURL);
      }

      return user;
    } 
    
    else {
      final emailKey = authUser.email!.trim().toLowerCase();
      final invitationDocRef = _db.collection('invitations').doc(emailKey);
      final invitationDocSnapshot = await invitationDocRef.get();

      if (invitationDocSnapshot.exists) {
        log('Invitación encontrada para usuario NUEVO.', name: 'FirestoreService');
        final invitationData = invitationDocSnapshot.data()!;
        
        final newUserData = {
          'email': authUser.email,
          'name': authUser.displayName ?? '',
          'photoUrl': authUser.photoURL,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'emergencyContact': {},
          
          // Estructura Multi-Empresa
          'companies': {
            invitationData['companyId']: {
              'role': invitationData['role'],
              'name': invitationData['companyName'] ?? 'Empresa Invitada'
            }
          },
          'companyIds': [invitationData['companyId']],
          'ownedCompanies': [],
          'currentCompanyId': invitationData['companyId'],
        };

        final batch = _db.batch();
        batch.set(userDocRef, newUserData);
        batch.delete(invitationDocRef);
        await batch.commit();
        
        userDocSnapshot = await userDocRef.get();
        return User.fromFirestore(userDocSnapshot);

      } else {
        log('Usuario nuevo sin invitación. Creando perfil Super Admin...', name: 'FirestoreService');
        
        final newUserData = {
          'email': authUser.email,
          'name': authUser.displayName ?? 'Nuevo Admin',
          'photoUrl': authUser.photoURL,
          'status': 'pending_company',
          'createdAt': FieldValue.serverTimestamp(),
          'emergencyContact': {},
          
          'companies': {},
          'ownedCompanies': [],
          'currentCompanyId': '',
        };

        await userDocRef.set(newUserData);
        
        userDocSnapshot = await userDocRef.get();
        return User.fromFirestore(userDocSnapshot);
      }
    }
  }

  Future<bool> createCompany({
    required String companyName,
    String? rfc,
    String? businessLine,
  }) async {
    final fbAuth.User? authUser = _auth.currentUser;
    if (authUser == null) return false;

    try {
      // Obtenemos datos actuales del usuario para validar límites
      final userDocRef = _db.collection('users').doc(authUser.uid);
      final userSnapshot = await userDocRef.get();
      final user = User.fromFirestore(userSnapshot);

      // --- VALIDACIÓN DE LÍMITE DE CREACIÓN ---
      if (user.ownedCompanies.length >= 10) {
        log('Error: Límite de empresas creadas alcanzado (10).', name: 'FirestoreService');
        return false; // O lanzar una excepción personalizada
      }

      final companyRef = _db.collection('companies').doc();
      
      final Map<String, dynamic> companyData = {
        'name': companyName,
        'rfc': rfc ?? '',
        'businessLine': businessLine ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': authUser.uid,
      };

      final batch = _db.batch();
      
      // 1. Crear la empresa
      batch.set(companyRef, companyData);
      
      // 2. Actualizar el usuario (Multi-Empresa)
      // Usamos set con merge: true para mayor seguridad si faltan campos
      batch.set(userDocRef, {
        // Agregar a la lista de empresas propias
        'ownedCompanies': FieldValue.arrayUnion([companyRef.id]),
        'companyIds': FieldValue.arrayUnion([companyRef.id]),
        
        // Guardamos rol Y nombre (Merge de mapas anidados)
        'companies': {
           companyRef.id: {
            'role': 'super_admin',
            'name': companyName
           }
        },
        
        // Establecer como activa
        'currentCompanyId': companyRef.id,
        'status': 'active'
      }, SetOptions(merge: true));

      await batch.commit();
      log('Empresa creada y asignada exitosamente.', name: 'FirestoreService');
      return true;
    } catch (e) {
      print('--- DEBUG error al crear la empresa: $e ---');
      log('Error al crear la empresa: $e', name: 'FirestoreService');
      return false;
    }
  }

  Future<bool> inviteUser({
    required String email,
    required String role, 
  }) async {
    try {
      final User? currentUser = await getUserData();
      
      if (currentUser == null || currentUser.companyId.isEmpty) {
        log('Error: No se puede invitar sin estar en una empresa.', name: 'FirestoreService');
        return false;
      }

      final emailKey = email.trim().toLowerCase(); 
      final invitationRef = _db.collection('invitations').doc(emailKey);

      final invitationData = {
        'email': emailKey,
        'companyId': currentUser.companyId, 
        // Guardamos el nombre de la empresa actual para que el invitado lo vea
        'companyName': currentUser.currentCompanyName, 
        'role': role,
        'invitedBy': currentUser.uid, 
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await invitationRef.set(invitationData);
      
      log('Invitación enviada a $emailKey', name: 'FirestoreService');
      return true;

    } catch (e) {
      log('Error al invitar usuario: $e', name: 'FirestoreService');
      return false;
    }
  }

  Future<bool> switchCompany(String newCompanyId) async {
    final fbAuth.User? authUser = _auth.currentUser;
    if (authUser == null) return false;

    try {
      await _db.collection('users').doc(authUser.uid).update({
        'currentCompanyId': newCompanyId,
      });
      log('Cambio de empresa exitoso a: $newCompanyId', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al cambiar de empresa: $e', name: 'FirestoreService');
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final data = {
        'name': user.name,
        'phone': user.phone,
        'photoUrl': user.photoUrl,
        'birthday': user.birthday,
        'gender': user.gender,
        'emergencyContact': user.emergencyContact,
        'department': user.department,
        'position': user.position,
        'contractType': user.contractType,
        'hireDate': user.hireDate,
        'rfc': user.rfc,
        'curp': user.curp,
        'nss': user.nss,
      };

      await _db.collection('users').doc(user.uid).update(data);
      log('Usuario actualizado exitosamente.', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al actualizar usuario: $e', name: 'FirestoreService');
      return false;
    }
  }
  // --- ORGANIZATION MANAGEMENT ---
  Stream<List<User>> getEmployees(String companyId) {
    return _db
        .collection('users')
        .where('companyIds', arrayContains: companyId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Obtener detalles de la empresa (incluyendo deptos y roles)
  Stream<DocumentSnapshot> getCompanyStream(String companyId) {
    return _db.collection('companies').doc(companyId).snapshots();
  }

  Future<void> updateDepartments(String companyId, List<String> departments) async {
    await _db.collection('companies').doc(companyId).update({
      'departments': departments,
    });
  }

  Future<void> updateJobTitles(String companyId, List<String> jobTitles) async {
    await _db.collection('companies').doc(companyId).update({
      'jobTitles': jobTitles,
    });
  }

  // Actualizar perfil laboral de un empleado (solo admins)
  Future<void> updateEmployeeWorkProfile(String userId, String companyId, {
    String? department,
    String? position,
    String? role, // Admin / User role
  }) async {
    Map<String, dynamic> updates = {};
    if (department != null) updates['department'] = department;
    if (position != null) updates['position'] = position;
    
    // Si cambia el rol de sistema (Admin/User), actualizamos el mapa
    if (role != null) {
       updates['companies.$companyId.role'] = role;
    }

  }

  // --- PERFORMANCE EVALUATIONS ---

  Future<void> addEvaluation(Evaluation evaluation) async {
    await _db.collection('evaluations').add(evaluation.toJson());
  }

  Stream<List<Evaluation>> getEmployeeEvaluations(String employeeId) {
    return _db
        .collection('evaluations')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Evaluation.fromFirestore(doc)).toList());
  }

  // --- ATTENDANCE ---
  
  // Registrar asistencia (Check-in / Check-out)
  // Simple version: creates a new document for each event or updates today's doc.
  // We'll use a document per day per user: `attendance/{companyId}/days/{date}/records/{userId}`
  // Simplified: `attendance/{recordId}` with userId, date, checkIn, checkOut
  
  Future<void> logCheckIn(String userId, String companyId) async {
    final now = DateTime.now();
    // Normalizar fecha (sin hora) para buscar si ya existe registro hoy
    final todayStr = "${now.year}-${now.month}-${now.day}"; 
    final recordId = "${userId}_$todayStr";
    
    final docRef = _db.collection('attendance').doc(recordId);
    
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'userId': userId,
        'companyId': companyId,
        'date': todayStr,
        'checkIn': FieldValue.serverTimestamp(),
        'status': 'present', // podria ser 'late' si comparamos con horario
      });
    }
  }

  Future<void> logCheckOut(String userId) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}"; 
    final recordId = "${userId}_$todayStr";
    
    await _db.collection('attendance').doc(recordId).update({
      'checkOut': FieldValue.serverTimestamp(),
    });
  }

  // Obtener asistencia de un usuario
  Stream<List<Map<String, dynamic>>> getUserAttendance(String userId) {
    return _db
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- LEAVE REQUESTS (PERMISOS Y VACACIONES) ---

  // 1. Empleado crea una nueva solicitud
  Future<bool> createLeaveRequest(Map<String, dynamic> requestData) async {
    try {
      await _db.collection('leave_requests').add(requestData);
      log('Solicitud de permiso enviada con éxito.', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al enviar solicitud de permiso: $e', name: 'FirestoreService');
      return false;
    }
  }

  // 2. Obtener solicitudes (Solo filtramos por empresa para evitar pedir Composite Indexes en Firebase)
  Stream<QuerySnapshot> getLeaveRequests(String companyId) {
    return _db.collection('leave_requests').where('companyId', isEqualTo: companyId).snapshots();
  }

  Future<bool> updateLeaveRequestStatus(String requestId, String newStatus) async {
    try {
      await _db.collection('leave_requests').doc(requestId).update({
        'status': newStatus,
      });
      log('Estado de la solicitud actualizado a: $newStatus', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al actualizar estado del permiso: $e', name: 'FirestoreService');
      return false;
    }
  }

  // --- EVENTS (EVENTOS Y COMUNICADOS) ---

  // 1. Crear un nuevo evento (Solo Admin/SuperAdmin)
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      await _db.collection('events').add(eventData);
      log('Evento creado con éxito.', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al crear evento: $e', name: 'FirestoreService');
      return false;
    }
  }

  // 2. Obtener los eventos de la empresa
  Stream<QuerySnapshot> getEvents(String companyId) {
    // Nota: Por ahora NO usamos orderBy para no requerir un índice compuesto en Firebase de inmediato.
    return _db
        .collection('events')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  // 3. Editar un evento (Solo Admin/SuperAdmin)
  Future<bool> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      await _db.collection('events').doc(eventId).update(eventData);
      log('Evento actualizado con éxito.', name: 'FirestoreService');
      return true;
    } catch (e) {
      log('Error al actualizar evento: $e', name: 'FirestoreService');
      return false;
    }
  }

  // --- NOTIFICACIONES ---

  Future<bool> createNotification(Map<String, dynamic> notifData) async {
    try {
      await _db.collection('notifications').add(notifData);
      return true;
    } catch (e) {
      log('Error al crear notificación: $e', name: 'FirestoreService');
      return false;
    }
  }

  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({'isRead': true});
    } catch (e) {
      log('Error al actualizar notificación: $e', name: 'FirestoreService');
    }
  }

  // Notificar a todos los empleados de una empresa (Ej: Nuevo Evento)
  Future<void> notifyCompanyUsers(String companyId, Map<String, dynamic> notificationBase) async {
    try {
      final usersSnap = await _db.collection('users').where('companyIds', arrayContains: companyId).get();
      final batch = _db.batch();

      for (var doc in usersSnap.docs) {
        // No notificamos al mismo creador si es necesario, pero para eventos está bien que le salga.
        final notifRef = _db.collection('notifications').doc();
        final notifData = Map<String, dynamic>.from(notificationBase);
        notifData['userId'] = doc.id; // Asignamos la alerta a cada empleado
        batch.set(notifRef, notifData);
      }

      await batch.commit();
      log('Notificaciones de evento enviadas a ${usersSnap.docs.length} usuarios.', name: 'FirestoreService');
    } catch (e) {
      log('Error al enviar notificaciones masivas: $e', name: 'FirestoreService');
    }
  }

  // Notificar a los admins cuando alguien pide un permiso
  Future<void> notifyAdmins(String companyId, Map<String, dynamic> notificationBase) async {
    try {
      final usersSnap = await _db.collection('users').where('companyIds', arrayContains: companyId).get();
      final batch = _db.batch();
      
      int adminsNotified = 0;
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        final companies = data['companies'] as Map<String, dynamic>? ?? {};
        final userCompanyData = companies[companyId] as Map<String, dynamic>?;
        
        if (userCompanyData != null) {
          final role = userCompanyData['role'];
          if (role == 'admin' || role == 'super_admin') {
            final notifRef = _db.collection('notifications').doc();
            final notifData = Map<String, dynamic>.from(notificationBase);
            notifData['userId'] = doc.id;
            batch.set(notifRef, notifData);
            adminsNotified++;
          }
        }
      }

      if (adminsNotified > 0) {
        await batch.commit();
        log('Notificación enviada a $adminsNotified admins.', name: 'FirestoreService');
      }
    } catch (e) {
      log('Error al notificar admins: $e', name: 'FirestoreService');
    }
  }
}