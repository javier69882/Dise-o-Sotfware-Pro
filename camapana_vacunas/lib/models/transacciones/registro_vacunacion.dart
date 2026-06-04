import 'seguimiento_sintomas.dart';

class RegistroVacunacion {
  DateTime fechaHora;
  String observaciones;
  late SeguimientoSintomas _seguimiento;

  RegistroVacunacion({
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