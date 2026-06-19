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

  // Variables Historial Médico (Listas y Controladores)
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
    
    setState(() {
      _historialGenerado = director.construirHistorialCompleto(paciente, _misAlergias, _misCondiciones);
    });
  }

  @override
  Widget build(BuildContext context) {
    Paciente miPerfil = db.usuarioActivo as Paciente;

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
                      "Hola, ${miPerfil.nombres} 👋",
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
                        "Portal del Paciente • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
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
                      child: TabBar(
                        padding: const EdgeInsets.all(6),
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary, 
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent, // Quita la línea de abajo
                        tabs: const [
                          Tab(icon: Icon(Icons.event_available_rounded), text: "Auto-Agendamiento"),
                          Tab(icon: Icon(Icons.medical_information_rounded), text: "Mi Historial Médico"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // CONTENIDO DE LAS PESTAÑAS
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildPestanaAgendamiento(miPerfil),
                          _buildPestanaHistorial(miPerfil),
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

// VISTA: PESTAÑA DE HISTORIAL MÉDICO
  Widget _buildPestanaHistorial(Paciente perfil) {
    // 1. Detectamos si es una pantalla grande (Desktop/Web) o pequeña (Celular)
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    // 2. CONTENIDO DEL FORMULARIO (Desacoplado)
    List<Widget> formContent = [
      Text("Construir Antecedentes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onBackground, letterSpacing: -0.5)),
      const SizedBox(height: 24),
      TextField(
        controller: _alergiaCtrl,
        decoration: InputDecoration(
          labelText: "Añadir Alergia", hintText: "Ej. Polvo, Penicilina...",
          prefixIcon: Icon(Icons.sick_outlined, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(Icons.add_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
            onPressed: () { if (_alergiaCtrl.text.isNotEmpty) setState(() { _misAlergias.add(_alergiaCtrl.text); _alergiaCtrl.clear(); }); },
          ),
        ),
      ),
      if (_misAlergias.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Wrap(
            spacing: 8.0, runSpacing: 8.0,
            children: _misAlergias.map((a) => Chip(
              label: Text(a, style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontWeight: FontWeight.w600, fontSize: 13)),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
              deleteIconColor: Theme.of(context).colorScheme.error,
              onDeleted: () => setState(() => _misAlergias.remove(a)),
            )).toList(),
          ),
        ),
      const SizedBox(height: 32),
      TextField(
        controller: _condicionCtrl,
        decoration: InputDecoration(
          labelText: "Añadir Condición Previa", hintText: "Ej. Asma, Hipertensión...",
          prefixIcon: Icon(Icons.monitor_heart_outlined, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(Icons.add_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
            onPressed: () { if (_condicionCtrl.text.isNotEmpty) setState(() { _misCondiciones.add(_condicionCtrl.text); _condicionCtrl.clear(); }); },
          ),
        ),
      ),
      if (_misCondiciones.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Wrap(
            spacing: 8.0, runSpacing: 8.0,
            children: _misCondiciones.map((c) => Chip(
              label: Text(c, style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontWeight: FontWeight.w600, fontSize: 13)),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
              deleteIconColor: Theme.of(context).colorScheme.error,
              onDeleted: () => setState(() => _misCondiciones.remove(c)),
            )).toList(),
          ),
        ),
    ];

    Widget botonGenerar = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
      onPressed: () => _generarHistorialMedico(perfil),
      icon: const Icon(Icons.download_rounded),
      label: const Text("Generar Documento"),
    );

    // 3. ARMADO DEL PANEL IZQUIERDO
    Widget panelIzquierdo = Container(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0), // Menos padding interno en celular
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: isDesktop 
        ? Column(
            children: [
              Expanded(child: ListView(physics: const BouncingScrollPhysics(), children: formContent)),
              const SizedBox(height: 16),
              botonGenerar,
            ],
          )
        : Column( // En celular dejamos que el formulario ocupe su altura natural
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...formContent, const SizedBox(height: 32), botonGenerar],
          ),
    );

    // 4. ARMADO DEL PANEL DERECHO (REPORTE)
    Widget panelDerechoContenido = _historialGenerado == null
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.assignment_add, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              Text("Sin documento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))),
              const SizedBox(height: 12),
              Text("Agrega tus datos en el formulario y genera el reporte.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            ],
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text("🏥 REPORTE MÉDICO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Theme.of(context).colorScheme.onBackground))),
            const SizedBox(height: 16), const Divider(thickness: 1), const SizedBox(height: 16),
            Text("1. DATOS DEL PACIENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8), Text(_historialGenerado!.datosPersonales, style: TextStyle(color: Theme.of(context).colorScheme.onBackground, height: 1.5)),
            const SizedBox(height: 24),
            Text("2. ANTECEDENTES CLÍNICOS", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8), Text("Alergias: ${_historialGenerado!.alergias}\nCondiciones: ${_historialGenerado!.condicionesPrevias}", style: TextStyle(color: Theme.of(context).colorScheme.onBackground, height: 1.5)),
            const SizedBox(height: 24),
            Text("3. REGISTRO DE VACUNACIÓN", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8), Text(_historialGenerado!.vacunasAplicadas, style: TextStyle(color: Theme.of(context).colorScheme.onBackground, height: 1.5)),
            const SizedBox(height: 32), const Divider(), const SizedBox(height: 8),
            Center(child: Text("Generado el ${DateFormatter.formatDateTime(DateTime.now())}", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          ],
        );

    Widget panelDerechoDecorado = Container(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
      decoration: BoxDecoration(
        color: _historialGenerado == null ? Theme.of(context).colorScheme.surface.withOpacity(0.7) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: _historialGenerado == null ? 1.5 : 1.0),
        boxShadow: _historialGenerado == null ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: isDesktop ? ListView(physics: const BouncingScrollPhysics(), children: [panelDerechoContenido]) : panelDerechoContenido,
    );

    // 5. RENDERIZADO FINAL
    if (isDesktop) {
      // Pantalla ancha: Lado a lado
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: panelIzquierdo),
          const SizedBox(width: 32),
          Expanded(flex: 2, child: panelDerechoDecorado),
        ],
      );
    } else {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          panelIzquierdo,
          const SizedBox(height: 24), // Espacio vertical entre ambas tarjetas
          panelDerechoDecorado,
        ],
      );
    }
  }

  // VISTA: PESTAÑA DE AUTO-AGENDAMIENTO
  Widget _buildPestanaAgendamiento(Paciente miPerfil) {
    if (db.campanas.isEmpty) return Center(child: Text("No hay campañas activas en este momento.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
    
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
      physics: const BouncingScrollPhysics(),
      children: [
        DropdownButtonFormField<Campana>(
          value: _campanaSeleccionada,
          decoration: InputDecoration(labelText: "Seleccionar Campaña", prefixIcon: Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary)),
          items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (${c.vacuna.nombre})"))).toList(),
          onChanged: (val) => setState(() { _campanaSeleccionada = val; _tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null; }),
        ),
        const SizedBox(height: 16),
        if (_campanaSeleccionada!.tramos.isNotEmpty)
          DropdownButtonFormField<TramoCampana>(
            value: _tramoSeleccionado,
            decoration: InputDecoration(labelText: "Seleccionar Tramo", prefixIcon: Icon(Icons.groups_rounded, color: Theme.of(context).colorScheme.primary)),
            items: _campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(value: t, child: Text("${t.nombreTramo} (Prioridad: ${t.poblacionObjetivo})"))).toList(),
            onChanged: (val) => setState(() => _tramoSeleccionado = val),
          ),
        const SizedBox(height: 16),
        if (centrosConStock.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Text("No hay sedes disponibles con stock.", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          DropdownButtonFormField<CentroVacunacion>(
            value: _centroSeleccionado,
            decoration: InputDecoration(labelText: "Sedes Disponibles", prefixIcon: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary)),
            items: centrosConStock.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (Horario: ${c.horarioAtencion})"))).toList(),
            onChanged: (val) => setState(() { _centroSeleccionado = val; _horaSeleccionada = null; }),
          ),
        const SizedBox(height: 24),
        
        // SELECTOR DE FECHA Y HORA
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () => _seleccionarFecha(context),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5), // Centralizado
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), // Sombra del botón
                        blurRadius: 12,
                        offset: const Offset(0, 4), // Elevar el botón
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _fechaSeleccionada == null ? "Seleccionar Fecha" : DateFormatter.formatDateOnly(_fechaSeleccionada!),
                        style: TextStyle(fontSize: 16, color: _fechaSeleccionada == null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onBackground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<TimeOfDay>(
                value: _horaSeleccionada,
                decoration: InputDecoration(labelText: "Hora", prefixIcon: Icon(Icons.access_time_rounded, color: Theme.of(context).colorScheme.primary)),
                disabledHint: const Text("Elija Sede"),
                items: horasDisponibles.map((h) => DropdownMenuItem(value: h, child: Text("${h.hour.toString().padLeft(2,'0')}:${h.minute.toString().padLeft(2,'0')}"))).toList(),
                onChanged: _fechaSeleccionada == null ? null : (val) => setState(() => _horaSeleccionada = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline_rounded),
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
          label: const Text("Confirmar Cita Personal"),
        ),
        
        const SizedBox(height: 40),
        const Divider(height: 1),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Icon(Icons.history_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text("Mis Citas Programadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          ],
        ),
        const SizedBox(height: 20),
        
        misCitas.isEmpty
            ? Text("No registras citas activas.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            : ListView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(),
                itemCount: misCitas.length,
                itemBuilder: (context, index) {
                  var c = misCitas[index];
                  String centroN = db.centros.firstWhere((x) => x.idCentro == c.idCentro).nombre;
                  
                  // Variables para un diseño más moderno
                  final primaryColor = Theme.of(context).colorScheme.primary;
                  final primarySoft = primaryColor.withOpacity(0.08);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, // Centralizado
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Contenedor del Icono
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primarySoft, 
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.vaccines_rounded,
                              color: primaryColor,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 2. Información Principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormatter.formatDateTime(c.fechaHora), 
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: Theme.of(context).colorScheme.onBackground, // Centralizado
                                )
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      centroN, 
                                      style: TextStyle(
                                        fontSize: 14, 
                                        color: Theme.of(context).colorScheme.onSurfaceVariant, // Centralizado
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 3. Pill de Estado (Colores semánticos)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.estado == 'Agendada' 
                                ? Theme.of(context).colorScheme.primaryContainer // Centralizado
                                : Theme.of(context).colorScheme.secondaryContainer, // Centralizado
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            c.estado, 
                            style: TextStyle(
                              color: c.estado == 'Agendada' 
                                  ? Theme.of(context).colorScheme.primary // Centralizado
                                  : Theme.of(context).colorScheme.onSecondaryContainer, // Centralizado
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
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