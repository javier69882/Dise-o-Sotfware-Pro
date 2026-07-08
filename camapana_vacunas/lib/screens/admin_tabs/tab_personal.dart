import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/mock_database.dart';
import '/models/usuarios/administrador.dart';
import '/models/usuarios/enfermero.dart';
import '/models/usuarios/medico.dart';
import '/models/usuarios/secretario.dart';
import '/widgets/custom_dialogs.dart';
import '/utils/app_validators.dart';

class TabPersonal extends StatefulWidget {
  const TabPersonal({super.key});

  @override
  State<TabPersonal> createState() => _TabPersonalState();
}

class _TabPersonalState extends State<TabPersonal> {
  final db = MockDatabase();

  @override
  Widget build(BuildContext context) {
    var listaPersonal = db.usuarios.where((u) => u.runtimeType.toString() != 'Paciente').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text("Personal del Sistema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
            ElevatedButton.icon(
              onPressed: () => _mostrarFormularioFuncionario(null), 
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text("Registrar Funcionario"),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 48), 
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: listaPersonal.length,
            itemBuilder: (context, index) {
              var funcionario = listaPersonal[index];
              String rol = funcionario.runtimeType.toString();
              
              Color pillColor = Theme.of(context).colorScheme.secondaryContainer;
              Color pillTextColor = Theme.of(context).colorScheme.onSecondaryContainer;
              
              if (rol == 'Administrador') {
                pillColor = Theme.of(context).colorScheme.primaryContainer;
                pillTextColor = Theme.of(context).colorScheme.primary;
              } else if (rol == 'Secretario') {
                pillColor = Colors.orange.shade100;
                pillTextColor = Colors.orange.shade900;
              }

              String infoEspecifica = "";
              if (funcionario is Administrador) {
                infoEspecifica = "Departamento: ${funcionario.departamento}";
              } else if (funcionario is Secretario) {
                infoEspecifica = "ID Operativo: ${funcionario.idSecretario}";
              } else if (funcionario is Medico) {
                infoEspecifica = "Especialidad: ${funcionario.especialidad}\nRNPI: ${funcionario.registro}";
              } else if (funcionario is Enfermero) {
                infoEspecifica = "Unidad: ${funcionario.unidadAsignada}\nRNPI: ${funcionario.registro}";
              }

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        funcionario.nombres[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text("${funcionario.nombres} ${funcionario.apellidos}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(funcionario.correo, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(rol, style: TextStyle(color: pillTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      const SizedBox(height: 4),
                                      Text("RUT: ${funcionario.rut}\nTeléfono: ${funcionario.telefono}", style: const TextStyle(height: 1.5)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Datos del Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      const SizedBox(height: 4),
                                      Text(infoEspecifica, style: const TextStyle(height: 1.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (funcionario.rut != db.usuarioActivo!.rut)
                                  TextButton.icon(
                                    onPressed: () => _confirmarEliminacion(funcionario),
                                    icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                                    label: Text("Revocar Acceso", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _mostrarFormularioFuncionario(funcionario), 
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text("Editar Datos"),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _confirmarEliminacion(var funcionario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Revocar Acceso?"),
        content: Text("Estás a punto de eliminar al ${funcionario.runtimeType} ${funcionario.nombres} del sistema. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () {
              setState(() {
                db.usuarios.removeWhere((u) => u.rut == funcionario.rut);
              });
              Navigator.pop(ctx);
              CustomDialogs.showSnackBar(context, "Acceso revocado exitosamente.");
            },
            child: const Text("Eliminar Funcionario"),
          )
        ],
      ),
    );
  }

  void _mostrarFormularioFuncionario(var usuarioAEditar) {
    bool isEditing = usuarioAEditar != null;
    final formKey = GlobalKey<FormState>();
    
    final rutCtrl = TextEditingController(text: isEditing ? usuarioAEditar.rut : "");
    final nombresCtrl = TextEditingController(text: isEditing ? usuarioAEditar.nombres : "");
    final apellidosCtrl = TextEditingController(text: isEditing ? usuarioAEditar.apellidos : "");
    final correoCtrl = TextEditingController(text: isEditing ? usuarioAEditar.correo : "");
    final telefonoCtrl = TextEditingController(text: isEditing ? usuarioAEditar.telefono : "");
    
    String rolSeleccionado = isEditing ? usuarioAEditar.runtimeType.toString() : "Secretario";
    
    final deptoCtrl = TextEditingController(text: isEditing && usuarioAEditar is Administrador ? usuarioAEditar.departamento : "");
    final registroCtrl = TextEditingController(
      text: isEditing 
          ? (usuarioAEditar is Medico ? usuarioAEditar.registro : (usuarioAEditar is Enfermero ? usuarioAEditar.registro : ""))
          : ""
    );
    final especialidadCtrl = TextEditingController(text: isEditing && usuarioAEditar is Medico ? usuarioAEditar.especialidad : "");
    final unidadCtrl = TextEditingController(text: isEditing && usuarioAEditar is Enfermero ? usuarioAEditar.unidadAsignada : "");

    bool intentoGuardar = false;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: intentoGuardar ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
                          child: Icon(Icons.badge_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEditing ? "Editar Funcionario" : "Registrar Funcionario",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Gestión de credenciales y accesos",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: const InputDecoration(labelText: "Rol del Funcionario", prefixIcon: Icon(Icons.work_outline_rounded)),
                          items: ["Administrador", "Medico", "Enfermero", "Secretario"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: isEditing ? null : (val) => setStateDialog(() => rolSeleccionado = val!),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: rutCtrl,
                          decoration: const InputDecoration(labelText: "RUT", prefixIcon: Icon(Icons.pin_outlined)),
                          inputFormatters: [
                            RutFormatter(),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          validator: AppValidators.validarRut, 
                          enabled: !isEditing,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nombresCtrl,
                                decoration: const InputDecoration(labelText: "Nombres", prefixIcon: Icon(Icons.person_outline_rounded)),
                                validator: (v) => AppValidators.validarVacio(v, "Nombres"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: apellidosCtrl,
                                decoration: const InputDecoration(labelText: "Apellidos"),
                                validator: (v) => AppValidators.validarVacio(v, "Apellidos"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: correoCtrl,
                          decoration: const InputDecoration(labelText: "Correo Electrónico", prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress,
                          validator: AppValidators.validarCorreo, 
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telefonoCtrl,
                          decoration: const InputDecoration(labelText: "Teléfono", prefixIcon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.filtroTelefono,
                          validator: AppValidators.validarTelefono, 
                        ),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider()),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Información Específica", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ),
                        const SizedBox(height: 16),

                        if (rolSeleccionado == "Administrador") ...[
                          TextFormField(controller: deptoCtrl, decoration: const InputDecoration(labelText: "Departamento", prefixIcon: Icon(Icons.domain_rounded)), validator: (v) => AppValidators.validarVacio(v, "Departamento")),
                        ] else if (rolSeleccionado == "Secretario") ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: colorScheme.onSecondaryContainer, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text("El ID Operativo es gestionado por el sistema.", style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13))),
                              ],
                            ),
                          ),
                        ] else if (rolSeleccionado == "Medico" || rolSeleccionado == "Enfermero") ...[
                          TextFormField(controller: registroCtrl, decoration: const InputDecoration(labelText: "Registro RNPI", prefixIcon: Icon(Icons.verified_user_outlined)), validator: (v) => AppValidators.validarVacio(v, "Registro RNPI")),
                          const SizedBox(height: 16),
                          if (rolSeleccionado == "Medico")
                            TextFormField(controller: especialidadCtrl, decoration: const InputDecoration(labelText: "Especialidad", prefixIcon: Icon(Icons.medical_services_outlined)), validator: (v) => AppValidators.validarVacio(v, "Especialidad"))
                          else
                            TextFormField(controller: unidadCtrl, decoration: const InputDecoration(labelText: "Unidad Asignada", prefixIcon: Icon(Icons.local_hospital_outlined)), validator: (v) => AppValidators.validarVacio(v, "Unidad Asignada")),
                        ],
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: colorScheme.outlineVariant)),
                                child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                onPressed: () {
                                  setStateDialog(() {
                                    intentoGuardar = true;
                                  });
                                  if (formKey.currentState!.validate()) {
                                    
                                    rutCtrl.text = AppValidators.formatearRut(rutCtrl.text);

                                    if (isEditing) db.usuarios.removeWhere((u) => u.rut == usuarioAEditar.rut);

                                    var usuarioActualizado;
                                    if (rolSeleccionado == "Administrador") {
                                      usuarioActualizado = Administrador(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), departamento: deptoCtrl.text);
                                    } else if (rolSeleccionado == "Secretario") {
                                      usuarioActualizado = Secretario(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), idSecretario: isEditing ? (usuarioAEditar as Secretario).idSecretario : "SEC-${DateTime.now().millisecondsSinceEpoch}");
                                    } else if (rolSeleccionado == "Medico") {
                                      usuarioActualizado = Medico(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), registro: registroCtrl.text, especialidad: especialidadCtrl.text);
                                    } else if (rolSeleccionado == "Enfermero") {
                                      usuarioActualizado = Enfermero(rut: rutCtrl.text, nombres: nombresCtrl.text, apellidos: apellidosCtrl.text, correo: correoCtrl.text, telefono: telefonoCtrl.text, fechaNacimiento: DateTime(1990), registro: registroCtrl.text, unidadAsignada: unidadCtrl.text);
                                    }

                                    setState(() => db.usuarios.add(usuarioActualizado));
                                    Navigator.pop(context);
                                    CustomDialogs.showSnackBar(context, isEditing ? "Datos actualizados exitosamente" : "$rolSeleccionado registrado con éxito");
                                  }
                                },
                                child: Text(isEditing ? "Guardar" : "Registrar"),
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