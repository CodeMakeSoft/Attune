import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String companyId;
  final String name;
  final String? rfc;
  final String? businessLine;
  final Timestamp createdAt;
  final String ownerUid; // El UID del Super Admin que la creó
  
  // Configuraciones
  final List<String> departments;
  final List<String> jobTitles;
  final List<Map<String, dynamic>> benefits;
  final String workStartTime; // HH:mm
  final String workEndTime;   // HH:mm

  const Company({
    required this.companyId,
    required this.name,
    this.rfc,
    this.businessLine,
    required this.createdAt,
    required this.ownerUid,
    this.departments = const [],
    this.jobTitles = const [],
    this.benefits = const [],
    this.workStartTime = '09:00',
    this.workEndTime = '18:00',
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
      benefits: List<Map<String, dynamic>>.from(data['benefits'] ?? []),
      workStartTime: data['workStartTime'] ?? '09:00',
      workEndTime: data['workEndTime'] ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rfc': rfc,
      'businessLine': businessLine,
      'createdAt': createdAt,
      'ownerUid': ownerUid,
      'departments': departments,
      'jobTitles': jobTitles,
      'benefits': benefits,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
    };
  }
}