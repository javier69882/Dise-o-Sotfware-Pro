import 'notificacion_decorator.dart';

class NotificacionWhatsApp extends NotificacionDecorator {
  NotificacionWhatsApp(super.notificacionBase);

  @override
  void enviarMensaje() {
    super.enviarMensaje(); // Ejecuta el envío de la base y decoradores previos
    _enviarPorWhatsApp();  // Añade la funcionalidad específica de WhatsApp
  }

  void _enviarPorWhatsApp() {
    print("🟢 [WhatsApp] Enviando copia del mensaje vía WhatsApp...");
  }
}