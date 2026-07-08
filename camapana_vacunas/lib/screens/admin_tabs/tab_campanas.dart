import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/mock_database.dart';
import '/models/usuarios/administrador.dart';
import '/models/usuarios/paciente.dart';
import '/models/usuarios/empresa.dart';
import '/models/campanas/campana.dart';
import '/models/campanas/tramo_campana.dart';
import '/widgets/custom_dialogs.dart';
import '/utils/date_formatter.dart';
import '/utils/app_validators.dart';
import '/screens/reporte_estadistico_screen.dart';

class TabCampanas extends StatefulWidget {
  final Administrador admin;
  
  const TabCampanas({super.key, required this.admin});

  @override
  State<TabCampanas> createState() => _TabCampanasState();
}

class _TabCampanasState extends State<TabCampanas> {
  final db = MockDatabase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text("Campañas Activas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            Wrap(
              spacing: 12, 
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _mostrarVerificadorPaciente(), 
                  icon: const Icon(Icons.how_to_reg_rounded, size: 22), 
                  label: const Text("Verificar Paciente"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, 
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _mostrarFormularioCampana(widget.admin),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text("Nueva Campaña"),
                  style: OutlinedButton.styleFrom(
                    elevation: 0, 
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.75),
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: db.campanas.length,
            itemBuilder: (context, index) {
              var campana = db.campanas[index];
              String tipoStr = campana.empresaAsociada == null ? "Pública" : "Empresa: ${campana.empresaAsociada!.razonSocial}";
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                      child: Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(campana.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    subtitle: Text("Avance: ${campana.calcularAvanceGlobal().toStringAsFixed(1)}% | Tipo: $tipoStr", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: "Editar Campaña",
                      onPressed: () => _mostrarFormularioCampana(widget.admin, campanaAEditar: campana),
                    ),
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Tramos de Vacunación", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                        ),
                      ),
                      ...campana.tramos.map((t) => ListTile(
                        leading: Icon(Icons.group_rounded, color: Theme.of(context).colorScheme.secondary),
                        title: Text(t.nombreTramo),
                        subtitle: Text("Objetivo: ${t.poblacionObjetivo} | Prioridad: ${t.nivelPrioridad}\nFechas: ${DateFormatter.formatDateOnly(t.fechaInicio)} al ${DateFormatter.formatDateOnly(t.fechaFin)}"),
                      )),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ReporteEstadisticoScreen(campana: campana)),
                                );
                              },
                              icon: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                              label: const Text("Ver Estadísticas Completas"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarFormularioTramo(campana),
                              icon: const Icon(Icons.add_task_rounded),
                              label: const Text("Añadir Tramo"),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // --- LÓGICA DE DIÁLOGOS Y FORMULARIOS ---

  void _mostrarVerificadorPaciente() {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController();
    Campana? campanaSeleccionada = db.campanas.isNotEmpty ? db.campanas.first : null;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent, 
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.how_to_reg_rounded, size: 36, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Verificar Elegibilidad",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Valida si un paciente cumple con los requisitos",
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: rutCtrl,
                      decoration: const InputDecoration(
                        labelText: "RUT del Paciente", 
                        prefixIcon: Icon(Icons.badge_outlined)
                      ),
                      inputFormatters: [
                        RutFormatter(),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      validator: AppValidators.validarRut,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Campana>(
                      value: campanaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: "Campaña a Consultar", 
                        prefixIcon: Icon(Icons.campaign_outlined)
                      ),
                      items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                      onChanged: (val) => campanaSeleccionada = val,
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate() && campanaSeleccionada != null) {
                                rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);
                                String rutIngresado = rutCtrl.text;
                                
                                var pacientes = db.usuarios.whereType<Paciente>().where((p) => p.rut == rutIngresado).toList();
                                
                                if (pacientes.isEmpty) {
                                  CustomDialogs.showMessage(context, "Error", "El RUT ingresado no corresponde a ningún paciente registrado.");
                                  return;
                                }
                                
                                var paciente = pacientes.first;
                                bool esElegible = false;
                                
                                for (var tramo in campanaSeleccionada!.tramos) {
                                  if (tramo.validarPrioridadPaciente(paciente)) {
                                    esElegible = true;
                                    break;
                                  }
                                }

                                Navigator.pop(context); 
                                
                                if (esElegible) {
                                  CustomDialogs.showMessage(
                                    context, 
                                    "✅ Paciente Elegible", 
                                    "El paciente ${paciente.nombres} ${paciente.apellidos} SÍ cumple con los requisitos de prioridad para ser inoculado en esta campaña."
                                  );
                                } else {
                                  CustomDialogs.showMessage(
                                    context, 
                                    "❌ No Elegible", 
                                    "El paciente ${paciente.nombres} ${paciente.apellidos} NO pertenece a la población objetivo de los tramos activos en esta campaña."
                                  );
                                }
                              }
                            },
                            child: const Text("Verificar RUT"),
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

  void _mostrarFormularioCampana(Administrador admin, {Campana? campanaAEditar}) {
    bool isEditing = campanaAEditar != null;
    final formKey = GlobalKey<FormState>();
    
    final nombreCtrl = TextEditingController(text: isEditing ? campanaAEditar.nombre : "");
    final descCtrl = TextEditingController(text: isEditing ? campanaAEditar.descripcion : ""); 
    
    String tipoSeleccionado = (isEditing && campanaAEditar.empresaAsociada != null) ? "Empresa" : "Pública";
    Empresa? empresaSeleccionada = (isEditing && campanaAEditar.empresaAsociada != null) 
        ? campanaAEditar.empresaAsociada 
        : (db.empresas.isNotEmpty ? db.empresas.first : null);
    
    DateTime fechaInicio = isEditing ? campanaAEditar.fechaInicio : DateTime.now();
    DateTime fechaTermino = isEditing ? campanaAEditar.fechaTermino : DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent, 
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isEditing ? Icons.edit_rounded : Icons.campaign_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEditing ? "Editar Campaña" : "Nueva Campaña",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing ? "Modifica los parámetros de la campaña" : "Define los parámetros y duración",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: "Nombre de la Campaña", prefixIcon: Icon(Icons.drive_file_rename_outline_rounded)),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: "Población Objetivo / Detalles", prefixIcon: Icon(Icons.people_alt_outlined)),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: tipoSeleccionado,
                          decoration: const InputDecoration(labelText: "Tipo de Campaña", prefixIcon: Icon(Icons.public_rounded)),
                          items: ["Pública", "Empresa"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Duración Prevista", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  var picked = await showDatePicker(
                                    context: context, initialDate: fechaInicio, firstDate: DateTime(2020), lastDate: DateTime(2030)
                                  );
                                  if (picked != null) setStateDialog(() => fechaInicio = picked);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Inicio", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Text(DateFormatter.formatDateOnly(fechaInicio), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  var picked = await showDatePicker(
                                    context: context, initialDate: fechaTermino, firstDate: fechaInicio, lastDate: DateTime(2030)
                                  );
                                  if (picked != null) setStateDialog(() => fechaTermino = picked);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Término", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Text(DateFormatter.formatDateOnly(fechaTermino), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: colorScheme.outlineVariant)),
                                child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    setState(() {
                                      if (isEditing) {
                                        campanaAEditar.nombre = nombreCtrl.text;
                                        campanaAEditar.descripcion = descCtrl.text;
                                        campanaAEditar.fechaInicio = fechaInicio;
                                        campanaAEditar.fechaTermino = fechaTermino;
                                        campanaAEditar.empresaAsociada = tipoSeleccionado == "Empresa" ? empresaSeleccionada : null;
                                      } else {
                                        String nuevaIdCampana = "CAMP-${DateTime.now().millisecondsSinceEpoch}";
                                        var nuevaCampana = Campana(
                                          idCampana: nuevaIdCampana, rutAdmin: admin.rut, vacuna: db.vacunas.first, 
                                          nombre: nombreCtrl.text, descripcion: descCtrl.text, 
                                          fechaInicio: fechaInicio, fechaTermino: fechaTermino, 
                                          empresaAsociada: tipoSeleccionado == "Empresa" ? empresaSeleccionada : null,
                                        );
                                        db.campanas.add(nuevaCampana);
                                      }
                                    });
                                    Navigator.pop(context);
                                    CustomDialogs.showSnackBar(context, isEditing ? "Campaña actualizada" : "Campaña creada exitosamente.");
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

  void _mostrarFormularioTramo(Campana campana) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final prioridadCtrl = TextEditingController(text: "1");
    String poblacionSeleccionada = "Adultos Mayores";
    DateTime fechaInicio = DateTime.now();
    DateTime fechaFin = DateTime.now().add(const Duration(days: 30));

    final opcionesPoblacion = ["Adultos Mayores", "Crónicos", "Embarazadas", "Personal de Salud", "Jovenes Sanos", "Público General"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Añadir Tramo a:\n${campana.nombre}"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre del Tramo"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: poblacionSeleccionada,
                        decoration: const InputDecoration(labelText: "Población Objetivo"),
                        items: opcionesPoblacion.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setStateDialog(() => poblacionSeleccionada = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: prioridadCtrl,
                        decoration: const InputDecoration(labelText: "Nivel de Prioridad"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Inválido" : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      var nuevoTramo = TramoCampana(
                        idTramo: "TR-${DateTime.now().millisecondsSinceEpoch}", idCampana: campana.idCampana,
                        nombreTramo: nombreCtrl.text, poblacionObjetivo: poblacionSeleccionada,
                        nivelPrioridad: int.parse(prioridadCtrl.text), fechaInicio: fechaInicio, fechaFin: fechaFin,
                      );
                      setState(() { campana.agregarTramo(nuevoTramo); });
                      Navigator.pop(context);
                      CustomDialogs.showSnackBar(context, "Tramo añadido con éxito");
                    }
                  },
                  child: const Text("Guardar Tramo"),
                )
              ],
            );
          }
        );
      }
    );
  }
}