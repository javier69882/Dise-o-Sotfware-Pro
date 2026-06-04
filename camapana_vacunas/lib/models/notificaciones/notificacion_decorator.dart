import 'i_notificacion.dart';

abstract class NotificacionDecorator implements INotificacion {
  final INotificacion notificacionBase;

  NotificacionDecorator(this.notificacionBase);

  @override
  void enviarMensaje() {
    // Delega la ejecución al objeto base (o al decorador anterior)
    notificacionBase.enviarMensaje();
  }
}