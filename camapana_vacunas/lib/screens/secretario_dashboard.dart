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

      while (actual.hour < limite.hour ||
          (actual.hour == limite.hour && actual.minute < limite.minute)) {
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
                        decoration: const InputDecoration(
                          labelText: "RUT Paciente",
                        ),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: nombresCtrl,
                        decoration: const InputDecoration(labelText: "Nombres"),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(
                          labelText: "Apellidos",
                        ),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      TextFormField(
                        controller: correoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Correo Electrónico",
                        ),
                        validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: grupoRiesgo,
                        decoration: const InputDecoration(
                          labelText: "Grupo de Riesgo",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  "Adultos Mayores",
                                  "Crónicos",
                                  "Embarazadas",
                                  "Jovenes Sanos",
                                  "Público General",
                                ]
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => grupoRiesgo = val!),
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
      _horaSeleccionada = null;
    }
    _centroSeleccionado ??= centrosConStock.isNotEmpty
        ? centrosConStock.first
        : null;

    List<Paciente> listaPacientes = db.usuarios.whereType<Paciente>().toList();
    _rutBeneficiarioSeleccionado ??= listaPacientes.isNotEmpty
        ? listaPacientes.first.rut
        : db.usuarioActivo!.rut;

    List<CitaVacunacion> todasLasCitas = [];
    for (var c in db.centros) {
      todasLasCitas.addAll(c.citasAgendadas);
    }

    List<TimeOfDay> horasDisponibles = _centroSeleccionado != null
        ? _generarBloquesHorarios(_centroSeleccionado!.horarioAtencion)
        : [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Módulo de Agendamiento Presencial",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _mostrarFormularioCrearPaciente,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("Registrar Paciente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade100,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _rutBeneficiarioSeleccionado,
            decoration: const InputDecoration(
              labelText: "Beneficiario de la Hora Médica",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFFFF9C4),
            ),
            items: [
              DropdownMenuItem(
                value: db.usuarioActivo!.rut,
                child: Text(
                  "✨ Agendar para mí mismo (${db.usuarioActivo!.nombres})",
                ),
              ),
              ...listaPacientes.map(
                (p) => DropdownMenuItem(
                  value: p.rut,
                  child: Text(
                    "Paciente: ${p.nombres} ${p.apellidos} (${p.rut})",
                  ),
                ),
              ),
            ],
            onChanged: (val) =>
                setState(() => _rutBeneficiarioSeleccionado = val),
          ),
          const SizedBox(height: 12),

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
            onChanged: (val) => setState(() {
              _campanaSeleccionada = val;
              _tramoSeleccionado = val!.tramos.isNotEmpty
                  ? val.tramos.first
                  : null;
            }),
          ),
          const SizedBox(height: 12),

          if (_campanaSeleccionada!.tramos.isNotEmpty)
            DropdownButtonFormField<TramoCampana>(
              value: _tramoSeleccionado,
              decoration: const InputDecoration(
                labelText: "Tramo de Prioridad",
                border: OutlineInputBorder(),
              ),
              items: _campanaSeleccionada!.tramos
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text("${t.nombreTramo} -> ${t.poblacionObjetivo}"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _tramoSeleccionado = val),
            ),
          const SizedBox(height: 12),

          DropdownButtonFormField<CentroVacunacion>(
            value: _centroSeleccionado,
            decoration: const InputDecoration(
              labelText: "Sede de Vacunación",
              border: OutlineInputBorder(),
            ),
            items: centrosConStock
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text("${c.nombre} (Horario: ${c.horarioAtencion})"),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() {
              _centroSeleccionado = val;
              _horaSeleccionada = null;
            }),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.teal,
                    ),
                    title: Text(
                      _fechaSeleccionada == null
                          ? "Seleccionar Fecha"
                          : DateFormatter.formatDateOnly(_fechaSeleccionada!),
                    ),
                    onTap: () => _seleccionarFecha(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<TimeOfDay>(
                  value: _horaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: "Bloque Horario",
                    border: OutlineInputBorder(),
                  ),
                  disabledHint: const Text("Elija Día"),
                  items: horasDisponibles
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text(
                            "${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _fechaSeleccionada == null
                      ? null
                      : (val) => setState(() => _horaSeleccionada = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.bookmark_added),
            label: const Text(
              "Confirmar Registro de Cita",
              style: TextStyle(fontSize: 16),
            ),
            onPressed:
                (_tramoSeleccionado == null ||
                    _centroSeleccionado == null ||
                    _fechaSeleccionada == null ||
                    _horaSeleccionada == null)
                ? null
                : () {
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
                        estadoVacunacion: "Sin vacunas",
                      );
                    } else {
                      pacienteDestino =
                          db.usuarios.firstWhere(
                                (u) => u.rut == _rutBeneficiarioSeleccionado,
                              )
                              as Paciente;
                    }

                    DateTime fechaHoraFinal = DateTime(
                      _fechaSeleccionada!.year,
                      _fechaSeleccionada!.month,
                      _fechaSeleccionada!.day,
                      _horaSeleccionada!.hour,
                      _horaSeleccionada!.minute,
                    );

                    CitaVacunacion? cita = _centroSeleccionado!.crearCita(
                      fechaHoraFinal,
                      pacienteDestino,
                      _tramoSeleccionado!.idTramo,
                    );
                    if (cita != null) {
                      CustomDialogs.showMessage(
                        context,
                        "Éxito",
                        "Cita agendada correctamente en ${_centroSeleccionado!.nombre}.",
                      );
                      setState(() {
                        _fechaSeleccionada = null;
                        _horaSeleccionada = null;
                      });
                    } else {
                      CustomDialogs.showMessage(
                        context,
                        "Error",
                        "Sin cupos para el bloque horario.",
                      );
                    }
                  },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            "Control e Historial de Citas del Sistema:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: todasLasCitas.length,
              itemBuilder: (context, index) {
                var c = todasLasCitas[index];
                var centroNombre = db.centros
                    .firstWhere((centro) => centro.idCentro == c.idCentro)
                    .nombre;
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.bookmark, color: Colors.blueGrey),
                    title: Text("Paciente RUT: ${c.rutPaciente}"),
                    subtitle: Text(
                      "Sede: $centroNombre\nFecha: ${DateFormatter.formatDateTime(c.fechaHora)}",
                    ),
                    trailing: Chip(label: Text(c.estado)),
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
