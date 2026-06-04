import '../notificaciones/i_observador_cita.dart';
import '../usuarios/paciente.dart';
import '../centros/centro_vacunacion.dart';

class CitaVacunacion {
  DateTime fechaHora;
  String estado;
  String motivoCambio;
  
  // Lista de observadores
  final List<IObservadorCita> _observadores = [];

  CitaVacunacion({
    required this.fechaHora,
    this.estado = 'Pendiente',
    this.motivoCambio = '',
  });

  void crearCita(DateTime fecha, Paciente paciente, CentroVacunacion centro) {
    fechaHora = fecha;
    estado = 'Programada';
    motivoCambio = 'Cita inicial creada';
    notificarObservadores();
  }

  // Patrón Observer: Suscripción
  void agregarObservador(IObservadorCita obs) {
    _observadores.add(obs);
  }

  // Patrón Observer: Desuscripción
  void eliminarObservador(IObservadorCita obs) {
    _observadores.remove(obs);
  }

  void cambiarEstado(String nuevoEstado, String motivo) {
    estado = nuevoEstado;
    motivoCambio = motivo;
    notificarObservadores();
  }

  // Patrón Observer: Notificación
  void notificarObservadores() {
    for (var observador in _observadores) {
      observador.actualizarEstadoCita(estado, motivoCambio);
    }
  }
}