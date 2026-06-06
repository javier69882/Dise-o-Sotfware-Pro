import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // PALETA DE COLORES CENTRALIZADA
  static const Color primaryDark = Color(0xFF004D40); // Textos fuertes
  static const Color primary = Color(0xFF00796B);     // Botones principales
  static const Color accent = Color(0xFF26A69A);      // Detalles, iconos
  static const Color background = Color(0xFFF8FAFA);
  static const Color textMuted = Color(0xFF78909C);   // Subtítulos, roles
  
  // Botones destacados o llamadas de atención secundarias (Pill de nuevo paciente)
  static const Color botonesLlamativos = Color.fromRGBO(255, 202, 40, 1); // Ámbar/Amarillo
  
  // Colores de estado semánticos universales (Éxito y Error)
  static const Color success = Color(0xFF2E7D32);     // Verde para "Programada" o "Vacunado"
  static const Color successContainer = Color(0xFFE8F5E9); // Fondo suave para estados de éxito
  static const Color error = Color(0xFFD32F2F);       // Rojo para cancelaciones o alertas
  static const Color errorContainer = Color(0xFFFFEBEE); // Fondo suave para errores

  // CONFIGURACIÓN DEL TEMA GLOBAL
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      
      // 1. ESQUEMA DE COLORES COMPLETO 
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        tertiary: botonesLlamativos,
        onTertiary: const Color.fromARGB(255, 0, 0, 0),
        background: background,
        
        // Contenedores sutiles (Pills de fechas, fondos de íconos en listas)
        primaryContainer: const Color(0xFFE0F2F1),
        onPrimaryContainer: primaryDark,
        
        // Mapeo de estados a contenedores secundarios para el historial
        secondaryContainer: successContainer,      
        onSecondaryContainer: success,
        
        error: error,
        errorContainer: errorContainer,
        
        // Superficies de tarjetas flotantes y diálogos
        surface: Colors.white,
        onSurface: const Color(0xFF263238),
        onBackground: const Color(0xFF263238),
        onSurfaceVariant: textMuted,
        
        // Bordes y líneas sutiles (Selector de fecha, cajas de texto)
        outlineVariant: const Color(0xFFE0E0E0),
      ),

      // 2. TIPOGRAFÍA GLOBAL
      textTheme: GoogleFonts.outfitTextTheme(),
      //textTheme:GoogleFonts.spaceGroteskTextTheme(),

      // 3. ESTILIZACIÓN GLOBAL DE COMPONENTES
      
      // Botones Principales (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withOpacity(0.3),
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Campos de Texto (Inputs de Formularios y Dropdowns)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),

      // Separadores (Dividers)
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECEFF1),
        thickness: 1,
        space: 1,
      ),

      // Red de seguridad para Tarjetas (Card)
      // Si alguno usa un Card tradicional, el programa se adapta al estilo automáticamente
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFECEFF1), width: 1),
        ),
      ),

      // Pestañas (TabBar) 
      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      
    );
  }
}