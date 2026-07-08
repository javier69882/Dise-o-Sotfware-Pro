import 'package:flutter/services.dart';

class AppValidators {
  
  // 1. Validación de RUT (Formato y limpieza)
  static String? validarRut(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUT es obligatorio.';
    }
    // Limpiamos puntos y guiones para revisar la base
    String rutLimpio = value.replaceAll(RegExp(r'[^0-9kK]'), '');
    
    if (rutLimpio.length < 8 || rutLimpio.length > 9) {
      return 'El largo del RUT no es válido.';
    }
    return null; // Null significa que pasó la validación
  }

  // 2. Validación de Correo con Dominio Específico
  static String? validarCorreo(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio.';
    }
    
    // Regex estándar para correos
    final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!regex.hasMatch(value)) {
      return 'Formato de correo inválido.';
    }
    
    return null;
  }

  // 3. Validación de Teléfono
  static String? validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio.';
    }
    // Aceptamos formato +569 o solo los 9 dígitos
    final regex = RegExp(r'^(\+?56)?9[0-9]{8}$');
    if (!regex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Debe ser número válido (Ej: +56912345678).';
    }
    return null;
  }

  // 4. Validación Genérica (Para nombres, apellidos, texto simple)
  static String? validarVacio(String? value, String nombreCampo) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $nombreCampo es obligatorio.';
    }
    return null;
  }

  // 5. Auto-formateo de RUT UNIFICADO
  static String formatearRut(String rawInput) {
    String inputTrimeado = rawInput.trim();
    
    // Si tiene arroba, asumimos que es correo y lo devolvemos tal cual (útil para el login combinado)
    if (inputTrimeado.contains('@')) return inputTrimeado;

    // Limpiamos dejando solo números y la letra K
    String cleaned = inputTrimeado.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (cleaned.isEmpty) return '';

    // Separamos DV y Cuerpo sin importar el largo (soporta formato en tiempo real)
    String dv = cleaned.length > 1 ? cleaned.substring(cleaned.length - 1) : "";
    String body = cleaned.length > 1 ? cleaned.substring(0, cleaned.length - 1) : cleaned;
    
    String formattedBody = "";
    int count = 0;
    
    for (int i = body.length - 1; i >= 0; i--) {
      formattedBody = body[i] + formattedBody;
      count++;
      if (count % 3 == 0 && i != 0) {
        formattedBody = ".$formattedBody";
      }
    }
    
    return dv.isNotEmpty ? "$formattedBody-$dv" : formattedBody;
  }
  
  // Restricciones de entrada para campos de teléfono (solo números y +)
  static final List<TextInputFormatter> filtroTelefono = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
  ];
}

class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Llamamos a tu función estática
    String formatted = AppValidators.formatearRut(newValue.text);

    return TextEditingValue(
      text: formatted,
      // Mantiene el cursor siempre al final del texto mientras escribes
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BuscadorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Si empieza con número, es estrictamente un RUT
    if (RegExp(r'^[0-9]').hasMatch(newValue.text)) {
      String formatted = AppValidators.formatearRut(newValue.text);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}