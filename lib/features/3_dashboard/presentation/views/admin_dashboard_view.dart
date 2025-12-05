import 'package:attune/features/3_dashboard/presentation/widgets/dashboard_grid_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // 2 Columnas
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // Basado en tu mockup "¡Hola Admin!"
        DashboardGridButton(
          icon: FontAwesomeIcons.solidUser, 
          label: 'Mi Perfil',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.users,
          label: 'Empleados',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.clipboardCheck, // Icono para "Aprobar"
          label: 'Aprobar Permisos',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.chartLine, // Icono para "Evaluar"
          label: 'Evaluar Desempeño',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.moneyBillWave,
          label: 'Pagos',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.clockRotateLeft, // Icono para "Historial"
          label: 'Historial',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.calendarWeek,
          label: 'Eventos',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.solidCircleQuestion,
          label: 'Soporte',
          onPressed: () { /* TODO */ },
        ),
      ],
    );
  }
}