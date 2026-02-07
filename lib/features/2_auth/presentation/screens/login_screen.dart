import 'package:attune/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer';
import 'dart:async';
import 'package:attune/utils/app_colors.dart';

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
        body: Stack(
          children: [
            // 1. Fondo decorativo superior con gradiente
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),

            // 2. Contenido Principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Column(
                    children: [
                      // Header Section
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icon/icon.svg',
                            width: 64.0,
                            height: 64.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¡Bienvenido!',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa a tu cuenta para continuar.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Tarjeta del Formulario
                      Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Correo Electrónico',
                                    hintText: 'ejemplo@empresa.com',
                                    errorText: _emailError,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isPasswordObscured,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    errorText: _passwordError,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.contentSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordObscured = !_isPasswordObscured;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _showPasswordResetDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(color: colorScheme.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleEmailSignIn,
                                  child: const Text('INGRESAR'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // 4. Social Login & Register (Fuera de la tarjeta para menos ruido visual)
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'O ingresa con',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.contentSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialLoginButton(
                            icon: FontAwesomeIcons.google,
                            color: Colors.red,
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                          ),
                          const SizedBox(width: 24),
                          _SocialLoginButton(
                            icon: FontAwesomeIcons.facebook,
                            color: Colors.blue,
                            onTap: _isLoading ? null : _handleFacebookSignIn,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta?',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.contentSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _showRegistrationDialog, 
                            child: const Text(
                              'Regístrate aquí',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 5. Loading Indicator Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para botones sociales redondos y limpios
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: FaIcon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
