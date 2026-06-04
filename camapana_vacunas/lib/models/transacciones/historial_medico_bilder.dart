import 'historial_medico.dart';

class HistorialMedicoBuilder {
  final List<String> _alergias = [];
  final List<String> _condiciones = [];
  bool _consentimiento = false;

  HistorialMedicoBuilder agregarAlergia(String alergia) {
    _alergias.add(alergia);
    return this; // Permite encadenamiento (chaining)
  }

  HistorialMedicoBuilder agregarCondicion(String condicion) {
    _condiciones.add(condicion);
    return this;
  }

  HistorialMedicoBuilder setConsentimiento(bool estado) {
    _consentimiento = estado;
    return this;
  }

  HistorialMedico build() {
    return HistorialMedico.crear(
      alergias: _alergias.join(', '),
      condicionesPrevias: _condiciones.join(', '),
      consentimientoCompartir: _consentimiento,
    );
  }
}