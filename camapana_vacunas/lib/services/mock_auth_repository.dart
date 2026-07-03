import 'i_auth_repository.dart';
import '../../models/usuarios/persona_usuaria.dart';
import 'mock_database.dart';

class MockAuthRepository implements IAuthRepository {
  final db = MockDatabase.instancia;

  @override
  Future<PersonaUsuaria?> login(String identificador, String password) async {
    // Simulamos un pequeño retraso de red (1 segundo) para que se vea real
    await Future.delayed(const Duration(seconds: 1)); 

    try {
      // Buscamos si el RUT o el correo coinciden en nuestra lista en memoria
      var usuarioEncontrado = db.usuarios.firstWhere(
        (u) => u.rut == identificador || u.correo == identificador
      );

      // Como es un Mock, aceptamos una contraseña genérica para pruebas
      if (password == '1234') {
        db.usuarioActivo = usuarioEncontrado; // Guardamos el estado global
        return usuarioEncontrado;
      } else {
        return null; // Contraseña incorrecta
      }
    } catch (e) {
      return null; // El firstWhere lanza error si no encuentra a nadie
    }
  }

  @override
  Future<void> logout() async {
    db.usuarioActivo = null;
    
  }
}
