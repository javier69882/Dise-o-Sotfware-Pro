class HistorialMedico {
  final String datosPersonales;
  final String vacunasAplicadas;
  final String alergias;
  final String condicionesPrevias;
  final bool consentimientoCompartir;

  // Constructor privado para obligar el uso del Builder
  HistorialMedico._({
    required this.datosPersonales,
    required this.vacunasAplicadas,
    required this.alergias,
    required this.condicionesPrevias,
    required this.consentimientoCompartir,
  });

  // Amigo de la clase Builder
  factory HistorialMedico.crear({
    String datosPersonales = "Sin información",
    String vacunasAplicadas = "Ninguna",
    required String alergias,
    required String condicionesPrevias,
    required bool consentimientoCompartir,
  }) {
    return HistorialMedico._(
      datosPersonales: datosPersonales,
      vacunasAplicadas: vacunasAplicadas,
      alergias: alergias.isEmpty ? "Ninguna declarada" : alergias,
      condicionesPrevias: condicionesPrevias.isEmpty ? "Ninguna declarada" : condicionesPrevias,
      consentimientoCompartir: consentimientoCompartir,
    );
  }
}