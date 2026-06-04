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
import 'welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = MockDatabase();

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

  // --- PANEL ADMINISTRADOR ---
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
                onPressed: _mostrarFormularioCampana,
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
                String tipoStr = campana.empresaAsociada == null 
                    ? "Pública" 
                    : "Empresa: ${campana.empresaAsociada!.razonSocial}";

                return Card(
                  child: ListTile(
                    title: Text(campana.nombre),
                    subtitle: Text("Avance: ${campana.calcularAvanceGlobal()}%\nTipo: $tipoStr"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        admin.solicitarReporteEfectos(campana);
                        var reporte = campana.generarReporteEfectos();
                        _mostrarDialogo("Reporte de Efectos", reporte.toString());
                      },
                      child: const Text("Generar Reporte"),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // Lógica de Formulario HU-05
  void _mostrarFormularioCampana() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String tipoSeleccionado = "Pública";
    Empresa? empresaSeleccionada = db.empresas.isNotEmpty ? db.empresas.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Permite actualizar estado dentro del dialog
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
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: "Descripción"),
                        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: const InputDecoration(labelText: "Público Objetivo"),
                        items: ["Pública", "Empresa"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            tipoSeleccionado = val!;
                          });
                        },
                      ),
                      if (tipoSeleccionado == "Empresa") ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Empresa>(
                          value: empresaSeleccionada,
                          decoration: const InputDecoration(labelText: "Seleccionar Empresa"),
                          items: db.empresas.map((e) => DropdownMenuItem(value: e, child: Text(e.razonSocial))).toList(),
                          onChanged: (val) {
                            setStateDialog(() {
                              empresaSeleccionada = val;
                            });
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      var nuevaCampana = Campana(
                        nombre: nombreCtrl.text,
                        descripcion: descCtrl.text,
                        fechaInicio: DateTime.now(),
                        fechaTermino: DateTime.now().add(const Duration(days: 30)),
                        empresaAsociada: tipoSeleccionado == "Empresa" ? empresaSeleccionada : null,
                      );
                      
                      // Añadimos un tramo general para que funcione el agendamiento por defecto
                      nuevaCampana.agregarTramo(TramoCampana(
                        nombreTramo: "General",
                        poblacionObjetivo: "Jovenes Sanos",
                        nivelPrioridad: 1,
                        fechaInicio: DateTime.now(),
                        fechaFin: DateTime.now().add(const Duration(days: 30))
                      ));

                      setState(() {
                        db.campanas.add(nuevaCampana);
                      });
                      
                      Navigator.pop(context);
                      _mostrarDialogo("Éxito", "La campaña ha sido creada y publicada correctamente.");
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

  // --- PANEL SECRETARIO / PACIENTE ---
  Widget _buildPanelAgendamiento() {
    var campana = db.campanas.first;
    var tramo = campana.tramos.first;
    var centro = db.centros.first;
    
    Paciente pacienteObjetivo = db.usuarioActivo is Paciente 
        ? db.usuarioActivo as Paciente 
        : db.usuarios.firstWhere((u) => u is Paciente) as Paciente;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Agendamiento Web: ${centro.nombre}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              bool ok = tramo.validarPrioridadPaciente(pacienteObjetivo);
              if (!ok) {
                _mostrarDialogo("Error", "El paciente no pertenece a la población objetivo.");
                return;
              }

              DateTime fechaCita = DateTime.now().add(const Duration(days: 1));
              CitaVacunacion? cita = centro.crearCita(fechaCita, pacienteObjetivo);

              if (cita != null) {
                _mostrarDialogo("Éxito", "Cita creada para el ${cita.fechaHora.toString().substring(0,16)}");
                setState(() {}); 
              } else {
                _mostrarDialogo("Error", "No hay disponibilidad en la fecha seleccionada.");
              }
            },
            child: const Text("Iniciar Agendamiento"),
          ),
          const SizedBox(height: 20),
          const Text("Mis citas agendadas:", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: centro.citasAgendadas.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(centro.citasAgendadas[index].fechaHora.toString().substring(0, 16)),
                    subtitle: Text("Estado: ${centro.citasAgendadas[index].estado}"),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
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