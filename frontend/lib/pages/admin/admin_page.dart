import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_inicio_page.dart';
import 'admin_macroeventos_page.dart';
import 'admin_usuarios_page.dart';
import 'admin_folios_page.dart';
import 'admin_historial_xp_page.dart';
import 'admin_perfil_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, this.nombre = 'Administrador',
    this.correo = '', this.id = 'ADMIN-DEMO', this.onLogout});
  final String nombre, correo, id;
  /// Conectar aquí limpieza de JWT/Google y navegación al login del proyecto.
  final Future<void> Function()? onLogout;
  @override
  Widget build(BuildContext context) => Theme(data: AdminStyle.theme,
    child: _AdminShell(nombre: nombre, correo: correo, id: id, onLogout: onLogout));
}
class _AdminShell extends StatefulWidget {
  const _AdminShell({required this.nombre, required this.correo, required this.id, this.onLogout});
  final String nombre, correo, id;
  final Future<void> Function()? onLogout;
  @override
  State<_AdminShell> createState() => _AdminPageState();
}
class _AdminPageState extends State<_AdminShell> {
  late final AdminStore store;
  int selected = 0;
  bool loggingOut = false;
  static const labels = ['Inicio', 'Macro eventos', 'Usuarios',
    'Verificar folios', 'Historial XP', 'Mi perfil'];
  static const icons = [Icons.home_outlined, Icons.event_outlined,
    Icons.people_outline, Icons.verified_user_outlined,
    Icons.bar_chart_rounded, Icons.person_outline];
  @override
  void initState() {
    super.initState();
    store = AdminStore(adminName: widget.nombre, adminEmail: widget.correo,
      adminId: widget.id);
  }
  @override
  void dispose() { store.dispose(); super.dispose(); }
  void navigate(int index) => setState(() => selected = index);
  Future<void> logout() async {
    if (loggingOut || widget.onLogout == null) return;
    setState(() => loggingOut = true);
    try { await widget.onLogout!(); }
    catch (_) { if (mounted) adminMessage(context, 'No se pudo cerrar la sesión.'); }
    finally { if (mounted) setState(() => loggingOut = false); }
  }
  @override
  Widget build(BuildContext context) => Theme(data: AdminStyle.theme,
    child: AnimatedBuilder(animation: store, builder: (context, _) {
      return LayoutBuilder(builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        final compact = constraints.maxWidth < 1150;
        return Scaffold(
          appBar: mobile ? AppBar(title: const Text('Comunidad UNIX ITC'),
            actions: [profileMenu()]) : null,
          drawer: mobile ? Drawer(backgroundColor: AdminStyle.surface,
            child: sidebar(false, closeDrawer: true)) : null,
          body: SafeArea(child: Row(children: [
            if (!mobile) SizedBox(width: compact ? 82 : 226,
              child: sidebar(compact)),
            Expanded(child: Column(children: [
              if (!mobile) Container(height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: AdminStyle.surface,
                child: Row(children: [const Expanded(child: Text(
                  'Comunidad UNIX ITC', style: TextStyle(fontWeight: FontWeight.bold))),
                  Flexible(child: Text(store.adminName, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8), profileMenu()])),
              Expanded(child: SingleChildScrollView(
                padding: EdgeInsets.all(mobile ? 16 : 26),
                child: Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(selected == 0 ? 'Panel de administración' : labels[selected],
                      style: TextStyle(fontSize: mobile ? 25 : 30,
                        fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Demostración local · Los cambios no se guardan en el servidor',
                        style: TextStyle(color: AdminStyle.muted, fontSize: 12)),
                      const SizedBox(height: 24),
                      // Mantiene el estado de búsqueda y filtros al cambiar de sección.
                      Column(children: [
                        for (final entry in <Widget>[
                        AdminInicioPage(store: store, onNavigate: navigate),
                        AdminMacroeventosPage(store: store),
                        AdminUsuariosPage(store: store),
                        AdminFoliosPage(store: store),
                        AdminHistorialXpPage(store: store),
                        AdminPerfilPage(store: store, onLogout: widget.onLogout == null
                          ? null : logout, loggingOut: loggingOut),
                        ].asMap().entries) Visibility(
                          visible: entry.key == selected, maintainState: true,
                          child: entry.value),
                      ]),
                    ]))),
              )),
            ])),
          ])),
          bottomNavigationBar: mobile ? NavigationBar(
            backgroundColor: AdminStyle.surface,
            selectedIndex: selected <= 2 ? selected : 3,
            onDestinationSelected: (index) {
              if (index < 3) { navigate(index); } else { showMore(); }
            }, destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Eventos'),
              NavigationDestination(icon: Icon(Icons.people_outline), label: 'Usuarios'),
              NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
            ]) : null,
        );
      });
    }));
  Widget profileMenu() => PopupMenuButton<int>(
    tooltip: 'Opciones de cuenta',
    icon: const Icon(Icons.keyboard_arrow_down_rounded),
    onSelected: (value) { if (value == 0) { navigate(5); } else { logout(); } },
    itemBuilder: (_) => [const PopupMenuItem(value: 0, child: Text('Mi perfil')),
      PopupMenuItem(value: 1, enabled: widget.onLogout != null && !loggingOut,
        child: Text(loggingOut ? 'Cerrando sesión…' : 'Cerrar sesión'))]);
  Widget sidebar(bool compact, {bool closeDrawer = false}) => Container(
    color: AdminStyle.surface,
    child: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: compact ? const Icon(Icons.terminal, color: AdminStyle.orange, size: 32)
          : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('UNIX ITC', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              SizedBox(height: 8), AdminBadge('Super Admin', color: AdminStyle.green)])),
      Expanded(child: ListView.builder(itemCount: labels.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Tooltip(message: labels[index], child: ListTile(
            selected: index == selected,
            selectedColor: AdminStyle.orange,
            selectedTileColor: AdminStyle.orange.withAlpha(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(icons[index]), title: compact ? null : Text(labels[index]),
            onTap: () { navigate(index); if (closeDrawer) Navigator.of(context).pop(); },
          ))))),
    ])));
  void showMore() {
    showModalBottomSheet<void>(context: context,
      backgroundColor: AdminStyle.surface, builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final index in [3, 4, 5]) ListTile(leading: Icon(icons[index]),
            title: Text(labels[index]), onTap: () {
              Navigator.pop(sheet); navigate(index);
            }),
        ])));
  }
}
