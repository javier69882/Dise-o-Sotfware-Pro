import 'i_observador_cita.dart';
import 'i_notificacion.dart';
import 'notificacion_base.dart';
import 'notificacion_email.dart';
import 'notificacion_sms.dart';
import 'notificacion_whatsapp.dart';

class NotificacionManager implements IObservadorCita {
  static final NotificacionManager _instancia = NotificacionManager._internal();
  factory NotificacionManager() => _instancia;
  NotificacionManager._internal();

  final List<String> registroNotificaciones = [];

  @override
  void actualizarEstadoCita(String estado, String motivo) {
    String mensaje = "Su cita ha cambiado a estado: $estado. Motivo: $motivo";
    _ensamblarYEnviar("Sistema de Citas", mensaje, usarEmail: true, usarSMS: true, usarWhatsApp: false);
  }

  void notificarRegistroInmunizacion(String rutPaciente, String idRegistro) {
    String mensaje = "Se ha registrado exitosamente la inmunización del paciente $rutPaciente (Reg: $idRegistro).";
    _ensamblarYEnviar("Clínico", mensaje, usarEmail: true, usarWhatsApp: true, usarSMS: false);
  }

  // --- NUEVO MÉTODO PARA HU-16: Confirmación de Agendamiento ---
  void notificarNuevaCita(String rutPaciente, String fechaFormateada, String nombreCentro) {
    String mensaje = "Estimado paciente ($rutPaciente), su cita ha sido agendada con éxito para el $fechaFormateada en la sede $nombreCentro.";
    // Decidimos despacharlo por Email y SMS
    _ensamblarYEnviar("Agendamiento", mensaje, usarEmail: true, usarSMS: true, usarWhatsApp: false);
  }

  void _ensamblarYEnviar(String tipo, String mensaje, {bool usarEmail = false, bool usarWhatsApp = false, bool usarSMS = false}) {
    print("\n--- INICIANDO ENVÍO DE NOTIFICACIÓN ---");
    
    INotificacion notificacion = NotificacionBase(tipo: tipo, mensaje: mensaje);

    if (usarEmail) {
      notificacion = NotificacionEmail(notificacion);
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