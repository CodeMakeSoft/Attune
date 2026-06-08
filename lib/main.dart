import 'package:flutter/material.dart';
import 'package:attune/app/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:attune/core/services/notification_service.dart';

// Keys for Firestone
import 'firebase_options.dart';

// Colors
import 'package:attune/utils/app_colors.dart';


import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('es', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background Message Handler (FCM)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Notification Service Initialization
  await NotificationService.initialize();

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
        
        // 2. El esquema de color modernizado
        colorScheme: ColorScheme(
          brightness: Brightness.light, 
          
          primary: AppColors.accentPrimary,    
          onPrimary: AppColors.contentInverse, 
          
          secondary: AppColors.accentSecondary, 
          onSecondary: AppColors.contentInverse, // Ahora blanco para mejor contraste
          
          error: AppColors.stateError,      
          onError: AppColors.contentInverse,  
          
          surface: AppColors.backgroundSurface, // Tarjetas blancas
          onSurface: AppColors.contentPrimary,    
 
          inverseSurface: AppColors.backgroundDark, 
          onInverseSurface: AppColors.contentInverse, 
        ),

        // 3. Tema moderna para AppBars
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundPrimary, 
          foregroundColor: AppColors.contentPrimary,   
          elevation: 0, 
          centerTitle: true,
          scrolledUnderElevation: 0, 
        ),
        
        // 4. Input Fields más modernos y limpios
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSubtle, // Cambiado a un tono sutil (gris muy claro) para que resalte sobre blanco
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.contentSecondary),
          labelStyle: const TextStyle(color: AppColors.contentSecondary),
          
          // Bordes más suaves
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent), // Sin borde por defecto si tiene fondo
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stateError),
          ),
        ),

        // 5. Botones más prominentes y redondeados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: AppColors.contentInverse,
            elevation: 2, // Sutil elevación
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // 6. Configuración de Tarjetas
        cardTheme: CardThemeData(
          color: AppColors.backgroundSurface,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
      ),
      // -----------------------------
      
      home: const AuthGate(), // Esto sigue igual
    );
  }
}