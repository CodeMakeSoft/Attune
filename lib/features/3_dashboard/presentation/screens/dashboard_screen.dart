import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/auth_service.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/2_auth/presentation/screens/create_company_screen.dart'; 
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

        if (appUser.role == 'super_admin' && appUser.companyId.isEmpty) {
          
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
            dashboardView = const AdminDashboardView();
            break;
          case 'super_admin':
            dashboardView = const SuperAdminDashboardView();
            break;
          case 'user':
          default:
            dashboardView = const UserDashboardView();
            break;
        }

        return Scaffold(
          appBar: AppBar(
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