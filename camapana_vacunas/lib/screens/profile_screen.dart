import 'package:flutter/material.dart';

import '../models/usuarios/persona_usuaria.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/medico.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/profesional_salud.dart';

class ProfileScreen extends StatefulWidget {
  final PersonaUsuaria usuarioActivo;

  const ProfileScreen({super.key, required this.usuarioActivo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController(text: widget.usuarioActivo.correo);
    _telefonoController = TextEditingController(text: widget.usuarioActivo.telefono);

    _correoController.addListener(_checkForChanges);
    _telefonoController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _correoController.text != widget.usuarioActivo.correo ||
                       _telefonoController.text != widget.usuarioActivo.telefono;
    
    if (_hasUnsavedChanges != hasChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<bool> _mostrarDialogoConfirmacion() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Has modificado tus datos de contacto. ¿Deseas guardar los cambios antes de salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('Descartar', style: TextStyle(color: colorScheme.error)),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí falta integrar la llamada a la BD / Hive para guardar
              print("Guardando nuevo correo: ${_correoController.text}");
              print("Guardando nuevo teléfono: ${_telefonoController.text}");
              Navigator.pop(context, true); 
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    return result ?? false; 
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges, 
      onPopInvoked: (didPop) async {
        if (didPop) return; 

        final shouldPop = await _mostrarDialogoConfirmacion();
        if (shouldPop && context.mounted) {
          Navigator.pop(context); 
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mi Perfil"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 24),
            
            _buildReadOnlyGeneralInfo(colorScheme),
            const SizedBox(height: 16),
            
            _buildRoleSpecificInfo(colorScheme),
            const SizedBox(height: 16),

            _buildEditableData(colorScheme),
            const SizedBox(height: 80), // Espacio extra al final para que no lo tape el FAB
          ],
        ),
        floatingActionButton: _hasUnsavedChanges 
            ? FloatingActionButton.extended(
                onPressed: () {
                  // TODO: Lógica de guardado en BD
                  setState(() => _hasUnsavedChanges = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Datos actualizados correctamente'),
                      backgroundColor: colorScheme.secondary,
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
              ) 
            : null,
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildHeader(ColorScheme colorScheme) {
    String rolLabel = widget.usuarioActivo.runtimeType.toString();
    
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: colorScheme.primary,
          child: Text(
            widget.usuarioActivo.nombres[0].toUpperCase(),
            style: TextStyle(fontSize: 40, color: colorScheme.surface, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "${widget.usuarioActivo.nombres} ${widget.usuarioActivo.apellidos}",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            rolLabel,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyGeneralInfo(ColorScheme colorScheme) {
    final fecha = widget.usuarioActivo.fechaNacimiento;
    final fechaStr = "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Información Personal", style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildDataRow("RUT", widget.usuarioActivo.rut, Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildDataRow("Fecha Nacimiento", fechaStr, Icons.cake_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificInfo(ColorScheme colorScheme) {
    final u = widget.usuarioActivo;
    List<Widget> rows = [];

    // Lógica Polimórfica para los datos específicos
    if (u is Paciente) {
      rows = [
        _buildDataRow("Previsión", u.prevision, Icons.health_and_safety_outlined),
        const SizedBox(height: 12),
        _buildDataRow("Grupo de Riesgo", u.grupoRiesgo, Icons.warning_amber_rounded),
        const SizedBox(height: 12),
        _buildDataRow("Estado Vacunación", u.estadoVacunacion, Icons.vaccines_outlined),
      ];
    } else if (u is ProfesionalSalud) {
      rows.add(_buildDataRow("Registro (RNPI)", u.registro, Icons.verified_user_outlined));
      rows.add(const SizedBox(height: 12));
      
      if (u is Medico) {
        rows.add(_buildDataRow("Especialidad", u.especialidad, Icons.medical_services_outlined));
      } else if (u is Enfermero) {
        rows.add(_buildDataRow("Unidad Asignada", u.unidadAsignada, Icons.local_hospital_outlined));
      }
    } else if (u is Administrador) {
      rows = [
        _buildDataRow("Departamento", u.departamento, Icons.domain_outlined),
      ];
    } else if (u is Secretario) {
      rows = [
        _buildDataRow("ID Operativo", u.idSecretario, Icons.assignment_ind_outlined),
      ];
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detalles del Perfil", style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableData(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Datos de Contacto", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Puedes modificar tus datos de contacto.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir filas de datos bloqueados con iconos
  Widget _buildDataRow(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.secondary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            Text(value, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}