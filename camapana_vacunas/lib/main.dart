import 'package:flutter/material.dart';
import 'routes/app_routes.dart'; // <-- ESTA ES LA LÍNEA QUE FALTABA

void main() {
  runApp(const VacunacionApp());
}

class VacunacionApp extends StatelessWidget {
  const VacunacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Vacunación',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Integración del sistema de rutas centralizado
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.getRoutes(),
    );
  }
}