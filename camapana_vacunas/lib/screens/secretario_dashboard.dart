import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';

class SecretarioDashboard extends StatefulWidget {
  const SecretarioDashboard({super.key});

  @override
  State<SecretarioDashboard> createState() => _SecretarioDashboardState();
}

class _SecretarioDashboardState extends State<SecretarioDashboard> {
  final db = MockDatabase();

  Campana? _campanaSeleccionada;
  TramoCampana? _tramoSeleccionado;
  CentroVacunacion? _centroSeleccionado;

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String? _rutBeneficiarioSeleccionado;

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

  void _mostrarFormularioCrearPaciente() {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController();
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    String grupoRiesgo = "Público General";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Registrar Paciente (Asistido)"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: rutCtrl,
                        decoration: const InputDecoration(labelText: "RUT Paciente"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: nombresCtrl,
                        decoration: const InputDecoration(labelText: "Nombres"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(labelText: "Apellidos"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: correoCtrl,
                        decoration: const InputDecoration(labelText: "Correo Electrónico"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: grupoRiesgo,
                        decoration: const InputDecoration(
                          labelText: "Grupo de Riesgo",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          "Adultos Mayores",
                          "Crónicos",
                          "Embarazadas",
                          "Jovenes Sanos",
                          "Público General",
                        ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setStateDialog(() => grupoRiesgo = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      var nuevoPaciente = Paciente(
                        rut: rutCtrl.text,
                        nombres: nombresCtrl.text,
                        apellidos: apellidosCtrl.text,
                        correo: correoCtrl.text,
                        telefono: "S/N",
                        fechaNacimiento: DateTime(1990, 1, 1),
                        rutSecretarioCreador: db.usuarioActivo!.rut,
                        prevision: "Fonasa",
                        grupoRiesgo: grupoRiesgo,
                        estadoVacunacion: "Sin vacunas",
                      );
                      setState(() {
                        db.usuarios.add(nuevoPaciente);
                        _rutBeneficiarioSeleccionado = nuevoPaciente.rut;
                      });
                      Navigator.pop(context);
                      CustomDialogs.showSnackBar(
                        context,
                        "Paciente registrado e integrado al selector.",
                      );
                    }
                  },
                  child: const Text("Guardar Perfil"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // LÓGICA DE NEGOCIO
    if (db.campanas.isEmpty) return const Center(child: Text("No hay campañas activas."));

    _campanaSeleccionada ??= db.campanas.first;
    if (!_campanaSeleccionada!.tramos.contains(_tramoSeleccionado)) {
      _tramoSeleccionado = _campanaSeleccionada!.tramos.isNotEmpty ? _campanaSeleccionada!.tramos.first : null;
    }

    List<CentroVacunacion> centrosConStock = db.centros.where(
      (c) => c.tieneStockDeVacuna(_campanaSeleccionada!.vacuna.idVacuna),
    ).toList();
    
    if (_centroSeleccionado != null && !centrosConStock.contains(_centroSeleccionado)) {
      _centroSeleccionado = null;
      _horaSeleccionada = null;
    }
    _centroSeleccionado ??= centrosConStock.isNotEmpty ? centrosConStock.first : null;

    List<Paciente> listaPacientes = db.usuarios.whereType<Paciente>().toList();
    _rutBeneficiarioSeleccionado ??= listaPacientes.isNotEmpty ? listaPacientes.first.rut : db.usuarioActivo!.rut;

    List<CitaVacunacion> todasLasCitas = [];
    for (var c in db.centros) {
      todasLasCitas.addAll(c.citasAgendadas);
    }

    List<TimeOfDay> horasDisponibles = _centroSeleccionado != null ? _generarBloquesHorarios(_centroSeleccionado!.horarioAtencion) : [];

    // CONSTRUCCIÓN DE LA VISTA
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
                      "Hola, ${db.usuarioActivo?.nombres ?? 'Secretari@'} 👋",
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
                        "Panel de Recepción • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _mostrarFormularioCrearPaciente,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text("Nuevo Paciente"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                )
              ],
            ),
          ),

          // CUERPO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Módulo de Agendamiento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  const SizedBox(height: 24),
                  
                  // FORMULARIO DE AGENDAMIENTO
                  DropdownButtonFormField<String>(
                    value: _rutBeneficiarioSeleccionado,
                    decoration: InputDecoration(
                      labelText: "Beneficiario de la Hora Médica", 
                      prefixIcon: Icon(Icons.badge_outlined, color: Theme.of(context).colorScheme.primary),
                      fillColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      filled: true,
                    ),
                    items: [
                      DropdownMenuItem(value: db.usuarioActivo!.rut, child: Text("✨ Agendar para mí mismo (${db.usuarioActivo!.nombres})")),
                      ...listaPacientes.map((p) => DropdownMenuItem(value: p.rut, child: Text("${p.nombres} ${p.apellidos} (${p.rut})")))
                    ],
                    onChanged: (val) => setState(() => _rutBeneficiarioSeleccionado = val),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<Campana>(
                    value: _campanaSeleccionada,
                    decoration: InputDecoration(labelText: "Campaña Activa", prefixIcon: Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.primary)),
                    items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (${c.vacuna.nombre})"))).toList(),
                    onChanged: (val) => setState(() { _campanaSeleccionada = val; _tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null; }),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_campanaSeleccionada!.tramos.isNotEmpty) ...[
                    DropdownButtonFormField<TramoCampana>(
                      value: _tramoSeleccionado,
                      decoration: InputDecoration(labelText: "Tramo de Prioridad", prefixIcon: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary)),
                      items: _campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(value: t, child: Text("${t.nombreTramo} -> ${t.poblacionObjetivo}"))).toList(),
                      onChanged: (val) => setState(() => _tramoSeleccionado = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  DropdownButtonFormField<CentroVacunacion>(
                    value: _centroSeleccionado,
                    decoration: InputDecoration(labelText: "Sede de Vacunación", prefixIcon: Icon(Icons.local_hospital_outlined, color: Theme.of(context).colorScheme.primary)),
                    items: centrosConStock.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
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
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5), 
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
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<TimeOfDay>(
                          value: _horaSeleccionada,
                          decoration: InputDecoration(labelText: "Bloque", prefixIcon: Icon(Icons.access_time_rounded, color: Theme.of(context).colorScheme.primary)), 
                          disabledHint: const Text("Sede?"),
                          items: horasDisponibles.map((h) => DropdownMenuItem(
                            value: h, 
                            child: Text("${h.hour.toString().padLeft(2,'0')}:${h.minute.toString().padLeft(2,'0')}")
                          )).toList(),
                          onChanged: _fechaSeleccionada == null ? null : (val) => setState(() => _horaSeleccionada = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // BOTÓN DE AGENDAR
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
                    label: const Text("Confirmar Cita Médica", style: TextStyle(fontSize: 18)),
                    onPressed: (_tramoSeleccionado == null || _centroSeleccionado == null || _fechaSeleccionada == null || _horaSeleccionada == null) ? null : () {
                      Paciente pacienteDestino;
                      if (_rutBeneficiarioSeleccionado == db.usuarioActivo!.rut) {
                        pacienteDestino = Paciente(
                          rut: db.usuarioActivo!.rut, 
                          nombres: db.usuarioActivo!.nombres, 
                          apellidos: db.usuarioActivo!.apellidos, 
                          correo: db.usuarioActivo!.correo, 
                          telefono: "S/N", 
                          fechaNacimiento: DateTime.now(), 
                          prevision: "Fonasa", 
                          grupoRiesgo: "Público General", 
                          estadoVacunacion: "Sin vacunas"
                        );
                      } else {
                        pacienteDestino = db.usuarios.firstWhere((u) => u.rut == _rutBeneficiarioSeleccionado) as Paciente;
                      }
                      
                      DateTime fechaHoraFinal = DateTime(
                        _fechaSeleccionada!.year, 
                        _fechaSeleccionada!.month, 
                        _fechaSeleccionada!.day, 
                        _horaSeleccionada!.hour, 
                        _horaSeleccionada!.minute
                      );
                      
                      CitaVacunacion? cita = _centroSeleccionado!.crearCita(fechaHoraFinal, pacienteDestino, _tramoSeleccionado!.idTramo);
                      
                      if (cita != null) {
                        CustomDialogs.showMessage(context, "Éxito", "Cita agendada correctamente en ${_centroSeleccionado!.nombre}.");
                        setState(() { _fechaSeleccionada = null; _horaSeleccionada = null; });
                      } else {
                        CustomDialogs.showMessage(context, "Error", "Sin cupos para el bloque horario.");
                      }
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  
                  // HISTORIAL DE CITAS (Tarjetas flotantes)
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text("Historial de Citas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todasLasCitas.length,
                    itemBuilder: (context, index) {
                      var c = todasLasCitas[index];
                      var centroNombre = db.centros.firstWhere((centro) => centro.idCentro == c.idCentro).nombre;
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
                            child: Icon(Icons.vaccines_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text("RUT: ${c.rutPaciente}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text("$centroNombre\n${DateFormatter.formatDateTime(c.fechaHora)}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c.estado, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}