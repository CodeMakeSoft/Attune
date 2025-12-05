import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/features/4_profile/presentation/widgets/profile_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _firestoreService.getUserData();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave(User updatedUser) async {
    setState(() => _isSaving = true);
    final success = await _firestoreService.updateUser(updatedUser);
    
    if (mounted) {
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Perfil actualizado correctamente' : 'Error al actualizar perfil'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      
      if (success) {
        setState(() {
          _user = updatedUser;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Error al cargar usuario")),
      );
    }

    // Lógica básica: Para "Mi Perfil", cualquiera puede editar sus datos personales.
    // Datos Laborales y Legales suelen ser de solo lectura para el empleado,
    // a menos que sea el Super Admin/Dueño.
    final isActiveSuperAdmin = _user!.role == 'super_admin';

    final permissions = ProfilePermissions(
      canEditPersonal: true,
      canEditJob: isActiveSuperAdmin, 
      canEditLegal: isActiveSuperAdmin,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header con Avatar (Placeholder por ahora)
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: _user!.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
              child: _user!.photoUrl == null 
                ? Text(_user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?', 
                    style: const TextStyle(fontSize: 40, color: Colors.white))
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              _user!.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Mostrar Rol en la Empresa (Puesto) en lugar del Rol de Sistema
            if (_user!.position != null && _user!.position!.isNotEmpty)
              Text(
                _user!.position!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 32),
            
            ProfileForm(
              user: _user,
              permissions: permissions,
              onSave: _handleSave,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
