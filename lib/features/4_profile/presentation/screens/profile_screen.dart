import 'package:attune/app/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/features/4_profile/presentation/widgets/profile_form.dart';
import 'package:attune/core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _departments = [];
  List<String> _positions = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _firestoreService.getUserData();
    
    List<String> depts = [];
    List<String> pos = [];

    // Si el usuario pertenece a una empresa, obtenemos sus departamentos y puestos
    if (user != null && user.currentCompanyId.isNotEmpty) {
      final docSn = await _firestoreService.getCompanyStream(user.currentCompanyId).first;
      if (docSn.exists) {
         final data = docSn.data() as Map<String, dynamic>;
         if (data['departments'] != null) {
           depts = List<String>.from(data['departments']);
         }
         if (data['jobTitles'] != null) {
           pos = List<String>.from(data['jobTitles']);
         }
      }
    }

    if (mounted) {
      setState(() {
        _user = user;
        _departments = depts;
        _positions = pos;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave(User updatedUser) async {
    // Quitar el foco del teclado
    FocusScope.of(context).unfocus();

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

    final isActiveSuperAdmin = _user!.role == 'super_admin';

    final permissions = ProfilePermissions(
      canEditPersonal: true,
      canEditJob: isActiveSuperAdmin, 
      canEditLegal: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await _authService.signOut();
              
              if (context.mounted) {
                // Esto borra todo el historial de pantallas y te manda a la ruta principal
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4), // Grosor del anillo
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3), // Borde interior de separación
                decoration: const BoxDecoration(
                  color: Colors.white, // Color del fondo de separación (o Colors.black si es dark mode)
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: _user!.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
                  child: _user!.photoUrl == null
                      ? Text(
                          _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 40, 
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
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
              availableDepartments: _departments,
              availablePositions: _positions,
            ),
          ],
        ),
      ),
    );
  }
}
