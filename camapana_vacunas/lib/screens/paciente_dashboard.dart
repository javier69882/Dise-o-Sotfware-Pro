import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/transacciones/historial_medico_builder.dart';
import '../models/transacciones/director_historial.dart';
import '../models/transacciones/historial_medico.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';

class PacienteDashboard extends StatefulWidget {
  const PacienteDashboard({super.key});

  @override
  State<PacienteDashboard> createState() => _PacienteDashboardState();
}

class _PacienteDashboardState extends State<PacienteDashboard> {
  final db = MockDatabase();

  // Variables Agendamiento
  Campana? _campanaSeleccionada;
  TramoCampana? _tramoSeleccionado;
  CentroVacunacion? _centroSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  // Variables Historial Médico (NUEVO: Listas y Controladores)
  HistorialMedico? _historialGenerado;
  final List<String> _misAlergias = [];
  final List<String> _misCondiciones = [];
  final _alergiaCtrl = TextEditingController();
  final _condicionCtrl = TextEditingController();

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

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context, 
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
    );

    if (pickedDate != null && context.mounted) {
      setState(() {
        _fechaSeleccionada = pickedDate;
        _horaSeleccionada = null; 
      });
    }
  }

  void _generarHistorialMedico(Paciente paciente) {
    var builder = HistorialMedicoBuilder();
    var director = DirectorHistorial(builder);
    
    // Le pasamos al director los datos que el usuario agregó en la UI
    setState(() {
      _historialGenerado = director.construirHistorialCompleto(paciente, _misAlergias, _misCondiciones);
    });
  }

  @override
  Widget build(BuildContext context) {
    Paciente miPerfil = db.usuarioActivo as Paciente;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.event), text: "Auto-Agendamiento"),
                Tab(icon: Icon(Icons.medical_information), text: "Mi Historial Médico"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPestanaAgendamiento(miPerfil),
                  _buildPestanaHistorial(miPerfil),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestanaHistorial(Paciente perfil) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PANEL IZQUIERDO: Formulario de llenado
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              const Text("Construir Antecedentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Agregar Alergias
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _alergiaCtrl,
                      decoration: const InputDecoration(labelText: "Añadir Alergia", border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
                    onPressed: () {
                      if (_alergiaCtrl.text.isNotEmpty) {
                        setState(() { _misAlergias.add(_alergiaCtrl.text); _alergiaCtrl.clear(); });
                      }
                    },
                  )
                ],
              ),
              if (_misAlergias.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: _misAlergias.map((a) => Chip(
                      label: Text(a),
                      onDeleted: () => setState(() => _misAlergias.remove(a)),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 16),

              // Agregar Condiciones Previas
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _condicionCtrl,
                      decoration: const InputDecoration(labelText: "Añadir Condición Previa", border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
                    onPressed: () {
                      if (_condicionCtrl.text.isNotEmpty) {
                        setState(() { _misCondiciones.add(_condicionCtrl.text); _condicionCtrl.clear(); });
                      }
                    },
                  )
                ],
              ),
              if (_misCondiciones.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: _misCondiciones.map((c) => Chip(
                      label: Text(c),
                      onDeleted: () => setState(() => _misCondiciones.remove(c)),
                    )).toList(),
                  ),
                ),
              
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _generarHistorialMedico(perfil),
                icon: const Icon(Icons.download),
                label: const Text("Generar Documento"),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 24),
        
        // PANEL DERECHO: Visualización del Historial
        Expanded(
          flex: 2,
          child: _historialGenerado == null 
            ? const Center(child: Text("Llena tus antecedentes y presiona 'Generar Documento'.", style: TextStyle(color: Colors.grey)))
            : Card(
                elevation: 3,
                color: Colors.yellow.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListView(
                    children: [
                      const Center(child: Text("🏥 REPORTE MÉDICO OFICIAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))),
                      const Divider(thickness: 2),
                      const SizedBox(height: 10),
                      const Text("1. DATOS DEL PACIENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text(_historialGenerado!.datosPersonales),
                      const SizedBox(height: 16),
                      const Text("2. ANTECEDENTES CLÍNICOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text("Alergias: ${_historialGenerado!.alergias}\nCondiciones: ${_historialGenerado!.condicionesPrevias}"),
                      const SizedBox(height: 16),
                      const Text("3. REGISTRO DE VACUNACIÓN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text(_historialGenerado!.vacunasAplicadas),
                      const SizedBox(height: 30),
                      const Divider(),
                      Center(child: Text("Documento generado el ${DateFormatter.formatDateTime(DateTime.now())}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              ),
        )
      ],
    );
  }

  Widget _buildPestanaAgendamiento(Paciente miPerfil) {
    if (db.campanas.isEmpty) return const Center(child: Text("No hay campañas activas en este momento."));
    
    _campanaSeleccionada ??= db.campanas.first;
    if (!_campanaSeleccionada!.tramos.contains(_tramoSeleccionado)) {
      _tramoSeleccionado = _campanaSeleccionada!.tramos.isNotEmpty ? _campanaSeleccionada!.tramos.first : null;
    }

    List<CentroVacunacion> centrosConStock = db.centros.where((c) => c.tieneStockDeVacuna(_campanaSeleccionada!.vacuna.idVacuna)).toList();
    if (_centroSeleccionado != null && !centrosConStock.contains(_centroSeleccionado)) {
      _centroSeleccionado = null;
      _horaSeleccionada = null;
    }
    _centroSeleccionado ??= centrosConStock.isNotEmpty ? centrosConStock.first : null;

    List<CitaVacunacion> misCitas = [];
    for (var c in db.centros) {
      misCitas.addAll(c.citasAgendadas.where((cita) => cita.rutPaciente == miPerfil.rut));
    }

    List<TimeOfDay> horasDisponibles = _centroSeleccionado != null ? _generarBloquesHorarios(_centroSeleccionado!.horarioAtencion) : [];

    return ListView(
      children: [
        DropdownButtonFormField<Campana>(
          value: _campanaSeleccionada,
          decoration: const InputDecoration(labelText: "Seleccionar Campaña", border: OutlineInputBorder()),
          items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (${c.vacuna.nombre})"))).toList(),
          onChanged: (val) => setState(() { _campanaSeleccionada = val; _tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null; }),
        ),
        const SizedBox(height: 16),
        if (_campanaSeleccionada!.tramos.isNotEmpty)
          DropdownButtonFormField<TramoCampana>(
            value: _tramoSeleccionado,
            decoration: const InputDecoration(labelText: "Seleccionar Tramo", border: OutlineInputBorder()),
            items: _campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(value: t, child: Text("${t.nombreTramo} (Prioridad: ${t.poblacionObjetivo})"))).toList(),
            onChanged: (val) => setState(() => _tramoSeleccionado = val),
          ),
        const SizedBox(height: 16),
        if (centrosConStock.isEmpty)
          const Text("⚠️ No hay sedes disponibles con stock.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
        else
          DropdownButtonFormField<CentroVacunacion>(
            value: _centroSeleccionado,
            decoration: const InputDecoration(labelText: "Sedes Disponibles", border: OutlineInputBorder()),
            items: centrosConStock.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (Horario: ${c.horarioAtencion})"))).toList(),
            onChanged: (val) => setState(() { _centroSeleccionado = val; _horaSeleccionada = null; }),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(_fechaSeleccionada == null ? "Seleccionar Fecha" : DateFormatter.formatDateOnly(_fechaSeleccionada!)),
                  onTap: () => _seleccionarFecha(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<TimeOfDay>(
                value: _horaSeleccionada,
                decoration: const InputDecoration(labelText: "Hora", border: OutlineInputBorder()),
                disabledHint: const Text("Elija Sede"),
                items: horasDisponibles.map((h) => DropdownMenuItem(value: h, child: Text("${h.hour.toString().padLeft(2,'0')}:${h.minute.toString().padLeft(2,'0')}"))).toList(),
                onChanged: _fechaSeleccionada == null ? null : (val) => setState(() => _horaSeleccionada = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          onPressed: (_tramoSeleccionado == null || _centroSeleccionado == null || _fechaSeleccionada == null || _horaSeleccionada == null) ? null : () {
            bool ok = _tramoSeleccionado!.validarPrioridadPaciente(miPerfil);
            if (ok) {
              _agendar(miPerfil);
            } else {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Advertencia de Prioridad"),
                  content: const Text("No cumples con los criterios. Tu hora quedará sujeta a reasignación."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                    ElevatedButton(onPressed: () { Navigator.pop(ctx); _agendar(miPerfil); }, child: const Text("Agendar de todas formas"))
                  ],
                )
              );
            }
          },
          child: const Text("Confirmar Cita Personal"),
        ),
        const SizedBox(height: 24),
        const Text("Mis Citas Programadas:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        misCitas.isEmpty
            ? const Text("No registras citas activas.")
            : ListView.builder(
                shrinkWrap: true, // Para evitar errores dentro del ListView padre
                physics: const NeverScrollableScrollPhysics(),
                itemCount: misCitas.length,
                itemBuilder: (context, index) {
                  var c = misCitas[index];
                  String centroN = db.centros.firstWhere((x) => x.idCentro == c.idCentro).nombre;
                  return Card(child: ListTile(leading: const Icon(Icons.calendar_today, color: Colors.teal), title: Text(DateFormatter.formatDateTime(c.fechaHora)), subtitle: Text("Sede: $centroN\nEstado: ${c.estado}")));
                },
              )
      ],
    );
  }

  void _agendar(Paciente perfil) {
    DateTime fechaHoraFinal = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day, _horaSeleccionada!.hour, _horaSeleccionada!.minute);
    var cita = _centroSeleccionado!.crearCita(fechaHoraFinal, perfil, _tramoSeleccionado!.idTramo);
    if (cita != null) {
      CustomDialogs.showMessage(context, "Éxito", "Cita tomada de forma exitosa.");
      setState(() { _fechaSeleccionada = null; _horaSeleccionada = null; });
    }
  }
}