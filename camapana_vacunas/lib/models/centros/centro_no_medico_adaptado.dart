import 'centro_vacunacion.dart';

class CentroNoMedicoAdaptado extends CentroVacunacion {
  String ubicacionEstablecimiento;

  CentroNoMedicoAdaptado({
    required super.idCentro,
    required super.nombre,
    required super.direccion,
    required super.comuna,
    required super.region,
    required super.capacidadDiaria,
    required super.horarioAtencion,
    required super.tipo,
    super.estadoDisponibilidad,
    required this.ubicacionEstablecimiento,
  });
}