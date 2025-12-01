import 'package:attune/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController= TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  String? _emailError;
  String? _passwordError;
  Timer? _errorTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }
  
  // Handles
  void _handleGoogleSignIn() async {
    setState(() { _isLoading = true; });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null && mounted) {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      log ('Error en Google Sign-In: $e', name: 'LoginScreen');
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    }
  }

  void _handleFacebookSignIn() async {
    setState(() { _isLoading = true; });

    try {
      final userCredential = await _authService.signInWithFacebook();

      if(userCredential == null && mounted) {
        setState(() { _isLoading = false; });
      }
      
    } catch (e) {
      log ('Error en Facebook Sign-In: $e', name: 'LoginScreen');
      if(mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión con Facebook: $e')),
        );
      }
    }
  }

  void _handleEmailSignIn() async {
    if(!_validateForm()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final userCredential = await _authService.signInWithEmailPassword(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );

      if(userCredential == null && mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Usuario o contraseña incorrectos.'),
          ),
        );
      }
    } catch (e) {
      log ('Error en Email Sign-In: $e', name: 'LoginScreen');
      if(mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Reset password
  void _showPasswordResetDialog() {

    final dialogEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    String? dialogEmailError; 
    Timer? errorTimer;        

    void disposeDialog() {
      errorTimer?.cancel();
    }

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDialogLoading = false; 

            void validateAndSend() async {
              errorTimer?.cancel();

              final email = dialogEmailController.text.trim();
              if (email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
                
                setDialogState(() {
                  dialogEmailError = 'Por favor, ingresa un correo válido';
                });

                errorTimer = Timer(const Duration(seconds: 3), () {
                  setDialogState(() {
                    dialogEmailError = null;
                  });
                });
                
                return; // Detenemos la función
              }
              
              setDialogState(() { 
                isDialogLoading = true;
                dialogEmailError = null;
              });
              
              final success = await _authService.sendPasswordResetEmail(email);
              
              Navigator.pop(dialogContext); // Cierra el pop-up

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    success 
                      ? '¡Revisa tu correo! Se ha enviado un enlace.'
                      : 'Error: No se pudo enviar el correo.'
                  )),
                );
              }
            }
            
            return PopScope(
              onPopInvoked: (_) => disposeDialog(),
              child: AlertDialog(
                title: const Text('Restablecer Contraseña'),
                content: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: dialogEmailController,
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          errorText: dialogEmailError, 
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext), 
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isDialogLoading ? null : validateAndSend,
                    child: isDialogLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


// TODO Falta agregar el timer para quitar los errores desoues de inputs invalidas
void _showRegistrationDialog() {
  final dialogEmailController = TextEditingController();
  final dialogPasswordController = TextEditingController();
  final dialogConfirmPasswordController = TextEditingController();
  final dialogFormKey = GlobalKey<FormState>(); 
  bool isDialogPassObscured = true;
  bool isDialogCPassObscured = true;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDialogLoading = false;
            String? dialogError; 
            Timer? errorTimer;

            void disposeDialog() {
              errorTimer?.cancel();
            }

            void validateAndRegister() async {
              errorTimer?.cancel(); 
              setDialogState(() { dialogError = null; }); 

              if (!dialogFormKey.currentState!.validate()) return;
              
              final pass = dialogPasswordController.text;
              final confirmPass = dialogConfirmPasswordController.text;

              if (pass != confirmPass) {
                setDialogState(() {
                  dialogError = 'Las contraseñas no coinciden';
                });
                errorTimer = Timer(const Duration(seconds: 3), () {
                  setDialogState(() { dialogError = null; });
                });
                return; 
              }

              setDialogState(() { isDialogLoading = true; });

              UserCredential? userCredential;
              String? errorMessage;

              try {
                userCredential = await _authService.registerWithEmailPassword(
                  dialogEmailController.text.trim(),
                  pass,
                );
                
                if (userCredential == null) {
                  errorMessage = 'Error: El email ya está en uso o la contraseña es muy débil.';
                }
              } catch (e) {
                log('Error en validateAndRegister: $e', name: 'LoginScreen');
                errorMessage = 'Error inesperado. Intenta de nuevo.';
              }
              if (context.mounted) {
                Navigator.pop(dialogContext);
              }

              if (mounted) {
                if (errorMessage != null) { 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              }
            }

            return PopScope(
              onPopInvoked: (_) => disposeDialog(),
              child: AlertDialog(
                title: const Text('Crear una cuenta nueva'),
                content: SingleChildScrollView(
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: dialogEmailController,
                          decoration: const InputDecoration(labelText: 'Correo'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) { 
                            if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dialogPasswordController,
                          obscureText: isDialogPassObscured,
                          decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                                isDialogPassObscured ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setDialogState(() { 
                                  isDialogPassObscured = !isDialogPassObscured;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dialogConfirmPasswordController,
                          obscureText: isDialogCPassObscured,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(
                                isDialogCPassObscured ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  isDialogCPassObscured = !isDialogCPassObscured;
                                });
                              },
                            ),
                            errorText: dialogError,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirma tu contraseña';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isDialogLoading ? null : validateAndRegister,
                    child: isDialogLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Registrar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _validateForm() {
    _errorTimer?.cancel();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    bool isValid = true;
    if(email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      setState(() {
        _emailError = 'Por favor, ingresa un correo válido';
      });
      isValid = false;
    }
    if(password.isEmpty || password.length < 6) {
      setState(() {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      });
      isValid = false;
    }
    if(!isValid) {
      _errorTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _emailError = null;
          _passwordError = null;
        });
      });
    }
    return isValid;
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
              Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            errorText: _passwordError,
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
                            onPressed: _isLoading ? null : _showPasswordResetDialog,
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes una cuenta?',
                              style: textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _showRegistrationDialog, 
                              child: const Text('Registrate'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
