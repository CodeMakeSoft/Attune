import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String companyId;
  final String type;
  final String reason;
  final DateTime startDate; 
  final DateTime endDate;  
  final String status;        // 'pending', 'approved', 'rejected'
  final DateTime createdAt;   

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.companyId,
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.status = 'pending',
    required this.createdAt,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> data, String documentId) {
    return LeaveRequest(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Desconocido',
      companyId: data['companyId'] ?? '',
      type: data['type'] ?? 'otro',
      reason: data['reason'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'companyId': companyId,
      'type': type,
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
