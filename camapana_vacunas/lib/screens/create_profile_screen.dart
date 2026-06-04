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

  void _crearYGuardar() {
    if (_formKey.currentState!.validate()) {
      // Crear el objeto Paciente con los datos del formulario
      var nuevoPaciente = Paciente(
        rut: _rutCtrl.text,
        nombres: _nombresCtrl.text,
        apellidos: _apellidosCtrl.text,
        correo: _correoCtrl.text,
        telefono: "S/N", // Por defecto para hacer el form más corto
        fechaNacimiento: DateTime(2000, 1, 1), 
        prevision: "Fonasa", 
        grupoRiesgo: "Jovenes Sanos", 
        estadoVacunacion: "Sin vacunas"
      );

      // Guardar en la Mock DB
      MockDatabase().usuarios.add(nuevoPaciente);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil creado exitosamente')),
      );

      // Volver a la pantalla de bienvenida
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