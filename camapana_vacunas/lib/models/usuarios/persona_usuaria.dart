abstract class PersonaUsuaria {
  String rut;
  String nombres;
  String apellidos;
  DateTime fechaNacimiento;
  String correo;
  String telefono;

  PersonaUsuaria({
    required this.rut,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.correo,
    required this.telefono,
  });
}