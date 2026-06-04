import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart'; // Agregamos Médico
import '../routes/app_routes.dart';

// Importamos las 3 vistas separadas
import 'admin_dashboard.dart';
import 'agendamiento_dashboard.dart';
import 'enfermero_dashboard.dart'; // Importamos la nueva vista

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _cerrarSesion(BuildContext context) {
    MockDatabase().usuarioActivo = null;
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    
    if (db.usuarioActivo == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text("Panel: ${db.usuarioActivo!.nombres}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _cerrarSesion(context),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _seleccionarVistaSegunRol(db.usuarioActivo),
        ),
      ),
    );
  }

  Widget _seleccionarVistaSegunRol(dynamic usuarioActivo) {
    if (usuarioActivo is Administrador) {
      return const AdminDashboard();
    }
    if (usuarioActivo is Secretario || usuarioActivo is Paciente) {
      return const AgendamientoDashboard();
    }
    if (usuarioActivo is Enfermero || usuarioActivo is Medico) {
      return const EnfermeroDashboard(); // Redirige al nuevo panel de Fachada
    }
    
    return const Center(child: Text("Rol no reconocido"));
  }
}