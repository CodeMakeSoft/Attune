import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _userId;
  String? _companyId;

  // Stream var to prevent rebuilding
  Stream<List<Map<String, dynamic>>>? _attendanceStream;

  @override
  void initState() {
    super.initState();
    _loadUserAndLogs();
  }

  Future<void> _loadUserAndLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userId = user.uid;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _companyId = data?['currentCompanyId'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_userId != null) {
          _attendanceStream = _firestoreService.getUserAttendance(_userId!);
        }
      });
    }
  }

  Future<void> _handleCheckInOut() async {
     if (_userId == null || _companyId == null || _companyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes una empresa asignada.')),
      );
      return;
    }

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Registro de Asistencia"),
          content: const Text("¿Qué deseas registrar?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performCheckIn();
              },
              child: const Text("ENTRADA"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performCheckOut();
              },
              child: const Text("SALIDA"),
            ),
          ],
        ),
      );
  }

  Future<void> _performCheckIn() async {
     await _firestoreService.logCheckIn(_userId!, _companyId!);
     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entrada Registrada')));
  }

  Future<void> _performCheckOut() async {
     await _firestoreService.logCheckOut(_userId!);
     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Salida Registrada')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingScreen();

    return Column(
      children: [
        // --- Header ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: const [
              Text(
                'CONTROL DE ASISTENCIA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // ISOLATED CLOCK WIDGET
              DigitalClockWidget(), 
            ],
          ),
        ),

        // --- Active Interaction ---
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Big Button
                GestureDetector(
                  onTap: _handleCheckInOut,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPrimary.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, color: Colors.white, size: 64),
                        SizedBox(height: 12),
                        Text(
                          "REGISTRAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Recent Activity
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ACTIVIDAD RECIENTE",
                        style: TextStyle(
                          color: AppColors.contentSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Builder(
                        builder: (context) {
                          if (_attendanceStream == null) return const SizedBox();

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _attendanceStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                // IMPROVED ERROR HANDLING UI
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text("Error de base de datos. Verifica la consola o los índices.", style: TextStyle(color: Colors.red[900], fontSize: 12))),
                                    ],
                                  ),
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final logs = snapshot.data!;
                              if (logs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Center(child: Text("Sin registros hoy")),
                                );
                              }

                              return Column(
                                children: logs.take(3).map((log) {
                                   final date = log['date'] as String? ?? '';
                                   // Simple status logic: if checkout exists, completed.
                                   final status = log['checkOut'] != null ? 'Completado' : 'Entrada'; 
                                   
                                   return Container(
                                     margin: const EdgeInsets.only(bottom: 12),
                                     padding: const EdgeInsets.all(16),
                                     decoration: BoxDecoration(
                                       color: Colors.white,
                                       borderRadius: BorderRadius.circular(16),
                                       boxShadow: [
                                         BoxShadow(
                                           color: Colors.black.withOpacity(0.03),
                                           blurRadius: 10,
                                           offset: const Offset(0, 4),
                                         ),
                                       ],
                                     ),
                                     child: Row(
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.all(10),
                                           decoration: BoxDecoration(
                                             color: AppColors.backgroundSubtle,
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: const Icon(Icons.history, color: AppColors.contentSecondary),
                                         ),
                                         const SizedBox(width: 16),
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text(status.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                             ],
                                           ),
                                         ),
                                         const Icon(Icons.chevron_right, color: Colors.grey),
                                       ],
                                     ),
                                   );
                                }).toList(),
                              );
                            },
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),
      ],
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
