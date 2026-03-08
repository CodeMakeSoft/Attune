import 'package:flutter/material.dart';
import 'package:attune/core/models/evaluation_model.dart';
import 'package:attune/core/services/firestore_service.dart';
// Import User model if needed
import 'package:intl/intl.dart';

class UserPerformanceScreen extends StatelessWidget {
  final String userId;
  final bool isReadOnly; // Para que un admin vea el desempeño de un empleado

  const UserPerformanceScreen({
    super.key,
    required this.userId,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Desempeño')),
      body: StreamBuilder<List<Evaluation>>(
        stream: FirestoreService().getEmployeeEvaluations(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}"),
            ));
          }
          
          final evaluations = snapshot.data ?? [];

          if (evaluations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Aún no tienes evaluaciones registradas."),
                ],
              ),
            );
          }

          // Calcular promedio general de todas
          final totalAvg = evaluations.fold(0.0, (sum, e) => sum + e.overallAverage) / evaluations.length;

          return Column(
            children: [
              // Resumen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      totalAvg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Text("Promedio General", style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("${evaluations.length} Evaluaciones"),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: evaluations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final eval = evaluations[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForScore(eval.overallAverage),
                          child: Text(
                            eval.overallAverage.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(DateFormat.yMMMd('es').format(eval.date)),
                        subtitle: Text("Evaluador: ${eval.evaluatorName}"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...eval.scores.entries.map((e) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < e.value ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      )),
                                    )
                                  ],
                                )),
                                const Divider(height: 24),
                                const Text("Feedback:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(eval.feedback),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.blue;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }
}
