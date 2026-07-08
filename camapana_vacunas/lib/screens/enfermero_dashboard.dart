import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/transacciones/fachada_registro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';
import '../widgets/header_actions.dart';
import '../widgets/modal_inoculacion.dart';

class EnfermeroDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const EnfermeroDashboard({super.key, required this.onLogout});

  @override
  State<EnfermeroDashboard> createState() => _EnfermeroDashboardState();
}

class _EnfermeroDashboardState extends State<EnfermeroDashboard> {
  final db = MockDatabase();
  CentroVacunacion? _centroSeleccionado;
  final _obsCtrl = TextEditingController(text: "Procedimiento exitoso sin reacciones inmediatas.");

  // --- COMPONENTE VISUAL DE STOCK DE VACUNAS ---
  Widget _buildStockVisualizer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_centroSeleccionado == null) return const SizedBox.shrink();

    final inventarioLocal = _centroSeleccionado!.inventarios;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Disponibilidad de Stock de la Sede",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          inventarioLocal.isEmpty
              ? Text(
                  "No hay vacunas registradas en este recinto.",
                  style: TextStyle(color: colorScheme.error, fontStyle: FontStyle.italic),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: inventarioLocal.map((inv) {
                    final cantidad = inv.cantidadDisponible;
                    final estaVencida = inv.estaVencida();

                    Color badgeColor;
                    String textDisplay = cantidad.toString();

                    if (estaVencida) {
                      badgeColor = colorScheme.error;
                      textDisplay = "VENCIDA";
                    } else if (cantidad > 20) {
                      badgeColor = Colors.green;
                    } else if (cantidad > 0) {
                      badgeColor = Colors.orange;
                    } else {
                      badgeColor = colorScheme.error;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.vaccines_rounded, color: badgeColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            inv.vacuna.idVacuna,
                            style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              textDisplay,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // --- MODAL DE HISTORIAL MÉDICO (NUEVO) ---
  void _mostrarHistorialMedico(BuildContext context, Paciente paciente) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colorScheme.surface,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medical_information_rounded, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text("Ficha Clínica", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                Text("${paciente.nombres} ${paciente.apellidos}", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),

                // AQUÍ LA APP "ESCUCHA" EL CHECK DEL PACIENTE
                if (paciente.dioConsentimientoMedico) ...[
                  // SI DIO CONSENTIMIENTO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Antecedentes Registrados:", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        const SizedBox(height: 8),
                        Text(paciente.antecedentesMedicos, style: TextStyle(height: 1.5, color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ] else ...[
                  // SI NO DIO CONSENTIMIENTO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_person_rounded, size: 36, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        Text("Acceso Restringido", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text(
                          "El paciente no ha otorgado el consentimiento para compartir sus antecedentes médicos con el personal de salud en esta sesión.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text("Cerrar"),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
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

    _centroSeleccionado ??= db.centros.isNotEmpty ? db.centros.first : null;

    if (_centroSeleccionado == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text("No existen sedes registradas en el sistema.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }

    var citasPendientes = _centroSeleccionado!.citasAgendadas
        .where((c) => c.estado == "En Sala de Espera")
        .toList();

    var registrosSede = db.historialRegistros
        .where((reg) => reg.idCentro == _centroSeleccionado!.idCentro)
        .toList();

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
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hola, ${db.usuarioActivo?.nombres ?? 'Enfermer@'} 👋",
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
                        "Módulo de Inmunización • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
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

          // CUERPO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<CentroVacunacion>(
                    value: _centroSeleccionado,
                    decoration: InputDecoration(
                      labelText: "Punto de Atención Actual", 
                      prefixIcon: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary),
                      fillColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    ),
                    items: db.centros.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                    onChanged: (val) => setState(() => _centroSeleccionado = val),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildStockVisualizer(context),
                  
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text("Pacientes en Espera (${citasPendientes.length})", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    flex: 4,
                    child: citasPendientes.isEmpty
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.coffee_rounded, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                                const SizedBox(height: 16),
                                Text("No hay pacientes en sala de espera actualmente.", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: citasPendientes.length,
                            itemBuilder: (context, index) {
                              var cita = citasPendientes[index];
                              var paciente = db.usuarios.firstWhere((u) => u.rut == cita.rutPaciente) as Paciente;

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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2), shape: BoxShape.circle),
                                    child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.tertiary),
                                  ),
                                  title: Text("${paciente.nombres} ${paciente.apellidos} (${paciente.rut})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  
                                  // --- AQUÍ ESTÁ EL CAMBIO (NUEVO SUBTITLE) ---
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Grupo: ${paciente.grupoRiesgo}\nLlegada: ${DateFormatter.formatDateTime(cita.fechaHora)}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                                        const SizedBox(height: 8),
                                        
                                        // EL BOTÓN / LINK DE HISTORIAL
                                        InkWell(
                                          onTap: () => _mostrarHistorialMedico(context, paciente), // <-- Llama al modal
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.medical_information_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Ver antecedentes médicos", 
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary, 
                                                  fontWeight: FontWeight.bold, 
                                                  decoration: TextDecoration.underline, 
                                                  fontSize: 13
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ---------------------------------------------

                                  trailing: FilledButton.icon(
                                    icon: const Icon(Icons.vaccines_rounded, size: 18),
                                    label: const Text(
                                      "Inmunizar", 
                                      style: TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (contextDialog) => ModalInoculacion(
                                          cita: cita,
                                          paciente: paciente,
                                          centro: _centroSeleccionado!,
                                          onSuccess: () => setState(() {}), 
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text("Historial de Vacunaciones Realizadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    flex: 3,
                    child: registrosSede.isEmpty
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                            ),
                            child: Center(child: Text("Aún no se registran vacunaciones en este turno.", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: registrosSede.length,
                            itemBuilder: (context, index) {
                              var reg = registrosSede[index];
                              var paciente = db.usuarios.firstWhere((u) => u.rut == reg.rutPaciente) as Paciente;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer, 
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary, size: 32),
                                  title: Text("${paciente.nombres} ${paciente.apellidos}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text("ID Registro: ${reg.idRegistro}\nFecha Aplicación: ${DateFormatter.formatDateTime(reg.fechaHora)}", style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8), height: 1.4)),
                                  ),
                                  trailing: Text("RUT: ${paciente.rut}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}