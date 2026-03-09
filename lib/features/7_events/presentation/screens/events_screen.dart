import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/event_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  final User currentUser;
  
  const EventsScreen({super.key, required this.currentUser});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool get _isAdmin => widget.currentUser.role == 'super_admin' || widget.currentUser.role == 'admin';
  final Set<String> _expandedEvents = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos y Comunicados'),
      ),
      // Solo el Admin o SuperAdmin tiene permisos para hacer nuevos comunicados
      floatingActionButton: _isAdmin 
        ? FloatingActionButton(
            backgroundColor: AppColors.accentPrimary,
            child: const Icon(Icons.add_alert_rounded, color: Colors.white),
            onPressed: () => _showCreateEventDialog(context),
          ) 
        : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getEvents(widget.currentUser.companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Ocurrió un error al cargar los eventos."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("No hay eventos próximos", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Transformamos los datos y los ORDENAMOS aquí localmente (por fecha) para evitar el índice compuesto
          final rawDocs = snapshot.data!.docs;
          List<CompanyEvent> eventsList = rawDocs.map((doc) {
            return CompanyEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
          
          eventsList.sort((a, b) => a.date.compareTo(b.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventsList.length,
            itemBuilder: (context, index) {
              return _buildEventCard(eventsList[index]);
            },
          );
        },
      ),
    );
  }

  // --- TARJETA VISUAL DE UN COMUNICADO / EVENTO ---
  Widget _buildEventCard(CompanyEvent event) {
    final bool isPast = event.date.isBefore(DateTime.now());
    final dateFormat = DateFormat('EEEE, dd MMM yyyy - HH:mm', 'es');
    final bool isExpanded = _expandedEvents.contains(event.id);
    
    return Card(
      elevation: 0,
      color: isPast ? Colors.grey.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedEvents.remove(event.id);
            } else {
              _expandedEvents.add(event.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey.withOpacity(0.2) : AppColors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPast ? Icons.history : Icons.calendar_month_rounded, 
                      color: isPast ? Colors.grey : AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: isPast ? Colors.grey : AppColors.contentPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(event.date),
                          style: TextStyle(color: isPast ? Colors.grey : AppColors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Botón de Editar si es admin y no ha pasado
                  if (_isAdmin && !isPast)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditEventDialog(context, event),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: isPast ? Colors.grey : AppColors.contentPrimary, height: 1.4),
              ),
              if (!isExpanded && event.description.length > 80)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Ver más...",
                    style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP PARA CREAR UN COMUNICADO ---
  void _showCreateEventDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Publicar Comunicado', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Título del Comunicado o Evento'),
                        validator: (v) => v!.isEmpty ? 'Ingresa un título' : null,
                        onChanged: (v) => title = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Descripción / Detalles', alignLabelWithHint: true),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Ingresa una descripción' : null,
                        onChanged: (v) => description = v,
                      ),
                      const SizedBox(height: 24),
                      
                      // Seleccionar Fecha y Hora
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDate: selectedDate,
                                );
                                if (d != null) setDialogState(() => selectedDate = d);
                              },
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(DateFormat('dd MMM').format(selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: selectedTime);
                                if (t != null) setDialogState(() => selectedTime = t);
                              },
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Fusionar la Fecha elegida con la Hora elegida
                      final combinedDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute,
                      );

                      final newEvent = CompanyEvent(
                        id: '', 
                        title: title,
                        description: description,
                        date: combinedDateTime,
                        companyId: widget.currentUser.companyId,
                        createdBy: widget.currentUser.uid,
                        createdAt: DateTime.now(),
                      );
                      
                       await _firestoreService.createEvent(newEvent.toMap());

                       if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Evento publicado en el Muro')),
                          );
                       }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                  child: const Text('Publicar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- POPUP PARA EDITAR UN COMUNICADO ---
  void _showEditEventDialog(BuildContext context, CompanyEvent event) {
    final formKey = GlobalKey<FormState>();
    String title = event.title;
    String description = event.description;
    DateTime selectedDate = event.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(event.date);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Comunicado', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: title,
                        decoration: const InputDecoration(labelText: 'Título del Comunicado o Evento'),
                        validator: (v) => v!.isEmpty ? 'Ingresa un título' : null,
                        onChanged: (v) => title = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(labelText: 'Descripción / Detalles', alignLabelWithHint: true),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Ingresa una descripción' : null,
                        onChanged: (v) => description = v,
                      ),
                      const SizedBox(height: 24),
                      
                      // Seleccionar Fecha y Hora
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDate: selectedDate,
                                );
                                if (d != null) setDialogState(() => selectedDate = d);
                              },
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(DateFormat('dd MMM').format(selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: selectedTime);
                                if (t != null) setDialogState(() => selectedTime = t);
                              },
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final combinedDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute,
                      );

                      // Actualizar los datos del evento
                      final updatedData = {
                        'title': title,
                        'description': description,
                        'date': Timestamp.fromDate(combinedDateTime),
                      };
                      
                       await _firestoreService.updateEvent(event.id, updatedData);

                       if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Evento actualizado correctamente')),
                          );
                       }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                  child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
