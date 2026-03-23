import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/features/9_performance/presentation/screens/statistics_screen.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TeamScreen extends StatefulWidget {
  final User currentUser;
  const TeamScreen({super.key, required this.currentUser});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  bool get _isAdmin {
    final role = widget.currentUser.role.toLowerCase();
    print("--- DEBUG TEAM SCREEN ---");
    print("Rol detectado: $role");
    print("Company ID: ${widget.currentUser.companyId}");
    
    return role == 'admin' || 
           role == 'superadmin' || 
           role == 'super_admin' || 
           widget.currentUser.ownedCompanies.contains(widget.currentUser.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Equipo'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: _firestoreService.getEmployees(widget.currentUser.companyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar empleados'));
                }
                
                final employees = snapshot.data ?? [];
                final filteredEmployees = employees.where((e) {
                  return e.name.toLowerCase().contains(_searchQuery);
                }).toList();
                
                if (filteredEmployees.isEmpty) {
                  return const Center(child: Text('No se encontraron empleados'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return _buildEmployeeCard(employee);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(User employee) {
    // Determinar rol dentro de la empresa actual
    final String role = employee.companies[widget.currentUser.companyId]?['role'] ?? 'user';
    final bool isSelectedEmployeeAdmin = role == 'admin' || role == 'super_admin';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderDefault),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.accentPrimary.withOpacity(0.1),
          backgroundImage: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
              ? NetworkImage(employee.photoUrl!)
              : null,
          child: employee.photoUrl == null || employee.photoUrl!.isEmpty
              ? Text(
                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.accentPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isSelectedEmployeeAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.accentPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.position ?? 'Sin puesto asignado',
              style: TextStyle(color: AppColors.contentSecondary, fontSize: 13),
            ),
            Text(
              employee.department ?? 'Sin departamento',
              style: TextStyle(color: AppColors.contentSecondary.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
        trailing: _isAdmin 
          ? IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditEmployeeDialog(employee),
            )
          : null,
        onTap: () => _showEmployeeDetails(employee),
      ),
    );
  }

  void _showEmployeeDetails(User employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            final bool isMe = employee.uid == widget.currentUser.uid;
            final bool canDelete = isMe || _isAdmin;

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accentPrimary.withOpacity(0.1),
                        backgroundImage: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                            ? NetworkImage(employee.photoUrl!)
                            : null,
                        child: employee.photoUrl == null || employee.photoUrl!.isEmpty
                            ? Text(
                                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: AppColors.accentPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              employee.position ?? 'Puesto no asignado',
                              style: TextStyle(fontSize: 16, color: AppColors.accentPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDetailRow(Icons.email_outlined, 'Email', employee.email),
                  _buildDetailRow(Icons.phone_outlined, 'Teléfono', employee.phone ?? 'No registrado'),
                  _buildDetailRow(Icons.business_outlined, 'Departamento', employee.department ?? 'No asignado'),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Fecha de ingreso', 
                    employee.hireDate != null ? DateFormat('dd/MM/yyyy').format(employee.hireDate!.toDate()) : 'No registrada'),
                  _buildDetailRow(Icons.assignment_ind_outlined, 'Tipo de contrato', employee.contractType ?? 'No registrado'),
                  
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentPrimary.withOpacity(0.2)),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatisticsScreen(employeeId: employee.uid, employeeName: employee.name),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart_rounded, color: AppColors.accentPrimary),
                      label: const Text(
                        'Ver estadísticas de desempeño',
                        style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.w900, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  if (canDelete) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _confirmDeleteEmployee(employee, isMe),
                        icon: Icon(isMe ? Icons.exit_to_app : Icons.person_remove_outlined, color: Colors.red),
                        label: Text(
                          isMe ? "Darse de baja de la empresa" : "Eliminar empleado de la nómina",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmployee(User employee, bool isMe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isMe ? "¿Deseas salir de la empresa?" : "¿Eliminar empleado?"),
        content: Text(isMe 
          ? "Perderás el acceso a todas las herramientas de esta empresa. Esta acción no se puede deshacer por ti mismo."
          : "Esta acción revocará el acceso de ${employee.name} a la empresa de forma inmediata. No se borrarán sus datos personales."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar Dialog
              Navigator.pop(context); // Cerrar Sheet
              
              try {
                final companyId = widget.currentUser.companyId;
                await _firestoreService.removeEmployeeFromCompany(employee.uid, companyId);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${employee.name} ha sido eliminado."), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al eliminar: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Confirmar Eliminación", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.contentSecondary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.contentSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(User employee) {
    String? selectedPosition = employee.position;
    String? selectedDepartment = employee.department;
    String? selectedContractType = employee.contractType;
    DateTime? selectedHireDate = employee.hireDate?.toDate();
    List<String> assignedBenefits = List<String>.from(employee.assignedBenefits);
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Editar: ${employee.name.split(' ')[0]}'),
              content: SingleChildScrollView(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('companies').doc(widget.currentUser.companyId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
                    
                    final companyData = snapshot.data!.data() as Map<String, dynamic>?;
                    final availableDepartments = List<String>.from(companyData?['departments'] ?? []);
                    final availablePositions = List<String>.from(companyData?['jobTitles'] ?? []);
                    final companyBenefits = List<Map<String, dynamic>>.from(companyData?['benefits'] ?? []);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: availableDepartments.contains(selectedDepartment) ? selectedDepartment : null,
                          decoration: const InputDecoration(
                            labelText: 'Departamento', 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                          ),
                          items: availableDepartments.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: availableDepartments.isEmpty ? null : (val) => setDialogState(() => selectedDepartment = val),
                          hint: Text(availableDepartments.isEmpty ? "Aún no creado" : "Selecciona uno"),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: availablePositions.contains(selectedPosition) ? selectedPosition : null,
                          decoration: const InputDecoration(
                            labelText: 'Puesto / Cargo', 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                          ),
                          items: availablePositions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: availablePositions.isEmpty ? null : (val) => setDialogState(() => selectedPosition = val),
                          hint: Text(availablePositions.isEmpty ? "Aún no creado" : "Selecciona uno"),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: ['Planta', 'Temporal', 'Prácticas', 'Honorarios'].contains(selectedContractType) ? selectedContractType : null,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Contrato', 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Planta', child: Text('Planta', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Temporal', child: Text('Temporal', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Prácticas', child: Text('Prácticas', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Honorarios', child: Text('Honorarios', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) => setDialogState(() => selectedContractType = val),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedHireDate ?? DateTime.now(),
                              firstDate: DateTime(1980),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setDialogState(() => selectedHireDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Fecha de Contratación",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                            ),
                            child: Text(selectedHireDate != null ? DateFormat('dd/MM/yyyy').format(selectedHireDate!) : 'Seleccionar fecha...'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Prestaciones Asignadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (companyBenefits.isEmpty)
                          const Text('No hay prestaciones creadas en la empresa.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        else
                          ...companyBenefits.map((benefit) {
                            final title = benefit['title'] as String;
                            final isSelected = assignedBenefits.contains(title);
                            
                            return CheckboxListTile(
                              title: Text(title, style: const TextStyle(fontSize: 14)),
                              value: isSelected,
                              dense: true,
                              activeColor: AppColors.accentPrimary,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    assignedBenefits.add(title);
                                  } else {
                                    assignedBenefits.remove(title);
                                  }
                                });
                              },
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    try {
                      final Map<String, dynamic> updateData = {
                        'position': selectedPosition ?? employee.position ?? '',
                        'department': selectedDepartment ?? employee.department ?? '',
                        'contractType': selectedContractType ?? employee.contractType,
                      };
                      
                      if (selectedHireDate != null) {
                        updateData['hireDate'] = Timestamp.fromDate(selectedHireDate!);
                      }
                      
                      // Actualizar datos básicos
                      await _firestoreService.updateUserFields(employee.uid, updateData);
                      
                      // Actualizar prestaciones
                      await _firestoreService.updateEmployeeBenefits(
                        employee.uid, 
                        widget.currentUser.companyId, 
                        assignedBenefits
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Empleado actualizado correctamente'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                        setDialogState(() => isLoading = false);
                      }
                    }
                  },
                  child: isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
