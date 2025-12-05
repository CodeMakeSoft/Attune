import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  // Autentication data
  final String uid;
  final String email;
  
  // Multi-Company Architecture
  // Clave: companyId
  // Valor: { 'role': 'admin', 'name': 'Tech Solutions' }
  final Map<String, dynamic> companies; 
  
  final List<String> ownedCompanies;
  final String currentCompanyId;
  
  final String status;
  final Timestamp createdAt;

  // Personal data
  final String name;
  final String? photoUrl;
  final Timestamp? birthday;
  final String? gender;
  final Map<String, String> emergencyContact;

  // Job data
  final String? department;
  final String? position;
  final String? contractType;
  final Timestamp? hireDate;

  // Legal data
  final String? rfc;
  final String? curp;
  final String? nss;

  // Helper for efficient querying
  final List<String> companyIds;

  // --- Getters de Compatibilidad ---
  String get companyId => currentCompanyId;
  
  String get role {
    if (currentCompanyId.isEmpty) return 'user';
    
    final companyData = companies[currentCompanyId];
    if (companyData == null) return 'user';
    
    // Soporte híbrido: Si es String (viejo) o Map (nuevo)
    if (companyData is String) return companyData;
    if (companyData is Map) return companyData['role'] ?? 'user';
    
    return 'user';
  }
  
  // Nuevo getter para obtener el nombre de la empresa actual
  String get currentCompanyName {
    if (currentCompanyId.isEmpty) return '';
    final companyData = companies[currentCompanyId];
    if (companyData is Map) return companyData['name'] ?? '';
    return '';
  }

  const User({
    required this.uid,
    required this.email,
    required this.companies,
    required this.companyIds, // Changed
    required this.ownedCompanies,
    required this.currentCompanyId,
    required this.status,
    required this.createdAt,
    required this.name,
    this.photoUrl,
    this.birthday,
    this.gender,
    required this.emergencyContact,
    this.department,
    this.position,
    this.contractType,
    this.hireDate,
    this.rfc,
    this.curp,
    this.nss,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Manejo robusto del mapa de compañías
    Map<String, dynamic> companiesMap = {};
    
    if (data['companies'] != null) {
      companiesMap = Map<String, dynamic>.from(data['companies']);
    } else if (data['companyId'] != null && data['companyId'].toString().isNotEmpty) {
      // Migración legacy
      companiesMap[data['companyId']] = {
        'role': data['role'] ?? 'user',
        'name': 'Empresa (Sin nombre)' // Placeholder para datos viejos
      };
    }

    List<String> ownedList = [];
    if (data['ownedCompanies'] != null) {
      ownedList = List<String>.from(data['ownedCompanies']);
    }

    // Helper list companyIds
    List<String> companyIdsList = [];
    if (data['companyIds'] != null) {
      companyIdsList = List<String>.from(data['companyIds']);
    } else {
      // Fallback: generate from companies map keys if missing
      companyIdsList = companiesMap.keys.toList();
    }

    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      
      companies: companiesMap,
      companyIds: companyIdsList,
      ownedCompanies: ownedList,
      currentCompanyId: data['currentCompanyId'] ?? (companiesMap.isNotEmpty ? companiesMap.keys.first : ''),
      
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),

      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      birthday: data['birthday'],
      gender: data['gender'],
      emergencyContact: Map<String, String>.from(data['emergencyContact'] ?? {}),

      department: data['department'],
      position: data['position'],
      contractType: data['contractType'],
      hireDate: data['hireDate'],

      rfc: data['rfc'],
      curp: data['curp'],
      nss: data['nss'],
    );
  }

  User copyWith({
    String? name,
    String? photoUrl,
    Timestamp? birthday,
    String? gender,
    Map<String, String>? emergencyContact,
    String? currentCompanyId,
    List<String>? companyIds,
    Map<String, dynamic>? companies,
  }) {
    return User(
      uid: uid,
      email: email,
      companies: companies ?? this.companies,
      companyIds: companyIds ?? this.companyIds,
      ownedCompanies: ownedCompanies,
      currentCompanyId: currentCompanyId ?? this.currentCompanyId,
      status: status,
      createdAt: createdAt,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      department: department,
      position: position,
      contractType: contractType,
      hireDate: hireDate,
      rfc: rfc,
      curp: curp,
      nss: nss,
    );
  }
}