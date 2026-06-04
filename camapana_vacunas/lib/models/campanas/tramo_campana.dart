import '../usuarios/paciente.dart';
import '../transacciones/registro_vacunacion.dart';

class TramoCampana {
  String idTramo; // PK
  String idCampana; // FK
  String nombreTramo;
  String poblacionObjetivo;
  int nivelPrioridad;
  DateTime fechaInicio;
  DateTime fechaFin;
  
  List<RegistroVacunacion> registros = [];

  TramoCampana({
    required this.idTramo,
    required this.idCampana,
    required this.nombreTramo,
    required this.poblacionObjetivo,
    required this.nivelPrioridad,
    required this.fechaInicio,
    required this.fechaFin,
  });

  bool validarPrioridadPaciente(Paciente paciente) {
    return paciente.grupoRiesgo.toLowerCase() == poblacionObjetivo.toLowerCase();
  }

  void registrarVacunacion(RegistroVacunacion registro) {
    registros.add(registro);
  }

  int contarVacunadosTramo() {
    return registros.length;
  }

  Map<String, int> recopilarSintomas() {
    Map<String, int> statsTramo = {"Leve": 0, "Moderado": 0, "Grave": 0};
    for (var reg in registros) {
      var sint = reg.getSintomas();
      var statsSintoma = sint.compilarEstadisticasGravedad();
      statsTramo["Leve"] = (statsTramo["Leve"] ?? 0) + (statsSintoma["Leve"] ?? 0);
      statsTramo["Moderado"] = (statsTramo["Moderado"] ?? 0) + (statsSintoma["Moderado"] ?? 0);
      statsTramo["Grave"] = (statsTramo["Grave"] ?? 0) + (statsSintoma["Grave"] ?? 0);
    }
    return statsTramo;
  }
}