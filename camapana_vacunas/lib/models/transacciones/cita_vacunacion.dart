import '../notificaciones/i_observador_cita.dart';

class CitaVacunacion {
  String idCita; // PK
  String rutPaciente; // FK
  String idTramo; // FK
  String idCentro; // FK
  
  DateTime fechaHora;
  String estado;
  String motivoCambio;
  
  final List<IObservadorCita> _observadores = [];

  CitaVacunacion({
    required this.idCita,
    required this.rutPaciente,
    required this.idTramo,
    required this.idCentro,
    required this.fechaHora,
    this.estado = 'Programada',
    this.motivoCambio = 'Cita inicial creada',
  });

  void agregarObservador(IObservadorCita obs) {
    _observadores.add(obs);
  }

  void eliminarObservador(IObservadorCita obs) {
    _observadores.remove(obs);
  }

  void cambiarEstado(String nuevoEstado, String motivo) {
    estado = nuevoEstado;
    motivoCambio = motivo;
    notificarObservadores();
  }

  void notificarObservadores() {
    for (var observador in _observadores) {
      observador.actualizarEstadoCita(estado, motivoCambio);
    }
  }
}