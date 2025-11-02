import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attune - Login'),
      ),
      body: const Center(
        child: Text('Pantalla de Login'),
      ),
    );
  }
}