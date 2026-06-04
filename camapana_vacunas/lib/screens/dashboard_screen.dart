import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
import '../routes/app_routes.dart';

// Importación de las 4 pantallas 100% separadas por Rol
import 'admin_dashboard.dart';
import 'paciente_dashboard.dart';
import 'secretario_dashboard.dart';
import 'enfermero_dashboard.dart';

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
        title: Text("Panel: ${db.usuarioActivo!.nombres} (${db.usuarioActivo!.runtimeType})"),
        backgroundColor: Colors.teal.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.teal),
            tooltip: "Cerrar Sesión",
            onPressed: () => _cerrarSesion(context),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _enrutarPorRol(db.usuarioActivo),
        ),
      ),
    );
  }

  Widget _enrutarPorRol(dynamic usuario) {
    if (usuario is Administrador) return const AdminDashboard();
    if (usuario is Paciente) return const PacienteDashboard();
    if (usuario is Secretario) return const SecretarioDashboard();
    if (usuario is Enfermero || usuario is Medico) return const EnfermeroDashboard();
    
    return const Center(child: Text("Error: Rol no parametrizado en el sistema."));
  }
}