import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import '../models/usuarios/administrador.dart';
import '../widgets/header_actions.dart';


import 'admin_tabs/tab_campanas.dart';
import 'admin_tabs/tab_inventario.dart';
import 'admin_tabs/tab_personal.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = MockDatabase();

  @override
  Widget build(BuildContext context) {
    if (db.usuarioActivo == null) {
      Future.microtask(() => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false));
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
    
    var admin = db.usuarioActivo as Administrador;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ENCABEZADO GLOBAL
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hola, ${admin.nombres} 👋",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "Panel de Administración • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                HeaderActions(onLogout: widget.onLogout, usuarioActivo: db.usuarioActivo!),
              ],
            ),
          ),

          // CUERPO PRINCIPAL CON TABS DESACOPLADOS
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.campaign_rounded), text: "Gestión de Campañas"),
                          Tab(icon: Icon(Icons.local_shipping_rounded), text: "Inventario por Sede"),
                          Tab(icon: Icon(Icons.badge_rounded), text: "Gestión de Personal"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          TabCampanas(admin: admin),
                          const TabInventarioSedes(),
                          const TabPersonal(), 
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}