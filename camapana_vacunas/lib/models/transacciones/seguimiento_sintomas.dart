class SeguimientoSintomas {
  DateTime fechaReporte;
  String sintomas;
  String nivelGravedad; 

  SeguimientoSintomas({
    required this.fechaReporte,
    this.sintomas = "Sin síntomas reportados",
    this.nivelGravedad = "Ninguno",
  });

  void actualizarSintomas(String nuevosSintomas, String gravedad) {
    sintomas = nuevosSintomas;
    nivelGravedad = gravedad;
    fechaReporte = DateTime.now();
  }

  
  Map<String, int> compilarEstadisticasGravedad() {
    Map<String, int> stats = {"Leve": 0, "Moderado": 0, "Grave": 0};
    if (nivelGravedad == "Leve") stats["Leve"] = 1;
    if (nivelGravedad == "Moderado") stats["Moderado"] = 1;
    if (nivelGravedad == "Grave") stats["Grave"] = 1;
    return stats;
  }
}