import 'package:attune/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:attune/core/models/company_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  final String companyId;
  const ScheduleScreen({super.key, required this.companyId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    if (widget.companyId.isEmpty) {
       return const LoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text("Gestión de Horarios"),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getCompanyStream(widget.companyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final company = Company.fromFirestore(snapshot.data!);
          return _buildScheduleEditor(context, company);
        },
      ),
    );
  }

  Widget _buildScheduleEditor(BuildContext context, Company company) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Horario de Trabajo", "Configura la hora de entrada y salida base para el control de asistencia."),
          const SizedBox(height: 24),
          _buildTimeTile(
            context,
            title: "Hora de Entrada",
            subtitle: "Los empleados que marquen después de esta hora aparecerán con retraso.",
            time: company.workStartTime,
            icon: Icons.login_rounded,
            color: Colors.green,
            onTap: () => _selectTime(context, company.workStartTime, (newTime) {
              _firestoreService.updateCompanySchedule(widget.companyId, newTime, company.workEndTime);
            }),
          ),
          const SizedBox(height: 16),
          _buildTimeTile(
            context,
            title: "Hora de Salida",
            subtitle: "Hora estándar de finalización de jornada.",
            time: company.workEndTime,
            icon: Icons.logout_rounded,
            color: Colors.orange,
            onTap: () => _selectTime(context, company.workEndTime, (newTime) {
              _firestoreService.updateCompanySchedule(widget.companyId, company.workStartTime, newTime);
            }),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "El sistema permite un margen de 10 minutos de tolerancia después de la hora de entrada.",
                    style: TextStyle(color: Colors.blue[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeTile(BuildContext context, {
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.accentPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String currentTime, Function(String) onConfirm) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      final String formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      onConfirm(formatted);
    }
  }
}
