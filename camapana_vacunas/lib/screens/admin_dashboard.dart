import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/empresa.dart';
import '../models/campanas/campana.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/vacuna.dart';
import '../models/campanas/inventario_vacuna.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/centros/centro_medico.dart';
import '../models/centros/centro_no_medico_adaptado.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = MockDatabase();

  @override
  Widget build(BuildContext context) {
    var admin = db.usuarioActivo as Administrador;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ENCABEZADO
          Container(
            padding: const EdgeInsets.fromLTRB(32, 50, 32, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, ${admin.nombres} 👋",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Panel de Administración • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CUERPO PRINCIPAL (Pestañas y Contenido)
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PESTAÑAS
                    Container(
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
                      child: const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.campaign_rounded), text: "Gestión de Campañas"),
                          Tab(icon: Icon(Icons.local_shipping_rounded), text: "Inventario por Sede"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // CONTENIDO DE LAS PESTAÑAS
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildTabCampanas(admin),
                          _buildTabInventarioSedes(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // VISTA: PESTAÑA DE CAMPAÑAS
  Widget _buildTabCampanas(Administrador admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Campañas Activas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            ElevatedButton.icon(
              onPressed: () => _mostrarFormularioCampana(admin),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Nueva Campaña"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                elevation: 0,
                minimumSize: const Size(0, 48), 
              ),
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
                                admin.solicitarReporteEfectos(campana);
                                var reporte = campana.generarReporteEfectos();
                                CustomDialogs.showMessage(context, "Reporte de Efectos", reporte.toString());
                              },
                              icon: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                              label: Text("Reporte Efectos", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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

  // VISTA: PESTAÑA DE INVENTARIO
  Widget _buildTabInventarioSedes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Sedes de Vacunación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _mostrarFormularioCrearSede,
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text("Nueva Sede"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size(0, 48), 
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _mostrarFormularioCargaStock,
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: const Text("Cargar Stock"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
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
            itemCount: db.centros.length,
            itemBuilder: (context, index) {
              var centro = db.centros[index];
              String extraInfo = centro is CentroMedico 
                ? "Establecimiento: ${centro.tipoEstablecimiento}" 
                : "Ubicación: ${(centro as CentroNoMedicoAdaptado).ubicacionEstablecimiento}";

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
                      child: Icon(Icons.apartment_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(centro.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    subtitle: Text("${centro.comuna}, ${centro.region} | $extraInfo", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    children: [
                      const Divider(),
                      ListTile(
                        dense: true,
                        leading: Icon(Icons.schedule_rounded, color: Theme.of(context).colorScheme.secondary),
                        title: Text("Horario: ${centro.horarioAtencion} | Capacidad Diaria: ${centro.capacidadDiaria} personas"),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Lotes y Vacunas Almacenadas", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      if (centro.inventarios.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("No hay stock disponible en esta sede actualmente.", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        )
                      else
                        ...centro.inventarios.map((inv) => ListTile(
                          leading: Icon(Icons.vaccines_rounded, color: Theme.of(context).colorScheme.primary),
                          title: Text("${inv.vacuna.nombre} (Lote: ${inv.lote})"),
                          subtitle: Text("Disponibles: ${inv.cantidadDisponible} | Vence: ${DateFormatter.formatDateOnly(inv.fechaVencimiento)}"),
                          trailing: inv.estaVencida()
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                                  child: Text("VENCIDO", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                                  child: Text("${inv.cantidadDisponible} dosis", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                        )),
                      const SizedBox(height: 8),
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

  // LÓGICA DE DIÁLOGOS Y FORMULARIOS
  void _mostrarFormularioCrearSede() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final comunaCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController();
    final horarioCtrl = TextEditingController(text: "08:30 - 17:30");
    
    final tipoEstablecimientoCtrl = TextEditingController();
    final ubicacionEstablecimientoCtrl = TextEditingController();

    String tipoSedeSeleccionado = "Médico";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Registrar Nueva Sede de Vacunación"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: tipoSedeSeleccionado,
                        decoration: const InputDecoration(labelText: "Tipo de Centro", border: OutlineInputBorder()),
                        items: ["Médico", "Adaptado"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setStateDialog(() => tipoSedeSeleccionado = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre de la Sede"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: direccionCtrl,
                        decoration: const InputDecoration(labelText: "Dirección"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: comunaCtrl,
                        decoration: const InputDecoration(labelText: "Comuna"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: regionCtrl,
                        decoration: const InputDecoration(labelText: "Región"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: horarioCtrl,
                        decoration: const InputDecoration(labelText: "Horario de Atención"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: capacidadCtrl,
                        decoration: const InputDecoration(labelText: "Capacidad Diaria"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Ingrese un número válido" : null,
                      ),
                      const SizedBox(height: 16),
                      if (tipoSedeSeleccionado == "Médico") ...[
                        TextFormField(
                          controller: tipoEstablecimientoCtrl,
                          decoration: const InputDecoration(labelText: "Tipo (ej: Hospital, SAPU)"),
                          validator: (v) => v!.isEmpty ? "Especifique" : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: ubicacionEstablecimientoCtrl,
                          decoration: const InputDecoration(labelText: "Ubicación (ej: Gimnasio)"),
                          validator: (v) => v!.isEmpty ? "Especifique" : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      String nuevoIdCentro = "CEN-${DateTime.now().millisecondsSinceEpoch}";
                      CentroVacunacion nuevaSede;

                      if (tipoSedeSeleccionado == "Médico") {
                        nuevaSede = CentroMedico(
                          idCentro: nuevoIdCentro,
                          nombre: nombreCtrl.text,
                          direccion: direccionCtrl.text,
                          comuna: comunaCtrl.text,
                          region: regionCtrl.text,
                          capacidadDiaria: int.parse(capacidadCtrl.text),
                          horarioAtencion: horarioCtrl.text,
                          tipo: "Médico",
                          tipoEstablecimiento: tipoEstablecimientoCtrl.text,
                        );
                      } else {
                        nuevaSede = CentroNoMedicoAdaptado(
                          idCentro: nuevoIdCentro,
                          nombre: nombreCtrl.text,
                          direccion: direccionCtrl.text,
                          comuna: comunaCtrl.text,
                          region: regionCtrl.text,
                          capacidadDiaria: int.parse(capacidadCtrl.text),
                          horarioAtencion: horarioCtrl.text,
                          tipo: "Adaptado",
                          ubicacionEstablecimiento: ubicacionEstablecimientoCtrl.text,
                        );
                      }

                      setState(() {
                        db.centros.add(nuevaSede);
                      });

                      Navigator.pop(context);
                      CustomDialogs.showSnackBar(context, "Sede '${nombreCtrl.text}' registrada");
                    }
                  },
                  child: const Text("Registrar Sede"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarFormularioCargaStock() {
    final formKey = GlobalKey<FormState>();
    final loteCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    
    CentroVacunacion? centroSeleccionado = db.centros.isNotEmpty ? db.centros.first : null;
    Vacuna? vacunaSeleccionada = db.vacunas.isNotEmpty ? db.vacunas.first : null;
    DateTime fechaVencimiento = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Cargar Stock"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<CentroVacunacion>(
                        value: centroSeleccionado,
                        decoration: const InputDecoration(labelText: "Sede Destino"),
                        items: db.centros.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                        onChanged: (val) => setStateDialog(() => centroSeleccionado = val),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Vacuna>(
                        value: vacunaSeleccionada,
                        decoration: const InputDecoration(labelText: "Tipo de Vacuna"),
                        items: db.vacunas.map((v) => DropdownMenuItem(value: v, child: Text(v.nombre))).toList(),
                        onChanged: (val) => setStateDialog(() => vacunaSeleccionada = val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: loteCtrl,
                        decoration: const InputDecoration(labelText: "Código de Lote"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cantidadCtrl,
                        decoration: const InputDecoration(labelText: "Cantidad de Dosis"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Inválido" : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                        title: Text("Vence: ${DateFormatter.formatDateOnly(fechaVencimiento)}"),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: () async {
                          var picked = await showDatePicker(
                            context: context,
                            initialDate: fechaVencimiento,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setStateDialog(() => fechaVencimiento = picked);
                        },
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && centroSeleccionado != null && vacunaSeleccionada != null) {
                      var nuevoInventario = InventarioVacuna(
                        idInventario: "INV-${DateTime.now().millisecondsSinceEpoch}",
                        idCentro: centroSeleccionado!.idCentro,
                        vacuna: vacunaSeleccionada!,
                        lote: loteCtrl.text,
                        cantidadDisponible: int.parse(cantidadCtrl.text),
                        fechaVencimiento: fechaVencimiento,
                      );
                      setState(() {
                        centroSeleccionado!.inventarios.add(nuevoInventario);
                      });
                      Navigator.pop(context);
                      CustomDialogs.showSnackBar(context, "Stock cargado con éxito");
                    }
                  },
                  child: const Text("Cargar Dosis"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarFormularioCampana(Administrador admin) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    String tipoSeleccionado = "Pública";
    Empresa? empresaSeleccionada = db.empresas.isNotEmpty ? db.empresas.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Crear Nueva Campaña"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre de la Campaña"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: const InputDecoration(labelText: "Público Objetivo"),
                        items: ["Pública", "Empresa"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
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
                      String nuevaIdCampana = "CAMP-${DateTime.now().millisecondsSinceEpoch}";
                      var nuevaCampana = Campana(
                        idCampana: nuevaIdCampana, rutAdmin: admin.rut,
                        vacuna: db.vacunas.first, nombre: nombreCtrl.text, descripcion: "Descripción",
                        fechaInicio: DateTime.now(), fechaTermino: DateTime.now().add(const Duration(days: 30)),
                        empresaAsociada: tipoSeleccionado == "Empresa" ? empresaSeleccionada : null,
                      );
                      setState(() { db.campanas.add(nuevaCampana); });
                      Navigator.pop(context);
                      CustomDialogs.showMessage(context, "Éxito", "La campaña ha sido creada.");
                    }
                  },
                  child: const Text("Guardar"),
                )
              ],
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