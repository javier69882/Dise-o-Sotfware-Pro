import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/create_profile_screen.dart';
import '../screens/enfermero_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/secretario_dashboard.dart';
import '../screens/login_screen.dart';
import '../services/mock_auth_repository.dart';

class AppRoutes {
  // Nombres de las rutas
  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String createProfile = '/create_profile';

  // 1. Definir los identificadores de ruta para cada rol
  static const String enfermeroDashboard = '/enfermero_dashboard';
  static const String adminDashboard = '/admin_dashboard';
  static const String secretarioDashboard = '/secretario_dashboard';

  // Mapa de rutas para el MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
  // Función centralizada para cerrar sesión desde las rutas directas
    void handleLogout(BuildContext context) async {
      await MockAuthRepository().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }

    return {
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      createProfile: (context) => const CreateProfileScreen(),

      // 2. Mapear cada ruta con su respectivo Widget de pantalla
      enfermeroDashboard: (context) => EnfermeroDashboard(
        onLogout: () => handleLogout(context),
      ),
      adminDashboard: (context) => AdminDashboard(
        onLogout: () => handleLogout(context),
      ),
      secretarioDashboard: (context) => SecretarioDashboard(
        onLogout: () => handleLogout(context),
      ),
    };
  }
}