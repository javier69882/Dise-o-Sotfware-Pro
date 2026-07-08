import '../usuarios/paciente.dart';
import '../centros/centro_vacunacion.dart';
import '../campanas/inventario_vacuna.dart';
import '../notificaciones/notificacion_manager.dart';
import 'cita_vacunacion.dart';
import 'registro_vacunacion.dart';
import '../../services/mock_database.dart';

// La Fachada se encarga de orquestar todo el proceso de registro de vacunación, 
// desde la verificación del inventario hasta la actualización del estado de la cita y el paciente. 
// También se encarga de notificar al sistema sobre el nuevo registro de inmunización.
class FachadaRegistroVacunacion {
  
  static String procesarVacunacion({
    required CitaVacunacion cita, 
    required Paciente paciente, 
    required CentroVacunacion centro,
    required String rutProfesional,
    required String observaciones,
    required InventarioVacuna loteSeleccionado,
  }) {
    try {
      var db = MockDatabase();

      // 1. Validar el lote seleccionado explícitamente (Seguridad clínica)
      if (loteSeleccionado.cantidadDisponible <= 0) {
        throw Exception("El lote seleccionado ya no tiene stock disponible.");
      }
      if (loteSeleccionado.estaVencida()) {
        throw Exception("El lote seleccionado se encuentra vencido.");
      }

      // 2. Descontar el stock de manera atómica
      loteSeleccionado.cantidadDisponible -= 1; 
      
      // 3. AQUÍ SE DISPARA EL PATRÓN OBSERVER AUTOMÁTICAMENTE
      cita.estado = "Completada";         
      
      paciente.estadoVacunacion = "Completo"; 

      // 4. Crear el registro histórico usando los datos exactos del lote seleccionado
      var nuevoRegistro = RegistroVacunacion(
        idRegistro: "REG-${DateTime.now().millisecondsSinceEpoch}",
        rutPaciente: paciente.rut,
        idCentro: centro.idCentro,
        idTramo: cita.idTramo,
        idInventario: loteSeleccionado.idInventario, // Se enlaza con el inventario correcto
        idCita: cita.idCita,
        rutProfesional: rutProfesional,
        fechaHora: DateTime.now(),
        observaciones: observaciones,
      );

      // 5. Guardar en base de datos
      db.historialRegistros.add(nuevoRegistro);

      // 6. Disparar notificaciones
      NotificacionManager().notificarRegistroInmunizacion(paciente.rut, nuevoRegistro.idRegistro);

      return "Éxito: Inmunización registrada para ${paciente.nombres}. Lote: ${loteSeleccionado.lote}";
    } catch (e) {
      return "Error: ${e.toString().replaceAll("Exception: ", "")}";
    }
  }
}