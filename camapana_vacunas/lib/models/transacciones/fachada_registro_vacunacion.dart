import 'registro_vacunacion.dart';
import '../campanas/inventario_vacuna.dart';
import 'seguimiento_sintomas.dart';
import '../notificaciones/notificacion_manager.dart';

class FachadaRegistroVacunacion {
  final NotificacionManager _notificacionManager = NotificacionManager();

  void procesarVacunacionCompleta(
    RegistroVacunacion registro,
    InventarioVacuna inventario,
  ) {
    print("Iniciando proceso centralizado de vacunación...");

    // 1. Descontar stock
    if (inventario.cantidadDisponible > 0) {
      inventario.cantidadDisponible -= 1;
      print("Stock descontado. Restante: ${inventario.cantidadDisponible}");
    } else {
      throw Exception("Sin stock de vacunas en el lote ${inventario.lote}");
    }

    // 2. Registrar observaciones
    registro.observaciones += " | Vacuna aplicada exitosamente.";

    // 3. Iniciar seguimiento
    SeguimientoSintomas seguimiento = registro.getSintomas();
    seguimiento.nivelGravedad = "Ninguno (Inicial)";

    // 4. Activar Notificación
    _notificacionManager.enviarNotificacion(
      "Vacunación",
      "Se ha completado el registro de su vacunación.",
    );

    print("Proceso de vacunación finalizado con éxito.");
  }
}