import 'i_observador_cita.dart';

class NotificacionManager implements IObservadorCita {
  // Patrón Singleton: Instancia única privada
  static final NotificacionManager _instancia = NotificacionManager._internal();

  // Constructor factory que retorna la instancia única
  factory NotificacionManager() {
    return _instancia;
  }

  // Constructor interno privado
  NotificacionManager._internal();

  @override
  void actualizarEstadoCita(String estado, String motivo) {
    print("NotificacionManager: Estado de cita actualizado a '$estado'. Motivo: $motivo");
    enviarNotificacion("Sistema", "Su cita ha cambiado a estado $estado.");
  }

  void enviarNotificacion(String tipo, String mensaje) {
    // Aquí se integraría la lógica para despachar la notificación base
    print("Enviando notificación [$tipo]: $mensaje");
  }
}