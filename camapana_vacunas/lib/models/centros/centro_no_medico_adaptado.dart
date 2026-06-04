import 'centro_vacunacion.dart';

class CentroNoMedicoAdaptado extends CentroVacunacion {
  String ubicacionEstablecimiento; // Ej: Gimnasio, Estadio, Colegio

  CentroNoMedicoAdaptado({
    required super.nombre,
    required super.direccion,
    required super.capacidadDiaria,
    required super.horarioAtencion,
    super.estadoDisponibilidad,
    required this.ubicacionEstablecimiento,
  });
}