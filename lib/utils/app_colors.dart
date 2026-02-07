import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  // --- 1. Colores de Contenido/Texto (Content) ---
  static const Color contentPrimary = Color(0xFF1A1D24); // Gris oscuro/negro para texto principal.
  static const Color contentInverse = Color(0xFFFFFFFF); // Blanco para texto sobre fondos oscuros.
  static const Color contentSecondary = Color(0xFF6B7280); // Gris más suave y moderno.

  // --- 2. Colores de Fondo (Background) ---
  static const Color backgroundPrimary = Color(0xFFF9FAFB); // Off-white moderno (Cool Gray 50).
  static const Color backgroundSurface = Color(0xFFFFFFFF); // Blanco puro para tarjetas.
  static const Color backgroundSubtle = Color(0xFFF3F4F6);  // Fondo secundario (Cool Gray 100).
  static const Color backgroundDark = Color(0xFF0F172A);    // Fondo para Modo Oscuro (Slate 900).

  // --- 3. Colores de Interfaz/Acción (Accent & Brand) - Colores del logo ---
  static const Color accentPrimary = Color(0xFF153065);    // voidNavy - Base.
  static const Color accentPrimaryLight = Color(0xFF2563EB); // Un azul más vibrante para interacciones.
  static const Color accentSecondary = Color(0xFF0EA5E9);  // Sky Blue - más moderno que el teal anterior.
  
  // Gradientes
  static const Color gradientStart = Color(0xFF153065);
  static const Color gradientEnd = Color(0xFF1E40AF); // Un azul un poco más claro para dar profundidad.

  // --- 4. Colores de Estado (State/Semantic) ---
  static const Color stateSuccess = Color(0xFF10B981);    // Emerald 500
  static const Color stateError = Color(0xFFEF4444);      // Red 500
  static const Color stateWarning = Color(0xFFF59E0B);    // Amber 500
  static const Color stateInfo = Color(0xFF3B82F6);       // Blue 500

  // --- 5. Colores de Estructura (Structure) ---
  static const Color borderDefault = Color(0xFFE5E7EB); // Gray 200
  static const Color dividerDark = Color(0xFF1F2937);   // Gray 800
}