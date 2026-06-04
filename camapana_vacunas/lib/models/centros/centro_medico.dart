import 'centro_vacunacion.dart';

class CentroMedico extends CentroVacunacion {
  String tipoEstablecimiento; // Ej: CESFAM, Hospital, Clínica Privada

  CentroMedico({
    required super.nombre,
    required super.direccion,
    required super.capacidadDiaria,
    required super.horarioAtencion,
    super.estadoDisponibilidad,
    required this.tipoEstablecimiento,
  });
}