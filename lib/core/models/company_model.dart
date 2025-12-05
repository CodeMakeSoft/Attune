import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String companyId;
  final String name;
  final String? rfc;
  final String? businessLine;
  final Timestamp createdAt;
  final String ownerUid; // El UID del Super Admin que la creó
  
  // Listas de configuración
  final List<String> departments;
  final List<String> jobTitles; // Roles de empresa (Puestos)

  const Company({
    required this.companyId,
    required this.name,
    this.rfc,
    this.businessLine,
    required this.createdAt,
    required this.ownerUid,
    this.departments = const [],
    this.jobTitles = const [],
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Company(
      companyId: doc.id,
      name: data['name'] ?? '',
      rfc: data['rfc'],
      businessLine: data['businessLine'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      ownerUid: data['ownerUid'] ?? '',
      departments: List<String>.from(data['departments'] ?? []),
      jobTitles: List<String>.from(data['jobTitles'] ?? []),
    );
  }

  // Método para crear el mapa para Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rfc': rfc,
      'businessLine': businessLine,
      'createdAt': createdAt,
      'ownerUid': ownerUid,
      'departments': departments,
      'jobTitles': jobTitles,
    };
  }
}