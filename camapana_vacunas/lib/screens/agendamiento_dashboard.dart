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
  const AgendamientoDashboard({super.key});

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
    if (db.campanas.isEmpty)
      return const Center(child: Text("No hay campañas activas."));

    _campanaSeleccionada ??= db.campanas.first;
    if (!_campanaSeleccionada!.tramos.contains(_tramoSeleccionado)) {
      _tramoSeleccionado = _campanaSeleccionada!.tramos.isNotEmpty
          ? _campanaSeleccionada!.tramos.first
          : null;
    }

    List<CentroVacunacion> centrosConStock = db.centros
        .where(
          (c) => c.tieneStockDeVacuna(_campanaSeleccionada!.vacuna.idVacuna),
        )
        .toList();

    if (_centroSeleccionado != null &&
        !centrosConStock.contains(_centroSeleccionado)) {
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
          if (cita.rutPaciente == pacienteObjetivo.rut)
            misCitasTotales.add(cita);
        } else {
          misCitasTotales.add(cita);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Solicitud de Agendamiento Web",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<Campana>(
            value: _campanaSeleccionada,
            decoration: const InputDecoration(
              labelText: "Seleccionar Campaña",
              border: OutlineInputBorder(),
            ),
            items: db.campanas
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text("${c.nombre} (Vacuna: ${c.vacuna.nombre})"),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _campanaSeleccionada = val;
                _tramoSeleccionado = val!.tramos.isNotEmpty
                    ? val.tramos.first
                    : null;
              });
            },
          ),
          const SizedBox(height: 16),

          if (_campanaSeleccionada!.tramos.isEmpty)
            const Text(
              "Esta campaña no tiene tramos activos actualmente.",
              style: TextStyle(color: Colors.red),
            )
          else
            DropdownButtonFormField<TramoCampana>(
              value: _tramoSeleccionado,
              decoration: const InputDecoration(
                labelText: "Seleccionar Tramo de Prioridad",
                border: OutlineInputBorder(),
              ),
              items: _campanaSeleccionada!.tramos
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        "${t.nombreTramo} (Dirigido a: ${t.poblacionObjetivo})",
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _tramoSeleccionado = val),
            ),
          const SizedBox(height: 16),

          if (centrosConStock.isEmpty)
            const Text(
              "⚠️ Ningún centro tiene stock disponible de la vacuna para esta campaña.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )
          else
            DropdownButtonFormField<CentroVacunacion>(
              value: _centroSeleccionado,
              decoration: const InputDecoration(
                labelText: "Sedes disponibles con Stock",
                border: OutlineInputBorder(),
              ),
              items: centrosConStock
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text("${c.nombre} - ${c.comuna} (${c.tipo})"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _centroSeleccionado = val),
            ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _fechaCitaSeleccionada == null
                    ? "Seleccionar Fecha y Hora de la Cita"
                    : "Fecha seleccionada: ${DateFormatter.formatDateTime(_fechaCitaSeleccionada!)}",
              ),
              trailing: ElevatedButton(
                onPressed: () => _seleccionarFechaHora(context),
                child: const Text("Elegir Fecha"),
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed:
                (_tramoSeleccionado == null ||
                    _centroSeleccionado == null ||
                    _fechaCitaSeleccionada == null)
                ? null
                : () {
                    bool tienePrioridad = _tramoSeleccionado!
                        .validarPrioridadPaciente(pacienteObjetivo);

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
                              child: const Text("Continuar de todos modos"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.event_available),
            label: const Text("Confirmar y Agendar"),
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "Mis citas agendadas:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: misCitasTotales.isEmpty
                ? const Text("Aún no tienes citas programadas.")
                : ListView.builder(
                    itemCount: misCitasTotales.length,
                    itemBuilder: (context, index) {
                      var cita = misCitasTotales[index];
                      String nombreCentro = db.centros
                          .firstWhere((c) => c.idCentro == cita.idCentro)
                          .nombre;
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.calendar_month,
                            color: Colors.teal,
                          ),
                          title: Text(
                            DateFormatter.formatDateTime(cita.fechaHora),
                          ),
                          subtitle: Text(
                            "Centro: $nombreCentro \nEstado: ${cita.estado}",
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
