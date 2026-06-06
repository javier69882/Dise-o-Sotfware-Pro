import '../usuarios/paciente.dart';
import '../centros/centro_vacunacion.dart';
import '../notificaciones/notificacion_manager.dart'; // <-- Nueva importación
import 'cita_vacunacion.dart';
import 'registro_vacunacion.dart';
import '../../services/mock_database.dart';
// La Fachada se encarga de orquestar todo el proceso de registro de vacunación, desde la verificación del inventario hasta la actualización del estado de la cita y el paciente. También se encarga de notificar al sistema sobre el nuevo registro de inmunización.
class FachadaRegistroVacunacion {
  
  static String procesarVacunacion({
    required CitaVacunacion cita, 
    required Paciente paciente, 
    required CentroVacunacion centro,
    required String rutProfesional,
    required String observaciones
  }) {
    try {
      var db = MockDatabase();

      var campana = db.campanas.firstWhere((c) => c.tramos.any((t) => t.idTramo == cita.idTramo));
      String idVacunaRequerida = campana.vacuna.idVacuna;

      var inventario = centro.inventarios.firstWhere(
        (inv) => inv.vacuna.idVacuna == idVacunaRequerida && inv.cantidadDisponible > 0 && !inv.estaVencida(),
        orElse: () => throw Exception("Sede sin stock vigente para esta inmunización.")
      );

      inventario.cantidadDisponible -= 1; 
      
      // AQUÍ SE DISPARA EL PATRÓN OBSERVER AUTOMÁTICAMENTE
      cita.estado = "Completada";         
      
      paciente.estadoVacunacion = "Completo"; 

      var nuevoRegistro = RegistroVacunacion(
        idRegistro: "REG-${DateTime.now().millisecondsSinceEpoch}",
        rutPaciente: paciente.rut,
        idCentro: centro.idCentro,
        idTramo: cita.idTramo,
        idInventario: inventario.idInventario,
        idCita: cita.idCita,
        rutProfesional: rutProfesional,
        fechaHora: DateTime.now(),
        observaciones: observaciones,
      );

      db.historialRegistros.add(nuevoRegistro);

   
      NotificacionManager().notificarRegistroInmunizacion(paciente.rut, nuevoRegistro.idRegistro);

      return "Éxito: Inmunización registrada para ${paciente.nombres}. Lote: ${inventario.lote}";
    } catch (e) {
      return "Error: ${e.toString().replaceAll("Exception: ", "")}";
    }
  }
}