import 'vacuna.dart';

class InventarioVacuna {
  String idInventario; // PK
  String idCentro; // FK
  Vacuna vacuna; // FK id_vacuna
  String lote;
  int cantidadDisponible;
  DateTime fechaVencimiento;

  InventarioVacuna({
    required this.idInventario,
    required this.idCentro,
    required this.vacuna,
    required this.lote,
    required this.cantidadDisponible,
    required this.fechaVencimiento,
  });

  bool verificarStockCritico(int umbral) {
    return cantidadDisponible <= umbral;
  }

  bool estaVencida() {
    return DateTime.now().isAfter(fechaVencimiento);
  }
}