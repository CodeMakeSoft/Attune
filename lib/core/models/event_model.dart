import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String companyId;
  final String createdBy; 
  final DateTime createdAt;

  CompanyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.companyId,
    required this.createdBy,
    required this.createdAt,
  });

  factory CompanyEvent.fromMap(Map<String, dynamic> data, String documentId) {
    return CompanyEvent(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      companyId: data['companyId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'companyId': companyId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
