import 'package:attune/features/3_dashboard/presentation/widgets/dashboard_grid_button.dart';
import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';
import 'package:attune/features/5_employees/presentation/screens/employee_list_screen.dart';
import 'package:attune/features/5_employees/presentation/screens/invite_user_screen.dart';
import 'package:attune/features/8_organization/presentation/screens/organization_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SuperAdminDashboardView extends StatelessWidget {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // Basado en tu mockup "¡Hola Super Admin!"
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
          icon: FontAwesomeIcons.sitemap,
          label: 'Deptos. y Roles',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrganizationScreen()),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.users,
          label: 'Empleados',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.solidGem, // Membresía
          label: 'Membresía',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.moneyBillWave,
          label: 'Pagos',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.clockRotateLeft,
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