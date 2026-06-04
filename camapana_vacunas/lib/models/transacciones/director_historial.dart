import 'historial_medico_builder.dart';
import 'historial_medico.dart';
import '../usuarios/paciente.dart';
import '../../services/mock_database.dart';
import '../../utils/date_formatter.dart';

class DirectorHistorial {
  final HistorialMedicoBuilder _builder;

  DirectorHistorial(this._builder);

  /// Ahora el Director recibe las alergias y condiciones ingresadas en la UI
  HistorialMedico construirHistorialCompleto(
    Paciente paciente, 
    List<String> alergiasPaciente, 
    List<String> condicionesPaciente
  ) {
    var db = MockDatabase();

    // Paso 1: Datos Personales
    _builder.setDatosPersonales(
      "Nombre: ${paciente.nombres} ${paciente.apellidos}\n"
      "RUT: ${paciente.rut}\n"
      "Previsión: ${paciente.prevision} | Grupo de Riesgo: ${paciente.grupoRiesgo}"
    );

    // Paso 2: Antecedentes (Dinámicos ingresados por el usuario)
    for (var alergia in alergiasPaciente) {
      _builder.agregarAlergia(alergia);
    }
    for (var condicion in condicionesPaciente) {
      _builder.agregarCondicion(condicion);
    }
    _builder.setConsentimiento(true);

    // Paso 3: Buscar las vacunas
    var registros = db.historialRegistros.where((r) => r.rutPaciente == paciente.rut).toList();
    
    for (var reg in registros) {
      String centroN = db.centros.firstWhere((c) => c.idCentro == reg.idCentro).nombre;
      
      String bloqueVacuna = "• Aplicación: ${DateFormatter.formatDateTime(reg.fechaHora)} en $centroN\n"
                            "  ID Registro: ${reg.idRegistro}\n"
                            "  Síntomas reportados: ${reg.getSintomas().sintomas.isEmpty ? 'Ninguno' : reg.getSintomas().sintomas}\n"
                            "  Observaciones clínicas: ${reg.observaciones}";
      _builder.agregarVacuna(bloqueVacuna);
    }

    return _builder.build();
  }
}