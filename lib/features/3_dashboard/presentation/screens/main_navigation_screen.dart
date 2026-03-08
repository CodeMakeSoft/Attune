import 'dart:ui'; // Necesario para el efecto borroso (Blur)
import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:attune/features/3_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:attune/features/10_attendance/presentation/screens/attendance_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(), // Index 0: Inicio
    const AttendanceScreen(), // Index 1: Asistencia
    const Center(child: Text("Pantalla Equipo")), // Index 2: Placeholder
    const Center(child: Text("Pantalla Perfil")), // Index 3: Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // CLAVE: Permite que el contenido baje tras la barra
      
      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Margen para flotar
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // Fondo semitransparente
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