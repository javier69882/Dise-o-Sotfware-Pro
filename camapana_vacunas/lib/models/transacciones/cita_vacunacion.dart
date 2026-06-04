import '../usuarios/paciente.dart';
import '../notificaciones/i_observador_cita.dart';
import '../notificaciones/notificacion_manager.dart';

class CitaVacunacion {
  String idCita;
  String rutPaciente;
  String idTramo;
  String idCentro;
  DateTime fechaHora;
  
  // Atributo privado para controlar el setter
  String _estado; 
  
  // Lista de Observadores
  final List<IObservadorCita> _observadores = [];

  CitaVacunacion({
    required this.idCita,
    required this.rutPaciente,
    required this.idTramo,
    required this.idCentro,
    required this.fechaHora,
    required String estado,
  }) : _estado = estado {
    // Se suscribe automáticamente al Manager al instanciarse
    agregarObservador(NotificacionManager());
  }

  // Getter del estado
  String get estado => _estado;

  // Setter interceptado (Notifica al cambiar)
  set estado(String nuevoEstado) {
    if (_estado != nuevoEstado) {
      _estado = nuevoEstado;
      _notificarObservadores("Cambio gestionado por el sistema o profesional.");
    }
  }

  void agregarObservador(IObservadorCita observador) {
    if (!_observadores.contains(observador)) {
      _observadores.add(observador);
    }
  }

  void removerObservador(IObservadorCita observador) {
    _observadores.remove(observador);
  }

  void _notificarObservadores(String motivo) {
    for (var observador in _observadores) {
      observador.actualizarEstadoCita(_estado, motivo);
    }
  }
}