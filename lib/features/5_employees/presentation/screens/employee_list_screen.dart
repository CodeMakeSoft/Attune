import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/5_employees/presentation/screens/invite_user_screen.dart';
import 'package:attune/features/5_employees/presentation/screens/edit_employee_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Note: We'll add navigation to detail screen later

class EmployeeListScreen extends StatefulWidget {
  final Function(User)? onEmployeeSelected;

  const EmployeeListScreen({
    super.key, 
    this.onEmployeeSelected,
  });

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
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
      if (user.role == 'super_admin' || user.role == 'admin') {
         setState(() {
          _companyId = user.currentCompanyId;
        });
      } else {
        // Unauthorized
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para ver esta sección.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     if (_companyId == null || _companyId!.isEmpty) {
       return const LoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Empleados"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to invite screen
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InviteUserScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<User>>(
        stream: _firestoreService.getEmployees(_companyId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return const Center(child: Text("No hay empleados registrados."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: employee.photoUrl != null ? NetworkImage(employee.photoUrl!) : null,
                  child: employee.photoUrl == null 
                    ? Text(employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                    : null,
                ),
                title: Text(employee.name),
                subtitle: Text(employee.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (widget.onEmployeeSelected != null) {
                    widget.onEmployeeSelected!(employee);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployeeScreen(employee: employee),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
