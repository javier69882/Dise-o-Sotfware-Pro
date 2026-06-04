import '../usuarios/paciente.dart';
import '../centros/centro_vacunacion.dart';
import 'cita_vacunacion.dart';
import 'registro_vacunacion.dart';
import '../../services/mock_database.dart';

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

      // 1. Obtener vacuna requerida
      var campana = db.campanas.firstWhere((c) => c.tramos.any((t) => t.idTramo == cita.idTramo));
      String idVacunaRequerida = campana.vacuna.idVacuna;

      // 2. Control de Inventario y Stock
      var inventario = centro.inventarios.firstWhere(
        (inv) => inv.vacuna.idVacuna == idVacunaRequerida && inv.cantidadDisponible > 0 && !inv.estaVencida(),
        orElse: () => throw Exception("Sede sin stock vigente para esta inmunización.")
      );

      // 3. Modificaciones transaccionales simultáneas
      inventario.cantidadDisponible -= 1; // Restar stock
      cita.estado = "Completada";         // Modificar Cita
      paciente.estadoVacunacion = "Completo"; // Actualizar esquema paciente

      // 4. CREAR E INSERTAR EL REGISTRO (Fachada unifica la creación de la transacción)
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

      return "Éxito: Inmunización registrada para ${paciente.nombres}. Lote: ${inventario.lote}";
    } catch (e) {
      return "Error: ${e.toString().replaceAll("Exception: ", "")}";
    }
  }
}