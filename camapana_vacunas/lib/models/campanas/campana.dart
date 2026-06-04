import 'tramo_campana.dart';
import '../usuarios/empresa.dart';
import 'vacuna.dart';

class Campana {
  String idCampana; // PK
  String rutAdmin; // FK (NN)
  Vacuna vacuna; // Representa FK id_vacuna (NN)
  Empresa? empresaAsociada; // Representa FK rut_empresa
  
  String nombre;
  String descripcion;
  DateTime fechaInicio;
  DateTime fechaTermino;
  bool vigencia;
  
  List<TramoCampana> tramos = [];

  Campana({
    required this.idCampana,
    required this.rutAdmin,
    required this.vacuna,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaTermino,
    this.vigencia = true,
    this.empresaAsociada,
  });

  void agregarTramo(TramoCampana tramo) {
    tramos.add(tramo);
  }

  double calcularAvanceGlobal() {
    if (tramos.isEmpty) return 0.0;
    int totalVacunados = tramos.fold(0, (sum, tramo) => sum + tramo.contarVacunadosTramo());
    int metaEstimada = 100; 
    return (totalVacunados / metaEstimada) * 100;
  }

  Map<String, int> generarReporteEfectos() {
    Map<String, int> statsGlobal = {"Leve": 0, "Moderado": 0, "Grave": 0};
    for (var t in tramos) {
      var statsTramo = t.recopilarSintomas();
      statsGlobal["Leve"] = (statsGlobal["Leve"] ?? 0) + (statsTramo["Leve"] ?? 0);
      statsGlobal["Moderado"] = (statsGlobal["Moderado"] ?? 0) + (statsTramo["Moderado"] ?? 0);
      statsGlobal["Grave"] = (statsGlobal["Grave"] ?? 0) + (statsTramo["Grave"] ?? 0);
    }
    return statsGlobal;
  }
}