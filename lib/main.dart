// Importa el paquete de Material Design, que contiene los widgets visuales.
import 'package:flutter/material.dart';

// La función `main` es el punto de entrada de toda app de Flutter.
void main() {
  // `runApp` infla el widget que le pasas y lo adjunta a la pantalla.
  runApp(const MyApp());
}

// MyApp es el widget raíz de tu aplicación.
// Es "Stateless" porque su estado no cambia con el tiempo.
class MyApp extends StatelessWidget {
  // El constructor del widget.
  const MyApp({super.key});

  // El método `build` describe cómo mostrar el widget.
  // Es llamado por el framework de Flutter cada vez que necesita dibujar el widget.
  @override
  Widget build(BuildContext context) {
    // `MaterialApp` es un widget que envuelve varias funcionalidades y widgets
    // que son comúnmente requeridos, como la navegación y los temas.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // El título de la aplicación, usado por el sistema operativo.
      title: 'Hola Mundo App',
      // La "home" es la primera pantalla que el usuario verá.
      home: Scaffold(
        // `AppBar` es la barra de título que aparece en la parte superior.
        appBar: AppBar(
          title: const Text('Mi Primera App'),
          backgroundColor: Colors.blueGrey, // Un color para la barra
        ),
        // `body` es el contenido principal de la pantalla.
        body: const Center(
          // `Center` es un widget que centra a su widget hijo.
          child: Text(
            '¡Hola, mundo!',
            style: TextStyle(fontSize: 36), // Le damos un tamaño de fuente
          ),
        ),
      ),
    );
  }
}