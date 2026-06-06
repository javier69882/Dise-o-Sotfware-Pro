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
    "Secretario/a",
    "Enfermero/a",
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
        case "Secretario/a":
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
        case "Enfermero/a":
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
      // AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: Text(
          "Crear Nuevo Perfil",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            children: [
              // Contenedor principal
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.manage_accounts_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Datos de la Cuenta",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _rolSeleccionado,
                        decoration: InputDecoration(
                          labelText: "Tipo de Perfil (Rol)",
                          prefixIcon: Icon(Icons.badge_rounded, color: Theme.of(context).colorScheme.primary),
                          fillColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                        ),
                        items: _opcionesRol.map((rol) => DropdownMenuItem(value: rol, child: Text(rol))).toList(),
                        onChanged: (val) => setState(() => _rolSeleccionado = val!),
                      ),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Icons.person_pin_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Información Personal",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _rutCtrl,
                        decoration: InputDecoration(
                          labelText: "RUT (Ej: 12.345.678-9)",
                          prefixIcon: Icon(Icons.credit_card_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return 'Este campo es obligatorio.';
                          if (!RegExp(r"\d{1,2}\.\d{3}\.\d{3}-[\dKk]$").hasMatch(value)) {
                            return 'No tiene el formato solicitado';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombresCtrl,
                        decoration: InputDecoration(
                          labelText: "Nombres",
                          prefixIcon: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosCtrl,
                        decoration: InputDecoration(
                          labelText: "Apellidos",
                          prefixIcon: Icon(Icons.people_alt_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _correoCtrl,
                        decoration: InputDecoration(
                          labelText: "Correo Electrónico",
                          prefixIcon: Icon(Icons.email_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return 'Este campo es obligatorio.';
                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&ñ'*+-/=?^_`{|}~]+@[a-zA-Z0-9ñ]+\.[a-zA-Zñ]+").hasMatch(value)) {
                            return 'No tiene formato de correo válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Icons.work_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Información Específica del Rol",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_rolSeleccionado == "Paciente") ...[
                        DropdownButtonFormField<String>(
                          value: _grupoRiesgoSeleccionado,
                          decoration: InputDecoration(
                            labelText: "Grupo de Riesgo",
                            prefixIcon: Icon(Icons.health_and_safety_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          items: _opcionesRiesgo.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) => setState(() => _grupoRiesgoSeleccionado = val!),
                        ),
                      ],

                      if (_rolSeleccionado == "Administrador") ...[
                        TextFormField(
                          controller: _departamentoCtrl,
                          decoration: InputDecoration(
                            labelText: "Departamento a Cargo",
                            prefixIcon: Icon(Icons.domain_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],

                      if (_rolSeleccionado == "Secretario/a") ...[
                        TextFormField(
                          controller: _idSecretarioCtrl,
                          decoration: InputDecoration(
                            labelText: "ID de Secretario (Ej: SEC-002)",
                            prefixIcon: Icon(Icons.assignment_ind_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],

                      if (_rolSeleccionado == "Enfermero/a" || _rolSeleccionado == "Médico") ...[
                        TextFormField(
                          controller: _registroCtrl,
                          decoration: InputDecoration(
                            labelText: "Registro Nacional de Salud",
                            prefixIcon: Icon(Icons.medical_information_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_rolSeleccionado == "Enfermero/a") ...[
                        TextFormField(
                          controller: _unidadAsignadaCtrl,
                          decoration: InputDecoration(
                            labelText: "Unidad Asignada (Ej: Vacunatorio B)",
                            prefixIcon: Icon(Icons.vaccines_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],

                      if (_rolSeleccionado == "Médico") ...[
                        TextFormField(
                          controller: _especialidadCtrl,
                          decoration: InputDecoration(
                            labelText: "Especialidad (Ej: Inmunología)",
                            prefixIcon: Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _crearYGuardar,
                        icon: const Icon(Icons.save_rounded),
                        label: Text("Registrar $_rolSeleccionado"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}