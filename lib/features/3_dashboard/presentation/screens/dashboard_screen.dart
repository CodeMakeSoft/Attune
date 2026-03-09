import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/services/auth_service.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/2_auth/presentation/screens/create_company_screen.dart'; 
import 'package:attune/features/3_dashboard/presentation/views/admin_dashboard_view.dart';
import 'package:attune/features/3_dashboard/presentation/views/super_admin_dashboard_view.dart';
import 'package:attune/features/3_dashboard/presentation/views/user_dashboard_view.dart';
import 'package:attune/features/11_notifications/presentation/screens/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final User currentUser;
  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  @override
  Widget build(BuildContext context) {
    final appUser = widget.currentUser;

    // Si el usuario no tiene ninguna empresa asignada, lo redirigimos a crear una.
    if (appUser.companies.isEmpty && appUser.companyId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateCompanyScreen(),
          ),
        );
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

    return Column(
      children: [
        // --- 1. Custom Header Moderno ---
        _buildModernHeader(context, appUser),

        // --- 2. El contenido (Dashboard View) ---
        Expanded(
          child: dashboardView,
        ),
      ],
    );
  }

  // Widget del Header Personalizado
  Widget _buildModernHeader(BuildContext context, User appUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30), // Padding superior para Status Bar
      decoration: const BoxDecoration(
        // Gradiente usando los colores definidos
        gradient: LinearGradient(
          colors: [Color(0xFF153065), Color(0xFF1E40AF)], // Usando hardcoded o AppColors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Empresa y Notificaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Selector de Empresa (Estilo Chip)
              GestureDetector(
                onTap: () => _showCompanySelector(context, appUser),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _getCompanyName(appUser), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              // Aquí la campana de notificaciones
              _buildNotificationBell(context, appUser),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Saludo
          Text(
            'Hola, ${appUser.name.split(' ')[0]} 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bienvenido de nuevo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getCompanyName(User user) {
      if (user.currentCompanyId.isEmpty) return 'Sin Empresa';
      final companyData = user.companies[user.currentCompanyId];
      if (companyData is Map) {
          return companyData['name'] ?? 'Mi Empresa';
      }
      return 'Mi Empresa';
  }

  void _showCompanySelector(BuildContext context, User appUser) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecciona una Empresa'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: appUser.companies.entries.map((entry) {
          final companyId = entry.key;
          final companyData = entry.value;
          final isSelected = companyId == appUser.currentCompanyId;
          
          String companyName = 'Empresa (Sin nombre)';
          String role = 'user';

          if (companyData is Map) {
            companyName = companyData['name'] ?? 'Empresa (Sin nombre)';
            role = companyData['role'] ?? 'user';
          } else if (companyData is String) {
            role = companyData;
          }

          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () async {
              Navigator.pop(context); 
              if (!isSelected) {
                await _firestoreService.switchCompany(companyId);
              }
            },
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      Text('Rol: $role', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, User appUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUserNotifications(appUser.uid),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] == false;
          }).length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen(currentUser: appUser)),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}