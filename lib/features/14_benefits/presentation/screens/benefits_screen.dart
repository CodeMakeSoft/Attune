import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/company_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BenefitsScreen extends StatefulWidget {
  final User currentUser;
  const BenefitsScreen({super.key, required this.currentUser});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool get isAdmin => widget.currentUser.role == 'admin' || widget.currentUser.role == 'super_admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Prestaciones y Beneficios'),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: _firestoreService.getUserStream(),
        builder: (context, userSnapshot) {
          final currentUser = userSnapshot.data ?? widget.currentUser;
          
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getCompanyStream(currentUser.companyId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final company = Company.fromFirestore(snapshot.data!);
              
              // Si es admin ve todas, si es usuario solo las asignadas
              List<Map<String, dynamic>> displayedBenefits;
              if (isAdmin) {
                displayedBenefits = company.benefits;
              } else {
                final assignedTitles = currentUser.assignedBenefits;
                displayedBenefits = company.benefits.where((b) => assignedTitles.contains(b['title'])).toList();
              }

              return Column(
                children: [
                  _buildHeader(displayedBenefits.length),
                  Expanded(
                    child: displayedBenefits.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: displayedBenefits.length,
                            itemBuilder: (context, index) {
                              final benefit = displayedBenefits[index];
                              return _buildBenefitCard(benefit, index, company.benefits);
                            },
                          ),
                  ),
                  if (isAdmin) _buildAddButton(company.benefits),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Gestión de Beneficios' : 'Mis Prestaciones',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin 
              ? 'Administra las prestaciones para todos tus empleados.'
              : 'Tienes $count prestaciones activas en tu perfil.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(Map<String, dynamic> benefit, int index, List<Map<String, dynamic>> allBenefits) {
    final String title = benefit['title'] ?? 'Sin título';
    final String description = benefit['description'] ?? 'Sin descripción';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: AppColors.accentPrimary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          if (isAdmin)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                  onPressed: () => _showEditDialog(benefit, index, allBenefits),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(index, allBenefits),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.umbrellaBeach, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            'No hay beneficios registrados aún',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(List<Map<String, dynamic>> currentBenefits) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        label: const Text('Agregar Prestación'),
        onPressed: () => _showAddDialog(currentBenefits),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showAddDialog(List<Map<String, dynamic>> currentBenefits) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Nueva Prestación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newList = List<Map<String, dynamic>>.from(currentBenefits);
                newList.add({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                });
                _firestoreService.updateBenefits(widget.currentUser.companyId, newList);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> benefit, int index, List<Map<String, dynamic>> allBenefits) {
    final titleController = TextEditingController(text: benefit['title']);
    final descController = TextEditingController(text: benefit['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Editar Prestación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newList = List<Map<String, dynamic>>.from(allBenefits);
                newList[index] = {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                };
                _firestoreService.updateBenefits(widget.currentUser.companyId, newList);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index, List<Map<String, dynamic>> allBenefits) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar prestación?'),
        content: const Text('Esta acción quitará el beneficio de la lista para todos los empleados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Conservar')),
          ElevatedButton(
            onPressed: () {
              final newList = List<Map<String, dynamic>>.from(allBenefits);
              newList.removeAt(index);
              _firestoreService.updateBenefits(widget.currentUser.companyId, newList);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
