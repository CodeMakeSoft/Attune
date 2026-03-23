import 'package:attune/app/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attune/features/9_performance/presentation/screens/statistics_screen.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/features/4_profile/presentation/widgets/profile_form.dart';
import 'package:attune/core/services/auth_service.dart';
import 'package:attune/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isSaving = false;
  List<String> _departments = [];
  List<String> _positions = [];

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    List<String> depts = [];
    List<String> pos = [];

    if (_user!.currentCompanyId.isNotEmpty) {
      final docSn = await _firestoreService.getCompanyStream(_user!.currentCompanyId).first;
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
        _departments = depts;
        _positions = pos;
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
    return StreamBuilder<User?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.currentUser;
        final permissions = const ProfilePermissions(
          canEditPersonal: true,
          canEditJob: false, // Nadie cambia su departamento/puesto desde Mi Perfil
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
                _buildProfileHeader(user),
                const SizedBox(height: 32),
                
                ProfileForm(
                  user: _user!,
                  permissions: permissions,
                  onSave: _handleSave,
                  isLoading: _isSaving,
                  availableDepartments: _departments,
                  availablePositions: _positions,
                ),
                const SizedBox(height: 24),
                _buildStatisticsButton(context, _user!),
                const SizedBox(height: 24),
                _buildBenefitsSection(_user!),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
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
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
          user.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (user.position != null && user.position!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              user.position!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBenefitsSection(User user) {
    final benefits = user.assignedBenefits;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Prestaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${benefits.length}',
                  style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (benefits.isEmpty)
            const Text(
              'No tienes prestaciones asignadas actualmente.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: benefits.map((benefit) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(benefit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsButton(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, AppColors.accentPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatisticsScreen(employeeId: user.uid, employeeName: user.name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(FontAwesomeIcons.chartLine, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Desempeño',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ver gráfica y estadísticas semanales',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
