import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  // Autentication data
  final String uid;
  final String email;
  final String companyId;
  final String role;
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

  const User({
    required this.uid,
    required this.email,
    required this.companyId,
    required this.role,
    required this.status,
    required this.createdAt,
    // Editables
    required this.name,
    this.photoUrl,
    this.birthday,
    this.gender,
    required this.emergencyContact,
    // Admin
    this.department,
    this.position,
    this.contractType,
    this.hireDate,
    // Legal
    this.rfc,
    this.curp,
    this.nss,
  });

  // Firestone constructor
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      companyId: data['companyId'] ?? '',
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),

      // Info Personal
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      birthday: data['birthday'],
      gender: data['gender'],
      // Hacemos un 'cast' seguro del mapa
      emergencyContact: Map<String, String>.from(data['emergencyContact'] ?? {}),

      // Info Laboral
      department: data['department'],
      position: data['position'],
      contractType: data['contractType'],
      hireDate: data['hireDate'],

      // Info Legal
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
  }) {
    return User(
      // --- Grupo 1 (SIN 'this.') ---
      // 'this.' es innecesario porque no hay ambigüedad
      uid: uid,
      email: email,
      companyId: companyId,
      role: role,
      status: status,
      createdAt: createdAt,
      
      // --- Grupo 2 (CON 'this.') ---
      // 'this.' ES OBLIGATORIO para diferenciar
      // el parámetro 'name' del miembro de la clase 'this.name'
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,

      // --- Grupo 1 (SIN 'this.') ---
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