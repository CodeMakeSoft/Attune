import 'package:attune/features/3_dashboard/presentation/widgets/dashboard_grid_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';

import 'package:attune/core/models/user_model.dart';
import 'package:attune/features/9_performance/presentation/screens/user_performance_screen.dart';
import 'package:attune/features/10_attendance/presentation/screens/user_attendance_screen.dart';
import 'package:attune/features/6_permissions/presentation/screens/leave_request_screen.dart';
import 'package:attune/features/7_events/presentation/screens/events_screen.dart';

import 'package:attune/core/widgets/generic_placeholder_screen.dart';
import 'package:attune/features/13_support/presentation/screens/support_screen.dart';

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
        DashboardGridButton(
          icon: FontAwesomeIcons.fileInvoiceDollar, // Finanzas
          label: 'Finanzas',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const GenericPlaceholderScreen(title: 'Finanzas', icon: FontAwesomeIcons.fileInvoiceDollar)));
          },
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaveRequestScreen(currentUser: currentUser)),
            );
          },
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
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (c) => const GenericPlaceholderScreen(title: 'Prestaciones', icon: FontAwesomeIcons.umbrellaBeach)));
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.calendarWeek,
          label: 'Eventos',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventsScreen(currentUser: currentUser)),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.solidCircleQuestion,
          label: 'Soporte',
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (c) => const SupportScreen()));
          },
        ),
      ],
    );
  }
}