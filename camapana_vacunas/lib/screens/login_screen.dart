import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// Importamos el repositorio desde la carpeta services
import '../services/mock_auth_repository.dart';

// Importamos los roles para poder hacer el ruteo dinámico
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
  // Controladores de texto originales
  final TextEditingController _identificadorCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  // Inyectamos el repositorio
  final _authRepository = MockAuthRepository(); 
  
  // Variables de estado
  bool _isLoading = false;
  bool _obscureText = true; // Controla la visibilidad de la contraseña

  void _ejecutarLogin() async {
    setState(() => _isLoading = true);

    // Llamamos a la validación
    var usuario = await _authRepository.login(
      _identificadorCtrl.text.trim(), 
      _passwordCtrl.text.trim()
    );

    // Seguridad de Flutter: verificar si el widget sigue en pantalla después del await
    if (!mounted) return; 

    setState(() => _isLoading = false);

    if (usuario != null) {
      // LÓGICA DE RUTEO INTACTA
      if (usuario is Paciente) {
        Navigator.pushReplacementNamed(context, '/dashboard'); 
      } else if (usuario is Enfermero) {
        Navigator.pushReplacementNamed(context, '/enfermero_dashboard');
        print("Login exitoso: Eres Enfermero");
      } else if (usuario is Medico) {
        Navigator.pushReplacementNamed(context, '/medico_dashboard');
        print("Login exitoso: Eres Médico");
      } else if (usuario is Administrador) {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
        print("Login exitoso: Eres Admin");
      } else if (usuario is Secretario) {
        Navigator.pushReplacementNamed(context, '/secretario_dashboard');
        print("Login exitoso: Eres Secretario");
      }
    } else {
      // Alerta de error integrada con tu tema
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
    _identificadorCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Fondo con gradiente suave
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
              // Tarjeta elevada
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono / Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150, // Ajusta el tamaño según se vea mejor
                        height: 150,
                        fit: BoxFit.contain, // Para que no se deforme
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

                    // Campos de Texto
                    TextField(
                      controller: _identificadorCtrl,
                      decoration: InputDecoration(
                        labelText: "RUT o Correo Electrónico",
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscureText, 
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        // Botón para ver/ocultar clave
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón de Ingreso
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

                    // Redirección a Registro
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
    );
  }
}