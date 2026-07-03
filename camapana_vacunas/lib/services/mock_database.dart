import '../models/campanas/campana.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/vacuna.dart';
import '../models/campanas/inventario_vacuna.dart';
import '../models/centros/centro_medico.dart';
import '../models/centros/centro_no_medico_adaptado.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/transacciones/registro_vacunacion.dart'; // <-- Nueva Importación
import '../models/usuarios/administrador.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
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
  List<RegistroVacunacion> historialRegistros = []; // <-- TABLA GLOBAL DE REGISTROS DE VACUNACIÓN

  PersonaUsuaria? usuarioActivo;

  void inicializarDatos() {
    usuarios.add(Administrador(rut: "11.111.111-1", nombres: "Admin", apellidos: "Sistema", correo: "admin@salud.cl", telefono: "999999999", fechaNacimiento: DateTime(1980, 1, 1), departamento: "Gestión Central"));
    usuarios.add(Secretario(rut: "22.222.222-2", nombres: "Marta", apellidos: "Recepcionista", correo: "marta@salud.cl", telefono: "888888888", fechaNacimiento: DateTime(1990, 5, 10), idSecretario: "SEC-001"));
    
    usuarios.add(Enfermero(rut: "33.333.333-3", nombres: "Laura", apellidos: "Clínica", correo: "laura.c@salud.cl", telefono: "966666666", fechaNacimiento: DateTime(1985, 3, 20), registro: "ENF-992", unidadAsignada: "Vacunatorio A"));
    usuarios.add(Medico(rut: "44.444.444-4", nombres: "Pedro", apellidos: "Rojas", correo: "pedro.rojas@salud.cl", telefono: "955555555", fechaNacimiento: DateTime(1975, 10, 12), registro: "MED-445", especialidad: "Inmunología"));

    usuarios.add(Paciente(rut: "21.345.678-9", nombres: "Javier", apellidos: "Ignacio", correo: "javier@correo.cl", telefono: "977777777", fechaNacimiento: DateTime(2004, 8, 15), prevision: "Fonasa", grupoRiesgo: "Jovenes Sanos", estadoVacunacion: "Incompleto"));
    usuarios.add(Paciente(rut: "55.555.555-5", nombres: "Rosa", apellidos: "Espinoza", correo: "rosa.e@correo.cl", telefono: "944444444", fechaNacimiento: DateTime(1950, 4, 2), prevision: "Fonasa", grupoRiesgo: "Adultos Mayores", estadoVacunacion: "Completo"));
    usuarios.add(Paciente(rut: "66.666.666-6", nombres: "Carlos", apellidos: "Soto", correo: "csoto@correo.cl", telefono: "933333333", fechaNacimiento: DateTime(1982, 11, 28), prevision: "Isapre", grupoRiesgo: "Crónicos", estadoVacunacion: "Incompleto"));
    usuarios.add(Paciente(rut: "77.777.777-7", nombres: "Camila", apellidos: "Vergara", correo: "camila.v@correo.cl", telefono: "922222222", fechaNacimiento: DateTime(1995, 7, 19), prevision: "Fonasa", grupoRiesgo: "Público General", estadoVacunacion: "Sin vacunas"));

    empresas.add(Empresa(rut: "77.777.777-7", razonSocial: "Tech Solutions S.A.", giro: "Desarrollo de Software"));

    var vacunaCOVID = Vacuna(idVacuna: "VAC-COVID", nombre: "Moderna Bivalente", laboratorio: "Moderna");
    var vacunaInfluenza = Vacuna(idVacuna: "VAC-INFLU", nombre: "Influenza 2026", laboratorio: "Sanofi");
    vacunas.addAll([vacunaCOVID, vacunaInfluenza]);

    var centroMedico = CentroMedico(
      idCentro: "CEN-001", nombre: "Centro Médico UdeC", direccion: "Barrio Universitario", comuna: "Concepción", region: "Biobío", capacidadDiaria: 50, horarioAtencion: "09:00 - 17:00", tipo: "Médico", tipoEstablecimiento: "Universitario"
    );
    var centroGimnasio = CentroNoMedicoAdaptado(
      idCentro: "CEN-002", nombre: "Gimnasio Sportlife Prat", direccion: "Prat 123", comuna: "Concepción", region: "Biobío", capacidadDiaria: 100, horarioAtencion: "10:00 - 16:00", tipo: "Adaptado", ubicacionEstablecimiento: "Gimnasio Adaptado"
    );

    centroMedico.inventarios.add(InventarioVacuna(idInventario: "INV-1", idCentro: centroMedico.idCentro, vacuna: vacunaCOVID, lote: "L-123", cantidadDisponible: 50, fechaVencimiento: DateTime.now().add(const Duration(days: 90))));
    centroGimnasio.inventarios.add(InventarioVacuna(idInventario: "INV-2", idCentro: centroGimnasio.idCentro, vacuna: vacunaInfluenza, lote: "L-999", cantidadDisponible: 100, fechaVencimiento: DateTime.now().add(const Duration(days: 90))));
    centros.addAll([centroMedico, centroGimnasio]);

    Campana campanaInvierno = Campana(
      idCampana: "CAMP-001", rutAdmin: "11.111.111-1", vacuna: vacunaCOVID, nombre: "Campaña COVID Invierno", descripcion: "Vacunación general", fechaInicio: DateTime.now().subtract(const Duration(days: 10)), fechaTermino: DateTime.now().add(const Duration(days: 60))
    );
    campanaInvierno.agregarTramo(TramoCampana(idTramo: "TR-001", idCampana: "CAMP-001", nombreTramo: "Jóvenes", poblacionObjetivo: "Jovenes Sanos", nivelPrioridad: 2, fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 30))));
    
    Campana campanaInfluenza = Campana(
      idCampana: "CAMP-002", rutAdmin: "11.111.111-1", vacuna: vacunaInfluenza, nombre: "Campaña Influenza Nacional", descripcion: "Campaña anual", fechaInicio: DateTime.now().subtract(const Duration(days: 5)), fechaTermino: DateTime.now().add(const Duration(days: 30))
    );
    campanaInfluenza.agregarTramo(TramoCampana(idTramo: "TR-002", idCampana: "CAMP-002", nombreTramo: "General", poblacionObjetivo: "Público General", nivelPrioridad: 1, fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 30))));

    campanas.addAll([campanaInvierno, campanaInfluenza]);

    centroMedico.citasAgendadas.add(CitaVacunacion(idCita: "CITA-001", rutPaciente: "21.345.678-9", idTramo: "TR-001", idCentro: "CEN-001", fechaHora: DateTime.now().add(const Duration(days: 2)), estado: "Programada"));
    centroGimnasio.citasAgendadas.add(CitaVacunacion(idCita: "CITA-002", rutPaciente: "55.555.555-5", idTramo: "TR-002", idCentro: "CEN-002", fechaHora: DateTime.now().add(const Duration(days: 5)), estado: "Programada"));
  }
}