import 'package:attune/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/evaluation_model.dart';
import 'package:attune/core/services/firestore_service.dart';

class EvaluationFormScreen extends StatefulWidget {
  final User employee;
  final User evaluator;

  const EvaluationFormScreen({
    super.key,
    required this.employee,
    required this.evaluator,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  bool _alreadyEvaluated = false;
  
  @override
  void initState() {
    super.initState();
    _checkEvaluationStatus();
  }

  Future<void> _checkEvaluationStatus() async {
    DateTime now = DateTime.now();
    int year = now.year;
    int weekOfYear = ((now.difference(DateTime(year, 1, 1)).inDays) / 7).ceil() + 1;
    
    bool hasEvaluated = await FirestoreService().hasEvaluatedThisWeek(widget.employee.uid, weekOfYear, year);
    if (mounted) {
      setState(() {
        _alreadyEvaluated = hasEvaluated;
        _isCheckingStatus = false;
      });
    }
  }

  final Map<String, int> _scores = {
    'Responsabilidad': 0,
    'Calidad de Trabajo': 0,
    'Trabajo en Equipo': 0,
    'Puntualidad': 0,
    'Iniciativa': 0,
  };

  final Map<String, IconData> _metricIcons = {
    'Responsabilidad': Icons.assignment_turned_in_rounded,
    'Calidad de Trabajo': Icons.high_quality_rounded,
    'Trabajo en Equipo': Icons.groups_rounded,
    'Puntualidad': Icons.update_rounded,
    'Iniciativa': Icons.lightbulb_outline_rounded,
  };

  final _feedbackController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_scores.values.any((s) => s == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor califica todos los aspectos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double sum = _scores.values.fold(0, (prev, element) => prev + element);
      double average = sum / _scores.length;

      DateTime now = DateTime.now();
      int year = now.year;
      int weekOfYear = ((now.difference(DateTime(year, 1, 1)).inDays) / 7).ceil() + 1;

      final evaluation = Evaluation(
        id: '',
        employeeId: widget.employee.uid,
        employeeName: widget.employee.name,
        evaluatorId: widget.evaluator.uid,
        evaluatorName: widget.evaluator.name,
        companyId: widget.employee.companyId,
        date: now,
        scores: _scores,
        overallAverage: average,
        feedback: _feedbackController.text.trim(),
        weekOfYear: weekOfYear,
        year: year,
      );

      await FirestoreService().addEvaluation(evaluation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Evaluación guardada correctamente.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMetricTile(String metric) {
    int currentScore = _scores[metric] ?? 0;
    IconData icon = _metricIcons[metric] ?? Icons.star_rounded;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                metric, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              bool isSelected = index < currentScore;
              return GestureDetector(
                onTap: () => setState(() => _scores[metric] = index + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentPrimary.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber[700] : Colors.grey[300],
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Realizar Evaluación'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isCheckingStatus 
          ? const Center(child: CircularProgressIndicator())
          : _alreadyEvaluated
              ? _buildAlreadyEvaluatedState()
              : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header con info del empleado mejorada
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, const Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: widget.employee.photoUrl != null
                        ? NetworkImage(widget.employee.photoUrl!)
                        : null,
                    child: widget.employee.photoUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employee.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          widget.employee.position ?? 'Sin puesto',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              "Indicadores de Desempeño",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._scores.keys.map((metric) => _buildMetricTile(metric)),

            const SizedBox(height: 16),
            
            const Text(
              "Observaciones Finales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Escribe aquí tus comentarios sobre el desempeño del colaborador...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (val) => val == null || val.isEmpty ? 'Por favor ingresa un comentario' : null,
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Finalizar Evaluación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyEvaluatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Evaluación Completa',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ya realizaste la evaluación de ${widget.employee.name.split(' ')[0]} para esta semana.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver al equipo'),
            ),
          ],
        ),
      ),
    );
  }
}
