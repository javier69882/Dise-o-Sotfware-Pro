import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
import '../services/mock_auth_repository.dart';

// Importación de las 4 pantallas 
import 'admin_dashboard.dart';
import 'paciente_dashboard.dart';
import 'secretario_dashboard.dart';
import 'enfermero_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

void _cerrarSesion(BuildContext context) async {
    // 1. Usamos tu nuevo repositorio para limpiar la sesión
    await MockAuthRepository().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
    }
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
              child: _enrutarPorRol(db.usuarioActivo, context),
            ),
          ),
        ),
      ),
    );
  }

Widget _enrutarPorRol(dynamic usuario, BuildContext context) {
    if (usuario is Administrador) {
      return AdminDashboard(onLogout: () => _cerrarSesion(context));
    }
    if (usuario is Paciente) {
      return PacienteDashboard(onLogout: () => _cerrarSesion(context));
    }
    if (usuario is Secretario) {
      return SecretarioDashboard(onLogout: () => _cerrarSesion(context));
    }
    if (usuario is Enfermero || usuario is Medico) {
      return EnfermeroDashboard(onLogout: () => _cerrarSesion(context));
    }
    
    return const Center(child: Text("Error: Rol no parametrizado en el sistema."));
  }
}