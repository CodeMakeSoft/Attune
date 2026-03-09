import 'package:attune/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:attune/core/models/company_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _firestoreService.getUserData();
    if (mounted && user != null) {
      setState(() {
        _companyId = user.currentCompanyId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_companyId == null || _companyId!.isEmpty) {
       return const LoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text("Gestión de Organización"),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getCompanyStream(_companyId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final company = Company.fromFirestore(snapshot.data!);

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: Theme.of(context).primaryColor,
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.white70,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: "Departamentos"),
                      Tab(text: "Puestos"),
                      Tab(text: "Horarios"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildListEditor(
                        context, 
                        items: company.departments, 
                        title: "Departamento", 
                        icon: Icons.business_center_rounded,
                        onSave: (newList) => _firestoreService.updateDepartments(_companyId!, newList),
                      ),
                      _buildListEditor(
                         context, 
                         items: company.jobTitles, 
                         title: "Puesto", 
                         icon: Icons.badge_rounded,
                         onSave: (newList) => _firestoreService.updateJobTitles(_companyId!, newList),
                      ),
                      _buildScheduleEditor(context, company),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListEditor(
    BuildContext context, {
    required List<String> items,
    required String title,
    required IconData icon,
    required Function(List<String>) onSave,
  }) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: items.isEmpty 
          ? _buildEmptyState(title)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.accentPrimary, size: 24),
                    ),
                    title: Text(item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () {
                        _confirmDelete(context, item, () {
                          final newList = List<String>.from(items);
                          newList.removeAt(index);
                          onSave(newList);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
        ),
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text("Agregar $title"),
            onPressed: () {
              _showAddDialog(context, title, (newItem) {
                if (newItem.isNotEmpty && !items.contains(newItem)) {
                  final newList = List<String>.from(items);
                  newList.add(newItem);
                  onSave(newList);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No hay ${title}s registrados",
            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 18),
          ),
        ],
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
              _firestoreService.updateCompanySchedule(_companyId!, newTime, company.workEndTime);
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
              _firestoreService.updateCompanySchedule(_companyId!, company.workStartTime, newTime);
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

  void _confirmDelete(BuildContext context, String item, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirmar eliminación"),
        content: Text("¿Seguro que deseas eliminar el $item de la lista?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, String title, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Nuevo $title"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Ej. Ventas, Gerente...",
            filled: true,
            fillColor: AppColors.backgroundSubtle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAdd(controller.text.trim());
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }
}
