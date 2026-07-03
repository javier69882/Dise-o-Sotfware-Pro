import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/app_routes.dart'; 
import 'utils/app_theme.dart';
import 'services/mock_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 3. Inicializa los usuarios, campañas y centros en memoria
  MockDatabase().inicializarDatos();
  runApp(const VacunacionApp());
}

class VacunacionApp extends StatelessWidget {
  const VacunacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Vacunación',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Tema definido en app_theme.dart
      
      initialRoute: AppRoutes.login,
      routes: AppRoutes.getRoutes(),
    );
  }
}
