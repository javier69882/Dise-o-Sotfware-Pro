import 'i_observador_cita.dart';
import 'i_notificacion.dart';
import 'notificacion_base.dart';
import 'notificacion_email.dart';
import 'notificacion_sms.dart';
import 'notificacion_whatsapp.dart';

// Aquí se utiliza el patrón Singleton
class NotificacionManager implements IObservadorCita {

  // Implementación del patrón Singleton
  static final NotificacionManager _instancia = NotificacionManager._internal();
  factory NotificacionManager() => _instancia;
  NotificacionManager._internal();

  //se usara este correo de prueba para enviar notificaciones por correo electrónico a través de Resend. En un entorno de producción, este correo debería ser dinámico y provenir de la base de datos del paciente.
  static const String correoPrueba = 'javier69882@gmail.com';

  final List<String> registroNotificaciones = [];

  @override
  void actualizarEstadoCita(String estado, String motivo) {
    String mensaje = "Su cita ha cambiado a estado: $estado. Motivo: $motivo";
    // Usamos un correo de prueba para Resend. En el futuro, podrías buscar el correo del paciente en la MockDatabase.
    _ensamblarYEnviar(
      "Sistema de Citas", 
      mensaje, 
      usarEmail: true, 
      usarSMS: true, 
      usarWhatsApp: false,
      correoDestinatario: correoPrueba 
    );
  }

  void notificarRegistroInmunizacion(String rutPaciente, String idRegistro) {
    String mensaje = "Se ha registrado exitosamente la inmunización del paciente $rutPaciente (Reg: $idRegistro).";
    _ensamblarYEnviar(
      "Clínico", 
      mensaje, 
      usarEmail: true, 
      usarWhatsApp: true, 
      usarSMS: false,
      correoDestinatario: correoPrueba
    );
  }
  
  void notificarNuevaCita(String rutPaciente, String fechaFormateada, String nombreCentro) {
    String mensaje = "Estimado paciente ($rutPaciente), su cita ha sido agendada con éxito para el $fechaFormateada en la sede $nombreCentro.";
    _ensamblarYEnviar(
      "Agendamiento", 
      mensaje, 
      usarEmail: true, 
      usarSMS: true, 
      usarWhatsApp: false,
      correoDestinatario: correoPrueba
    );
  }

  // Agregamos correoDestinatario con un valor por defecto vacío o genérico
  void _ensamblarYEnviar(String tipo, String mensaje, {
    bool usarEmail = false, 
    bool usarWhatsApp = false, 
    bool usarSMS = false,
    String correoDestinatario = ''
  }) {
    print("\n--- INICIANDO ENVÍO DE NOTIFICACIÓN ---");
    
    INotificacion notificacion = NotificacionBase(tipo: tipo, mensaje: mensaje);

    if (usarEmail) {
      // Ahora le pasamos el correo al decorador para que la API de Resend lo reciba
      notificacion = NotificacionEmail(notificacion, correoDestinatario: correoDestinatario);
    }
    if (usarWhatsApp) {
      notificacion = NotificacionWhatsApp(notificacion);
    }
    if (usarSMS) {
      notificacion = NotificacionSMS(notificacion);
    }

    notificacion.enviarMensaje();
    registroNotificaciones.add("[$tipo] $mensaje");
    
    print("---------------------------------------\n");
  }
}