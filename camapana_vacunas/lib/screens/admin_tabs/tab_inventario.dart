import 'package:flutter/material.dart';
import '/services/mock_database.dart';
import '/models/campanas/vacuna.dart';
import '/models/campanas/inventario_vacuna.dart';
import '/models/centros/centro_vacunacion.dart';
import '/models/centros/centro_medico.dart';
import '/models/centros/centro_no_medico_adaptado.dart';
import '/widgets/custom_dialogs.dart';
import '/utils/date_formatter.dart';

class TabInventarioSedes extends StatefulWidget {
  const TabInventarioSedes({super.key});

  @override
  State<TabInventarioSedes> createState() => _TabInventarioSedesState();
}

class _TabInventarioSedesState extends State<TabInventarioSedes> {
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
            Text("Sedes de Vacunación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            Wrap(
              spacing: 8, 
              runSpacing: 8, 
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

    String tipoSedeSeleccionado = "Medico";

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
                    BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
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
                          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
                          child: Icon(Icons.add_business_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nueva Sede",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Habilita un nuevo punto de atención",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        DropdownButtonFormField<String>(
                          value: tipoSedeSeleccionado,
                          decoration: const InputDecoration(labelText: "Tipo de Centro", prefixIcon: Icon(Icons.category_outlined)),
                          items: ["Medico", "Adaptado"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setStateDialog(() => tipoSedeSeleccionado = val!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: "Nombre de la Sede", prefixIcon: Icon(Icons.store_mall_directory_outlined)),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: direccionCtrl,
                          decoration: const InputDecoration(labelText: "Dirección", prefixIcon: Icon(Icons.map_outlined)),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(controller: comunaCtrl, decoration: const InputDecoration(labelText: "Comuna"), validator: (v) => v!.isEmpty ? "Obligatorio" : null),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(controller: regionCtrl, decoration: const InputDecoration(labelText: "Región"), validator: (v) => v!.isEmpty ? "Obligatorio" : null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(controller: horarioCtrl, decoration: const InputDecoration(labelText: "Horario", prefixIcon: Icon(Icons.schedule_rounded)), validator: (v) => v!.isEmpty ? "Obligatorio" : null),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(controller: capacidadCtrl, decoration: const InputDecoration(labelText: "Capacidad"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Error" : null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (tipoSedeSeleccionado == "Medico") ...[
                          TextFormField(controller: tipoEstablecimientoCtrl, decoration: const InputDecoration(labelText: "Tipo (ej: Hospital, SAPU)", prefixIcon: Icon(Icons.local_hospital_outlined)), validator: (v) => v!.isEmpty ? "Especifique" : null),
                        ] else ...[
                          TextFormField(controller: ubicacionEstablecimientoCtrl, decoration: const InputDecoration(labelText: "Ubicación (ej: Gimnasio)", prefixIcon: Icon(Icons.sports_basketball_outlined)), validator: (v) => v!.isEmpty ? "Especifique" : null),
                        ],
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
                                    String nuevoIdCentro = "CEN-${DateTime.now().millisecondsSinceEpoch}";
                                    CentroVacunacion nuevaSede;
                                    if (tipoSedeSeleccionado == "Medico") {
                                      nuevaSede = CentroMedico(idCentro: nuevoIdCentro, nombre: nombreCtrl.text, direccion: direccionCtrl.text, comuna: comunaCtrl.text, region: regionCtrl.text, capacidadDiaria: int.parse(capacidadCtrl.text), horarioAtencion: horarioCtrl.text, tipo: "MMedico", tipoEstablecimiento: tipoEstablecimientoCtrl.text);
                                    } else {
                                      nuevaSede = CentroNoMedicoAdaptado(idCentro: nuevoIdCentro, nombre: nombreCtrl.text, direccion: direccionCtrl.text, comuna: comunaCtrl.text, region: regionCtrl.text, capacidadDiaria: int.parse(capacidadCtrl.text), horarioAtencion: horarioCtrl.text, tipo: "Adaptado", ubicacionEstablecimiento: ubicacionEstablecimientoCtrl.text);
                                    }
                                    setState(() => db.centros.add(nuevaSede));
                                    Navigator.pop(context);
                                    CustomDialogs.showSnackBar(context, "Sede '${nombreCtrl.text}' registrada");
                                  }
                                },
                                child: const Text("Registrar Sede"),
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
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
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
                          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
                          child: Icon(Icons.inventory_2_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Cargar Stock",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ingreso de lotes y dosis a sede",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        DropdownButtonFormField<CentroVacunacion>(
                          value: centroSeleccionado,
                          decoration: const InputDecoration(labelText: "Sede Destino", prefixIcon: Icon(Icons.apartment_rounded)),
                          items: db.centros.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                          onChanged: (val) => setStateDialog(() => centroSeleccionado = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Vacuna>(
                          value: vacunaSeleccionada,
                          decoration: const InputDecoration(labelText: "Tipo de Vacuna", prefixIcon: Icon(Icons.vaccines_rounded)),
                          items: db.vacunas.map((v) => DropdownMenuItem(value: v, child: Text(v.nombre))).toList(),
                          onChanged: (val) => setStateDialog(() => vacunaSeleccionada = val),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: loteCtrl,
                                decoration: const InputDecoration(labelText: "Código Lote", prefixIcon: Icon(Icons.qr_code_2_rounded)),
                                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: cantidadCtrl,
                                decoration: const InputDecoration(labelText: "Dosis"),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Error" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Vencimiento del Lote", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            var picked = await showDatePicker(context: context, initialDate: fechaVencimiento, firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (picked != null) setStateDialog(() => fechaVencimiento = picked);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.event_busy_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                                const SizedBox(width: 12),
                                Text(DateFormatter.formatDateOnly(fechaVencimiento), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
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
                                  if (formKey.currentState!.validate() && centroSeleccionado != null && vacunaSeleccionada != null) {
                                    var nuevoInventario = InventarioVacuna(
                                      idInventario: "INV-${DateTime.now().millisecondsSinceEpoch}",
                                      idCentro: centroSeleccionado!.idCentro, vacuna: vacunaSeleccionada!, lote: loteCtrl.text, cantidadDisponible: int.parse(cantidadCtrl.text), fechaVencimiento: fechaVencimiento,
                                    );
                                    setState(() => centroSeleccionado!.inventarios.add(nuevoInventario));
                                    Navigator.pop(context);
                                    CustomDialogs.showSnackBar(context, "Stock cargado con éxito");
                                  }
                                },
                                child: const Text("Cargar Dosis"),
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