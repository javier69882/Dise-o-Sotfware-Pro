import '../transacciones/cita_vacunacion.dart';
import '../usuarios/paciente.dart';
import '../campanas/inventario_vacuna.dart';
import '../notificaciones/notificacion_manager.dart';
import '../../utils/date_formatter.dart';

class CentroVacunacion {
  String idCentro; // PK
  String nombre;
  String direccion;
  String comuna; 
  String region; 
  int capacidadDiaria;
  String horarioAtencion;
  bool estadoDisponibilidad;
  String tipo; 
  
  List<CitaVacunacion> citasAgendadas = [];
  List<InventarioVacuna> inventarios = []; // Relación Centro *-- Inventario

  CentroVacunacion({
    required this.idCentro,
    required this.nombre,
    required this.direccion,
    required this.comuna,
    required this.region,
    required this.capacidadDiaria,
    required this.horarioAtencion,
    required this.tipo,
    this.estadoDisponibilidad = true,
  });

  // NUEVO MÉTODO: Revisa si el centro tiene stock vigente de la vacuna requerida
  bool tieneStockDeVacuna(String idVacuna) {
    return inventarios.any((inv) => 
      inv.vacuna.idVacuna == idVacuna && 
      inv.cantidadDisponible > 0 && 
      !inv.estaVencida()
    );
  }

  bool consultarDisponibilidad(DateTime fecha) {
    if (!estadoDisponibilidad) return false;
    int citasMismoDia = citasAgendadas.where((c) => 
      c.fechaHora.year == fecha.year &&
      c.fechaHora.month == fecha.month &&
      c.fechaHora.day == fecha.day
    ).length;
    
    return citasMismoDia < capacidadDiaria;
  }

  CitaVacunacion? crearCita(DateTime fecha, Paciente paciente, String idTramo) {
    if (consultarDisponibilidad(fecha)) {
      var nuevaCita = CitaVacunacion(
        idCita: "CITA-${DateTime.now().millisecondsSinceEpoch}",
        rutPaciente: paciente.rut,
        idTramo: idTramo,
        idCentro: this.idCentro,
        fechaHora: fecha, // Corregido: usa el parámetro 'fecha'
        estado: "Programada", 
      );

      citasAgendadas.add(nuevaCita);

      // --- NUEVO CÓDIGO HU-16: DISPARAR NOTIFICACIÓN ---
      NotificacionManager().notificarNuevaCita(
        paciente.rut, 
        DateFormatter.formatDateTime(fecha), // Corregido: usa el parámetro 'fecha'
        this.nombre
      );

      return nuevaCita;
    }
    return null;
  }
}