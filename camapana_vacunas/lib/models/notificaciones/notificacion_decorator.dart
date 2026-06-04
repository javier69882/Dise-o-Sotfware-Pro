import 'notificacion_decorator.dart';

class NotificacionWhatsApp extends NotificacionDecorator {
  NotificacionWhatsApp(super.notificacionBase);

  @override
  void enviarMensaje() {
    super.enviarMensaje(); // Envía la base
    _enviarPorWhatsApp();  // Añade funcionalidad
  }

  void _enviarPorWhatsApp() {
    print("Enviando copia del mensaje vía WhatsApp...");
  }
}