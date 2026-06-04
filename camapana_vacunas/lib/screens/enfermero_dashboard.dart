import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/paciente.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/transacciones/fachada_registro_vacunacion.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/date_formatter.dart';

class EnfermeroDashboard extends StatefulWidget {
  const EnfermeroDashboard({super.key});

  @override
  State<EnfermeroDashboard> createState() => _EnfermeroDashboardState();
}

class _EnfermeroDashboardState extends State<EnfermeroDashboard> {
  final db = MockDatabase();
  CentroVacunacion? _centroSeleccionado;
  final _obsCtrl = TextEditingController(text: "Procedimiento exitoso sin reacciones inmediatas.");

  @override
  Widget build(BuildContext context) {
    _centroSeleccionado ??= db.centros.isNotEmpty ? db.centros.first : null;

    if (_centroSeleccionado == null) {
      return const Center(child: Text("No existen sedes registradas."));
    }

    // 1. Citas por atender
    var citasPendientes = _centroSeleccionado!.citasAgendadas
        .where((c) => c.estado == "Programada")
        .toList();

    // 2. Registros completados en ESTA sede (Filtrado de la tabla relacional)
    var registrosSede = db.historialRegistros
        .where((reg) => reg.idCentro == _centroSeleccionado!.idCentro)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Módulo de Inmunización", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<CentroVacunacion>(
            value: _centroSeleccionado,
            decoration: const InputDecoration(labelText: "Punto de Atención Actual", border: OutlineInputBorder()),
            items: db.centros.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
            onChanged: (val) => setState(() => _centroSeleccionado = val),
          ),
          const SizedBox(height: 20),
          
          // SECCIÓN 1: PENDIENTES
          Text("Pacientes en Espera (${citasPendientes.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          
          Expanded(
            flex: 4,
            child: citasPendientes.isEmpty
                ? const Card(child: Center(child: Text("No hay citas programadas para hoy.", style: TextStyle(fontStyle: FontStyle.italic))))
                : ListView.builder(
                    itemCount: citasPendientes.length,
                    itemBuilder: (context, index) {
                      var cita = citasPendientes[index];
                      var paciente = db.usuarios.firstWhere((u) => u.rut == cita.rutPaciente) as Paciente;

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text("${paciente.nombres} ${paciente.apellidos} (${paciente.rut})"),
                          subtitle: Text("Grupo: ${paciente.grupoRiesgo}\nPlanificado: ${DateFormatter.formatDateTime(cita.fechaHora)}"),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Inmunizar"),
                            onPressed: () {
                              // Llamada unificada a la Fachada
                              String resultado = FachadaRegistroVacunacion.procesarVacunacion(
                                cita: cita,
                                paciente: paciente,
                                centro: _centroSeleccionado!,
                                rutProfesional: db.usuarioActivo!.rut,
                                observaciones: _obsCtrl.text
                              );
                              
                              if (resultado.startsWith("Éxito")) {
                                CustomDialogs.showSnackBar(context, resultado);
                                setState(() {}); // Actualiza ambas listas al unísono
                              } else {
                                CustomDialogs.showMessage(context, "Error de Validación", resultado);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),

          // SECCIÓN 2: HISTORIAL LOGUEADO
          Text("Historial de Vacunaciones Realizadas (Sede)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 8),

          Expanded(
            flex: 3,
            child: registrosSede.isEmpty
                ? const Card(child: Center(child: Text("Aún no se registran vacunaciones en este turno.", style: TextStyle(fontStyle: FontStyle.italic))))
                : ListView.builder(
                    itemCount: registrosSede.length,
                    itemBuilder: (context, index) {
                      var reg = registrosSede[index];
                      var paciente = db.usuarios.firstWhere((u) => u.rut == reg.rutPaciente) as Paciente;
                      
                      return Card(
                        color: Colors.teal.shade50, // Resaltar visualmente los completados
                        child: ListTile(
                          leading: const Icon(Icons.assignment_turned_in, color: Colors.teal),
                          title: Text("${paciente.nombres} ${paciente.apellidos}"),
                          subtitle: Text("ID Registro: ${reg.idRegistro}\nFecha Aplicación: ${DateFormatter.formatDateTime(reg.fechaHora)}"),
                          trailing: Text("RUT: ${paciente.rut}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}