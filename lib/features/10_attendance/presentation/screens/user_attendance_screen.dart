import 'package:flutter/material.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class UserAttendanceScreen extends StatefulWidget {
  final String userId;
  final String companyId;

  const UserAttendanceScreen({
    super.key, 
    required this.userId, 
    required this.companyId
  });

  @override
  State<UserAttendanceScreen> createState() => _UserAttendanceScreenState();
}

class _UserAttendanceScreenState extends State<UserAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);
    await _firestoreService.logCheckIn(widget.userId, widget.companyId);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrada registrada')));
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);
    await _firestoreService.logCheckOut(widget.userId);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salida registrada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Column(
        children: [
          // Botones de acción rápida
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCheckIn,
                    icon: const Icon(FontAwesomeIcons.doorOpen),
                    label: const Text("Marcar Entrada"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCheckOut,
                    icon: const Icon(FontAwesomeIcons.doorClosed),
                    label: const Text("Marcar Salida"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Historial Reciente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getUserAttendance(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final records = snapshot.data ?? [];
                
                if (records.isEmpty) {
                  return const Center(child: Text("No hay registros de asistencia."));
                }

                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = records[index];
                    // Data fields: checkIn (Timestamp), checkOut (Timestamp), date (String)
                    // We need to handle nulls safely
                    
                    final checkInTime = data['checkIn'] as dynamic; // Timestamp?
                    final checkOutTime = data['checkOut'] as dynamic; // Timestamp?
                    final dateStr = data['date'] ?? '';

                    String tIn = '--:--';
                    String tOut = '--:--';

                     if (checkInTime != null && checkInTime is Timestamp) {
                      tIn = DateFormat.Hm().format(checkInTime.toDate());
                    }
                    if (checkOutTime != null && checkOutTime is Timestamp) {
                      tOut = DateFormat.Hm().format(checkOutTime.toDate());
                    }

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.access_time, color: Colors.white),
                      ),
                      title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Icon(Icons.login, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(tIn),
                          const SizedBox(width: 16),
                          Icon(Icons.logout, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(tOut),
                        ],
                      ),
                      trailing: Text(
                        data['status']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
