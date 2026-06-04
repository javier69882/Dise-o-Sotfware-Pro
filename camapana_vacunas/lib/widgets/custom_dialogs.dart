import 'package:flutter/material.dart';

class CustomDialogs {
  /// Muestra un cuadro de diálogo estándar con un título y contenido
  static void showMessage(BuildContext context, String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cerrar")
          )
        ],
      ),
    );
  }

  /// Muestra un Snackbar en la parte inferior de la pantalla
  static void showSnackBar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}