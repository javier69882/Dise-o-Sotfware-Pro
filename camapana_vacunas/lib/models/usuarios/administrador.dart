import 'persona_usuaria.dart';
import '../campanas/campana.dart';

class Administrador extends PersonaUsuaria {
  String departamento;

  Administrador({
    required super.rut,
    required super.nombres,
    required super.apellidos,
    required super.fechaNacimiento,
    required super.correo,
    required super.telefono,
    required this.departamento,
  });

  void solicitarAvanceCampana(Campana campana) {
    double avance = campana.calcularAvanceGlobal();
    print("Avance de la campaña '${campana.nombre}': ${avance.toStringAsFixed(2)}%");
  }

  void solicitarReporteEfectos(Campana campana) {
    Map reporte = campana.generarReporteEfectos();
    print("Reporte de efectos: $reporte");
  }
}