import '../models/campanas/campana.dart';
import '../models/campanas/tramo_campana.dart';
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

  // Memoria
  List<PersonaUsuaria> usuarios = [];
  List<Campana> campanas = [];
  List<CentroVacunacion> centros = [];
  List<Empresa> empresas = [];

  PersonaUsuaria? usuarioActivo;

  void inicializarDatos() {
    // 1. Crear Usuarios
    usuarios.add(Administrador(
      rut: "11.111.111-1", nombres: "Admin", apellidos: "Sistema", correo: "admin@salud.cl", telefono: "999999999", fechaNacimiento: DateTime(1980, 1, 1), departamento: "Gestión Central"
    ));
    usuarios.add(Secretario(
      rut: "22.222.222-2", nombres: "Marta", apellidos: "Recepcionista", correo: "marta@salud.cl", telefono: "888888888", fechaNacimiento: DateTime(1990, 5, 10), idSecretario: "SEC-001"
    ));
    usuarios.add(Paciente(
      rut: "21.345.678-9", nombres: "Javier", apellidos: "Ignacio", correo: "javier@correo.cl", telefono: "977777777", fechaNacimiento: DateTime(2004, 8, 15), prevision: "Fonasa", grupoRiesgo: "Jovenes Sanos", estadoVacunacion: "Incompleto"
    ));
    usuarios.add(Enfermero(
      rut: "33.333.333-3", nombres: "Laura", apellidos: "Clinica", correo: "laura@salud.cl", telefono: "966666666", fechaNacimiento: DateTime(1985, 3, 20), registro: "ENF-992", unidadAsignada: "Vacunatorio A"
    ));

    // 2. Crear Empresas de prueba
    empresas.add(Empresa(rut: "77.777.777-7", razonSocial: "Tech Solutions S.A.", giro: "Desarrollo de Software"));
    empresas.add(Empresa(rut: "88.888.888-8", razonSocial: "Constructora Biobío", giro: "Construcción"));

    // 3. Crear Centros
    centros.add(CentroMedico(
      nombre: "Centro Médico UdeC", direccion: "Barrio Universitario", capacidadDiaria: 50, horarioAtencion: "09:00 - 17:00", tipoEstablecimiento: "Universitario"
    ));
    centros.add(CentroNoMedicoAdaptado(
      nombre: "Gimnasio Sportlife Prat", direccion: "Prat 123", capacidadDiaria: 100, horarioAtencion: "10:00 - 16:00", ubicacionEstablecimiento: "Gimnasio Adaptado"
    ));

    // 4. Crear Campañas
    Campana campanaInvierno = Campana(nombre: "Campaña Invierno 2026", descripcion: "Vacunación general", fechaInicio: DateTime.now().subtract(const Duration(days: 10)), fechaTermino: DateTime.now().add(const Duration(days: 60)));
    campanaInvierno.agregarTramo(TramoCampana(nombreTramo: "Estudiantes y Jóvenes", poblacionObjetivo: "Jovenes Sanos", nivelPrioridad: 2, fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 30))));
    
    campanas.add(campanaInvierno);
  }
}