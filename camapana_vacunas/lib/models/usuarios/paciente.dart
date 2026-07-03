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

  // Mapeo para la BD (Firestore, SQL, etc.)
  Map<String, dynamic> toMap() {
    return {
      'rol': 'Paciente', // <-- CRÍTICO para el polimorfismo
      'rut': rut,
      'nombres': nombres,
      'apellidos': apellidos,
      'correo': correo,
      'telefono': telefono,
      'fechaNacimiento': fechaNacimiento.toIso8601String(), // Las fechas siempre van como String ISO
      'prevision': prevision,
      'grupoRiesgo': grupoRiesgo,
      'estadoVacunacion': estadoVacunacion,
    };
  }

  // 2. Reconstruir desde la BD
  factory Paciente.fromMap(Map<String, dynamic> map) {
    return Paciente(
      rut: map['rut'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      correo: map['correo'],
      telefono: map['telefono'],
      fechaNacimiento: DateTime.parse(map['fechaNacimiento']),
      prevision: map['prevision'],
      grupoRiesgo: map['grupoRiesgo'],
      estadoVacunacion: map['estadoVacunacion'],
    );
  }
}


