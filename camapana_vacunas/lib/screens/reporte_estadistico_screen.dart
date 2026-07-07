import 'package:flutter/material.dart';
import '../models/campanas/campana.dart';

class ReporteEstadisticoScreen extends StatelessWidget {
  final Campana campana;

  const ReporteEstadisticoScreen({super.key, required this.campana});

  @override
  Widget build(BuildContext context) {
    // Usamos los nuevos métodos de la clase Campana
    int totalVacunados = campana.calcularVacunadosTotales();
    int poblacionTotal = campana.calcularPoblacionTotal();
    double avance = poblacionTotal > 0 ? (totalVacunados / poblacionTotal) * 100 : 0.0;
    
    // Obtenemos el mapa de efectos que ya tenías programado
    Map<String, int> efectos = campana.generarReporteEfectos();

    return Scaffold(
      appBar: AppBar(title: Text("Reporte: ${campana.nombre}")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // Sección de Avance
            Card(
              child: ListTile(
                leading: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                title: Text("Avance de Campaña: ${avance.toStringAsFixed(1)}%"),
                subtitle: Text("Total vacunados: $totalVacunados de $poblacionTotal personas"),
              ),
            ),
            const SizedBox(height: 32),
            
            // Sección de Efectos Adversos
            Text("Estadísticas de Efectos Adversos", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...efectos.entries.map((entry) => Card(
              child: ListTile(
                title: Text(entry.key),
                trailing: Text("${entry.value} casos", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}