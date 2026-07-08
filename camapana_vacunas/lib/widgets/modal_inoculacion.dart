import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../models/centros/centro_vacunacion.dart';
import '../models/campanas/inventario_vacuna.dart';
import '../models/transacciones/fachada_registro_vacunacion.dart';
import '../services/mock_database.dart';
import '../widgets/custom_dialogs.dart';
import '../utils/app_theme.dart';

class ModalInoculacion extends StatefulWidget {
  final CitaVacunacion cita;
  final Paciente paciente;
  final CentroVacunacion centro;
  final VoidCallback onSuccess;

  const ModalInoculacion({
    super.key,
    required this.cita,
    required this.paciente,
    required this.centro,
    required this.onSuccess,
  });

  @override
  State<ModalInoculacion> createState() => _ModalInoculacionState();
}

class _ModalInoculacionState extends State<ModalInoculacion> {
  final db = MockDatabase();
  late List<InventarioVacuna> inventarioValido;
  InventarioVacuna? loteSeleccionado;
  final obsController = TextEditingController(text: "Procedimiento exitoso sin reacciones inmediatas.");

  @override
  void initState() {
    super.initState();
    // Filtramos solo el inventario válido al iniciar el modal
    inventarioValido = widget.centro.inventarios
        .where((inv) => inv.cantidadDisponible > 0 && !inv.estaVencida())
        .toList();
    if (inventarioValido.isNotEmpty) {
      loteSeleccionado = inventarioValido.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (inventarioValido.isEmpty) {
      return AlertDialog(
        title: const Text("Alerta de Stock"),
        content: const Text("No hay vacunas disponibles o vigentes en este recinto para realizar el procedimiento."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.vaccines_rounded, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Registrar Inoculación", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        Text("Confirmación clínica del procedimiento", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- RESUMEN DEL PACIENTE ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, color: colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Paciente: ${widget.paciente.nombres} ${widget.paciente.apellidos}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("RUT: ${widget.paciente.rut} | Grupo: ${widget.paciente.grupoRiesgo}", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- FORMULARIO CLÍNICO ---
              DropdownButtonFormField<InventarioVacuna>(
                value: loteSeleccionado,
                decoration: const InputDecoration(labelText: "Seleccionar Lote a Administrar", prefixIcon: Icon(Icons.inventory_2_rounded)),
                items: inventarioValido.map((inv) => DropdownMenuItem(
                  value: inv,
                  child: Text("${inv.vacuna.idVacuna} (Disp: ${inv.cantidadDisponible})", style: const TextStyle(fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (val) => setState(() => loteSeleccionado = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: obsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Observaciones o eventos adversos",
                  alignLabelWithHint: true,
                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 40.0), child: Icon(Icons.notes_rounded)),
                ),
              ),
              const SizedBox(height: 32),

            // BOTONES DE ACCIÓN
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      
                      String resultado = FachadaRegistroVacunacion.procesarVacunacion(
                        cita: widget.cita,
                        paciente: widget.paciente,
                        centro: widget.centro,
                        rutProfesional: db.usuarioActivo!.rut,
                        observaciones: obsController.text,
                        loteSeleccionado: loteSeleccionado!, 
                      );
                      
                      if (resultado.startsWith("Éxito")) {
                        CustomDialogs.showSnackBar(context, resultado);
                        widget.onSuccess(); 
                      } else {
                        CustomDialogs.showMessage(context, "Error", resultado);
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text("Confirmar Vacunación", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Hace juego con las tarjetas
                      ),
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
}
