import 'package:flutter/material.dart';
import '../models/usuarios/persona_usuaria.dart';
import '../screens/profile_screen.dart';

class HeaderActions extends StatelessWidget {
  final PersonaUsuaria usuarioActivo;
  final VoidCallback onLogout;

  const HeaderActions({
    super.key,
    required this.onLogout,
    required this.usuarioActivo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min, // Para que ocupen solo lo necesario
      children: [
        // 1. Botón "Mi Perfil"
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(usuarioActivo: usuarioActivo),
              ),
            );
          },
          icon: Icon(Icons.person_outline, size: 18, color: colorScheme.primary),
          label: const Text('Mi perfil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 12), // Espaciado entre botones
        
        // 2. Botón "Cerrar Sesión"
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
          label: Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error, // Usa tu rojo de error
            side: BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1.5),
            backgroundColor: colorScheme.errorContainer.withOpacity(0.3), // Fondo rojizo muy sutil
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}