import 'package:attune/core/models/user_model.dart' as model;
import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:attune/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final model.User currentUser;
  const AttendanceScreen({super.key, required this.currentUser});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userId = widget.currentUser.uid;
    final companyId = widget.currentUser.companyId;

    return StreamBuilder<DocumentSnapshot?>(
      stream: _firestoreService.getTodayAttendanceStream(userId),
      builder: (context, snapshot) {
        final attendanceData = snapshot.data?.data() as Map<String, dynamic>?;
        final bool hasCheckIn = attendanceData?['checkIn'] != null;
        final bool hasCheckOut = attendanceData?['checkOut'] != null;
        
        // Estado actual: 0 = No ha entrado, 1 = Trabajando, 2 = Completado
        int status = 0;
        if (hasCheckIn && !hasCheckOut) status = 1;
        if (hasCheckIn && hasCheckOut) status = 2;

        return Column(
          children: [
            _buildHeader(status, attendanceData),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildPunchButton(status, userId, companyId),
                    const SizedBox(height: 40),
                    _buildInfoCards(attendanceData),
                    const SizedBox(height: 30),
                    _buildHistorySection(userId),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int status, Map<String, dynamic>? data) {
    Color statusColor = Colors.grey;
    String statusText = "Sin Registro";
    
    if (status == 1) {
      statusColor = Colors.greenAccent;
      statusText = "Turno Activo";
    } else if (status == 2) {
      statusColor = Colors.orangeAccent;
      statusText = "Jornada Finalizada";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const DigitalClockWidget(),
          if (status == 1) ...[
             const SizedBox(height: 12),
             _buildTimer(data?['checkIn']),
          ],
        ],
      ),
    );
  }

  Widget _buildTimer(dynamic checkIn) {
    if (checkIn == null || checkIn is! Timestamp) return const SizedBox();
    
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final duration = DateTime.now().difference(checkIn.toDate());
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        return Text(
          "Tiempo transcurrido: $hours:$minutes:$seconds",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        );
      },
    );
  }

  Widget _buildPunchButton(int status, String userId, String companyId) {
    bool isCompleted = status == 2;
    bool isWorking = status == 1;

    return GestureDetector(
      onTap: isCompleted || _isLoading ? null : () => _handleAction(status, userId, companyId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? Colors.grey[200] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (isWorking ? Colors.red : AppColors.accentPrimary).withOpacity(isCompleted ? 0.05 : 0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isWorking ? Colors.red.withOpacity(0.2) : AppColors.accentPrimary.withOpacity(0.1),
            width: 8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWorking ? Icons.exit_to_app : Icons.fingerprint,
              color: isCompleted ? Colors.grey : (isWorking ? Colors.red : AppColors.accentPrimary),
              size: 70,
            ),
            const SizedBox(height: 12),
            Text(
              isWorking ? "MARCAR SALIDA" : (isCompleted ? "PUESTO CERRADO" : "MARCAR ENTRADA"),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCompleted ? Colors.grey : (isWorking ? Colors.red : AppColors.accentPrimary),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(Map<String, dynamic>? data) {
    final checkIn = data?['checkIn'] as Timestamp?;
    final checkOut = data?['checkOut'] as Timestamp?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _infoTile("Entrada", checkIn != null ? DateFormat.Hm().format(checkIn.toDate()) : "--:--", Icons.login, Colors.green),
          const SizedBox(width: 16),
          _infoTile("Salida", checkOut != null ? DateFormat.Hm().format(checkOut.toDate()) : "--:--", Icons.logout, Colors.orange),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "HISTORIAL RECIENTE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getUserAttendance(userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final logs = snapshot.data!;
              if (logs.isEmpty) return const Center(child: Text("Sin registros previos"));

              return Column(
                children: logs.map((log) => _buildHistoryItem(log)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> log) {
    final checkIn = log['checkIn'] as Timestamp?;
    final checkOut = log['checkOut'] as Timestamp?;
    final dateStr = log['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(
                      checkOut != null ? "Completado" : "Solo entrada",
                      style: TextStyle(color: checkOut != null ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (checkIn != null) ...[
                      const SizedBox(width: 8),
                      Text(
                         (checkIn.toDate().hour < 9 || (checkIn.toDate().hour == 9 && checkIn.toDate().minute <= 10)) 
                         ? "• Puntual" : "• Retraso",
                         style: TextStyle(
                           color: (checkIn.toDate().hour < 9 || (checkIn.toDate().hour == 9 && checkIn.toDate().minute <= 10)) 
                           ? Colors.blue : Colors.red, 
                           fontSize: 11, 
                           fontWeight: FontWeight.bold
                         ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(checkIn != null ? DateFormat.Hm().format(checkIn.toDate()) : "--", style: const TextStyle(fontSize: 13)),
              Text(checkOut != null ? DateFormat.Hm().format(checkOut.toDate()) : "--", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(int status, String userId, String companyId) async {
    if (companyId.isEmpty) {
      _showError("No tienes una empresa asignada. Contacta a soporte.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (status == 0) {
        await _firestoreService.logCheckIn(userId, companyId);
        _showSuccess("¡Entrada registrada!");
      } else if (status == 1) {
        await _firestoreService.logCheckOut(userId);
        _showSuccess("¡Salida registrada!");
      }
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ $msg"), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $msg"), backgroundColor: Colors.red));
  }
}

class DigitalClockWidget extends StatefulWidget {
  const DigitalClockWidget({super.key});

  @override
  State<DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w200,
            fontFamily: 'Courier', 
          ),
        ),
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
