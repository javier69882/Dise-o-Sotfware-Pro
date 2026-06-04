import 'historial_medico.dart';

class HistorialMedicoBuilder {
  String _datosPersonales = "";
  final List<String> _vacunas = [];
  final List<String> _alergias = [];
  final List<String> _condiciones = [];
  bool _consentimiento = false;

  HistorialMedicoBuilder setDatosPersonales(String datos) {
    _datosPersonales = datos;
    return this; // Permite encadenamiento (chaining)
  }

  HistorialMedicoBuilder agregarVacuna(String detalleVacuna) {
    _vacunas.add(detalleVacuna);
    return this;
  }

  HistorialMedicoBuilder agregarAlergia(String alergia) {
    _alergias.add(alergia);
    return this; 
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
      datosPersonales: _datosPersonales,
      vacunasAplicadas: _vacunas.isEmpty ? "No registra vacunas previas." : _vacunas.join('\n\n'),
      alergias: _alergias.join(', '),
      condicionesPrevias: _condiciones.join(', '),
      consentimientoCompartir: _consentimiento,
    );
  }
}