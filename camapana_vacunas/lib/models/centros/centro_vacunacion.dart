import '../transacciones/cita_vacunacion.dart';
import '../usuarios/paciente.dart';
import '../campanas/inventario_vacuna.dart';

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
        idCita: DateTime.now().millisecondsSinceEpoch.toString(), 
        rutPaciente: paciente.rut,
        idTramo: idTramo,
        idCentro: idCentro,
        fechaHora: fecha,
      );
      citasAgendadas.add(nuevaCita);
      return nuevaCita;
    }
    return null;
  }
}