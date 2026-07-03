import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';

class AgendamientoDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const AgendamientoDashboard({super.key, required this.onLogout});

  @override
  State<AgendamientoDashboard> createState() => _AgendamientoDashboardState();
}

class _AgendamientoDashboardState extends State<AgendamientoDashboard> {
  final db = MockDatabase();

  Campana? _campanaSeleccionada;
  TramoCampana? _tramoSeleccionado;
  CentroVacunacion? _centroSeleccionado;
  DateTime? _fechaCitaSeleccionada;

  Future<void> _seleccionarFechaHora(BuildContext context) async {
    DateTime fechaInicial = DateTime.now().add(const Duration(days: 1));
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null && context.mounted) {
      final TimeOfDay? horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (horaSeleccionada != null) {
        setState(() {
          _fechaCitaSeleccionada = DateTime(
            fechaSeleccionada.year,
            fechaSeleccionada.month,
            fechaSeleccionada.day,
            horaSeleccionada.hour,
            horaSeleccionada.minute,
          );
        });
      }
    }
  }

  void _procesarCita(
    CentroVacunacion centro,
    Paciente paciente,
    String idTramo,
    DateTime fechaCita,
  ) {
    CitaVacunacion? cita = centro.crearCita(fechaCita, paciente, idTramo);
    if (cita != null) {
      CustomDialogs.showMessage(
        context,
        "Éxito",
        "Cita creada exitosamente en ${centro.nombre} para el ${DateFormatter.formatDateTime(cita.fechaHora)}",
      );
      setState(() {
        _fechaCitaSeleccionada = null;
      });
    } else {
      CustomDialogs.showMessage(
        context,
        "Error",
        "No hay disponibilidad en el centro para la fecha seleccionada.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (db.campanas.isEmpty) {
      return Center(
        child: Text("No hay campañas activas.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    _campanaSeleccionada ??= db.campanas.first;
    if (!_campanaSeleccionada!.tramos.contains(_tramoSeleccionado)) {
      _tramoSeleccionado = _campanaSeleccionada!.tramos.isNotEmpty
          ? _campanaSeleccionada!.tramos.first
          : null;
    }

    List<CentroVacunacion> centrosConStock = db.centros
        .where((c) => c.tieneStockDeVacuna(_campanaSeleccionada!.vacuna.idVacuna))
        .toList();

    if (_centroSeleccionado != null && !centrosConStock.contains(_centroSeleccionado)) {
      _centroSeleccionado = null;
    }
    if (_centroSeleccionado == null && centrosConStock.isNotEmpty) {
      _centroSeleccionado = centrosConStock.first;
    }

    Paciente pacienteObjetivo = db.usuarioActivo is Paciente
        ? db.usuarioActivo as Paciente
        : db.usuarios.firstWhere((u) => u is Paciente) as Paciente;

    List<CitaVacunacion> misCitasTotales = [];
    for (var c in db.centros) {
      for (var cita in c.citasAgendadas) {
        if (db.usuarioActivo is Paciente) {
          if (cita.rutPaciente == pacienteObjetivo.rut) {
            misCitasTotales.add(cita);
          }
        } else {
          misCitasTotales.add(cita);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Solicitud de Agendamiento Web",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<Campana>(
            value: _campanaSeleccionada,
            decoration: InputDecoration(
              labelText: "Seleccionar Campaña",
              prefixIcon: Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            items: db.campanas.map((c) => DropdownMenuItem(
              value: c,
              child: Text("${c.nombre} (Vacuna: ${c.vacuna.nombre})"),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _campanaSeleccionada = val;
                _tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null;
              });
            },
          ),
          const SizedBox(height: 16),

          if (_campanaSeleccionada!.tramos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text("Esta campaña no tiene tramos activos actualmente.", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            DropdownButtonFormField<TramoCampana>(
              value: _tramoSeleccionado,
              decoration: InputDecoration(
                labelText: "Seleccionar Tramo de Prioridad",
                prefixIcon: Icon(Icons.groups_rounded, color: Theme.of(context).colorScheme.primary),
              ),
              items: _campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(
                value: t,
                child: Text("${t.nombreTramo} (Dirigido a: ${t.poblacionObjetivo})"),
              )).toList(),
              onChanged: (val) => setState(() => _tramoSeleccionado = val),
            ),
          const SizedBox(height: 16),

          if (centrosConStock.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Ningún centro tiene stock disponible de la vacuna para esta campaña.", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold))),
                ],
              ),
            )
          else
            DropdownButtonFormField<CentroVacunacion>(
              value: _centroSeleccionado,
              decoration: InputDecoration(
                labelText: "Sedes disponibles con Stock",
                prefixIcon: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary),
              ),
              items: centrosConStock.map((c) => DropdownMenuItem(
                value: c,
                child: Text("${c.nombre} - ${c.comuna} (${c.tipo})"),
              )).toList(),
              onChanged: (val) => setState(() => _centroSeleccionado = val),
            ),
          const SizedBox(height: 24),

          // Selector de Fecha y Hora Integrado
          InkWell(
            onTap: () => _seleccionarFechaHora(context),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _fechaCitaSeleccionada == null
                          ? "Seleccionar Fecha y Hora de la Cita"
                          : "Fecha: ${DateFormatter.formatDateTime(_fechaCitaSeleccionada!)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: _fechaCitaSeleccionada == null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onBackground,
                        fontWeight: _fechaCitaSeleccionada == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.edit_calendar_rounded, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            onPressed: (_tramoSeleccionado == null || _centroSeleccionado == null || _fechaCitaSeleccionada == null)
                ? null
                : () {
                    bool tienePrioridad = _tramoSeleccionado!.validarPrioridadPaciente(pacienteObjetivo);

                    if (tienePrioridad) {
                      _procesarCita(
                        _centroSeleccionado!,
                        pacienteObjetivo,
                        _tramoSeleccionado!.idTramo,
                        _fechaCitaSeleccionada!,
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            "Advertencia de Prioridad",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            "Tu grupo de riesgo (${pacienteObjetivo.grupoRiesgo}) no coincide con la población prioritaria (${_tramoSeleccionado!.poblacionObjetivo}).",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancelar"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _procesarCita(
                                  _centroSeleccionado!,
                                  pacienteObjetivo,
                                  _tramoSeleccionado!.idTramo,
                                  _fechaCitaSeleccionada!,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                              ),
                              child: const Text("Continuar de todos modos"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text("Confirmar y Agendar"),
          ),
          
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Icon(Icons.history_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Mis citas agendadas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: misCitasTotales.isEmpty
                ? Text("Aún no tienes citas programadas.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: misCitasTotales.length,
                    itemBuilder: (context, index) {
                      var cita = misCitasTotales[index];
                      String nombreCentro = db.centros.firstWhere((c) => c.idCentro == cita.idCentro).nombre;
                      
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
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                            child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(
                            DateFormatter.formatDateTime(cita.fechaHora),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text("Centro: $nombreCentro", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cita.estado, 
                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}