import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:attune/core/widgets/loading_screen.dart';
import 'package:attune/features/2_auth/presentation/screens/login_screen.dart';
import 'package:attune/features/3_dashboard/presentation/screens/main_navigation_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if(snapshot.hasData) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}