import 'persona_usuaria.dart';

class Paciente extends PersonaUsuaria {
  String? rutSecretarioCreador; // FK puede ser NULL
  String prevision;
  String grupoRiesgo;
  String estadoVacunacion;

  Paciente({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    this.rutSecretarioCreador,
    required this.prevision,
    required this.grupoRiesgo,
    required this.estadoVacunacion,
  });
}