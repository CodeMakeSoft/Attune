import 'package:cloud_firestore/cloud_firestore.dart';

class Evaluation {
  final String id;
  final String employeeId;
  final String employeeName; // Guardamos el nombre para facilitar vistas rápidas
  final String evaluatorId;
  final String evaluatorName;
  final String companyId;
  final DateTime date;
  final Map<String, int> scores; // e.g., {'Responsabilidad': 5, 'Trabajo en equipo': 4}
  final double overallAverage;
  final String feedback;
  final int weekOfYear;
  final int year;

  Evaluation({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.companyId,
    required this.date,
    required this.scores,
    required this.overallAverage,
    required this.feedback,
    required this.weekOfYear,
    required this.year,
  });

  factory Evaluation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Evaluation(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      evaluatorId: data['evaluatorId'] ?? '',
      evaluatorName: data['evaluatorName'] ?? '',
      companyId: data['companyId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      overallAverage: (data['overallAverage'] ?? 0).toDouble(),
      feedback: data['feedback'] ?? '',
      weekOfYear: data['weekOfYear'] ?? 0,
      year: data['year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'evaluatorId': evaluatorId,
      'evaluatorName': evaluatorName,
      'companyId': companyId,
      'date': Timestamp.fromDate(date),
      'scores': scores,
      'overallAverage': overallAverage,
      'feedback': feedback,
      'weekOfYear': weekOfYear,
      'year': year,
    };
  }
}
