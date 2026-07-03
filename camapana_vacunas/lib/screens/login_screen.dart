import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_validators.dart'; 

import '../services/mock_auth_repository.dart';

import '../models/usuarios/paciente.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/administrador.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 

  final TextEditingController _identificadorCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  // 1. CREAMOS EL VIGILANTE (FocusNode) PARA EL CAMPO DEL RUT
  final FocusNode _rutFocusNode = FocusNode();

  final _authRepository = MockAuthRepository(); 
  
  bool _isLoading = false;
  bool _obscureText = true; 

  @override
  void initState() {
    super.initState();
    // 2. LE ASIGNAMOS LA TAREA AL VIGILANTE AL INICIAR LA PANTALLA
    _rutFocusNode.addListener(() {
      // Si el campo acaba de perder el foco (el usuario clickeó en otro lado)
      if (!_rutFocusNode.hasFocus) {
        String textoActual = _identificadorCtrl.text;
        if (textoActual.isNotEmpty) {
          // Formateamos visualmente al instante
          _identificadorCtrl.text = AppValidators.formatearRut(textoActual);
        }
      }
    });
  }

  void _ejecutarLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    // Mantenemos esta línea aquí como "red de seguridad" 
    // por si el usuario presiona "Enter" en el teclado sin salir del campo.
    _identificadorCtrl.text = AppValidators.formatearRut(_identificadorCtrl.text);

    setState(() => _isLoading = true);

    var usuario = await _authRepository.login(
      _identificadorCtrl.text, 
      _passwordCtrl.text.trim()
    );

    if (!mounted) return; 

    setState(() => _isLoading = false);

    if (usuario != null) {
      if (usuario is Paciente) {
        Navigator.pushReplacementNamed(context, '/dashboard'); 
      } else if (usuario is Enfermero) {
        Navigator.pushReplacementNamed(context, '/enfermero_dashboard');
      } else if (usuario is Medico) {
        Navigator.pushReplacementNamed(context, '/medico_dashboard');
      } else if (usuario is Administrador) {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (usuario is Secretario) {
        Navigator.pushReplacementNamed(context, '/secretario_dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credenciales incorrectas (Prueba un RUT válido y clave 1234)'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    // 3. SIEMPRE DEBEMOS DESTRUIR EL FOCUSNODE PARA LIBERAR MEMORIA
    _rutFocusNode.dispose();
    _identificadorCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 150, 
                          height: 150,
                          fit: BoxFit.contain, 
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Iniciar Sesión",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ingresa tus credenciales para continuar",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 40),

                      TextFormField(
                        controller: _identificadorCtrl,
                        // 4. CONECTAMOS EL CAMPO DE TEXTO CON EL VIGILANTE
                        focusNode: _rutFocusNode, 
                        decoration: InputDecoration(
                          labelText: "RUT o Correo Electrónico",
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => AppValidators.validarVacio(val, "Identificador"),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscureText, 
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                        validator: (val) => AppValidators.validarVacio(val, "Contraseña"),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _ejecutarLogin,
                        child: _isLoading 
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(strokeWidth: 3)
                              )
                            : const Text("Ingresar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("¿No tienes una cuenta?", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/create_profile');
                            },
                            child: Text("Regístrate aquí", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}