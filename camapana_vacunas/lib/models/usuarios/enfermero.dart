import 'profesional_salud.dart';

class Enfermero extends ProfesionalSalud {
  String unidadAsignada;

  Enfermero({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    required super.registro,
    required this.unidadAsignada,
  });
}