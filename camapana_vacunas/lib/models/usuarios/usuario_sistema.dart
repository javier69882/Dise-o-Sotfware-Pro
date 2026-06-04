class UsuarioSistema {
  String identificador;
  String credencial; // Idealmente un hash, no texto plano
  String rol;
  String? tokenJWT;

  UsuarioSistema({
    required this.identificador,
    required this.credencial,
    required this.rol,
    this.tokenJWT,
  });

  bool iniciarSesion(String user, String pass) {
    if (identificador == user && credencial == pass) {
      // Simulación de generación de token
      tokenJWT = "header.payload.signature_${DateTime.now().millisecondsSinceEpoch}";
      return true;
    }
    return false;
  }

  void cerrarSesion() {
    tokenJWT = null;
  }

  bool validarTokenVigente() {
    return tokenJWT != null && tokenJWT!.isNotEmpty;
  }

  bool tienePermiso(String accionRequerida) {
    // Lógica básica de Control de Acceso Basado en Roles (RBAC)
    if (rol == 'Administrador') return true;
    if (rol == 'Secretario' && accionRequerida == 'Agendar') return true;
    return false;
  }
}