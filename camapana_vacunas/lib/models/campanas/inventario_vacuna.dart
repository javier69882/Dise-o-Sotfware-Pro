class InventarioVacuna {
  String lote;
  int cantidadDisponible;
  DateTime fechaVencimiento;

  InventarioVacuna({
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

  void registrarIngresoLote(int cantidad) {
    cantidadDisponible += cantidad;
  }
}