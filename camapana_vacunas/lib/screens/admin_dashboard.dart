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
import '../widgets/header_actions.dart';
import '../utils/app_validators.dart';

import '../models/usuarios/enfermero.dart';
import '../models/usuarios/medico.dart';
import '../models/usuarios/secretario.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = MockDatabase();

  @override
  Widget build(BuildContext context) {
    // Verificamos si hay un usuario activo, si no lo hay, redirigimos al login
    if (db.usuarioActivo == null) {
      Future.microtask(() => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false));
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16, // Separación horizontal cuando hay espacio
              runSpacing: 16, // Separación vertical cuando se caen a la línea de abajo
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Añade esto para que la columna no ocupe espacio infinito
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
                HeaderActions(onLogout: widget.onLogout, usuarioActivo: db.usuarioActivo!),
              ],
            ),
          ),

          // CUERPO PRINCIPAL (Pestañas y Contenido)
          Expanded(
            child: DefaultTabController(
              length: 3,
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
                          Tab(icon: Icon(Icons.badge_rounded), text: "Gestión de Personal"),
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
                          _buildTabPersonal(), // <--- NUEVA VISTA
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
        // Cambia el Row principal por este Wrap
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text("Sedes de Vacunación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            
            // Cambia el Row de los botones por este Wrap interno
            Wrap(
              spacing: 8, // Espacio horizontal entre botones
              runSpacing: 8, // Espacio vertical si un botón cae abajo
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

  // VISTA: PESTAÑA DE GESTIÓN DE PERSONAL
  Widget _buildTabPersonal() {
    var listaPersonal = db.usuarios.where((u) => u.runtimeType.toString() != 'Paciente').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text("Personal del Sistema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            ElevatedButton.icon(
              onPressed: () => _mostrarFormularioFuncionario(null), // null significa modo "Crear"
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text("Registrar Funcionario"),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 48), 
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: listaPersonal.length,
            itemBuilder: (context, index) {
              var funcionario = listaPersonal[index];
              String rol = funcionario.runtimeType.toString();
              
              Color pillColor = Theme.of(context).colorScheme.secondaryContainer;
              Color pillTextColor = Theme.of(context).colorScheme.onSecondaryContainer;
              
              if (rol == 'Administrador') {
                pillColor = Theme.of(context).colorScheme.primaryContainer;
                pillTextColor = Theme.of(context).colorScheme.primary;
              } else if (rol == 'Secretario') {
                pillColor = Colors.orange.shade100;
                pillTextColor = Colors.orange.shade900;
              }

              // Extraemos información específica para mostrarla al expandir
              String infoEspecifica = "";
              if (funcionario is Administrador) {
                infoEspecifica = "Departamento: ${funcionario.departamento}";
              } else if (funcionario is Secretario) {
                infoEspecifica = "ID Operativo: ${funcionario.idSecretario}";
              } else if (funcionario is Medico) {
                infoEspecifica = "Especialidad: ${funcionario.especialidad}\nRNPI: ${funcionario.registro}";
              } else if (funcionario is Enfermero) {
                infoEspecifica = "Unidad: ${funcionario.unidadAsignada}\nRNPI: ${funcionario.registro}";
              }

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
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        funcionario.nombres[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text("${funcionario.nombres} ${funcionario.apellidos}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(funcionario.correo, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(rol, style: TextStyle(color: pillTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      const SizedBox(height: 4),
                                      Text("RUT: ${funcionario.rut}\nTeléfono: ${funcionario.telefono}", style: const TextStyle(height: 1.5)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Datos del Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      const SizedBox(height: 4),
                                      Text(infoEspecifica, style: const TextStyle(height: 1.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Evita que el administrador activo se elimine a sí mismo
                                if (funcionario.rut != db.usuarioActivo!.rut)
                                  TextButton.icon(
                                    onPressed: () => _confirmarEliminacion(funcionario),
                                    icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                                    label: Text("Revocar Acceso", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _mostrarFormularioFuncionario(funcionario), // Pasamos el usuario para editar
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text("Editar Datos"),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  // --- MÉTODOS DE SOPORTE PARA LA GESTIÓN ---

  void _confirmarEliminacion(var funcionario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Revocar Acceso?"),
        content: Text("Estás a punto de eliminar al ${funcionario.runtimeType} ${funcionario.nombres} del sistema. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () {
              setState(() {
                db.usuarios.removeWhere((u) => u.rut == funcionario.rut);
              });
              Navigator.pop(ctx);
              CustomDialogs.showSnackBar(context, "Acceso revocado exitosamente.");
            },
            child: const Text("Eliminar Funcionario"),
          )
        ],
      ),
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

void _mostrarFormularioCampana(Administrador admin) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController(); // Añadimos controlador para descripción/población
    
    String tipoSeleccionado = "Pública";
    Empresa? empresaSeleccionada = db.empresas.isNotEmpty ? db.empresas.first : null;
    
    // Variables para manejar las fechas en el estado del diálogo
    DateTime fechaInicio = DateTime.now();
    DateTime fechaTermino = DateTime.now().add(const Duration(days: 30));

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
                        // 1. Icono de Encabezado
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.campaign_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        
                        // 2. Título
                        Text(
                          "Nueva Campaña",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Define los parámetros y duración",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // 3. Campos de Texto Básicos
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nombre de la Campaña",
                            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                          ),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: "Población Objetivo / Detalles",
                            prefixIcon: Icon(Icons.people_alt_outlined),
                          ),
                          validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: tipoSeleccionado,
                          decoration: const InputDecoration(
                            labelText: "Tipo de Campaña",
                            prefixIcon: Icon(Icons.public_rounded),
                          ),
                          items: ["Pública", "Empresa"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
                        ),
                        const SizedBox(height: 24),

                        // 4. Selectores de Fecha (Duración)
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
                                    context: context, 
                                    initialDate: fechaInicio, 
                                    firstDate: DateTime(2020), 
                                    lastDate: DateTime(2030)
                                  );
                                  if (picked != null) setStateDialog(() => fechaInicio = picked);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outlineVariant), 
                                    borderRadius: BorderRadius.circular(12)
                                  ),
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
                                    context: context, 
                                    initialDate: fechaTermino, 
                                    firstDate: fechaInicio, // La fecha de término no puede ser antes del inicio
                                    lastDate: DateTime(2030)
                                  );
                                  if (picked != null) setStateDialog(() => fechaTermino = picked);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outlineVariant), 
                                    borderRadius: BorderRadius.circular(12)
                                  ),
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

                        // 5. Botones de Acción
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
                                  if (formKey.currentState!.validate()) {
                                    String nuevaIdCampana = "CAMP-${DateTime.now().millisecondsSinceEpoch}";
                                    var nuevaCampana = Campana(
                                      idCampana: nuevaIdCampana, 
                                      rutAdmin: admin.rut,
                                      vacuna: db.vacunas.first, 
                                      nombre: nombreCtrl.text, 
                                      descripcion: descCtrl.text, // Usamos la descripción del campo
                                      fechaInicio: fechaInicio, // Usamos la fecha seleccionada
                                      fechaTermino: fechaTermino, // Usamos la fecha seleccionada
                                      empresaAsociada: tipoSeleccionado == "Empresa" ? empresaSeleccionada : null,
                                    );
                                    setState(() { db.campanas.add(nuevaCampana); });
                                    Navigator.pop(context);
                                    CustomDialogs.showMessage(context, "Éxito", "La campaña ha sido creada.");
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

void _mostrarFormularioFuncionario(var usuarioAEditar) {
    bool isEditing = usuarioAEditar != null;
    final formKey = GlobalKey<FormState>();
    
    final rutCtrl = TextEditingController(text: isEditing ? usuarioAEditar.rut : "");
    final nombresCtrl = TextEditingController(text: isEditing ? usuarioAEditar.nombres : "");
    final apellidosCtrl = TextEditingController(text: isEditing ? usuarioAEditar.apellidos : "");
    final correoCtrl = TextEditingController(text: isEditing ? usuarioAEditar.correo : "");
    final telefonoCtrl = TextEditingController(text: isEditing ? usuarioAEditar.telefono : "");
    
    String rolSeleccionado = isEditing ? usuarioAEditar.runtimeType.toString() : "Secretario";
    
    final deptoCtrl = TextEditingController(text: isEditing && usuarioAEditar is Administrador ? usuarioAEditar.departamento : "");
    final registroCtrl = TextEditingController(
      text: isEditing 
          ? (usuarioAEditar is Medico ? usuarioAEditar.registro : (usuarioAEditar is Enfermero ? usuarioAEditar.registro : ""))
          : ""
    );
    final especialidadCtrl = TextEditingController(text: isEditing && usuarioAEditar is Medico ? usuarioAEditar.especialidad : "");
    final unidadCtrl = TextEditingController(text: isEditing && usuarioAEditar is Enfermero ? usuarioAEditar.unidadAsignada : "");

    // 1. CREAMOS EL VIGILANTE PARA EL RUT
    final rutFocusNode = FocusNode();
    rutFocusNode.addListener(() {
      if (!rutFocusNode.hasFocus && rutCtrl.text.isNotEmpty) {
        rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);
      }
    });

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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
                          child: Icon(Icons.badge_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEditing ? "Editar Funcionario" : "Registrar Funcionario",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Gestión de credenciales y accesos",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: const InputDecoration(labelText: "Rol del Funcionario", prefixIcon: Icon(Icons.work_outline_rounded)),
                          items: ["Administrador", "Medico", "Enfermero", "Secretario"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: isEditing ? null : (val) => setStateDialog(() => rolSeleccionado = val!),
                        ),
                        const SizedBox(height: 16),
                        
                        // --- CAMPO RUT CON VIGILANTE Y VALIDADOR ---
                        TextFormField(
                          controller: rutCtrl,
                          focusNode: rutFocusNode, // Asignamos el vigilante
                          decoration: const InputDecoration(labelText: "RUT", prefixIcon: Icon(Icons.pin_outlined)),
                          validator: AppValidators.validarRut, // Validador estricto
                          enabled: !isEditing,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nombresCtrl,
                                decoration: const InputDecoration(labelText: "Nombres", prefixIcon: Icon(Icons.person_outline_rounded)),
                                validator: (v) => AppValidators.validarVacio(v, "Nombres"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: apellidosCtrl,
                                decoration: const InputDecoration(labelText: "Apellidos"),
                                validator: (v) => AppValidators.validarVacio(v, "Apellidos"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: correoCtrl,
                          decoration: const InputDecoration(labelText: "Correo Electrónico", prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress,
                          validator: AppValidators.validarCorreo, // Validador de correo
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telefonoCtrl,
                          decoration: const InputDecoration(labelText: "Teléfono", prefixIcon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.filtroTelefono,
                          validator: AppValidators.validarTelefono, // Validador de teléfono
                        ),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider()),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Información Específica", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ),
                        const SizedBox(height: 16),

                        if (rolSeleccionado == "Administrador") ...[
                          TextFormField(controller: deptoCtrl, decoration: const InputDecoration(labelText: "Departamento", prefixIcon: Icon(Icons.domain_rounded)), validator: (v) => AppValidators.validarVacio(v, "Departamento")),
                        ] else if (rolSeleccionado == "Secretario") ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: colorScheme.onSecondaryContainer, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text("El ID Operativo es gestionado por el sistema.", style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13))),
                              ],
                            ),
                          ),
                        ] else if (rolSeleccionado == "Medico" || rolSeleccionado == "Enfermero") ...[
                          TextFormField(controller: registroCtrl, decoration: const InputDecoration(labelText: "Registro RNPI", prefixIcon: Icon(Icons.verified_user_outlined)), validator: (v) => AppValidators.validarVacio(v, "Registro RNPI")),
                          const SizedBox(height: 16),
                          if (rolSeleccionado == "Medico")
                            TextFormField(controller: especialidadCtrl, decoration: const InputDecoration(labelText: "Especialidad", prefixIcon: Icon(Icons.medical_services_outlined)), validator: (v) => AppValidators.validarVacio(v, "Especialidad"))
                          else
                            TextFormField(controller: unidadCtrl, decoration: const InputDecoration(labelText: "Unidad Asignada", prefixIcon: Icon(Icons.local_hospital_outlined)), validator: (v) => AppValidators.validarVacio(v, "Unidad Asignada")),
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
                                    
                                    // Última red de seguridad de formateo antes de guardar
                                    rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);

                                    if (isEditing) db.usuarios.removeWhere((u) => u.rut == usuarioAEditar.rut);

                                    var usuarioActualizado;
                                    if (rolSeleccionado == "Administrador") {
                                      usuarioActualizado = Administrador(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), departamento: deptoCtrl.text);
                                    } else if (rolSeleccionado == "Secretario") {
                                      usuarioActualizado = Secretario(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), idSecretario: isEditing ? (usuarioAEditar as Secretario).idSecretario : "SEC-${DateTime.now().millisecondsSinceEpoch}");
                                    } else if (rolSeleccionado == "Medico") {
                                      usuarioActualizado = Medico(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), registro: registroCtrl.text, especialidad: especialidadCtrl.text);
                                    } else if (rolSeleccionado == "Enfermero") {
                                      usuarioActualizado = Enfermero(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), registro: registroCtrl.text, unidadAsignada: unidadCtrl.text);
                                    }

                                    setState(() => db.usuarios.add(usuarioActualizado));
                                    Navigator.pop(context);
                                    CustomDialogs.showSnackBar(context, isEditing ? "Datos actualizados exitosamente" : "$rolSeleccionado registrado con éxito");
                                  }
                                },
                                child: Text(isEditing ? "Guardar" : "Registrar"),
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
    ).then((_) {
      rutFocusNode.dispose();
    });
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