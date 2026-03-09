import 'package:attune/core/models/user_model.dart' as model;
import 'package:attune/core/models/company_model.dart';
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

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.currentUser.uid;
    final companyId = widget.currentUser.companyId;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getCompanyStream(companyId),
      builder: (context, companySnapshot) {
        if (!companySnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final company = Company.fromFirestore(companySnapshot.data!);
        
        return StreamBuilder<DocumentSnapshot?>(
          stream: _firestoreService.getTodayAttendanceStream(userId),
          builder: (context, snapshot) {
            final attendanceData = snapshot.data?.data() as Map<String, dynamic>?;
            final bool hasCheckIn = attendanceData?['checkIn'] != null;
            final bool hasCheckOut = attendanceData?['checkOut'] != null;
            
            // Estado: 0 = No entró, 1 = Trabajando, 2 = Salió
            int status = 0;
            if (hasCheckIn && !hasCheckOut) status = 1;
            if (hasCheckIn && hasCheckOut) status = 2;

            return Scaffold(
              backgroundColor: AppColors.backgroundPrimary,
              body: Column(
                children: [
                  _buildHeader(status, attendanceData),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            _buildPunchButton(status, userId, companyId),
                            const SizedBox(height: 40),
                            _buildStatusCards(attendanceData),
                            const SizedBox(height: 48),
                            _buildHistorySection(userId, company.workStartTime),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildHeader(int status, Map<String, dynamic>? data) {
    Color statusColor = AppColors.contentSecondary;
    String statusTitle = "Jornada no iniciada";
    
    if (status == 1) {
      statusColor = Colors.greenAccent;
      statusTitle = "Trabajando ahora";
    } else if (status == 2) {
      statusColor = AppColors.stateWarning;
      statusTitle = "Jornada finalizada";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPrimary, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  statusTitle.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const DigitalClockWidget(),
          if (status == 1) ...[
            const SizedBox(height: 16),
             _buildLiveTimer(data?['checkIn']),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveTimer(dynamic checkIn) {
    if (checkIn == null || checkIn is! Timestamp) return const SizedBox();
    
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final duration = DateTime.now().difference(checkIn.toDate());
        final h = duration.inHours.toString().padLeft(2, '0');
        final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Tiempo activo: $h:$m:$s",
            style: const TextStyle(
              color: Colors.white70, 
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  Widget _buildPunchButton(int status, String userId, String companyId) {
    bool isWorking = status == 1;
    bool isCompleted = status == 2;
    
    return Center(
      child: GestureDetector(
        onTap: isCompleted || _isLoading ? null : () => _handleAction(status, userId, companyId),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            double pulse = isWorking ? (1.0 + (_pulseController.value * 0.05)) : 1.0;
            return Transform.scale(
              scale: pulse,
              child: child,
            );
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.grey[200] : AppColors.backgroundSurface,
              boxShadow: [
                BoxShadow(
                  color: (isWorking ? Colors.red : AppColors.accentPrimary).withOpacity(isCompleted ? 0.05 : 0.15),
                  blurRadius: 30,
                  spreadRadius: 10,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bordes decorativos
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isWorking ? Colors.red : AppColors.accentPrimary).withOpacity(0.05),
                      width: 2,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isWorking ? Icons.logout_rounded : Icons.fingerprint_rounded,
                      color: isCompleted ? Colors.grey : (isWorking ? AppColors.stateError : AppColors.accentPrimary),
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isWorking ? "SALIDA" : (isCompleted ? "PUESTO" : "ENTRADA"),
                      style: TextStyle(
                        color: isCompleted ? Colors.grey : (isWorking ? Colors.red : AppColors.accentPrimary),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      isCompleted ? "TERMINADO" : "PULSAR AQUÍ",
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards(Map<String, dynamic>? data) {
    final checkIn = data?['checkIn'] as Timestamp?;
    final checkOut = data?['checkOut'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statusTile("Entrada", checkIn, Icons.login_rounded, Colors.green),
          const SizedBox(width: 16),
          _statusTile("Salida", checkOut, Icons.logout_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _statusTile(String title, Timestamp? time, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              time != null ? DateFormat.Hm().format(time.toDate()) : "--:--",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.contentPrimary),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.contentSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String userId, String workStartTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AppColors.contentSecondary),
              SizedBox(width: 8),
              Text(
                "HISTORIAL DE REGISTROS",
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.contentSecondary, fontSize: 11, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getUserAttendance(userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final logs = snapshot.data!;
              if (logs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text("No hay registros disponibles", style: TextStyle(color: AppColors.contentSecondary)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length > 5 ? 5 : logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildHistoryItem(logs[index], workStartTime),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> log, String workStartTime) {
    final checkIn = log['checkIn'] as Timestamp?;
    final checkOut = log['checkOut'] as Timestamp?;
    final dateStr = log['date'] as String? ?? '';
    final bool puntual = checkIn != null ? _isPunctual(checkIn, workStartTime) : true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: puntual ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              puntual ? Icons.check_circle_outline_rounded : Icons.timer_outlined,
              color: puntual ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(dateStr),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  puntual ? "Registro puntual" : "Retraso detectado",
                  style: TextStyle(color: puntual ? Colors.green[600] : Colors.red[600], fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkIn != null ? DateFormat.Hm().format(checkIn.toDate()) : "--:--",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                checkOut != null ? "Salida: ${DateFormat.Hm().format(checkOut.toDate())}" : "Sin salida",
                style: TextStyle(fontSize: 10, color: AppColors.contentSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return DateFormat('EEE, d MMM', 'es').format(date).toUpperCase();
    } catch (e) {
      return dateStr;
    }
  }

  bool _isPunctual(Timestamp checkIn, String startTimeStr) {
    try {
      final parts = startTimeStr.split(':');
      final startHour = int.parse(parts[0]);
      final startMin = int.parse(parts[1]);
      final checkInDate = checkIn.toDate();
      final limitMinutes = (startHour * 60) + startMin + 10;
      final actualMinutes = (checkInDate.hour * 60) + checkInDate.minute;
      return actualMinutes <= limitMinutes;
    } catch (e) {
      return true;
    }
  }

  Future<void> _handleAction(int status, String userId, String companyId) async {
    if (companyId.isEmpty) {
      _showError("Sin empresa asignada.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (status == 0) {
        await _firestoreService.logCheckIn(userId, companyId);
        _showSuccess("¡Entrada registrada con éxito!");
      } else if (status == 1) {
        await _firestoreService.logCheckOut(userId);
        _showSuccess("¡Salida registrada. Buen trabajo!");
      }
    } catch (e) {
      _showError("Error al marcar: $e");
    }
    setState(() => _isLoading = false);
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }
}

class DigitalClockWidget extends StatefulWidget {
  const DigitalClockWidget({super.key});

  @override
  State<DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  late Timer _timer;
  String _time = "";
  String _date = "";

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    if (mounted) {
      setState(() {
        _time = DateFormat('HH:mm').format(DateTime.now());
        _date = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w100,
                letterSpacing: -5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 5),
              child: Text(
                DateFormat('ss').format(DateTime.now()),
                style: const TextStyle(color: Colors.white38, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Text(
          _date.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
