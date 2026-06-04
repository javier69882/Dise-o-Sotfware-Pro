import '../models/campanas/campana.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/vacuna.dart';
import '../models/campanas/inventario_vacuna.dart';
import '../models/centros/centro_medico.dart';
import '../models/centros/centro_no_medico_adaptado.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/persona_usuaria.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/empresa.dart';

class MockDatabase {
  static final MockDatabase instancia = MockDatabase._internal();
  factory MockDatabase() => instancia;
  MockDatabase._internal();

  List<PersonaUsuaria> usuarios = [];
  List<Campana> campanas = [];
  List<CentroVacunacion> centros = [];
  List<Empresa> empresas = [];
  List<Vacuna> vacunas = [];

  PersonaUsuaria? usuarioActivo;

  void inicializarDatos() {
    usuarios.add(Administrador(rut: "11.111.111-1", nombres: "Admin", apellidos: "Sistema", correo: "admin@salud.cl", telefono: "999999999", fechaNacimiento: DateTime(1980, 1, 1), departamento: "Gestión Central"));
    usuarios.add(Secretario(rut: "22.222.222-2", nombres: "Marta", apellidos: "Recepcionista", correo: "marta@salud.cl", telefono: "888888888", fechaNacimiento: DateTime(1990, 5, 10), idSecretario: "SEC-001"));
    usuarios.add(Paciente(rut: "21.345.678-9", nombres: "Javier", apellidos: "Ignacio", correo: "javier@correo.cl", telefono: "977777777", fechaNacimiento: DateTime(2004, 8, 15), prevision: "Fonasa", grupoRiesgo: "Jovenes Sanos", estadoVacunacion: "Incompleto"));
    
    empresas.add(Empresa(rut: "77.777.777-7", razonSocial: "Tech Solutions S.A.", giro: "Desarrollo de Software"));

    // 1. Crear dos vacunas distintas
    var vacunaCOVID = Vacuna(idVacuna: "VAC-COVID", nombre: "Moderna Bivalente", laboratorio: "Moderna");
    var vacunaInfluenza = Vacuna(idVacuna: "VAC-INFLU", nombre: "Influenza 2026", laboratorio: "Sanofi");
    vacunas.addAll([vacunaCOVID, vacunaInfluenza]);

    // 2. Crear los centros
    var centroMedico = CentroMedico(
      idCentro: "CEN-001", nombre: "Centro Médico UdeC", direccion: "Barrio Universitario", comuna: "Concepción", region: "Biobío", capacidadDiaria: 50, horarioAtencion: "09:00 - 17:00", tipo: "Médico", tipoEstablecimiento: "Universitario"
    );
    var centroGimnasio = CentroNoMedicoAdaptado(
      idCentro: "CEN-002", nombre: "Gimnasio Sportlife Prat", direccion: "Prat 123", comuna: "Concepción", region: "Biobío", capacidadDiaria: 100, horarioAtencion: "10:00 - 16:00", tipo: "Adaptado", ubicacionEstablecimiento: "Gimnasio Adaptado"
    );

    // 3. Asignar inventarios (¡AQUÍ ESTÁ LA MAGIA!)
    // El Centro Médico UdeC SOLO tiene vacuna COVID
    centroMedico.inventarios.add(InventarioVacuna(idInventario: "INV-1", idCentro: centroMedico.idCentro, vacuna: vacunaCOVID, lote: "L-123", cantidadDisponible: 50, fechaVencimiento: DateTime.now().add(const Duration(days: 90))));
    
    // El Gimnasio SOLO tiene vacuna Influenza
    centroGimnasio.inventarios.add(InventarioVacuna(idInventario: "INV-2", idCentro: centroGimnasio.idCentro, vacuna: vacunaInfluenza, lote: "L-999", cantidadDisponible: 100, fechaVencimiento: DateTime.now().add(const Duration(days: 90))));

    centros.addAll([centroMedico, centroGimnasio]);

    // 4. Crear Campañas (Una para COVID, otra para Influenza)
    Campana campanaInvierno = Campana(
      idCampana: "CAMP-001", rutAdmin: "11.111.111-1", vacuna: vacunaCOVID, nombre: "Campaña COVID Invierno", descripcion: "Vacunación general", fechaInicio: DateTime.now().subtract(const Duration(days: 10)), fechaTermino: DateTime.now().add(const Duration(days: 60))
    );
    campanaInvierno.agregarTramo(TramoCampana(idTramo: "TR-001", idCampana: "CAMP-001", nombreTramo: "Jóvenes", poblacionObjetivo: "Jovenes Sanos", nivelPrioridad: 2, fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 30))));
    
    Campana campanaInfluenza = Campana(
      idCampana: "CAMP-002", rutAdmin: "11.111.111-1", vacuna: vacunaInfluenza, nombre: "Campaña Influenza Nacional", descripcion: "Campaña anual", fechaInicio: DateTime.now().subtract(const Duration(days: 5)), fechaTermino: DateTime.now().add(const Duration(days: 30))
    );
    campanaInfluenza.agregarTramo(TramoCampana(idTramo: "TR-002", idCampana: "CAMP-002", nombreTramo: "General", poblacionObjetivo: "Público General", nivelPrioridad: 1, fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 30))));

    campanas.addAll([campanaInvierno, campanaInfluenza]);
  }
}