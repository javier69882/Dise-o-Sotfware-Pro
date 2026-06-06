import 'i_notificacion.dart';
// El Decorator se encarga de agregar funcionalidades adicionales a las notificaciones sin modificar su estructura base. Permite combinar diferentes canales de envío (Email, SMS, WhatsApp) de manera flexible y escalable.
abstract class NotificacionDecorator implements INotificacion {
  final INotificacion notificacionBase;

  NotificacionDecorator(this.notificacionBase);

  @override
  void enviarMensaje() {
    // Delega la ejecución al objeto base (o al decorador anterior)
    notificacionBase.enviarMensaje();
  }
}