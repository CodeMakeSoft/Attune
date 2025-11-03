import 'package:attune/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController= TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Handles
  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    }
  }

  void _handleFacebookSignIn() async {
    setState(() {
      _isLoading = false;
    });

    try {
      final userCredential = await _authService.signInWithFacebook();

      if(userCredential == null && mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión con Facebook: $e')),
        );
      }
    }
  }

  void _handleEmailSignIn() async {
    if(_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa correo y contraseña'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithEmailPassword(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );

      if(userCredential == null && mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Usuario o contraseña incorrectos.'),
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Reset password
  void _handlePasswordReset() async {
    final email = _emailController.text.trim();

    if(email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu correo para restablecer la contraseña.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final bool success = await _authService.sendPasswordResetEmail(email);

    setState(() {
      _isLoading = false;
    });

    if(mounted) {
      if(success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Revisa tu correo! Se ha enviado un enlace para restablecer tu contraseña.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo enviar el correo. Verifica que el correo sea correcto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          // --- 4. Usamos un Stack para poner el 'loading' encima ---
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/icon.svg',
                        width: 100.0,
                        height: 100.0,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        '¡Bienvenido!',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 48),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handlePasswordReset,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailSignIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'o también',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Login With Google
                      OutlinedButton.icon(
                        // Si está cargando, deshabilitamos el botón (onPressed: null)
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red),
                        label: const Text('Ingresar con Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Login with Facebook
                      OutlinedButton.icon(
                        // Si está cargando, deshabilitamos el botón
                        onPressed: _isLoading ? null : _handleFacebookSignIn,
                        icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue),
                        label: const Text('Ingresar con Facebook'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- 6. El indicador de carga ---
              // Si _isLoading es true, muestra un 'loading' semitransparente
              if (_isLoading)
                Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
