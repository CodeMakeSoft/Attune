import 'dart:ui'; // Necesario para el efecto borroso (Blur)
import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:attune/features/3_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:attune/features/10_attendance/presentation/screens/attendance_screen.dart';
import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';
import 'package:attune/features/5_team/presentation/screens/team_screen.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/core/models/user_model.dart' as model;
import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/core/services/notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _tokenUpdated = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<model.User?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, snapshot) {
        debugPrint("--- Navegación: Estado del Stream: ${snapshot.connectionState} ---");
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          debugPrint("--- Navegación: ERROR DETECTADO: ${snapshot.error} ---");
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Error al cargar sesión:\n${snapshot.error}", 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}), 
                      child: const Text("Reintentar"),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint("--- Navegación: Perfil no encontrado. Intentando inicializar... ---");
          
          return FutureBuilder<model.User?>(
            future: _firestoreService.getUserData(),
            builder: (context, initSnapshot) {
              if (initSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              
              if (initSnapshot.hasError || initSnapshot.data == null) {
                debugPrint("--- Navegación: Error crítico al inicializar perfil: ${initSnapshot.error} ---");
                _firestoreService.signOut();
                return const Scaffold(body: Center(child: Text("Error al configurar tu perfil. Por favor, reintenta.")));
              }
              
              // Si todo sale bien, el Stream principal de arriba se refrescará solo
              return const LoadingScreen();
            },
          );
        }

        final currentUser = snapshot.data!;
        debugPrint("--- Navegación: Usuario cargado -> ${currentUser.name} (Rol: ${currentUser.role}) ---");

        // Al cargar el usuario, intentamos actualizar el token de notificaciones una sola vez
        if (!_tokenUpdated) {
          _updateFCMToken(currentUser.uid);
          _tokenUpdated = true;
        }

        final List<Widget> pages = [
          DashboardScreen(currentUser: currentUser),
          AttendanceScreen(currentUser: currentUser),
          TeamScreen(currentUser: currentUser),
          ProfileScreen(currentUser: currentUser),
        ];

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.backgroundPrimary,
          body: pages[_currentIndex],

          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.grid_view_rounded),
                      _buildNavItem(1, Icons.access_time_filled_rounded),
                      _buildNavItem(2, Icons.group_rounded),
                      _buildNavItem(3, Icons.person_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.contentSecondary,
          size: 26,
        ),
      ),
    );
  }

  Future<void> _updateFCMToken(String userId) async {
    try {
      String? token = await NotificationService.getToken();
      if (token != null) {
        await _firestoreService.updateUserFields(userId, {'fcmToken': token});
        debugPrint("--- FCM Token actualizado en Firestore ---");
      }
    } catch (e) {
      debugPrint("--- Error al actualizar FCM Token: $e ---");
    }
  }
}