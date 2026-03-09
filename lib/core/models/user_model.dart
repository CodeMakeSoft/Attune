import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  // Autentication data
  final String uid;
  final String email;
  
  // Multi-Company Architecture
  // Clave: companyId
  // Valor: { 'role': 'admin', 'name': 'Tech Solutions', 'assignedBenefits': [...] }
  final Map<String, dynamic> companies; 
  
  final List<String> ownedCompanies;
  final String currentCompanyId;
  
  final String status;
  final Timestamp createdAt;

  // Personal data
  final String name;
  final String? phone;
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
    
    if (companyData is String) return companyData;
    if (companyData is Map) return companyData['role'] ?? 'user';
    
    return 'user';
  }
  
  String get currentCompanyName {
    if (currentCompanyId.isEmpty) return '';
    final companyData = companies[currentCompanyId];
    if (companyData is Map) return companyData['name'] ?? '';
    return '';
  }

  List<String> get assignedBenefits {
    if (currentCompanyId.isEmpty) return [];
    final companyData = companies[currentCompanyId];
    if (companyData is Map) {
      return List<String>.from(companyData['assignedBenefits'] ?? []);
    }
    return [];
  }

  const User({
    required this.uid,
    required this.email,
    required this.companies,
    required this.companyIds,
    required this.ownedCompanies,
    required this.currentCompanyId,
    required this.status,
    required this.createdAt,
    required this.name,
    this.phone,
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
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper para manejar listas de forma segura
    List<String> safeList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    // Helper para manejar Timestamps de forma segura
    Timestamp? safeTimestamp(dynamic val) {
      if (val is Timestamp) return val;
      if (val is Map && val['_seconds'] != null) {
        return Timestamp(val['_seconds'], val['_nanoseconds'] ?? 0);
      }
      return null;
    }

    Map<String, dynamic> companiesMap = {};
    if (data['companies'] != null && data['companies'] is Map) {
      companiesMap = Map<String, dynamic>.from(data['companies']);
    } else if (data['companyId'] != null) {
      companiesMap[data['companyId'].toString()] = {
        'role': data['role']?.toString() ?? 'user',
        'name': 'Empresa'
      };
    }

    final companyIdsList = data['companyIds'] != null 
        ? safeList(data['companyIds']) 
        : companiesMap.keys.toList();

    return User(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      companies: companiesMap,
      companyIds: companyIdsList,
      ownedCompanies: safeList(data['ownedCompanies']),
      currentCompanyId: data['currentCompanyId']?.toString() ?? (companiesMap.isNotEmpty ? companiesMap.keys.first : ''),
      status: data['status']?.toString() ?? 'pending',
      createdAt: safeTimestamp(data['createdAt']) ?? Timestamp.now(),
      name: data['name']?.toString() ?? 'Sin Nombre',
      phone: data['phone']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      birthday: safeTimestamp(data['birthday']),
      gender: data['gender']?.toString(),
      emergencyContact: data['emergencyContact'] is Map 
          ? Map<String, String>.from((data['emergencyContact'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
          : {},
      department: data['department']?.toString(),
      position: data['position']?.toString(),
      contractType: data['contractType']?.toString(),
      hireDate: safeTimestamp(data['hireDate']),
      rfc: data['rfc']?.toString(),
      curp: data['curp']?.toString(),
      nss: data['nss']?.toString(),
    );
  }

  User copyWith({
    String? name,
    String? phone,
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
      phone: phone ?? this.phone,
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