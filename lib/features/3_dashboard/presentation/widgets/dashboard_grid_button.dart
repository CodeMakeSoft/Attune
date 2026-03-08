import 'package:flutter/material.dart';

class DashboardGridButton extends StatelessWidget {
  const DashboardGridButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon; // El ícono que se mostrará
  final String label;  // El texto debajo del ícono
  final VoidCallback onPressed; // La función que se llamará al tocarlo

  @override
  Widget build(BuildContext context) {
    // Usamos Card para darle el fondo y los bordes
    return Card(
      // Usamos el color 'surfaceVariant' del tema para un fondo sutil
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      elevation: 0, // Un look plano y moderno
      shape: RoundedRectangleBorder(
        // Bordes redondeados
        borderRadius: BorderRadius.circular(12),
        // Un borde muy ligero para que se distinga del fondo
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      // Usamos InkWell para que tenga el efecto "ripple" (onda) al tocar
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12), // Debe coincidir con el Card
        child: Column(
          // Centramos el contenido (ícono y texto)
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32, // Un tamaño de ícono legible
              // Usa el color primario de tu app (definido en main.dart)
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12), // Espacio entre ícono y texto
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, // Texto en semi-negrita
                  ),
            ),
          ],
        ),
      ),
    );
  }
}