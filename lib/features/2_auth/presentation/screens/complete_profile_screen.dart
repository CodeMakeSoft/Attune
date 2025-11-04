import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:attune/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  // TODO logica para foto pendiente

  bool _isLoading = false;

  void _onSavedProfile() async {
    if(_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // --- ¡LÓGICA CLAVE! ---
    // 1. Llamar a un servicio de Firestore para actualizar el 'name' y 'photoUrl'
    //    del usuario actual.
    // 2. Cuando termine, navegar al 'RegisterRoleScreen' o recargar.
    
    // Por ahora, solo simulamos
    await Future.delayed(const Duration(seconds: 1));
    
    // (Idealmente, esto forzaría al FutureBuilder del Dashboard a recargarse)
    // (Por ahora, no hace nada, pero la lógica de redirección ya está lista)
    
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu perfil'),
        automaticallyImplyLeading: false, // Can´t go back
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¡Estás por terminar! \nSolo unos datos más.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // TODO falta añador widget para seleccionar la foto de perfil

            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tu nombre completo'),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _onSavedProfile, 
              child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar y continuar'),
            ),
          ],
        ),
      ),
    );
  }
}