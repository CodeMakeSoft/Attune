import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String companyId;
  final String name;
  final String? rfc;
  final String? businessLine;
  final Timestamp createdAt;
  final String ownerUid; // El UID del Super Admin que la creó

  const Company({
    required this.companyId,
    required this.name,
    this.rfc,
    this.businessLine,
    required this.createdAt,
    required this.ownerUid,
  });

  // Método para crear el mapa para Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rfc': rfc,
      'businessLine': businessLine,
      'createdAt': createdAt,
      'ownerUid': ownerUid,
    };
  }
}