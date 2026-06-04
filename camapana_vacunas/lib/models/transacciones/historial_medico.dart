class HistorialMedico {
  final String alergias;
  final String condicionesPrevias;
  final bool consentimientoCompartir;

  // Constructor privado para obligar el uso del Builder
  HistorialMedico._({
    required this.alergias,
    required this.condicionesPrevias,
    required this.consentimientoCompartir,
  });

  // Amigo de la clase Builder
  factory HistorialMedico.crear({
    required String alergias,
    required String condicionesPrevias,
    required bool consentimientoCompartir,
  }) {
    return HistorialMedico._(
      alergias: alergias,
      condicionesPrevias: condicionesPrevias,
      consentimientoCompartir: consentimientoCompartir,
    );
  }
}