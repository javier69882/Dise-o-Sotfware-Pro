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
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.campaign), text: "Gestión de Campañas"),
                Tab(icon: Icon(Icons.local_shipping), text: "Inventario por Sede"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabCampanas(admin),
                  _buildTabInventarioSedes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabCampanas(Administrador admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Campañas Activas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _mostrarFormularioCampana(admin),
              icon: const Icon(Icons.add),
              label: const Text("Nueva Campaña"),
            )
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: db.campanas.length,
            itemBuilder: (context, index) {
              var campana = db.campanas[index];
              String tipoStr = campana.empresaAsociada == null ? "Pública" : "Empresa: ${campana.empresaAsociada!.razonSocial}";
              return Card(
                child: ExpansionTile(
                  title: Text(campana.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Avance: ${campana.calcularAvanceGlobal().toStringAsFixed(1)}% | Tipo: $tipoStr | Vacuna: ${campana.vacuna.nombre}"),
                  children: [
                    const Divider(),
                    const Text("Tramos de Vacunación", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...campana.tramos.map((t) => ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(t.nombreTramo),
                      subtitle: Text("Objetivo: ${t.poblacionObjetivo} | Prioridad: ${t.nivelPrioridad}\nFechas: ${DateFormatter.formatDateOnly(t.fechaInicio)} al ${DateFormatter.formatDateOnly(t.fechaFin)}"),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              admin.solicitarReporteEfectos(campana);
                              var reporte = campana.generarReporteEfectos();
                              CustomDialogs.showMessage(context, "Reporte de Efectos", reporte.toString());
                            },
                            icon: const Icon(Icons.analytics),
                            label: const Text("Reporte Efectos"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarFormularioTramo(campana),
                            icon: const Icon(Icons.add_task),
                            label: const Text("Añadir Tramo"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildTabInventarioSedes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Sedes de Vacunación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _mostrarFormularioCrearSede,
                  icon: const Icon(Icons.add_business),
                  label: const Text("Nueva Sede"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _mostrarFormularioCargaStock,
                  icon: const Icon(Icons.inventory),
                  label: const Text("Cargar Stock"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0F2F1)),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: db.centros.length,
            itemBuilder: (context, index) {
              var centro = db.centros[index];
              String extraInfo = "";
              if (centro is CentroMedico) {
                extraInfo = "Establecimiento: ${centro.tipoEstablecimiento}";
              } else if (centro is CentroNoMedicoAdaptado) {
                extraInfo = "Ubicación: ${centro.ubicacionEstablecimiento}";
              }

              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.apartment, color: Colors.teal),
                  title: Text(centro.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Ubicación: ${centro.comuna}, ${centro.region} | $extraInfo"),
                  children: [
                    const Divider(),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.schedule),
                      title: Text("Horario: ${centro.horarioAtencion} | Capacidad Diaria: ${centro.capacidadDiaria} personas"),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("Lotes y Vacunas Almacenadas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    if (centro.inventarios.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No hay stock disponible en esta sede actualmente.", style: TextStyle(fontStyle: FontStyle.italic)),
                      )
                    else
                      ...centro.inventarios.map((inv) => ListTile(
                        leading: const Icon(Icons.vaccines, color: Colors.teal),
                        title: Text("${inv.vacuna.nombre} (Lote: ${inv.lote})"),
                        subtitle: Text("Dosis Disponibles: ${inv.cantidadDisponible} | Vence: ${DateFormatter.formatDateOnly(inv.fechaVencimiento)}"),
                        trailing: inv.estaVencida()
                            ? const Chip(label: Text("VENCIDO"), backgroundColor: Colors.redAccent)
                            : Chip(label: Text("${inv.cantidadDisponible} dosis")),
                      )),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // FORMULARIO DINÁMICO HU-11: Crear Nueva Sede
  void _mostrarFormularioCrearSede() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final comunaCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController();
    final horarioCtrl = TextEditingController(text: "08:30 - 17:30");
    
    // Campos específicos de subclases
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
                      TextFormField(
                        controller: direccionCtrl,
                        decoration: const InputDecoration(labelText: "Dirección"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: comunaCtrl,
                        decoration: const InputDecoration(labelText: "Comuna"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: regionCtrl,
                        decoration: const InputDecoration(labelText: "Región"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: horarioCtrl,
                        decoration: const InputDecoration(labelText: "Horario de Atención"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: capacidadCtrl,
                        decoration: const InputDecoration(labelText: "Capacidad de Atención Diaria"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Ingrese un número válido" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Campos condicionales según HU-11
                      if (tipoSedeSeleccionado == "Médico") ...[
                        TextFormField(
                          controller: tipoEstablecimientoCtrl,
                          decoration: const InputDecoration(labelText: "Tipo de Establecimiento (ej: Hospital, SAPU)", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Especifique el tipo de establecimiento médico" : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: ubicacionEstablecimientoCtrl,
                          decoration: const InputDecoration(labelText: "Ubicación del Establecimiento (ej: Gimnasio, Escuela)", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Especifique el recinto adaptado" : null,
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
                      CustomDialogs.showSnackBar(context, "Sede '${nombreCtrl.text}' registrada con éxito");
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
              title: const Text("Cargar Stock en Sede"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<CentroVacunacion>(
                        value: centroSeleccionado,
                        decoration: const InputDecoration(labelText: "Seleccionar Sede Destino"),
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
                        decoration: const InputDecoration(labelText: "Código de Lote (Ej: LOT-2026)"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cantidadCtrl,
                        decoration: const InputDecoration(labelText: "Cantidad de Dosis"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Ingrese un número válido" : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text("Fecha de Vencimiento: ${DateFormatter.formatDateOnly(fechaVencimiento)}"),
                        trailing: const Icon(Icons.calendar_today),
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
                      CustomDialogs.showSnackBar(context, "Stock cargado con éxito en ${centroSeleccionado!.nombre}");
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
                      CustomDialogs.showMessage(context, "Éxito", "La campaña ha sido creada correctamente.");
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
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Ingrese un número válido" : null,
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