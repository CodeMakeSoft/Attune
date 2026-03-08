import 'package:attune/core/models/company_model.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/4_profile/presentation/widgets/profile_form.dart';
import 'package:flutter/material.dart';

class EditEmployeeScreen extends StatefulWidget {
  final User employee;

  const EditEmployeeScreen({super.key, required this.employee});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<String> _departments = [];
  List<String> _jobTitles = [];
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyConfig();
  }

  Future<void> _loadCompanyConfig() async {
    // Load current user's company (Admin's company)
    final currentUser = await _firestoreService.getUserData();
    if (currentUser != null && currentUser.currentCompanyId.isNotEmpty) {
      final companyDoc = await _firestoreService.getCompanyStream(currentUser.currentCompanyId).first;
      if (companyDoc.exists) {
        final company = Company.fromFirestore(companyDoc);
        if (mounted) {
           setState(() {
            _departments = company.departments;
            _jobTitles = company.jobTitles;
            _isLoadingConfig = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingConfig = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _handleSave(User updatedUser) async {
    setState(() => _isLoading = true);
    
    // We update the full user profile including Work Info (which Admin has permission to edit)
    // FirestoreService.updateUser updates all fields in the model.
    // However, we might want to ensure we are updating the right user ID.
    // The updatedUser object coming from ProfileForm should have the original UID.
    
    final success = await _firestoreService.updateUser(updatedUser);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado actualizado correctamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar empleado'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) return const LoadingScreen();

    // Permissions: Admin editing an employee.
    // Admin can edit Job and Legal info usually. Personal info? Maybe.
    // Let's give Admin full edit rights for now or restrict Personal.
    // Usually Admin needs to edit everything including fixing names.
    final permissions = ProfilePermissions(
      canEditPersonal: true,
      canEditJob: true,
      canEditLegal: true,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Editar: ${widget.employee.name}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ProfileForm(
          user: widget.employee,
          permissions: permissions,
          onSave: _handleSave,
          isLoading: _isLoading,
          availableDepartments: _departments,
          availablePositions: _jobTitles,
        ),
      ),
    );
  }
}
