import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/header_actions.dart';
import '../utils/app_validators.dart';
import 'paciente_detail_screen.dart'; // Ajusta esta ruta si es necesario

class SecretarioDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const SecretarioDashboard({super.key, required this.onLogout});

  @override
  State<SecretarioDashboard> createState() => _SecretarioDashboardState();
}

class _SecretarioDashboardState extends State<SecretarioDashboard> {
  final db = MockDatabase();
  
  // Controladores y Estados de la Búsqueda
  final _searchCtrl = TextEditingController();
  List<Paciente> _pacientesEncontrados = []; // Cambiado a lista
  bool _isSearching = false; 
  String? _errorMessage;     

  Future<void> _buscarPaciente() async {
    String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _pacientesEncontrados.clear(); // Limpiamos resultados anteriores
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    var pacientes = db.usuarios.whereType<Paciente>().where((p) {
      bool coincideRut = p.rut.toLowerCase().contains(query);
      bool coincideNombre = p.nombres.toLowerCase().contains(query) || p.apellidos.toLowerCase().contains(query);
      return coincideRut || coincideNombre;
    }).toList();

    setState(() {
      _isSearching = false;
      if (pacientes.isNotEmpty) {
        _pacientesEncontrados = pacientes; // Guardamos todos los resultados
      } else {
        _errorMessage = "No se encontraron registros para '$query'.";
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (db.usuarioActivo == null) {
      Future.microtask(() => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false));
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // --- ENCABEZADO ---
          Container(
            padding: const EdgeInsets.fromLTRB(32, 50, 32, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Hola, ${db.usuarioActivo?.nombres ?? 'Secretari@'} 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      child: Text("Módulo de Recepción • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HeaderActions(onLogout: widget.onLogout, usuarioActivo: db.usuarioActivo!),
                  ],
                ),
              ],
            ),
          ),

          // --- CUERPO PRINCIPAL (Buscador y Resultados) ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- BARRA DE BÚSQUEDA ---
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      inputFormatters: [
                        BuscadorFormatter(),  
                      ],
                      onSubmitted: (_) => _buscarPaciente(),
                      decoration: InputDecoration(
                        hintText: "Buscar por RUT, Nombre o Apellido...",
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _buscarPaciente,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Buscar"),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                // ÁREA DE RESULTADOS DINÁMICA
                  Expanded(
                    child: _isSearching
                        // 1. ESTADO DE CARGA
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: colorScheme.primary),
                                const SizedBox(height: 16),
                                Text("Buscando en la base de datos...", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        // 2. ESTADO SIN RESULTADOS
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_off_rounded, size: 64, color: colorScheme.error.withOpacity(0.8)),
                                    const SizedBox(height: 16),
                                    Text(_errorMessage!, style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text("Verifica los datos ingresados o crea un nuevo perfil.", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 32),
                                    ElevatedButton.icon(
                                      onPressed: _mostrarFormularioCrearPaciente,
                                      icon: const Icon(Icons.person_add_alt_1_rounded),
                                      label: const Text("Registrar Nuevo Paciente"),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        backgroundColor: colorScheme.primaryContainer,
                                        foregroundColor: colorScheme.onPrimaryContainer,
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                        // 3. ESTADO INICIAL (Pantalla vacía, antes de buscar)
                            : _pacientesEncontrados.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                          ),
                                          child: Icon(Icons.badge_outlined, size: 64, color: colorScheme.primary.withOpacity(0.5)),
                                        ),
                                        const SizedBox(height: 24),
                                        Text("Ingrese un RUT o Nombre para comenzar", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 32),
                                        
                                        // Separador visual elegante
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(height: 1, width: 60, color: colorScheme.outlineVariant),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text("O SI ES LA PRIMERA VEZ", style: TextStyle(color: colorScheme.outline, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            ),
                                            Container(height: 1, width: 60, color: colorScheme.outlineVariant),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: _mostrarFormularioCrearPaciente,
                                          icon: const Icon(Icons.person_add_alt_1_rounded),
                                          label: const Text("Registrar Nuevo Paciente"),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                            backgroundColor: colorScheme.secondary,
                                            foregroundColor: colorScheme.onSecondary,
                                            elevation: 0,
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                        // 4. ESTADO CON RESULTADOS EXITOSOS
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _pacientesEncontrados.length,
                                    itemBuilder: (context, index) {
                                      final paciente = _pacientesEncontrados[index];
                                      return Card(
                                        elevation: 0,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          leading: CircleAvatar(
                                            backgroundColor: colorScheme.primaryContainer,
                                            child: Text(paciente.nombres[0], style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text("${paciente.nombres} ${paciente.apellidos}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text("RUT: ${paciente.rut}"),
                                          trailing: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PacienteDetailScreen(paciente: paciente),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(elevation: 0),
                                            child: const Text("Ver Ficha"),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FORMULARIO CREAR PACIENTE ---
  void _mostrarFormularioCrearPaciente() {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController();
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    String grupoRiesgo = "Público General";
    
    bool intentoGuardar = false;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: intentoGuardar ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colorScheme.tertiary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.person_add_rounded, size: 36, color: colorScheme.tertiary)),
                        const SizedBox(height: 16),
                        Text("Registrar Paciente", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary)),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: rutCtrl, 
                          decoration: const InputDecoration(labelText: "RUT Paciente", prefixIcon: Icon(Icons.badge_rounded)), 
                          inputFormatters: [
                            RutFormatter(),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          validator: AppValidators.validarRut
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: nombresCtrl, decoration: const InputDecoration(labelText: "Nombres"), validator: (v) => AppValidators.validarVacio(v, "Nombres"))),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: "Apellidos"), validator: (v) => AppValidators.validarVacio(v, "Apellidos"))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: correoCtrl, 
                          decoration: const InputDecoration(labelText: "Correo Electrónico"), 
                          keyboardType: TextInputType.emailAddress, 
                          validator: AppValidators.validarCorreo
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telefonoCtrl, 
                          decoration: const InputDecoration(labelText: "Teléfono de contacto"), 
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.filtroTelefono,
                          validator: AppValidators.validarTelefono,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: grupoRiesgo,
                          decoration: const InputDecoration(labelText: "Grupo de Riesgo"),
                          items: ["Adultos Mayores", "Crónicos", "Embarazadas", "Jovenes Sanos", "Público General"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) => setStateDialog(() => grupoRiesgo = val!),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Cancelar"))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: () {
                                  setStateDialog(() => intentoGuardar = true);
                                  
                                  if (formKey.currentState!.validate()) {
                                    rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);
                                    var nuevoPaciente = Paciente(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), rutSecretarioCreador: db.usuarioActivo!.rut, prevision: "Fonasa", grupoRiesgo: grupoRiesgo, estadoVacunacion: "Sin vacunas");
                                    setState(() {
                                      db.usuarios.add(nuevoPaciente);
                                      _searchCtrl.text = nuevoPaciente.rut; 
                                    });
                                    Navigator.pop(context);
                                    _buscarPaciente(); 
                                    CustomDialogs.showSnackBar(context, "Paciente registrado correctamente.");
                                  }
                                },
                                child: const Text("Guardar"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }
}