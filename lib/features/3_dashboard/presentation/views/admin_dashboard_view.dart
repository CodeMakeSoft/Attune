import 'package:attune/features/3_dashboard/presentation/widgets/dashboard_grid_button.dart';
import 'package:attune/features/4_profile/presentation/screens/profile_screen.dart';
import 'package:attune/features/5_employees/presentation/screens/employee_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:attune/core/models/user_model.dart';
import 'package:attune/features/9_performance/presentation/screens/evaluation_form_screen.dart';
import 'package:attune/features/6_permissions/presentation/screens/leave_request_screen.dart';
import 'package:attune/features/7_events/presentation/screens/events_screen.dart';

import 'package:attune/core/widgets/generic_placeholder_screen.dart';

class AdminDashboardView extends StatelessWidget {
  final User currentUser;
  const AdminDashboardView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // 2 Columnas
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
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
          icon: FontAwesomeIcons.clipboardCheck, // Icono para "Aprobar"
          label: 'Aprobar Permisos',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaveRequestScreen(currentUser: currentUser)),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.chartLine, // Icono para "Evaluar"
          label: 'Evaluar Desempeño',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeListScreen(
                  onEmployeeSelected: (selectedEmployee) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EvaluationFormScreen(
                          employee: selectedEmployee,
                          evaluator: currentUser,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.moneyBillWave,
          label: 'Pagos',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const GenericPlaceholderScreen(title: 'Pagos', icon: FontAwesomeIcons.moneyBillWave)));
          },
        ),
        DashboardGridButton(
          icon: FontAwesomeIcons.clockRotateLeft, // Icono para "Historial"
          label: 'Historial',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const GenericPlaceholderScreen(title: 'Historial', icon: FontAwesomeIcons.clockRotateLeft)));
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
            Navigator.push(context, MaterialPageRoute(builder: (c) => const GenericPlaceholderScreen(title: 'Soporte', icon: FontAwesomeIcons.solidCircleQuestion)));
          },
        ),
      ],
    );
  }
}