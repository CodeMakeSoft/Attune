import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/evaluation_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  
  // Métricas estándar (pueden venir de config en el futuro)
  final Map<String, int> _scores = {
    'Responsabilidad': 0,
    'Calidad de Trabajo': 0,
    'Trabajo en Equipo': 0,
    'Puntualidad': 0,
    'Iniciativa': 0,
  };

  final _feedbackController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar que se hayan calificado todos los puntos (opcional, o asumir 0)
    if (_scores.values.any((s) => s == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor califica todos los aspectos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calcular promedio
      double sum = _scores.values.fold(0, (prev, element) => prev + element);
      double average = sum / _scores.length;

      final evaluation = Evaluation(
        id: '', // Firestore generará el ID
        employeeId: widget.employee.uid,
        employeeName: widget.employee.name,
        evaluatorId: widget.evaluator.uid,
        evaluatorName: widget.evaluator.name,
        companyId: widget.employee.companyId, // Asumimos misma empresa
        date: DateTime.now(),
        scores: _scores,
        overallAverage: average,
        feedback: _feedbackController.text.trim(),
      );

      await FirestoreService().addEvaluation(evaluation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación guardada correctamente.')),
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

  Widget _buildStarRating(String metric) {
    int currentScore = _scores[metric] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metric, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentScore ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  _scores[metric] = index + 1;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluar Desempeño')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabecera Empleado
            ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.employee.photoUrl != null
                    ? NetworkImage(widget.employee.photoUrl!)
                    : null,
                child: widget.employee.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(widget.employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.employee.position ?? 'Sin puesto'),
            ),
            const Divider(height: 30),
            
            const Text(
              "Califica los siguientes aspectos:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._scores.keys.map((metric) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildStarRating(metric),
            )),

            const SizedBox(height: 20),
            
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Comentarios / Feedback',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Guardar Evaluación"),
            ),
          ],
        ),
      ),
    );
  }
}
