import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/usuarios/administrador.dart';
import '../models/usuarios/secretario.dart';
import '../models/usuarios/enfermero.dart';
import '../models/usuarios/empresa.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/campanas/tramo_campana.dart';
import '../models/campanas/campana.dart';
import '../models/centros/centro_vacunacion.dart';
import 'welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = MockDatabase();

  Campana? _campanaSeleccionada;
  TramoCampana? _tramoSeleccionado;
  CentroVacunacion? _centroSeleccionado;

  void _cerrarSesion() {
    db.usuarioActivo = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (db.usuarioActivo == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text("Panel: ${db.usuarioActivo!.nombres}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: _cerrarSesion,
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildPanelRol(),
        ),
      ),
    );
  }

  Widget _buildPanelRol() {
    if (db.usuarioActivo is Administrador) return _buildPanelAdmin();
    if (db.usuarioActivo is Secretario || db.usuarioActivo is Paciente) return _buildPanelAgendamiento();
    if (db.usuarioActivo is Enfermero) return const Center(child: Text("Panel Enfermero (Próximamente)"));
    return const Center(child: Text("Rol no reconocido"));
  }

  // --- PANEL ADMINISTRADOR (Sin cambios) ---
  Widget _buildPanelAdmin() {
    var admin = db.usuarioActivo as Administrador;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Gestión de Campañas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioCampana(admin),
                icon: const Icon(Icons.add),
                label: const Text("Nueva Campaña"),
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: db.campanas.length,
              itemBuilder: (context, index) {
                var campana = db.campanas[index];
                String tipoStr = campana.empresaAsociada == null ? "Pública" : "Empresa: ${campana.empresaAsociada!.razonSocial}";
                return Card(
                  child: ExpansionTile(
                    title: Text(campana.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Avance: ${campana.calcularAvanceGlobal().toStringAsFixed(1)}% | Tipo: $tipoStr | Vacuna: ${campana.vacuna.nombre}"),
                    children: [
                      const Divider(),
                      const Text("Tramos de Vacunación", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...campana.tramos.map((t) => ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(t.nombreTramo),
                        subtitle: Text("Objetivo: ${t.poblacionObjetivo} | Prioridad: ${t.nivelPrioridad}\nFechas: ${t.fechaInicio.toString().substring(0,10)} al ${t.fechaFin.toString().substring(0,10)}"),
                      )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                admin.solicitarReporteEfectos(campana);
                                var reporte = campana.generarReporteEfectos();
                                _mostrarDialogo("Reporte de Efectos", reporte.toString());
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text("Reporte Efectos"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarFormularioTramo(campana),
                              icon: const Icon(Icons.add_task),
                              label: const Text("Añadir Tramo"),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _mostrarFormularioTramo(Campana campana) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final prioridadCtrl = TextEditingController(text: "1");
    String poblacionSeleccionada = "Adultos Mayores";
    DateTime fechaInicio = DateTime.now();
    DateTime fechaFin = DateTime.now().add(const Duration(days: 30));

    final opcionesPoblacion = ["Adultos Mayores", "Crónicos", "Embarazadas", "Personal de Salud", "Jovenes Sanos", "Público General"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Añadir Tramo a:\n${campana.nombre}"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre del Tramo (ej. Rezago)"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: poblacionSeleccionada,
                        decoration: const InputDecoration(labelText: "Población Objetivo"),
                        items: opcionesPoblacion.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setStateDialog(() => poblacionSeleccionada = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: prioridadCtrl,
                        decoration: const InputDecoration(labelText: "Nivel de Prioridad (1 = Mayor)"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? "Ingrese un número válido" : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      var nuevoTramo = TramoCampana(
                        idTramo: "TR-${DateTime.now().millisecondsSinceEpoch}", idCampana: campana.idCampana,
                        nombreTramo: nombreCtrl.text, poblacionObjetivo: poblacionSeleccionada,
                        nivelPrioridad: int.parse(prioridadCtrl.text), fechaInicio: fechaInicio, fechaFin: fechaFin,
                      );
                      setState(() { campana.agregarTramo(nuevoTramo); });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar Tramo"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarFormularioCampana(Administrador admin) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    String tipoSeleccionado = "Pública";
    Empresa? empresaSeleccionada = db.empresas.isNotEmpty ? db.empresas.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Crear Nueva Campaña"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre de la Campaña"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: const InputDecoration(labelText: "Público Objetivo"),
                        items: ["Pública", "Empresa"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      String nuevaIdCampana = "CAMP-${DateTime.now().millisecondsSinceEpoch}";
                      var nuevaCampana = Campana(
                        idCampana: nuevaIdCampana, rutAdmin: admin.rut,
                        vacuna: db.vacunas.first, nombre: nombreCtrl.text, descripcion: "Descripción",
                        fechaInicio: DateTime.now(), fechaTermino: DateTime.now().add(const Duration(days: 30)),
                        empresaAsociada: tipoSeleccionado == "Empresa" ? empresaSeleccionada : null,
                      );
                      setState(() { db.campanas.add(nuevaCampana); });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                )
              ],
            );
          }
        );
      }
    );
  }

  // --- PANEL SECRETARIO / PACIENTE (CON FILTRO DE CENTROS) ---
  Widget _buildPanelAgendamiento() {
    if (db.campanas.isEmpty) return const Center(child: Text("No hay campañas activas."));

    // 1. Inicialización segura de la campaña
    _campanaSeleccionada ??= db.campanas.first;
    if (!_campanaSeleccionada!.tramos.contains(_tramoSeleccionado)) {
      _tramoSeleccionado = _campanaSeleccionada!.tramos.isNotEmpty ? _campanaSeleccionada!.tramos.first : null;
    }

    // 2. FILTRAR CENTROS QUE TIENEN STOCK DE LA VACUNA
    List<CentroVacunacion> centrosConStock = db.centros.where((c) => 
      c.tieneStockDeVacuna(_campanaSeleccionada!.vacuna.idVacuna)
    ).toList();

    // 3. Reseteo seguro del centro si cambia la campaña y el anterior ya no sirve
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
          if (cita.rutPaciente == pacienteObjetivo.rut) misCitasTotales.add(cita);
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
          const Text("Solicitud de Agendamiento Web", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<Campana>(
            value: _campanaSeleccionada,
            decoration: const InputDecoration(labelText: "Seleccionar Campaña", border: OutlineInputBorder()),
            items: db.campanas.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} (Vacuna: ${c.vacuna.nombre})"))).toList(),
            onChanged: (val) {
              setState(() {
                _campanaSeleccionada = val;
                _tramoSeleccionado = val!.tramos.isNotEmpty ? val.tramos.first : null;
                // Al cambiar la campaña, el build() filtrará automáticamente los centros
              });
            },
          ),
          const SizedBox(height: 16),
          
          if (_campanaSeleccionada!.tramos.isEmpty)
            const Text("Esta campaña no tiene tramos activos actualmente.", style: TextStyle(color: Colors.red))
          else
            DropdownButtonFormField<TramoCampana>(
              value: _tramoSeleccionado,
              decoration: const InputDecoration(labelText: "Seleccionar Tramo de Prioridad", border: OutlineInputBorder()),
              items: _campanaSeleccionada!.tramos.map((t) => DropdownMenuItem(
                value: t, 
                child: Text("${t.nombreTramo} (Dirigido a: ${t.poblacionObjetivo})")
              )).toList(),
              onChanged: (val) => setState(() => _tramoSeleccionado = val),
            ),
          const SizedBox(height: 16),

          // Selector de Centros Filtrados
          if (centrosConStock.isEmpty)
            const Text("⚠️ Ningún centro tiene stock disponible de la vacuna para esta campaña.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          else
            DropdownButtonFormField<CentroVacunacion>(
              value: _centroSeleccionado,
              decoration: const InputDecoration(labelText: "Sedes disponibles con Stock", border: OutlineInputBorder()),
              items: centrosConStock.map((c) => DropdownMenuItem(
                value: c, 
                child: Text("${c.nombre} - ${c.comuna} (${c.tipo})")
              )).toList(),
              onChanged: (val) => setState(() => _centroSeleccionado = val),
            ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: (_tramoSeleccionado == null || _centroSeleccionado == null) ? null : () {
              bool tienePrioridad = _tramoSeleccionado!.validarPrioridadPaciente(pacienteObjetivo);
              DateTime fechaCita = DateTime.now().add(const Duration(days: 1));

              if (tienePrioridad) {
                _procesarCita(_centroSeleccionado!, pacienteObjetivo, _tramoSeleccionado!.idTramo, fechaCita);
              } else {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Advertencia de Prioridad"),
                    content: Text(
                      "Tu grupo de riesgo (${pacienteObjetivo.grupoRiesgo}) no coincide con la población prioritaria (${_tramoSeleccionado!.poblacionObjetivo})."
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _procesarCita(_centroSeleccionado!, pacienteObjetivo, _tramoSeleccionado!.idTramo, fechaCita);
                        },
                        child: const Text("Continuar de todos modos"),
                      )
                    ],
                  )
                );
              }
            },
            icon: const Icon(Icons.event_available),
            label: const Text("Confirmar y Agendar"),
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text("Mis citas agendadas:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: misCitasTotales.isEmpty 
              ? const Text("Aún no tienes citas programadas.")
              : ListView.builder(
                itemCount: misCitasTotales.length,
                itemBuilder: (context, index) {
                  var cita = misCitasTotales[index];
                  String nombreCentro = db.centros.firstWhere((c) => c.idCentro == cita.idCentro).nombre;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: Colors.teal),
                      title: Text(cita.fechaHora.toString().substring(0, 16)),
                      subtitle: Text("Centro: $nombreCentro \nEstado: ${cita.estado}"),
                    ),
                  );
                },
              ),
          )
        ],
      ),
    );
  }

  void _procesarCita(CentroVacunacion centro, Paciente paciente, String idTramo, DateTime fechaCita) {
    CitaVacunacion? cita = centro.crearCita(fechaCita, paciente, idTramo);
    if (cita != null) {
      _mostrarDialogo("Éxito", "Cita creada exitosamente en ${centro.nombre}");
      setState(() {}); 
    } else {
      _mostrarDialogo("Error", "No hay disponibilidad en el centro para la fecha seleccionada.");
    }
  }

  void _mostrarDialogo(String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(contenido),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))
        ],
      ),
    );
  }
}