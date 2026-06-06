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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: _enrutarPorRol(db.usuarioActivo),
            ),
          ),
        ),
      ),
      
      // BOTÓN DE CERRAR SESIÓN UNIVERSAL
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _cerrarSesion(context),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.error,
        elevation: 4,
        icon: const Icon(Icons.logout_rounded),
        label: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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