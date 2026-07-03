import '../../models/usuarios/persona_usuaria.dart';

abstract class IAuthRepository {
  // Retorna el usuario si el login es exitoso, o null si falla.
  Future<PersonaUsuaria?> login(String identificador, String password);
  
  // Opcional para el futuro:
  Future<void> logout();
}