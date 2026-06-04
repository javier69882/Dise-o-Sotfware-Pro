import 'persona_usuaria.dart';

class Secretario extends PersonaUsuaria {
  String idSecretario;

  Secretario({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    required this.idSecretario,
  });

  void iniciarAgendamiento() {
    print("Secretario $nombres abriendo módulo de agendamiento para pacientes...");
  }
}