import 'package:flutter/material.dart';
import 'package:attune/core/models/company_model.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      appBar: AppBar(title: const Text("Organización")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getCompanyStream(_companyId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final company = Company.fromFirestore(snapshot.data!);

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "Departamentos"),
                    Tab(text: "Puestos (Roles)"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildListEditor(
                        context, 
                        items: company.departments, 
                        title: "Departamento", 
                        onSave: (newList) => _firestoreService.updateDepartments(_companyId!, newList),
                      ),
                      _buildListEditor(
                         context, 
                         items: company.jobTitles, 
                         title: "Puesto", 
                         onSave: (newList) => _firestoreService.updateJobTitles(_companyId!, newList),
                      ),
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
    required Function(List<String>) onSave,
  }) {
    return Column(
      children: [
        Expanded(
          child: items.isEmpty 
          ? Center(child: Text("No hay ${title}s registrados"))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(context, item, () {
                        final newList = List<String>.from(items);
                        newList.removeAt(index);
                        onSave(newList);
                      });
                    },
                  ),
                );
              },
            ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
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
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String item, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Seguro que deseas eliminar '$item'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
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
        title: Text("Agregar $title"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Nombre del $title"),
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
