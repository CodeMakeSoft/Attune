// lib/features/2_auth/presentation/screens/create_company_screen.dart

import 'package:attune/core/services/auth_service.dart';
import 'package:attune/core/services/firestore_service.dart'; // Importaremos este
import 'package:flutter/material.dart';

class CreateCompanyScreen extends StatefulWidget {
  // Renombramos la clase
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _companyNameController = TextEditingController();
  final _rfcController = TextEditingController(); // Opcional
  final _businessLineController = TextEditingController(); // Opcional (Giro)
  
  // Instanciamos el servicio que usaremos
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _rfcController.dispose();
    _businessLineController.dispose();
    super.dispose();
  }

  Future<void> _onCreateCompany() async {
    final companyName = _companyNameController.text.trim();
    if (companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la empresa es obligatorio.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // 1. Llama al servicio de Firestore para crear la empresa
    // (Este método aún no existe, lo crearemos en el Paso 3)
    final bool success = await _firestoreService.createCompany(
      companyName: companyName,
      rfc: _rfcController.text.trim(),
      businessLine: _businessLineController.text.trim(),
    );

    // 2. Si tiene éxito, Navigator.pop() nos devolverá al DashboardScreen
    if (success && mounted) {
      Navigator.of(context).pop(true); // Envía 'true' para indicar éxito
    } else if (mounted) {
      // Si falla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la empresa. Intenta de nuevo.')),
      );
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu Empresa'),
        automaticallyImplyLeading: false, // El usuario NO PUEDE volver
        actions: [
          // Añadimos un botón de Salir por si acaso
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                '¡Bienvenido, Super Admin!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Solo falta un paso. Registra tu empresa para comenzar.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // --- Formulario ---
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Empresa (Obligatorio)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessLineController,
                decoration: const InputDecoration(labelText: 'Giro (Ej. Tecnología)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rfcController,
                decoration: const InputDecoration(labelText: 'RFC (Opcional)'),
              ),
              const SizedBox(height: 48),

              // --- Botón de Guardar ---
              ElevatedButton(
                onPressed: _isLoading ? null : _onCreateCompany,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar y Empezar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}