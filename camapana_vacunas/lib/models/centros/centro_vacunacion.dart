import '../transacciones/cita_vacunacion.dart';
import '../usuarios/paciente.dart';

class CentroVacunacion {
  String nombre;
  String direccion;
  int capacidadDiaria;
  String horarioAtencion;
  bool estadoDisponibilidad;
  
  List<CitaVacunacion> citasAgendadas = [];

  CentroVacunacion({
    required this.nombre,
    required this.direccion,
    required this.capacidadDiaria,
    required this.horarioAtencion,
    this.estadoDisponibilidad = true,
  });

  // Paso 1.2 diagrama agendar
  bool consultarDisponibilidad(DateTime fecha) {
    if (!estadoDisponibilidad) return false;
    // Verifica si las citas de ese día superan la capacidad
    int citasMismoDia = citasAgendadas.where((c) => 
      c.fechaHora.year == fecha.year &&
      c.fechaHora.month == fecha.month &&
      c.fechaHora.day == fecha.day
    ).length;
    
    return citasMismoDia < capacidadDiaria;
  }

  // Paso 1.3 diagrama agendar
  CitaVacunacion? crearCita(DateTime fecha, Paciente paciente) {
    if (consultarDisponibilidad(fecha)) {
      // Paso 1.3.1: crear cita
      var nuevaCita = CitaVacunacion(fechaHora: fecha);
      nuevaCita.crearCita(fecha, paciente, this);
      citasAgendadas.add(nuevaCita);
      return nuevaCita;
    }
    return null; // No hay disponibilidad
  }
}