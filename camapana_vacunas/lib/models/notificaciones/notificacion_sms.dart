import 'notificacion_decorator.dart';

class NotificacionSMS extends NotificacionDecorator {
  NotificacionSMS(super.notificacionBase);

  @override
  void enviarMensaje() {
    super.enviarMensaje(); 
    _enviarPorSMS();  
  }

  void _enviarPorSMS() {
    print("📱 Enviando copia del mensaje vía SMS (Mensaje de Texto)...");
  }
}