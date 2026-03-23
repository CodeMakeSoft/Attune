import 'package:attune/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

class InviteUserScreen extends StatefulWidget {
  const InviteUserScreen({super.key});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  String _selectedRole = 'user'; // Rol por defecto

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final success = await _firestoreService.inviteUser(
      email: _emailController.text,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Invitación enviada con éxito!')),
        );
        Navigator.pop(context); // Regresamos al dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la invitación. Revisa tu conexión.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar Empleado')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Envía una invitación por correo electrónico para que un empleado se una a tu empresa.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Campo de Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo del Empleado',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Selector de Rol
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol Asignado',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Empleado (User)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador (Admin)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              
              const Spacer(), // Empuja el botón al final
              
              ElevatedButton(
                onPressed: _isLoading ? null : _sendInvitation,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar Invitación', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}