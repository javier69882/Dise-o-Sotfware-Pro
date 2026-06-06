import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../routes/app_routes.dart';
import 'dashboard_screen.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final db = MockDatabase();
  
  // Controlador para el fondo animado
  late AnimationController _bgController;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  @override
  void initState() {
    super.initState();
    if (db.usuarios.isEmpty) db.inicializarDatos();

    // Configuramos la animación del fondo para que dure 10 segundos
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
    ]).animate(_bgController);

    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
    ]).animate(_bgController);

    _bgController.repeat(); // Hacer que el ciclo sea infinito
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _ingresarConPerfil(dynamic usuario) {
    db.usuarioActivo = usuario;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = CurvedAnimation(parent: animation, curve: Curves.easeOutExpo);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final double oscilacion = math.sin(_bgController.value * 2 * math.pi);

          return Stack(
            children: [
              // FONDO DE PANTALLA ANIMADO
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _topAlignment.value,
                    end: _bottomAlignment.value,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
              ),
              
              // ESFERAS FLOTANTES
              Positioned(
                top: -50 + (oscilacion * 40),
                left: -50 + (oscilacion * 20),
                child: Container(
                  width: 300, 
                  height: 300, 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Theme.of(context).colorScheme.primary.withOpacity(0.25), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100 - (oscilacion * 50),
                right: -80 - (oscilacion * 30),
                child: Container(
                  width: 400, 
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Theme.of(context).colorScheme.secondary.withOpacity(0.25), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // CONTENIDO PRINCIPAL
              child!,
            ],
          );
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: Icon(Icons.health_and_safety_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Sistema Clínico",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Selecciona tu perfil de acceso",
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 30),

                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: db.usuarios.length,
                        itemBuilder: (context, index) {
                          var u = db.usuarios[index];
                          return _buildGlassCard(u);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildPrimaryButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  // WIDGET: Tarjeta de Cristal Personalizada
  Widget _buildGlassCard(dynamic u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, spreadRadius: -5)
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _ingresarConPerfil(u),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${u.nombres} ${u.apellidos}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                            const SizedBox(height: 4),
                            Text("Rol: ${u.runtimeType}", style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.5), size: 18),
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

  // WIDGET: Botón de Crear Perfil
  Widget _buildPrimaryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.createProfile)
            .then((_) => setState(() {}));
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text("Registrar Nuevo Perfil"),
    );
  }
}