import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../services/mock_database.dart';
import '../utils/app_validators.dart'; 

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final db = MockDatabase();

  final _rutCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _previsionSeleccionada = "Fonasa";

  final FocusNode _rutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _rutFocusNode.addListener(() {
      if (!_rutFocusNode.hasFocus && _rutCtrl.text.isNotEmpty) {
        _rutCtrl.text = AppValidators.formatearRut(_rutCtrl.text);
      }
    });
  }

  void _registrarPaciente() {
    if (_formKey.currentState!.validate()) {
      
      _rutCtrl.text = AppValidators.formatearRut(_rutCtrl.text);

      var nuevoPaciente = Paciente(
        rut: _rutCtrl.text.trim(),
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        fechaNacimiento: DateTime(1990, 1, 1), 
        prevision: _previsionSeleccionada,
        grupoRiesgo: "Público General", 
        estadoVacunacion: "Sin vacunas", 
      );

      setState(() {
        db.usuarios.add(nuevoPaciente);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cuenta de paciente creada exitosamente. Por favor, inicia sesión.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context); 
    }
  }

  @override
  void dispose() {
    _rutFocusNode.dispose(); 
    _rutCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  // Se eliminó el autovalidateMode de aquí para que no salte todo de golpe
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      
                      // --- INICIO SECCIÓN LOGO ---
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 100, // Un poco más pequeño que en el login para balancear el espacio
                            height: 100,
                            fit: BoxFit.contain, 
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- FIN SECCIÓN LOGO ---

                      Text(
                        "Crear Cuenta",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Portal ciudadano",
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _rutCtrl,
                        focusNode: _rutFocusNode, 
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Validación independiente
                        decoration: InputDecoration(
                          labelText: "RUT (Ej: 12.345.678-9)",
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: AppValidators.validarRut, 
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombresCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction, // Validación independiente
                              decoration: InputDecoration(
                                labelText: "Nombres",
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => AppValidators.validarVacio(v, "Nombres"), 
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidosCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction, // Validación independiente
                              decoration: InputDecoration(
                                labelText: "Apellidos",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => AppValidators.validarVacio(v, "Apellidos"), 
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Validación independiente
                        decoration: InputDecoration(
                          labelText: "Correo Electrónico",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: AppValidators.validarCorreo, 
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoCtrl,
                              keyboardType: TextInputType.phone,
                              autovalidateMode: AutovalidateMode.onUserInteraction, // Validación independiente
                              decoration: InputDecoration(
                                labelText: "Teléfono",
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              inputFormatters: AppValidators.filtroTelefono, 
                              validator: AppValidators.validarTelefono, 
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _previsionSeleccionada,
                              decoration: InputDecoration(
                                labelText: "Previsión",
                                prefixIcon: const Icon(Icons.health_and_safety_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ["Fonasa", "Isapre", "Particular"].map((String val) {
                                return DropdownMenuItem(value: val, child: Text(val));
                              }).toList(),
                              onChanged: (newVal) => setState(() => _previsionSeleccionada = newVal!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _registrarPaciente,
                        child: const Text("Registrarme como Paciente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}