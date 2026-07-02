import 'dart:convert';
import 'package:http/http.dart' as http;

class ResendService {
 static const String _apiKey = 're_baqQnZ9F_3gA4QLYX3GyFTeimjPfPcrjo';
  static const String _apiUrl = 'https://api.resend.com/emails';

  static Future<void> enviarNotificacion({
    required String recipientEmail,
    required String mensaje, // <-- Aquí recibimos el texto de la NotificacionBase
  }) async {
    final url = Uri.parse(_apiUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'onboarding@resend.dev',
          'to': [recipientEmail],
          'subject': 'Nueva Notificación',
          'html': '<p>$mensaje</p>', // <-- Inyectamos el mensaje en el cuerpo del correo
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Correo enviado exitosamente a $recipientEmail');
      } else {
        print('❌ Error al enviar el correo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción al conectar con Resend: $e');
    }
  }
}