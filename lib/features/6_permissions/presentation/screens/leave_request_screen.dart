import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/leave_request_model.dart';
import 'package:attune/core/models/notification_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  final User currentUser;
  
  const LeaveRequestScreen({super.key, required this.currentUser});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool get _isAdmin => widget.currentUser.role == 'super_admin' || widget.currentUser.role == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Gestión de Permisos' : 'Mis Permisos'),
      ),
      // Solo el Empleado Normal (o admin solicitando para él mismo) puede ver el botón de crear
      floatingActionButton: _isAdmin ? null : FloatingActionButton(
        backgroundColor: AppColors.accentPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateRequestDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getLeaveRequests(widget.currentUser.companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Ocurrió un error al cargar los datos."));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No hay datos disponibles."),
            );
          }

          final rawDocs = snapshot.data!.docs;
          
          List<LeaveRequest> requests = rawDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LeaveRequest.fromMap(data, doc.id);
          }).where((req) => _isAdmin || req.userId == widget.currentUser.uid).toList();

          // Ordenar del más reciente al más antiguo
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (requests.isEmpty) {
            return const Center(
              child: Text("No hay solicitudes de permisos por mostrar."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
            },
          );
        },
      ),
    );
  }

  // --- TARJETA VISUAL DE UN PERMISO ---
  Widget _buildRequestCard(LeaveRequest req) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.access_time;
    String statusText = 'Pendiente';

    if (req.status == 'approved') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Aprobado';
    } else if (req.status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rechazado';
    }

    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    bool showAdminControls = _isAdmin && req.status == 'pending'; // Si ya se aprobó no dejar volver a picar

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y el status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isAdmin ? req.userName : req.type, // El admin necesita ver quién, el usuario qué pidió
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  avatar: Icon(statusIcon, color: Colors.white, size: 16),
                  label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mostrar el tipo si eres admin
            if (_isAdmin)
              Text("Tipo: ${req.type}", style: TextStyle(color: AppColors.contentSecondary)),

            Text("Motivo: ${req.reason}"),
            const SizedBox(height: 12),
            
            // Fechas
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text("${dateFormat.format(req.startDate)} - ${dateFormat.format(req.endDate)}"),
              ],
            ),

            // Botones de Admin (Aprobar/Rechazar)
            if (showAdminControls) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _firestoreService.updateLeaveRequestStatus(req.id, 'rejected');
                      _notifyStatusChange(req, 'Rechazado', 'rechazada');
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      _firestoreService.updateLeaveRequestStatus(req.id, 'approved');
                      _notifyStatusChange(req, 'Aprobado', 'aprobada');
                    },
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- POPUP PARA CREAR SOLICITUD ---
  void _showCreateRequestDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String selectedType = 'Vacaciones';
    String reason = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // StatefulBuilder nos permite hacer setState DENTRO del dialogo
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Solicitar Permiso'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown (Vacaciones, Enfermedad, Personal)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo de Permiso'),
                        items: ['Vacaciones', 'Enfermedad', 'Asunto Personal']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDialogState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 16),

                      // Rango de Fechas
                      ListTile(
                        title: const Text("Fechas"),
                        subtitle: Text("${DateFormat('dd MMM', 'es').format(startDate)} al ${DateFormat('dd MMM', 'es').format(endDate)}"),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: DateTimeRange(start: startDate, end: endDate),
                          );
                          if (range != null) {
                            setDialogState(() {
                              startDate = range.start;
                              endDate = range.end;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Razón
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Motivo (Breve)'),
                        maxLength: 50,
                        validator: (v) => v!.isEmpty ? 'Ingresa un motivo' : null,
                        onChanged: (v) => reason = v,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // 1. Armamos el objeto con la data del usuario
                      final newRequest = LeaveRequest(
                        id: '', // Se generará chueco en Firebase
                        userId: widget.currentUser.uid,
                        userName: widget.currentUser.name,
                        companyId: widget.currentUser.companyId,
                        type: selectedType,
                        reason: reason,
                        startDate: startDate,
                        endDate: endDate,
                        createdAt: DateTime.now(),
                      );
                      
                      // 2. Lo enviamos usando toMap()
                       await _firestoreService.createLeaveRequest(newRequest.toMap());

                       // Notificar a los administradores
                       _firestoreService.notifyAdmins(widget.currentUser.companyId, {
                         'title': 'Nueva Solicitud de Permiso',
                         'body': '${widget.currentUser.name} ha solicitado "${newRequest.type}".',
                         'type': 'leave_request',
                         'isRead': false,
                         'createdAt': Timestamp.now(),
                       });

                       if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Solicitud enviada')),
                          );
                       }
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- NOTIFICAR CAMBIO DE ESTADO ---
  void _notifyStatusChange(LeaveRequest req, String statusTitle, String bodyStatus) {
    if (req.userId.isEmpty) return;

    final notification = AppNotification(
      id: '',
      userId: req.userId,
      title: 'Permiso $statusTitle',
      body: 'Tu solicitud de "${req.type}" ha sido $bodyStatus por un administrador.',
      type: 'leave_request',
      createdAt: DateTime.now(),
    );

    _firestoreService.createNotification(notification.toMap());
  }
}
