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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<model.User?>(
      stream: _firestoreService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("Error al cargar sesión")));
        }

        final currentUser = snapshot.data!;

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
}