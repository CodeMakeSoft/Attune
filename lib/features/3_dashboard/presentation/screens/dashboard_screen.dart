import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/auth_service.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/2_auth/presentation/screens/create_company_screen.dart'; 
import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';
import 'package:attune/features/3_dashboard/presentation/views/admin_dashboard_view.dart';
import 'package:attune/features/3_dashboard/presentation/views/super_admin_dashboard_view.dart';
import 'package:attune/features/3_dashboard/presentation/views/user_dashboard_view.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  Future<User?>? _userFuture;
  @override
  void initState() {
    super.initState();
  
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userFuture = _firestoreService.getUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          _authService.signOut(); 
          return const LoadingScreen();
        }

        final appUser = snapshot.data!;

        // Si el usuario no tiene ninguna empresa asignada, lo redirigimos a crear una.
        if (appUser.companies.isEmpty && appUser.companyId.isEmpty) {
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateCompanyScreen(),
              ),
            ).then((result) {
              if (result == true) {
                _loadUserData();
              }
            });
          });
          
          return const LoadingScreen();
        }
        
        if (appUser.companyId.isEmpty) {
          return Scaffold(
            appBar: AppBar(actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _authService.signOut)]),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Error: Tu cuenta no está vinculada a ninguna empresa. Por favor, contacta a tu administrador.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        Widget dashboardView;
        switch (appUser.role) {
          case 'admin':
            dashboardView = AdminDashboardView(currentUser: appUser);
            break;
          case 'super_admin':
            dashboardView = SuperAdminDashboardView(currentUser: appUser);
            break;
          case 'user':
          default:
            dashboardView = UserDashboardView(currentUser: appUser);
            break;
        }

        return Scaffold(
          appBar: AppBar(
            // Botón de Empresas a la izquierda
            leading: IconButton(
              icon: const Icon(Icons.business),
              tooltip: 'Mis Empresas',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Selecciona una Empresa'),
                    children: appUser.companies.entries.map((entry) {
                      final companyId = entry.key;
                      final companyData = entry.value;
                      final isSelected = companyId == appUser.currentCompanyId;
                      
                      // Extraer nombre y rol de forma segura
                      String companyName = 'Empresa (Sin nombre)';
                      String role = 'user';

                      if (companyData is Map) {
                        companyName = companyData['name'] ?? 'Empresa (Sin nombre)';
                        role = companyData['role'] ?? 'user';
                      } else if (companyData is String) {
                        // Soporte legacy
                        role = companyData;
                      }

                      return SimpleDialogOption(
                        onPressed: () async {
                          Navigator.pop(context); // Cerrar diálogo
                          
                          if (!isSelected) {
                            // Cambiar empresa
                            await _firestoreService.switchCompany(companyId);
                            _loadUserData(); // Recargar Dashboard
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? Theme.of(context).primaryColor : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      companyName, 
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Rol: $role',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            title: Text('Hola, ${appUser.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _authService.signOut();
                },
              ),
            ],
          ),
          body: dashboardView,
        );
      },
    );
  }
}