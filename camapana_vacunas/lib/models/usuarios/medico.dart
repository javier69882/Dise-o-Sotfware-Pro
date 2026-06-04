import 'profesional_salud.dart';

class Medico extends ProfesionalSalud {
  String especialidad;

  Medico({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    required super.registro,
    required this.especialidad,
  });
}