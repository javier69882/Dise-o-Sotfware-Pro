import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../routes/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final db = MockDatabase();

  @override
  void initState() {
    super.initState();
    if (db.usuarios.isEmpty) db.inicializarDatos();
  }

  void _ingresarConPerfil(dynamic usuario) {
    db.usuarioActivo = usuario;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Vacunación - Bienvenida"),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                "Selecciona un perfil para ingresar",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: db.usuarios.length,
                  itemBuilder: (context, index) {
                    var u = db.usuarios[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text("${u.nombres} ${u.apellidos}"),
                        subtitle: Text("Rol: ${u.runtimeType}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _ingresarConPerfil(u),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createProfile)
                      .then((_) => setState(() {})); // Refresca la lista al volver
                },
                icon: const Icon(Icons.person_add),
                label: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Crear Nuevo Perfil", style: TextStyle(fontSize: 16)),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}