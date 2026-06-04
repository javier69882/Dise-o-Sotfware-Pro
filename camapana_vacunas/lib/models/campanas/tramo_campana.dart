import '../usuarios/paciente.dart';
import '../transacciones/registro_vacunacion.dart';

class TramoCampana {
  String nombreTramo;
  String poblacionObjetivo;
  int nivelPrioridad;
  DateTime fechaInicio;
  DateTime fechaFin;
  
  // Agregamos la lista de registros para cumplir con el diagrama de reportes
  List<RegistroVacunacion> registros = [];

  TramoCampana({
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

  // Refleja el paso 1.2 del diagrama hola.drawio.png
  Map<String, int> recopilarSintomas() {
    Map<String, int> statsTramo = {"Leve": 0, "Moderado": 0, "Grave": 0};
    
    // Paso 1.2.1: iterar registros y getSintomas()
    for (var reg in registros) {
      var sint = reg.getSintomas();
      // Paso 1.2.1.1: compilarEstadisticasGravedad()
      var statsSintoma = sint.compilarEstadisticasGravedad();
      
      statsTramo["Leve"] = (statsTramo["Leve"] ?? 0) + (statsSintoma["Leve"] ?? 0);
      statsTramo["Moderado"] = (statsTramo["Moderado"] ?? 0) + (statsSintoma["Moderado"] ?? 0);
      statsTramo["Grave"] = (statsTramo["Grave"] ?? 0) + (statsSintoma["Grave"] ?? 0);
    }
    return statsTramo;
  }
}