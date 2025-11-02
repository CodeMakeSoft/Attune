import 'package:flutter/material.dart';
import 'package:attune/app/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';

// Keys for Firestone
import 'firebase_options.dart';

// Colors
import 'package:attune/utils/app_colors.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attune',
      debugShowCheckedModeBanner: false,
      
      // --- AQUÍ ESTÁ LA MAGIA ---
      // Vamos a definir el tema global de la app
      theme: ThemeData(
        // 1. Color de fondo principal para todas las pantallas
        scaffoldBackgroundColor: AppColors.backgroundPrimary,
        
        // 2. El esquema de color (el más importante)
        colorScheme: ColorScheme(
          brightness: Brightness.light, // Modo claro
          
          primary: AppColors.accentPrimary,    // Tu color principal (voidNavy)
          onPrimary: AppColors.contentInverse,  // Texto sobre el color primario (blanco)
          
          secondary: AppColors.accentSecondary, // Tu color secundario (laserTeal)
          onSecondary: AppColors.contentPrimary, // Texto sobre el color secundario
          
          error: AppColors.stateError,      // Rojo para errores
          onError: AppColors.contentInverse,  // Texto sobre el color de error
          
          surface: AppColors.backgroundPrimary,      // Fondo principal
          onSurface: AppColors.contentPrimary,     // Texto sobre el fondo

          inverseSurface: AppColors.backgroundSubtle, // Fondo de tarjetas/campos
          onInverseSurface: AppColors.contentPrimary, // Texto sobre tarjetas
        ),

        // 3. Tema por defecto para las AppBars
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundPrimary, // Fondo de la barra
          foregroundColor: AppColors.contentPrimary,   // Color del título
          elevation: 0, // Sin sombra, para un look limpio
          centerTitle: true,
        ),
        
        // 4. Tema por defecto para los Campos de Texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSubtle,
          labelStyle: const TextStyle(color: AppColors.contentSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2.0),
          ),
        ),

        // 5. Tema por defecto para Botones Elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary, // Fondo del botón
            foregroundColor: AppColors.contentInverse, // Color del texto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // -----------------------------
      
      home: const AuthGate(), // Esto sigue igual
    );
  }
}