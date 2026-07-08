import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import '../services/mock_database.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/app_theme.dart';

class PacienteDetailScreen extends StatefulWidget {
  final Paciente paciente;

  const PacienteDetailScreen({super.key, required this.paciente});

  @override
  State<PacienteDetailScreen> createState() => _PacienteDetailScreenState();
}

class _PacienteDetailScreenState extends State<PacienteDetailScreen> {
  final db = MockDatabase();

  // --- LÓGICA DE BLOQUES HORARIOS MIGRADA ---
  List<TimeOfDay> _generarBloquesHorarios(String horarioAtencion) {
    try {
      var partes = horarioAtencion.split('-');
      var inicio = partes[0].trim().split(':');
      var fin = partes[1].trim().split(':');

      int horaInicio = int.parse(inicio[0]);
      int minInicio = int.parse(inicio[1]);
      int horaFin = int.parse(fin[0]);
      int minFin = int.parse(fin[1]);

      List<TimeOfDay> bloques = [];
      TimeOfDay actual = TimeOfDay(hour: horaInicio, minute: minInicio);
      TimeOfDay limite = TimeOfDay(hour: horaFin, minute: minFin);

      while (actual.hour < limite.hour || (actual.hour == limite.hour && actual.minute < limite.minute)) {
        bloques.add(actual);
        int nextMin = actual.minute + 30;
        int nextHour = actual.hour;
        if (nextMin >= 60) {
          nextMin -= 60;
          nextHour++;
        }
        actual = TimeOfDay(hour: nextHour, minute: nextMin);
      }
      return bloques;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paciente = widget.paciente;

    // Filtramos las citas de este paciente específico
    List<CitaVacunacion> citasPaciente = [];
    for (var c in db.centros) {
      citasPaciente.addAll(c.citasAgendadas.where((cita) => cita.rutPaciente == paciente.rut));
    }
    
    var pendientes = citasPaciente.where((c) => c.estado == "Programada" || c.estado == "Agendada" || c.estado == "En Sala de Espera").toList();
    var historial = citasPaciente.where((c) => c.estado == "Completada" || c.estado == "Cancelada").toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Ficha del Paciente"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TARJETA PRINCIPAL DEL PACIENTE ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32, backgroundColor: colorScheme.primaryContainer,
                    child: Text(paciente.nombres[0], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${paciente.nombres} ${paciente.apellidos}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
                        const SizedBox(height: 4),
                        Text("RUT: ${paciente.rut} | Contacto: ${paciente.telefono}", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarFormularioAgendamiento(paciente),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text("Agendar Cita"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- HISTORIAL Y CITAS ---
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna Izquierda: Pendientes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text("Próximas Citas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: pendientes.isEmpty
                              ? Text("No hay citas programadas.", style: TextStyle(color: colorScheme.onSurfaceVariant))
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: pendientes.length,
                                  itemBuilder: (context, index) => _buildTarjetaCita(pendientes[index], colorScheme),
                                ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Columna Derecha: Historial
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history_rounded, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text("Historial de Atención", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: historial.isEmpty
                              ? Text("No registra atenciones previas.", style: TextStyle(color: colorScheme.onSurfaceVariant))
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: historial.length,
                                  itemBuilder: (context, index) => _buildTarjetaCita(historial[index], colorScheme),
                                ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TARJETA CITA ---
  Widget _buildTarjetaCita(CitaVacunacion cita, ColorScheme colorScheme) {
    String centroNombre = db.centros.firstWhere((c) => c.idCentro == cita.idCentro).nombre;
    bool esPasada = cita.estado == "Completada" || cita.estado == "Cancelada";
    bool esEnSala = cita.estado == "En Sala de Espera";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esPasada ? colorScheme.surface : colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esPasada ? colorScheme.outlineVariant : colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FILA SUPERIOR: ICONO Y TEXTO ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: esPasada ? colorScheme.secondaryContainer : colorScheme.primary, shape: BoxShape.circle),
                child: Icon(Icons.vaccines_rounded, color: esPasada ? colorScheme.onSecondaryContainer : colorScheme.onPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.formatDateTime(cita.fechaHora), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(centroNombre, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          
          // --- FILA INFERIOR: ACCIONES O ESTADO ---
          const SizedBox(height: 12),
          if (esPasada || esEnSala)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: esPasada ? colorScheme.surfaceVariant : colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(cita.estado, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: esPasada ? colorScheme.onSurfaceVariant : colorScheme.onTertiaryContainer)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // --- BOTÓN REAGENDAR (Usa Acento de tu tema) ---
                Tooltip(
                  message: "Reagendar Cita",
                  child: InkWell(
                    onTap: () => _mostrarFormularioAgendamiento(widget.paciente, citaExistente: cita),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: colorScheme.secondary.withOpacity(0.3))
                      ),
                      child: Icon(Icons.edit_calendar_rounded, color: colorScheme.secondary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // --- BOTÓN LLEGADA (Usa AppTheme.success) ---
                Tooltip(
                  message: "Registrar Llegada",
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        cita.estado = "En Sala de Espera";
                        CustomDialogs.showSnackBar(context, "Paciente marcado en sala de espera.");
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.successContainer, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: AppTheme.success.withOpacity(0.3))
                      ),
                      child: const Icon(Icons.how_to_reg_rounded, color: AppTheme.success, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // --- BOTÓN CANCELAR (Usa AppTheme.error / colorScheme.error) ---
                Tooltip(
                  message: "Cancelar Cita",
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        cita.estado = "Cancelada";
                        CustomDialogs.showSnackBar(context, "Cita cancelada correctamente.");
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: AppTheme.error.withOpacity(0.3))
                      ),
                      child: const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 20),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- MODAL UNIFICADO: AGENDAMIENTO Y REAGENDAMIENTO ---
  void _mostrarFormularioAgendamiento(Paciente pacienteDestino, {CitaVacunacion? citaExistente}) {
    if (db.campanas.isEmpty) {
      CustomDialogs.showMessage(context, "Atención", "No hay campañas activas.");
      return;
    }

    bool esReagendamiento = citaExistente != null;
    Campana? campanaSeleccionada = db.campanas.first;
    TramoCampana? tramoSeleccionado = campanaSeleccionada!.tramos.isNotEmpty ? campanaSeleccionada!.tramos.first : null;
    CentroVacunacion? centroSeleccionado;
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            List<CentroVacunacion> centrosConStock = db.centros.where((c) => c.tieneStockDeVacuna(campanaSeleccionada!.vacuna.idVacuna)).toList();
            if (centroSeleccionado != null && !centrosConStock.contains(centroSeleccionado)) {
              centroSeleccionado = null; horaSeleccionada = null;
            }
            centroSeleccionado ??= centrosConStock.isNotEmpty ? centrosConStock.first : null;
            List<TimeOfDay> horasDisponibles = centroSeleccionado != null ? _generarBloquesHorarios(centroSeleccionado!.horarioAtencion) : [];

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))]),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16), 
                        decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle), 
                        child: Icon(esReagendamiento ? Icons.edit_calendar_rounded : Icons.event_available_rounded, size: 36, color: colorScheme.primary)
                      ),
                      const SizedBox(height: 16),
                      Text(esReagendamiento ? "Reagendar Cita" : "Agendar Cita", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text("Paciente: ${pacienteDestino.nombres} ${pacienteDestino.apellidos}", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 32),

                      DropdownButtonFormField<Campana>(
                        value: campanaSeleccionada,
                        decoration: const InputDecoration(labelText: "Campaña Activa", prefixIcon: Icon(Icons.campaign_rounded)),
                        items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                        onChanged: (val) => setStateDialog(() { campanaSeleccionada = val; tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null; }),
                      ),
                      const SizedBox(height: 16),
                      if (campanaSeleccionada!.tramos.isNotEmpty) ...[
                        DropdownButtonFormField<TramoCampana>(
                          value: tramoSeleccionado,
                          decoration: const InputDecoration(labelText: "Tramo de Prioridad", prefixIcon: Icon(Icons.groups_rounded)),
                          items: campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(value: t, child: Text(t.nombreTramo))).toList(),
                          onChanged: (val) => setStateDialog(() => tramoSeleccionado = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<CentroVacunacion>(
                        value: centroSeleccionado,
                        decoration: const InputDecoration(labelText: "Sede de Vacunación", prefixIcon: Icon(Icons.local_hospital_rounded)),
                        items: centrosConStock.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                        onChanged: (val) => setStateDialog(() { centroSeleccionado = val; horaSeleccionada = null; }),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: () async {
                                var picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                                if (picked != null) setStateDialog(() { fechaSeleccionada = picked; horaSeleccionada = null; });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                                child: Text(fechaSeleccionada == null ? "Elegir Fecha" : DateFormatter.formatDateOnly(fechaSeleccionada!), style: TextStyle(color: fechaSeleccionada == null ? colorScheme.onSurfaceVariant : colorScheme.onBackground)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<TimeOfDay>(
                              value: horaSeleccionada,
                              decoration: const InputDecoration(labelText: "Bloque"),
                              disabledHint: const Text("Día"),
                              items: horasDisponibles.map((h) => DropdownMenuItem(value: h, child: Text("${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}"))).toList(),
                              onChanged: fechaSeleccionada == null ? null : (val) => setStateDialog(() => horaSeleccionada = val),
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
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text("Cancelar"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: (tramoSeleccionado == null || centroSeleccionado == null || fechaSeleccionada == null || horaSeleccionada == null) ? null : () {
                                DateTime fechaHoraFinal = DateTime(fechaSeleccionada!.year, fechaSeleccionada!.month, fechaSeleccionada!.day, horaSeleccionada!.hour, horaSeleccionada!.minute);
                                
                                // Si es reagendamiento, cancelamos la cita anterior primero
                                if (esReagendamiento) {
                                  citaExistente!.estado = "Cancelada";
                                }

                                var cita = centroSeleccionado!.crearCita(fechaHoraFinal, pacienteDestino, tramoSeleccionado!.idTramo);
                                
                                if (cita != null) {
                                  Navigator.pop(context);
                                  CustomDialogs.showSnackBar(context, esReagendamiento ? "Cita reagendada correctamente." : "Cita agendada correctamente.");
                                  setState(() {}); // Refresca la pantalla
                                } else {
                                  // Si falló el reagendamiento, devolvemos la cita original a "Agendada"
                                  if (esReagendamiento) citaExistente!.estado = "Agendada"; 
                                  CustomDialogs.showMessage(context, "Error", "Sin cupos disponibles.");
                                }
                              },
                              child: Text(esReagendamiento ? "Confirmar Cambio" : "Confirmar Cita"),
                            ),
                          ),
                        ],
                      ),
                    ],
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