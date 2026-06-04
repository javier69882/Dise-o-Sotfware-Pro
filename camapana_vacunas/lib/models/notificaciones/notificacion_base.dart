import 'i_notificacion.dart';

class NotificacionBase implements INotificacion {
  String tipo;
  DateTime fechaEnvio;
  String mensaje;
  String estadoEnvio;

  NotificacionBase({
    required this.tipo,
    required this.mensaje,
  })  : fechaEnvio = DateTime.now(),
        estadoEnvio = 'Pendiente';

  @override
  void enviarMensaje() {
    estadoEnvio = 'Enviado';
    print("Notificación Base enviada: $mensaje");
  }
}