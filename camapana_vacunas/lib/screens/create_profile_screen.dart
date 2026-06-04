import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../services/mock_database.dart';

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
  
  // Variable para almacenar la selección del grupo de riesgo
  String _grupoRiesgoSeleccionado = "Público General";

  // Opciones estandarizadas que hacen "match" con los tramos de campaña
  final List<String> _opcionesRiesgo = [
    "Adultos Mayores",
    "Crónicos",
    "Embarazadas",
    "Personal de Salud",
    "Jovenes Sanos",
    "Público General"
  ];

  void _crearYGuardar() {
    if (_formKey.currentState!.validate()) {
      var nuevoPaciente = Paciente(
        rut: _rutCtrl.text,
        nombres: _nombresCtrl.text,
        apellidos: _apellidosCtrl.text,
        correo: _correoCtrl.text,
        telefono: "S/N", 
        fechaNacimiento: DateTime(2000, 1, 1), // Simplificado por ahora
        prevision: "Fonasa", 
        grupoRiesgo: _grupoRiesgoSeleccionado, // Usamos la variable del dropdown
        estadoVacunacion: "Sin vacunas"
      );

      MockDatabase().usuarios.add(nuevoPaciente);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil creado exitosamente')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Nuevo Paciente")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text("Ingresa tus datos personales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _rutCtrl,
                    decoration: const InputDecoration(labelText: "RUT (Ej: 12.345.678-9)", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombresCtrl,
                    decoration: const InputDecoration(labelText: "Nombres", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosCtrl,
                    decoration: const InputDecoration(labelText: "Apellidos", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _correoCtrl,
                    decoration: const InputDecoration(labelText: "Correo Electrónico", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nuevo Dropdown para HU-07
                  DropdownButtonFormField<String>(
                    value: _grupoRiesgoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: "Grupo de Riesgo",
                      border: OutlineInputBorder(),
                    ),
                    items: _opcionesRiesgo.map((grupo) {
                      return DropdownMenuItem(
                        value: grupo,
                        child: Text(grupo),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _grupoRiesgoSeleccionado = val!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _crearYGuardar,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text("Registrar Perfil", style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}