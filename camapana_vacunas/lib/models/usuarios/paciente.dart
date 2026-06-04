import 'persona_usuaria.dart';

class Paciente extends PersonaUsuaria {
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
    required this.prevision,
    required this.grupoRiesgo,
    required this.estadoVacunacion,
  });

  void iniciarAgendamiento() {
    print("Paciente $nombres iniciando agendamiento...");
    // Lógica para abrir flujo de CitaVacunacion
  }
}