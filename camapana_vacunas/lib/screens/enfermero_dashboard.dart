import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/transacciones/fachada_registro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';
import '../widgets/header_actions.dart';

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

    _centroSeleccionado ??= db.centros.isNotEmpty ? db.centros.first : null;

    if (_centroSeleccionado == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text("No existen sedes registradas en el sistema.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
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

    // 1. Citas por atender
    var citasPendientes = _centroSeleccionado!.citasAgendadas
        .where((c) => c.estado == "Programada")
        .toList();

    // 2. Registros completados en sede específica para el historial
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
                  
                  // SECCIÓN 1: PENDIENTES
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
                                Text("No hay citas programadas para hoy.", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                                    child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.tertiary), // Se usa el color terciario para llamar a la acción
                                  ),
                                  title: Text("${paciente.nombres} ${paciente.apellidos} (${paciente.rut})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text("Grupo: ${paciente.grupoRiesgo}\nPlanificado: ${DateFormatter.formatDateTime(cita.fechaHora)}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    icon: const Icon(Icons.vaccines_rounded),
                                    label: const Text("Inmunizar"),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      minimumSize: const Size(0, 40),
                                    ),
                                    onPressed: () {
                                      // Llamada unificada a la Fachada
                                      String resultado = FachadaRegistroVacunacion.procesarVacunacion(
                                        cita: cita,
                                        paciente: paciente,
                                        centro: _centroSeleccionado!,
                                        rutProfesional: db.usuarioActivo!.rut,
                                        observaciones: _obsCtrl.text
                                      );
                                      
                                      if (resultado.startsWith("Éxito")) {
                                        CustomDialogs.showSnackBar(context, resultado);
                                        setState(() {});
                                      } else {
                                        CustomDialogs.showMessage(context, "Error de Validación", resultado);
                                      }
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

                  // SECCIÓN 2: HISTORIAL LOGUEADO
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
                                  // Usamos secondaryContainer para los ítems ya procesados con éxito
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