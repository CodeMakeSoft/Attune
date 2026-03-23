import 'package:attune/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:attune/core/models/evaluation_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const StatisticsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Desempeño: ${employeeName.split(' ')[0]}'),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Evaluation>>(
        stream: FirestoreService().getEmployeeEvaluations(employeeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final evaluations = snapshot.data ?? [];
          
          if (evaluations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Sin Evaluaciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Aún no hay datos de desempeño registrados para generar estadísticas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Invertimos porque Firestore nos las trae de más nueva a más vieja
          // y queremos graficarlas de izquierda (vieja) a derecha (nueva).
          final sortedEvals = List<Evaluation>.from(evaluations).reversed.toList();
          final lastEval = evaluations.first;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSummaryCard(lastEval),
              const SizedBox(height: 32),
              
              const Text('Evolución (Últimas Semanas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildEvolutionChart(sortedEvals),
              
              const SizedBox(height: 32),
              const Text('Desglose de Última Evaluación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildScoreBreakdown(lastEval),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Evaluation lastEval) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentPrimary, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Promedio Actual', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lastEval.overallAverage.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(' / 5.0', style: TextStyle(fontSize: 20, color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Eval. de la Semana ${lastEval.weekOfYear}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(List<Evaluation> evals) {
    // Si solo hay una evaluación, el gráfico lineal necesitaría al menos dos puntos idealmente,
    // pero fl_chart la dibuja en X=0. Vamos a preparar la data.
    
    // Tomamos máximo las últimas 10 para no saturar 
    final chartEvals = evals.length > 10 ? evals.sublist(evals.length - 10) : evals;
    
    List<FlSpot> spots = [];
    for (int i = 0; i < chartEvals.length; i++) {
        spots.add(FlSpot(i.toDouble(), chartEvals[i].overallAverage));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < chartEvals.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('S${chartEvals[idx].weekOfYear}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (chartEvals.length - 1).toDouble().clamp(1.0, double.infinity),
          minY: 0,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accentPrimary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accentPrimary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(Evaluation evaluation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: evaluation.scores.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: entry.value / 5.0,
                      backgroundColor: Colors.grey[200],
                      color: _getColorForScore(entry.value),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForScore(int score) {
    if (score >= 4) return Colors.green;
    if (score == 3) return Colors.orange;
    return Colors.red;
  }
}
