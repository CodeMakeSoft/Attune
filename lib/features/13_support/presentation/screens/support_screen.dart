import 'package:flutter/material.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Soporte'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cómo podemos ayudarte?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuestro equipo está listo para resolver tus dudas.',
              style: TextStyle(color: AppColors.contentSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Canales de contacto rápidos
            Row(
              children: [
                _buildContactMethod(
                  context,
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _buildContactMethod(
                  context,
                  icon: FontAwesomeIcons.envelope,
                  label: 'Email',
                  color: AppColors.accentPrimary,
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Envíanos un mensaje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              decoration: InputDecoration(
                labelText: 'Asunto',
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Describe tu problema o duda aquí...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensaje enviado. Te contactaremos pronto.')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enviar Mensaje'),
            ),
            
            const SizedBox(height: 40),
            const Text(
              'Preguntas Frecuentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const ListTile(
              title: Text('¿Cómo agrego un nuevo empleado?'),
              trailing: Icon(Icons.keyboard_arrow_down),
            ),
            const Divider(),
            const ListTile(
              title: Text('¿Olvidaste tu contraseña?'),
              trailing: Icon(Icons.keyboard_arrow_down),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              FaIcon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
