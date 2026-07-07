import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadido para el TextInputFormatter
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';
import '../widgets/header_actions.dart';
import '../utils/app_validators.dart'; // Aseguramos tener los validadores

class SecretarioDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const SecretarioDashboard({super.key, required this.onLogout});

  @override
  State<SecretarioDashboard> createState() => _SecretarioDashboardState();
}

class _SecretarioDashboardState extends State<SecretarioDashboard> {
  final db = MockDatabase();
  
  // Controladores y Estados de la Búsqueda
  final _searchCtrl = TextEditingController();
  Paciente? _pacienteEncontrado;
  bool _isSearching = false; 
  String? _errorMessage;     

  // Lógica de bloques horarios
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

  Future<void> _buscarPaciente() async {
    String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _pacienteEncontrado = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    var pacientes = db.usuarios.whereType<Paciente>().where((p) {
      bool coincideRut = p.rut.toLowerCase().contains(query);
      bool coincideNombre = p.nombres.toLowerCase().contains(query) || p.apellidos.toLowerCase().contains(query);
      return coincideRut || coincideNombre;
    }).toList();

    setState(() {
      _isSearching = false;
      if (pacientes.isNotEmpty) {
        _pacienteEncontrado = pacientes.first; 
      } else {
        _errorMessage = "No se encontraron registros para '$query'.";
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (db.usuarioActivo == null) {
      Future.microtask(() => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false));
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ENCABEZADO
          Container(
            padding: const EdgeInsets.fromLTRB(32, 50, 32, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
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
                    Text("Hola, ${db.usuarioActivo?.nombres ?? 'Secretari@'} 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      child: Text("Módulo de Recepción • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _mostrarFormularioCrearPaciente,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                      label: const Text("Nuevo Paciente"),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.tertiary, foregroundColor: colorScheme.onTertiary, elevation: 0, minimumSize: const Size(0, 48)),
                    ),
                    HeaderActions(onLogout: widget.onLogout, usuarioActivo: db.usuarioActivo!),
                  ],
                ),
              ],
            ),
          ),

          // CUERPO PRINCIPAL (Buscador y Resultados)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- BARRA DE BÚSQUEDA REDISEÑADA ---
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      inputFormatters: [
                        BuscadorFormatter(),  
                      ],
                      onSubmitted: (_) => _buscarPaciente(),
                      decoration: InputDecoration(
                        hintText: "Buscar por RUT, Nombre o Apellido...",
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _buscarPaciente,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Buscar"),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- ÁREA DE RESULTADOS DINÁMICA ---
                  Expanded(
                    child: _isSearching
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: colorScheme.primary),
                                const SizedBox(height: 16),
                                Text("Buscando en la base de datos...", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_off_rounded, size: 64, color: colorScheme.error.withOpacity(0.6)),
                                    const SizedBox(height: 16),
                                    Text(_errorMessage!, style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text("Verifica el dato o registra un nuevo paciente.", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              )
                            : _pacienteEncontrado == null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.badge_outlined, size: 64, color: colorScheme.outlineVariant),
                                        const SizedBox(height: 16),
                                        Text("Ingrese un RUT o Nombre para localizar la ficha.", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                                      ],
                                    ),
                                  )
                                : _buildFichaPaciente(_pacienteEncontrado!, colorScheme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTE: FICHA DEL PACIENTE ---
  Widget _buildFichaPaciente(Paciente paciente, ColorScheme colorScheme) {
    List<CitaVacunacion> citasPaciente = [];
    for (var c in db.centros) {
      citasPaciente.addAll(c.citasAgendadas.where((cita) => cita.rutPaciente == paciente.rut));
    }
    
    // Filtramos para mostrar "En Sala de Espera" también en pendientes
    var pendientes = citasPaciente.where((c) => c.estado == "Programada" || c.estado == "Agendada" || c.estado == "En Sala de Espera").toList();
    var historial = citasPaciente.where((c) => c.estado == "Completada" || c.estado == "Cancelada").toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    );
  }

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
      child: Row(
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
          // MODIFICACIÓN DE BOTONES CHECK-IN / CANCELAR
          if (esPasada || esEnSala)
            Text(cita.estado, style: TextStyle(fontWeight: FontWeight.bold, color: esPasada ? colorScheme.onSurfaceVariant : colorScheme.tertiary))
          else
            PopupMenuButton<String>(
              tooltip: "Opciones de Cita",
              icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
              onSelected: (value) {
                setState(() {
                  if (value == 'checkin') {
                    cita.estado = "En Sala de Espera";
                    CustomDialogs.showSnackBar(context, "Paciente marcado en sala de espera.");
                  } else if (value == 'cancelar') {
                    cita.estado = "Cancelada";
                    CustomDialogs.showSnackBar(context, "Cita cancelada correctamente.");
                  }
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'checkin',
                  child: Row(
                    children: [
                      Icon(Icons.how_to_reg_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Registrar Llegada'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'cancelar',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar Cita'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- DIÁLOGOS MODERNOS ---

  void _mostrarFormularioAgendamiento(Paciente pacienteDestino) {
    if (db.campanas.isEmpty) {
      CustomDialogs.showMessage(context, "Atención", "No hay campañas activas.");
      return;
    }

    Campana? campanaSeleccionada = db.campanas.first;
    TramoCampana? tramoSeleccionado = campanaSeleccionada.tramos.isNotEmpty ? campanaSeleccionada.tramos.first : null;
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
                      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle), child: Icon(Icons.event_available_rounded, size: 36, color: colorScheme.primary)),
                      const SizedBox(height: 16),
                      Text("Agendar Cita", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5)),
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
                                var cita = centroSeleccionado!.crearCita(fechaHoraFinal, pacienteDestino, tramoSeleccionado!.idTramo);
                                if (cita != null) {
                                  Navigator.pop(context);
                                  CustomDialogs.showSnackBar(context, "Cita agendada correctamente.");
                                  setState(() {}); 
                                } else {
                                  CustomDialogs.showMessage(context, "Error", "Sin cupos disponibles.");
                                }
                              },
                              child: const Text("Confirmar Cita"),
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

  void _mostrarFormularioCrearPaciente() {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController();
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    String grupoRiesgo = "Público General";
    
    // VARIABLE PARA VALIDACIÓN INTELIGENTE
    bool intentoGuardar = false;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    // VALIDACIÓN INTELIGENTE APLICADA AQUÍ
                    autovalidateMode: intentoGuardar ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colorScheme.tertiary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.person_add_rounded, size: 36, color: colorScheme.tertiary)),
                        const SizedBox(height: 16),
                        Text("Registrar Paciente", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary)),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: rutCtrl, 
                          decoration: const InputDecoration(labelText: "RUT Paciente", prefixIcon: Icon(Icons.badge_rounded)), 
                          // FORMATTEO EN TIEMPO REAL
                          inputFormatters: [
                            RutFormatter(),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          validator: AppValidators.validarRut
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: nombresCtrl, decoration: const InputDecoration(labelText: "Nombres"), validator: (v) => AppValidators.validarVacio(v, "Nombres"))),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: "Apellidos"), validator: (v) => AppValidators.validarVacio(v, "Apellidos"))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: correoCtrl, 
                          decoration: const InputDecoration(labelText: "Correo Electrónico"), 
                          keyboardType: TextInputType.emailAddress, 
                          validator: AppValidators.validarCorreo
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telefonoCtrl, 
                          decoration: const InputDecoration(labelText: "Teléfono de contacto"), 
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.filtroTelefono,
                          validator: AppValidators.validarTelefono,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: grupoRiesgo,
                          decoration: const InputDecoration(labelText: "Grupo de Riesgo"),
                          items: ["Adultos Mayores", "Crónicos", "Embarazadas", "Jovenes Sanos", "Público General"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) => setStateDialog(() => grupoRiesgo = val!),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Cancelar"))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: () {
                                  // ACTIVAR VALIDACIÓN AL PRESIONAR EL BOTÓN
                                  setStateDialog(() => intentoGuardar = true);
                                  
                                  if (formKey.currentState!.validate()) {
                                    rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);
                                    var nuevoPaciente = Paciente(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), rutSecretarioCreador: db.usuarioActivo!.rut, prevision: "Fonasa", grupoRiesgo: grupoRiesgo, estadoVacunacion: "Sin vacunas");
                                    setState(() {
                                      db.usuarios.add(nuevoPaciente);
                                      _searchCtrl.text = nuevoPaciente.rut; // Autocompletar búsqueda
                                    });
                                    Navigator.pop(context);
                                    _buscarPaciente(); // Cargar ficha inmediatamente
                                    CustomDialogs.showSnackBar(context, "Paciente registrado correctamente.");
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
}