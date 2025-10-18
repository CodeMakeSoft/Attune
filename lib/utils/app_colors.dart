import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  // --- 1. Colores de Contenido/Texto (Content) ---
  static const Color contentPrimary = Color(0xFF1A1D24); // Gris oscuro/negro para texto principal.
  static const Color contentInverse = Color(0xFFFFFFFF); // Blanco para texto sobre fondos oscuros.
  static const Color contentSecondary = Color(0xFF424242); // Gris intermedio para texto secundario o hints.

  // --- 2. Colores de Fondo (Background) ---
  static const Color backgroundPrimary = Color(0xFFFFFFFF); // Fondo principal de la aplicación (Modo Claro).
  static const Color backgroundSubtle = Color(0xFFF2F5F7);  // Fondo de tarjetas, campos de entrada, o barras.
  static const Color backgroundDark = Color(0xFF0A0C10);    // Fondo para Modo Oscuro.

  // --- 3. Colores de Interfaz/Acción (Accent & Brand) - Colores del logo ---
  static const Color accentPrimary = Color(0xFF153065);    // voidNavy - Color principal de marca (botones, headers).
  static const Color accentSecondary = Color(0xFF59CCBD);  // laserTeal - Color de contraste/resaltado (enlaces, iconos).
  
  // Nuevo: Variante más clara del color primario para estados de interacción (hover)
  static const Color accentPrimaryLight = Color(0xFF4769AA); // Una versión más suave del voidNavy.

  // --- 4. Colores de Estado (State/Semantic) ---
  static const Color stateSuccess = Color(0xFF4CAF50);    // Verde para operaciones exitosas o confirmación.
  static const Color stateError = Color(0xFFE53935);      // Rojo para errores, fallas o alertas críticas.
  static const Color stateWarning = Color(0xFFFF9800);    // Naranja para advertencias o información importante.
  static const Color stateInfo = Color(0xFF2196F3);       // Azul claro para mensajes informativos.

  // --- 5. Colores de Estructura (Structure) ---
  static const Color borderDefault = Color(0xFFE3E8ED); // Líneas y contornos en modo claro.
  static const Color dividerDark = Color(0xFF2A2E36);   // Líneas divisorias en temas oscuros.
}