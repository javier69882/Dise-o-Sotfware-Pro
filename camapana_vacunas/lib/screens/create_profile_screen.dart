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
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  String _previsionSeleccionada = "Fonasa";

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FocusNode _rutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  void _registrarPaciente() {
    if (_formKey.currentState!.validate()) {
      
      final rutFormateado = AppValidators.formatearRut(_rutCtrl.text.trim());
      final correoIngresado = _correoCtrl.text.trim().toLowerCase();

      // --- VALIDACIÓN DE DUPLICADOS MANUAL ---
      bool rutDuplicado = db.usuarios.any((u) => u.rut == rutFormateado);
      bool correoDuplicado = db.usuarios.any((u) => u.correo.toLowerCase() == correoIngresado);

      if (rutDuplicado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Ya existe una cuenta registrada con este RUT.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return; 
      }

      if (correoDuplicado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Este correo electrónico ya está en uso.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return; 
      }

      // Si todo está correcto, creamos el paciente
      var nuevoPaciente = Paciente(
        rut: rutFormateado,
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        fechaNacimiento: DateTime(1990, 1, 1), 
        prevision: _previsionSeleccionada,
        grupoRiesgo: "Público General", 
        estadoVacunacion: "Sin vacunas", 
        // password: _passwordCtrl.text.trim(), // Descomentar si tu BD lo maneja
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
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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
                            width: 100, 
                            height: 100,
                            fit: BoxFit.contain, 
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.health_and_safety_rounded, size: 60, color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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

                      // --- SECCIÓN 1: DATOS PERSONALES ---
                      TextFormField(
                        controller: _rutCtrl,
                        focusNode: _rutFocusNode, 
                        autovalidateMode: AutovalidateMode.onUserInteraction, 
                        inputFormatters: [RutFormatter()],
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
                              autovalidateMode: AutovalidateMode.onUserInteraction, 
                              decoration: InputDecoration(
                                labelText: "Nombres",
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorMaxLines: 2,
                              ),
                              validator: (v) => AppValidators.validarVacio(v, "Nombres"), 
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidosCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction, 
                              decoration: InputDecoration(
                                labelText: "Apellidos",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorMaxLines: 2,
                              ),
                              validator: (v) => AppValidators.validarVacio(v, "Apellidos"), 
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoCtrl,
                              keyboardType: TextInputType.phone,
                              autovalidateMode: AutovalidateMode.onUserInteraction, 
                              decoration: InputDecoration(
                                labelText: "Teléfono",
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorMaxLines: 2,
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
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),

                      // --- SECCIÓN 2: DATOS DE ACCESO ---
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction, 
                        decoration: InputDecoration(
                          labelText: "Correo Electrónico",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorMaxLines: 2,
                        ),
                        validator: AppValidators.validarCorreo, 
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorMaxLines: 2,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Obligatorio.";
                                if (v.length < 6) return "Mínimo 6 caracteres.";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: TextFormField(
                              controller: _confirmPasswordCtrl,
                              obscureText: _obscureConfirmPassword,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Confirmar",
                                prefixIcon: const Icon(Icons.lock_reset_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Confirma clave.";
                                if (v != _passwordCtrl.text) return "No coinciden.";
                                return null;
                              },
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