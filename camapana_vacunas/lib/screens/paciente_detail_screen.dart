import 'package:flutter/material.dart';
import '../models/usuarios/paciente.dart';
import '../models/transacciones/cita_vacunacion.dart';
import '../services/mock_database.dart';
import '../utils/date_formatter.dart';

class PacienteDetailScreen extends StatelessWidget {
  final Paciente paciente;
  final db = MockDatabase();

  PacienteDetailScreen({super.key, required this.paciente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${paciente.nombres} ${paciente.apellidos}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
      ),
    );
  }
}