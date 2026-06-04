import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/create_profile_screen.dart';

class AppRoutes {
  // Nombres de las rutas
  static const String welcome = '/';
  static const String dashboard = '/dashboard';
  static const String createProfile = '/create_profile';

  // Mapa de rutas para el MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => const WelcomeScreen(),
      dashboard: (context) => const DashboardScreen(),
      createProfile: (context) => const CreateProfileScreen(),
    };
  }
}