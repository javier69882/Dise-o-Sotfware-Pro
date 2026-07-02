import 'notificacion_decorator.dart';
import 'notificacion_base.dart'; 
import '../../services/ResendService.dart'; // Importamos el servicio según la ruta de tu proyecto

class NotificacionEmail extends NotificacionDecorator {
  final String correoDestinatario;

  // Añadimos el correoDestinatario al constructor
  NotificacionEmail(super.notificacionBase, {required this.correoDestinatario});

  @override
  void enviarMensaje() {
    super.enviarMensaje(); // Ejecuta la cadena anterior
    _enviarPorEmail();     // Añade su propia funcionalidad
  }

  // Convertimos este método en asíncrono (async) para la petición HTTP
  Future<void> _enviarPorEmail() async {
    print("✉️ Preparando envío vía Correo Electrónico...");

    // Extraemos el mensaje de la clase base haciendo un casteo (cast) seguro
    String textoMensaje = '';
    if (notificacionBase is NotificacionBase) {
      textoMensaje = (notificacionBase as NotificacionBase).mensaje;
    } else {
      textoMensaje = 'Tienes una nueva notificación en el sistema.'; 
    }

    // Ejecutamos el envío
    await ResendService.enviarNotificacion(
      recipientEmail: correoDestinatario,
      mensaje: textoMensaje,
    );
  }
}