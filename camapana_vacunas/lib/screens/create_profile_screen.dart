import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
import '../models/usuarios/persona_usuaria.dart';
import '../services/mock_database.dart';
import '../widgets/custom_dialogs.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _rutCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();

  final _departamentoCtrl = TextEditingController();
  final _idSecretarioCtrl = TextEditingController();
  final _registroCtrl = TextEditingController();
  final _unidadAsignadaCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();

  String _rolSeleccionado = "Paciente";
  String _grupoRiesgoSeleccionado = "Público General";

  final List<String> _opcionesRol = [
    "Paciente",
    "Administrador",
    "Secretario",
    "Enfermero",
    "Médico",
  ];

  final List<String> _opcionesRiesgo = [
    "Adultos Mayores",
    "Crónicos",
    "Embarazadas",
    "Personal de Salud",
    "Jovenes Sanos",
    "Público General",
  ];

  void _crearYGuardar() {
    if (_formKey.currentState!.validate()) {
      PersonaUsuaria nuevoUsuario;
      DateTime fechaNac = DateTime(1990, 1, 1);

      switch (_rolSeleccionado) {
        case "Administrador":
          nuevoUsuario = Administrador(
            rut: _rutCtrl.text,
            nombres: _nombresCtrl.text,
            apellidos: _apellidosCtrl.text,
            correo: _correoCtrl.text,
            telefono: "S/N",
            fechaNacimiento: fechaNac,
            departamento: _departamentoCtrl.text.isEmpty
                ? "General"
                : _departamentoCtrl.text,
          );
          break;
        case "Secretario":
          nuevoUsuario = Secretario(
            rut: _rutCtrl.text,
            nombres: _nombresCtrl.text,
            apellidos: _apellidosCtrl.text,
            correo: _correoCtrl.text,
            telefono: "S/N",
            fechaNacimiento: fechaNac,
            idSecretario: _idSecretarioCtrl.text.isEmpty
                ? "SEC-NUEVO"
                : _idSecretarioCtrl.text,
          );
          break;
        case "Enfermero":
          nuevoUsuario = Enfermero(
            rut: _rutCtrl.text,
            nombres: _nombresCtrl.text,
            apellidos: _apellidosCtrl.text,
            correo: _correoCtrl.text,
            telefono: "S/N",
            fechaNacimiento: fechaNac,
            registro: _registroCtrl.text.isEmpty
                ? "REG-000"
                : _registroCtrl.text,
            unidadAsignada: _unidadAsignadaCtrl.text.isEmpty
                ? "Vacunatorio General"
                : _unidadAsignadaCtrl.text,
          );
          break;
        case "Médico":
          nuevoUsuario = Medico(
            rut: _rutCtrl.text,
            nombres: _nombresCtrl.text,
            apellidos: _apellidosCtrl.text,
            correo: _correoCtrl.text,
            telefono: "S/N",
            fechaNacimiento: fechaNac,
            registro: _registroCtrl.text.isEmpty
                ? "REG-MED"
                : _registroCtrl.text,
            especialidad: _especialidadCtrl.text.isEmpty
                ? "Medicina General"
                : _especialidadCtrl.text,
          );
          break;
        case "Paciente":
        default:
          nuevoUsuario = Paciente(
            rut: _rutCtrl.text,
            nombres: _nombresCtrl.text,
            apellidos: _apellidosCtrl.text,
            correo: _correoCtrl.text,
            telefono: "S/N",
            fechaNacimiento: fechaNac,
            prevision: "Fonasa",
            grupoRiesgo: _grupoRiesgoSeleccionado,
            estadoVacunacion: "Sin vacunas",
          );
          break;
      }

      MockDatabase().usuarios.add(nuevoUsuario);

      CustomDialogs.showSnackBar(
        context,
        'Perfil de $_rolSeleccionado creado exitosamente',
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Nuevo Perfil")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Datos de la Cuenta",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: "Tipo de Perfil (Rol)",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFE0F2F1),
                    ),
                    items: _opcionesRol
                        .map(
                          (rol) =>
                              DropdownMenuItem(value: rol, child: Text(rol)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _rolSeleccionado = val!),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Información Personal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rutCtrl,
                    decoration: const InputDecoration(
                      labelText: "RUT (Ej: 12.345.678-9)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio.';
                      }
                      if (!RegExp(
                        r"\d{1,2}\.\d{3}\.\d{3}-[\dKk]$",
                      ).hasMatch(value)) {
                        return 'No tiene formato de rut solicitado';
                      } //chequea formato básico de correo
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombresCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombres",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosCtrl,
                    decoration: const InputDecoration(
                      labelText: "Apellidos",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _correoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Correo Electrónico",
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio.';
                      }
                      if (!RegExp(
                        /*r'^[a-z|A-Z|0-9]+\@[a-z|A-Z|0-9]+\.[a-z]+$',*/
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&ñ'*+-/=?^_`{|}~]+@[a-zA-Z0-9ñ]+\.[a-zA-Zñ]+",
                      ).hasMatch(value)) {
                        return 'No tiene formato de correo';
                      } //chequea formato básico de correo
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Información Específica del Rol",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_rolSeleccionado == "Paciente") ...[
                    DropdownButtonFormField<String>(
                      value: _grupoRiesgoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Grupo de Riesgo",
                        border: OutlineInputBorder(),
                      ),
                      items: _opcionesRiesgo
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _grupoRiesgoSeleccionado = val!),
                    ),
                  ],

                  if (_rolSeleccionado == "Administrador") ...[
                    TextFormField(
                      controller: _departamentoCtrl,
                      decoration: const InputDecoration(
                        labelText: "Departamento a Cargo",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (_rolSeleccionado == "Secretario") ...[
                    TextFormField(
                      controller: _idSecretarioCtrl,
                      decoration: const InputDecoration(
                        labelText: "ID de Secretario (Ej: SEC-002)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (_rolSeleccionado == "Enfermero" ||
                      _rolSeleccionado == "Médico") ...[
                    TextFormField(
                      controller: _registroCtrl,
                      decoration: const InputDecoration(
                        labelText: "Registro Nacional de Salud",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_rolSeleccionado == "Enfermero") ...[
                    TextFormField(
                      controller: _unidadAsignadaCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unidad Asignada (Ej: Vacunatorio B)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (_rolSeleccionado == "Médico") ...[
                    TextFormField(
                      controller: _especialidadCtrl,
                      decoration: const InputDecoration(
                        labelText: "Especialidad (Ej: Inmunología)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _crearYGuardar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      "Registrar $_rolSeleccionado",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
