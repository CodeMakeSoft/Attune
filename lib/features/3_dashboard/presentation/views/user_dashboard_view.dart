import 'package:attune/features/3_dashboard/presentation/widgets/dashboard_grid_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';

import 'package:attune/core/models/user_model.dart';
import 'package:attune/features/9_performance/presentation/screens/user_performance_screen.dart';
import 'package:attune/features/10_attendance/presentation/screens/user_attendance_screen.dart';

class UserDashboardView extends StatelessWidget {
  final User currentUser;
  const UserDashboardView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // Basado en tu mockup "¡Hola User!"
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
          icon: FontAwesomeIcons.fileInvoiceDollar, // Finanzas
          label: 'Finanzas',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.solidCalendarCheck, // Asistencia
          label: 'Asistencia',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserAttendanceScreen(
                  userId: currentUser.uid,
                  companyId: currentUser.companyId,
                ),
              ),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.filePen, // Permisos (Solicitar)
          label: 'Solicitar Permiso',
          onPressed: () { /* TODO */ },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.chartSimple, // Desempeño
          label: 'Mi Desempeño',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserPerformanceScreen(userId: currentUser.uid)),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.umbrellaBeach, // Prestaciones
          label: 'Prestaciones',
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