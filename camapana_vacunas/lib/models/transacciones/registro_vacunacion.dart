import 'seguimiento_sintomas.dart';

class RegistroVacunacion {
  // --- Campos del Esquema de Base de Datos ---
  String idRegistro; // PK
  String rutPaciente; // FK
  String idCentro; // FK
  String idTramo; // FK
  String idInventario; // FK
  String? idCita; // FK (Puede ser NULL)
  String rutProfesional; // FK
  DateTime fechaHora;
  String observaciones;

  // --- Lógica Interna Original ---
  late SeguimientoSintomas _seguimiento;

  RegistroVacunacion({
    required this.idRegistro,
    required this.rutPaciente,
    required this.idCentro,
    required this.idTramo,
    required this.idInventario,
    this.idCita,
    required this.rutProfesional,
    required this.fechaHora,
    this.observaciones = '',
  }) {
    // Se inicializa un seguimiento vacío al momento de crear el registro
    _seguimiento = SeguimientoSintomas(
      fechaReporte: DateTime.now(),
    );
  }

  SeguimientoSintomas getSintomas() {
    return _seguimiento;
  }
}