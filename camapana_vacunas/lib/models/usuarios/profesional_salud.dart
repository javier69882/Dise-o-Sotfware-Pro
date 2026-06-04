import 'persona_usuaria.dart';

abstract class ProfesionalSalud extends PersonaUsuaria {
  String registro; // Registro Nacional de Prestadores Individuales

  ProfesionalSalud({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    required this.registro,
  });
}