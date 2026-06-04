import 'notificacion_decorator.dart';

class NotificacionEmail extends NotificacionDecorator {
  NotificacionEmail(super.notificacionBase);

  @override
  void enviarMensaje() {
    super.enviarMensaje(); // Ejecuta la cadena anterior
    _enviarPorEmail();     // Añade su propia funcionalidad
  }

  void _enviarPorEmail() {
    print("✉️ Enviando copia del mensaje vía Correo Electrónico...");
  }
}