import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const ComunidadUnixApp());

class AppColors {
  static const background = Color(0xFF050D1A);
  static const surface = Color(0xFF0A1628);
  static const card = Color(0xFF0F2040);
  static const cardHover = Color(0xFF162A52);
  static const border = Color(0xFF1E3A6E);
  static const orange = Color(0xFFF97316);
  static const orangeDark = Color(0xFFEA580C);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF3B82F6);
  static const text = Color(0xFFF1F5F9);
  static const textSoft = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
}

class ComunidadUnixApp extends StatelessWidget {
  const ComunidadUnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comunidad Unix ITC',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          secondary: AppColors.purple,
          surface: AppColors.surface,
        ),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141D35),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          labelStyle: const TextStyle(color: AppColors.textSoft),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.orange),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

enum AuthMode { login, register }
enum UserRole { alumno, instructor, externo }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode mode = AuthMode.login;
  UserRole role = UserRole.alumno;
  final formKey = GlobalKey<FormState>();

  void openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Row(
            children: [
              Expanded(
                flex: wide ? 64 : 100,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF19062E), AppColors.background, Color(0xFF07162E)],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 24, vertical: 30),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('InnovaciónTucán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 30),
                                Text(
                                  mode == AuthMode.login ? 'Bienvenido a Comunidad Unix ITC' : 'Crea tu cuenta',
                                  style: TextStyle(fontSize: wide ? 31 : 25, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mode == AuthMode.login ? 'Inicia sesión para continuar aprendiendo.' : 'Únete y comienza a aprender.',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 28),
                                _ModeTabs(mode: mode, onChanged: (value) => setState(() => mode = value)),
                                if (mode == AuthMode.register) ...[
                                  const SizedBox(height: 26),
                                  const Text('Selecciona tu tipo de registro', style: TextStyle(color: AppColors.textSoft, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  _RoleSelector(value: role, onChanged: (value) => setState(() => role = value)),
                                  const SizedBox(height: 22),
                                  const _Field(label: 'Nombre completo *', hint: 'Tu nombre completo', icon: Icons.person_outline),
                                  const SizedBox(height: 14),
                                  _Field(
                                    label: role == UserRole.externo ? 'Organización *' : 'ID / número de control *',
                                    hint: role == UserRole.externo ? 'Nombre de tu organización' : 'Ej. 21040123',
                                    icon: role == UserRole.externo ? Icons.business_outlined : Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 14),
                                  const _Field(label: 'Procedencia / Institución *', hint: 'Escribe tu institución', icon: Icons.school_outlined),
                                ],
                                const SizedBox(height: 18),
                                _PrimaryButton(
                                  text: mode == AuthMode.login ? 'Iniciar sesión con Google' : 'Registrarse con Google',
                                  onPressed: openDashboard,
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => mode = mode == AuthMode.login ? AuthMode.register : AuthMode.login),
                                    child: Text.rich(
                                      TextSpan(
                                        text: mode == AuthMode.login ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
                                        style: const TextStyle(color: AppColors.textMuted),
                                        children: [
                                          TextSpan(
                                            text: mode == AuthMode.login ? 'Regístrate' : 'Inicia sesión',
                                            style: const TextStyle(color: AppColors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (wide) const Expanded(flex: 36, child: _MascotPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFF171C36), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: AuthMode.values.map((item) {
          final active = mode == item;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: active ? const LinearGradient(colors: [Color(0xFF713D45), Color(0xFF4C2D78)]) : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(item == AuthMode.login ? 'Iniciar sesión' : 'Registrarse', style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? Colors.white : AppColors.textMuted)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});
  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    const data = {
      UserRole.alumno: (Icons.school_outlined, 'Alumno'),
      UserRole.instructor: (Icons.co_present_outlined, 'Instructor'),
      UserRole.externo: (Icons.groups_outlined, 'Externo'),
    };
    return Row(
      children: UserRole.values.map((item) {
        final active = value == item;
        final itemData = data[item]!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: item == UserRole.externo ? 0 : 8),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF3A183E) : const Color(0xFF151B33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? AppColors.orange : const Color(0xFF343854)),
                ),
                child: Column(children: [Icon(itemData.$1, color: active ? Colors.white : AppColors.textSoft), const SizedBox(height: 8), Text(itemData.$2, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppColors.textSoft))]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, required this.icon});
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSoft, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 19)),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF7A12), Color(0xFFF4510B)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x55F97316), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 28),
          label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _MascotPanel extends StatelessWidget {
  const _MascotPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF121840), Color(0xFF1F2D79)]),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Penguin(size: 210),
          SizedBox(height: 24),
          Text('¡Hola! Soy Lexus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Tu compañero de confianza en Linux.', style: TextStyle(color: AppColors.textSoft)),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.role});
  final UserRole role;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selected = 0;
  final labels = const ['Inicio', 'Mis cursos', 'Explorar cursos', 'Eventos', 'Constancias', 'Mi perfil'];
  final icons = const [Icons.home_outlined, Icons.menu_book_outlined, Icons.explore_outlined, Icons.calendar_month_outlined, Icons.workspace_premium_outlined, Icons.person_outline];

  String get roleLabel => widget.role == UserRole.externo ? 'Externo' : widget.role == UserRole.instructor ? 'Instructor' : 'Alumno';

  void logout() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  Widget _currentPage() {
    switch (selected) {
      case 0:
        return _DashboardHome(onNavigate: (index) => setState(() => selected = index));
      case 1:
        return const _MyCoursesPage();
      case 2:
        return const _ExplorePage();
      case 3:
        return const _EventsPage();
      case 4:
        return const _CertificatesPage();
      case 5:
        return _ProfilePage(role: roleLabel);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MediaQuery.sizeOf(context).width < 950 ? Drawer(backgroundColor: AppColors.surface, child: _Navigation(selected: selected, labels: labels, icons: icons, onSelected: (i) { setState(() => selected = i); Navigator.pop(context); }, onLogout: logout)) : null,
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 950)
            SizedBox(width: 240, child: _Navigation(selected: selected, labels: labels, icons: icons, onSelected: (i) => setState(() => selected = i), onLogout: logout)),
          Expanded(
            child: Column(
              children: [
                Builder(builder: (context) => _TopBar(role: roleLabel, showMenu: MediaQuery.sizeOf(context).width < 950, onMenu: () => Scaffold.of(context).openDrawer())),
                Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(selected), child: _currentPage()))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({required this.selected, required this.labels, required this.icons, required this.onSelected, required this.onLogout});
  final int selected;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(backgroundColor: AppColors.border, child: Icon(Icons.code, color: AppColors.orange)),
              title: Text('COMUNIDAD', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              subtitle: Text('Unix ITC', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
            ),
            const Divider(color: AppColors.border),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: labels.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    selected: selected == i,
                    selectedTileColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(icons[i], size: 20, color: selected == i ? Colors.white : AppColors.textSoft),
                    title: Text(labels[i], style: TextStyle(fontSize: 14, color: selected == i ? Colors.white : AppColors.textSoft, fontWeight: selected == i ? FontWeight.w700 : FontWeight.w400)),
                    onTap: () => onSelected(i),
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.border),
            ListTile(leading: const Icon(Icons.logout, color: AppColors.textSoft), title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.textSoft, fontSize: 14)), onTap: onLogout),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.role, required this.showMenu, required this.onMenu});
  final String role;
  final bool showMenu;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          if (showMenu) IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bienvenido, Juan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                if (MediaQuery.sizeOf(context).width > 650) const Text('Continúa aprendiendo y descubre nuevas actividades de la comunidad.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Stack(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.textSoft)), const Positioned(right: 10, top: 10, child: CircleAvatar(radius: 4, backgroundColor: AppColors.orange))]),
          const SizedBox(width: 10),
          const CircleAvatar(backgroundColor: AppColors.purple, child: Text('J', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 9),
          if (MediaQuery.sizeOf(context).width > 520) Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Juan', style: TextStyle(fontWeight: FontWeight.w700)), Text(role, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))]),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      return SingleChildScrollView(
        padding: EdgeInsets.all(desktop ? 30 : 18),
        child: Column(
          children: [
            const _StatsRow(),
            const SizedBox(height: 20),
            if (desktop)
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: _FeaturedCourse()), SizedBox(width: 18), Expanded(child: Column(children: [_EventCard(), SizedBox(height: 16), _LexusCard()]))])
            else
              const Column(children: [_FeaturedCourse(), SizedBox(height: 16), _EventCard(), SizedBox(height: 16), _LexusCard()]),
            const SizedBox(height: 28),
            Row(children: [const Expanded(child: Text('Mis cursos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), TextButton(onPressed: () => onNavigate(1), child: const Text('Ver todos'))]),
            const SizedBox(height: 12),
            const _CourseGrid(),
          ],
        ),
      );
    });
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 620;
    if (narrow) {
      return const Column(
        children: [
          _StatCard(value: '3', label: 'Cursos activos', color: AppColors.orange),
          SizedBox(height: 10),
          _StatCard(value: '1', label: 'Cursos completados', color: AppColors.purple),
          SizedBox(height: 10),
          _StatCard(value: '1', label: 'Constancias obtenidas', color: AppColors.blue),
        ],
      );
    }
    return const Row(
      children: [
        Expanded(child: _StatCard(value: '3', label: 'Cursos activos', color: AppColors.orange)),
        SizedBox(width: 14),
        Expanded(child: _StatCard(value: '1', label: 'Cursos completados', color: AppColors.purple)),
        SizedBox(width: 14),
        Expanded(child: _StatCard(value: '1', label: 'Constancias obtenidas', color: AppColors.blue)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: _cardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)), const SizedBox(height: 5), Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))]));
}

class _FeaturedCourse extends StatelessWidget {
  const _FeaturedCourse();
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 335),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.card, AppColors.cardHover, Color(0xFF1E1B4B)]), border: Border.all(color: const Color(0xFF2E3A6E)), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0x22F97316), borderRadius: BorderRadius.circular(20)), child: const Text('Continúa aprendiendo', style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(height: 18),
        const Text('Linux desde cero', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Domina los fundamentos de Linux, la terminal y los comandos esenciales.', style: TextStyle(color: AppColors.textSoft, height: 1.5)),
        const SizedBox(height: 28),
        const Row(children: [Expanded(child: Text('Progreso del curso', style: TextStyle(color: AppColors.textMuted))), Text('70%', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 9),
        const LinearProgressIndicator(value: .7, minHeight: 8, borderRadius: BorderRadius.all(Radius.circular(8)), backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(AppColors.orange)),
        const SizedBox(height: 28),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_forward, size: 17), label: const Text('Continuar curso'), style: FilledButton.styleFrom(backgroundColor: AppColors.orange, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: _cardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.calendar_month_outlined, color: AppColors.purple), SizedBox(width: 9), Text('PRÓXIMO EVENTO', style: TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1))]), const SizedBox(height: 16), const Text('Taller de Git y GitHub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 12), const Text('25 de septiembre — 4:00 PM', style: TextStyle(color: AppColors.textMuted, fontSize: 13)), const SizedBox(height: 6), const Text('Modalidad: Presencial', style: TextStyle(color: AppColors.textMuted, fontSize: 13)), const SizedBox(height: 16), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFA78BFA), side: const BorderSide(color: AppColors.purple)), child: const Text('Ver evento')))]));
}

class _LexusCard extends StatelessWidget {
  const _LexusCard();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: _cardDecoration(), child: const Row(children: [Penguin(size: 82), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Lexus', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Tu compañero de aprendizaje en Linux.', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Completa tus cursos y sigue avanzando.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))]))]));
}

class _CourseGrid extends StatelessWidget {
  const _CourseGrid();
  @override
  Widget build(BuildContext context) {
    const data = [('Linux desde cero', 'Linux', .70, AppColors.orange, Icons.terminal), ('Introducción a redes', 'Redes', .40, AppColors.purple, Icons.hub_outlined), ('Fundamentos de ciberseguridad', 'Seguridad', .20, AppColors.blue, Icons.shield_outlined)];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850 ? 3 : constraints.maxWidth >= 520 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(spacing: 14, runSpacing: 14, children: data.map((c) => SizedBox(width: width, child: _CourseCard(name: c.$1, category: c.$2, progress: c.$3, color: c.$4, icon: c.$5))).toList());
    });
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.name, required this.category, required this.progress, required this.color, required this.icon});
  final String name;
  final String category;
  final double progress;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: _cardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CircleAvatar(backgroundColor: color.withValues(alpha: .14), child: Icon(icon, color: color, size: 19)), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(16)), child: Text(category, style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11)))]), const SizedBox(height: 18), Text(name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 12), LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: const BorderRadius.all(Radius.circular(8)), backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(color)), const SizedBox(height: 6), Align(alignment: Alignment.centerRight, child: Text('${(progress * 100).round()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))), const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: .45))), child: const Text('Continuar')))]));
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.title, required this.subtitle, required this.child, this.action});
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 900 ? 30 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.hint = 'Buscar...'});
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ),
      );
}

class _MyCoursesPage extends StatelessWidget {
  const _MyCoursesPage();
  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: 'Mis cursos',
      subtitle: 'Retoma tus clases y revisa tu avance general.',
      action: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.explore_outlined), label: const Text('Explorar cursos')),
      child: Column(
        children: [
          const _SearchBar(hint: 'Buscar en mis cursos'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF13264A), Color(0xFF1E1B4B)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 27, backgroundColor: Color(0x22F97316), child: Icon(Icons.auto_graph, color: AppColors.orange)),
                SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tu progreso semanal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Completaste 4 lecciones. Mantén el ritmo para alcanzar tu meta.', style: TextStyle(color: AppColors.textSoft))])),
                Text('4/6', style: TextStyle(color: AppColors.orange, fontSize: 25, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _CourseGrid(),
        ],
      ),
    );
  }
}

class _ExplorePage extends StatefulWidget {
  const _ExplorePage();
  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  int filter = 0;
  final filters = const ['Todos', 'Linux', 'Redes', 'Seguridad'];
  @override
  Widget build(BuildContext context) {
    final catalog = [
      ('Administración de Linux', 'Linux', 'Intermedio', Icons.terminal, AppColors.orange),
      ('Redes para principiantes', 'Redes', 'Básico', Icons.hub_outlined, AppColors.purple),
      ('Seguridad en servidores', 'Seguridad', 'Avanzado', Icons.security_outlined, AppColors.blue),
      ('Git y trabajo colaborativo', 'Linux', 'Básico', Icons.account_tree_outlined, const Color(0xFF22C55E)),
    ].where((item) => filter == 0 || item.$2 == filters[filter]).toList();
    return _PageShell(
      title: 'Explorar cursos',
      subtitle: 'Descubre nuevas rutas de aprendizaje creadas por la comunidad.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SearchBar(hint: 'Buscar por tema, nivel o categoría'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(filters.length, (i) => ChoiceChip(label: Text(filters[i]), selected: filter == i, onSelected: (_) => setState(() => filter = i), selectedColor: AppColors.orange, backgroundColor: AppColors.card, side: const BorderSide(color: AppColors.border))),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850 ? 3 : constraints.maxWidth >= 540 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: catalog.map((item) => SizedBox(width: width, child: _CatalogCard(name: item.$1, category: item.$2, level: item.$3, icon: item.$4, color: item.$5))).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.name, required this.category, required this.level, required this.icon, required this.color});
  final String name;
  final String category;
  final String level;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CircleAvatar(backgroundColor: color.withValues(alpha: .15), child: Icon(icon, color: color)), const Icon(Icons.bookmark_border, color: AppColors.textMuted)]),
            const SizedBox(height: 24),
            Text(category.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 7),
            Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Nivel $level · 8 módulos', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: color), child: const Text('Ver curso'))),
          ],
        ),
      );
}

class _EventsPage extends StatelessWidget {
  const _EventsPage();
  @override
  Widget build(BuildContext context) {
    const events = [
      ('25 SEP', 'Taller de Git y GitHub', '4:00 PM', 'Presencial', AppColors.purple),
      ('02 OCT', 'Linux Install Fest', '10:00 AM', 'Presencial', AppColors.orange),
      ('10 OCT', 'Introducción a la ciberseguridad', '6:00 PM', 'En línea', AppColors.blue),
    ];
    return _PageShell(
      title: 'Eventos',
      subtitle: 'Participa en talleres, conferencias y actividades de la comunidad.',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF182650), Color(0xFF31205C)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
            child: const Row(children: [Icon(Icons.celebration_outlined, size: 42, color: AppColors.orange), SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Próxima actividad destacada', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Taller de Git y GitHub', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Aprende a colaborar, crear ramas y administrar tus proyectos.', style: TextStyle(color: AppColors.textSoft))]))]),
          ),
          const SizedBox(height: 20),
          ...events.map((event) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _EventListItem(date: event.$1, name: event.$2, time: event.$3, mode: event.$4, color: event.$5))),
        ],
      ),
    );
  }
}

class _EventListItem extends StatelessWidget {
  const _EventListItem({required this.date, required this.name, required this.time, required this.mode, required this.color});
  final String date;
  final String name;
  final String time;
  final String mode;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(children: [Container(width: 66, padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(date, style: TextStyle(color: color, fontWeight: FontWeight.w800))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('$time · $mode', style: const TextStyle(color: AppColors.textMuted))])), OutlinedButton(onPressed: () {}, child: const Text('Ver detalles'))]),
      );
}

class _CertificatesPage extends StatelessWidget {
  const _CertificatesPage();
  @override
  Widget build(BuildContext context) => _PageShell(
        title: 'Constancias',
        subtitle: 'Consulta y descarga los reconocimientos que has obtenido.',
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF102B50), Color(0xFF17204B)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
              child: Row(children: [const CircleAvatar(radius: 31, backgroundColor: Color(0x223B82F6), child: Icon(Icons.workspace_premium_outlined, color: AppColors.blue, size: 32)), const SizedBox(width: 18), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Introducción a Linux', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Emitida el 18 de septiembre de 2026 · Folio: UNIX-2026-001', style: TextStyle(color: AppColors.textMuted))])), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Descargar PDF'))]),
            ),
            const SizedBox(height: 22),
            Container(width: double.infinity, padding: const EdgeInsets.all(26), decoration: _cardDecoration(), child: const Column(children: [Icon(Icons.verified_outlined, size: 45, color: AppColors.purple), SizedBox(height: 12), Text('Sigue completando cursos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Tus nuevas constancias aparecerán aquí automáticamente.', style: TextStyle(color: AppColors.textMuted))])),
          ],
        ),
      );
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.role});
  final String role;
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  bool editing = false;
  @override
  Widget build(BuildContext context) => _PageShell(
        title: 'Mi perfil',
        subtitle: 'Administra tus datos personales y preferencias de cuenta.',
        action: FilledButton.icon(onPressed: () => setState(() => editing = !editing), icon: Icon(editing ? Icons.save_outlined : Icons.edit_outlined), label: Text(editing ? 'Guardar cambios' : 'Editar perfil')),
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final profile = Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(children: [const CircleAvatar(radius: 48, backgroundColor: AppColors.purple, child: Text('J', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800))), const SizedBox(height: 14), const Text('Juan Izquierdo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(widget.role, style: const TextStyle(color: AppColors.orange)), const SizedBox(height: 20), const Divider(color: AppColors.border), const SizedBox(height: 12), const Row(children: [Icon(Icons.verified_user_outlined, color: AppColors.blue), SizedBox(width: 10), Expanded(child: Text('Cuenta verificada'))])]),
          );
          final form = Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Información personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 20), TextFormField(initialValue: 'Juan Izquierdo', enabled: editing, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 14), TextFormField(initialValue: 'juan@comunidad.edu.mx', enabled: false, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined))), const SizedBox(height: 14), TextFormField(initialValue: widget.role == 'Externo' ? 'Organización externa' : 'Instituto Tecnológico de Cancún', enabled: editing, decoration: const InputDecoration(labelText: 'Institución', prefixIcon: Icon(Icons.school_outlined)))]),
          );
          return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 280, child: profile), const SizedBox(width: 18), Expanded(child: form)]) : Column(children: [profile, const SizedBox(height: 18), form]);
        }),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14));

class Penguin extends StatefulWidget {
  const Penguin({super.key, this.size = 120});
  final double size;

  @override
  State<Penguin> createState() => _PenguinState();
}

class _PenguinState extends State<Penguin> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool hovered = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final phase = controller.value * math.pi * 2;
          final floatOffset = math.sin(phase) * widget.size * .035;
          final blinkCycle = controller.value;
          final blink = blinkCycle > .46 && blinkCycle < .49 ? 1.0 : 0.0;
          final wing = math.sin(phase * 2) * (hovered ? .55 : .10);
          final tilt = hovered ? math.sin(phase * 1.5) * .035 : math.sin(phase) * .012;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: tilt,
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.2,
                child: CustomPaint(painter: _PenguinPainter(blink: blink, wing: wing, hovered: hovered)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PenguinPainter extends CustomPainter {
  const _PenguinPainter({required this.blink, required this.wing, required this.hovered});
  final double blink;
  final double wing;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 120;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final navy = Paint()..color = const Color(0xFF0F2040);
    final belly = Paint()..color = const Color(0xFFE2E8F0);
    final orange = Paint()..color = AppColors.orange;
    canvas.drawOval(Rect.fromCenter(center: p(50, 76), width: 56 * sx, height: 70 * sy), navy);
    canvas.save();
    canvas.translate(30 * sx, 62 * sy);
    canvas.rotate(-.20 - wing);
    canvas.drawOval(Rect.fromCenter(center: Offset(-5 * sx, 14 * sy), width: 18 * sx, height: 42 * sy), navy);
    canvas.restore();
    canvas.save();
    canvas.translate(70 * sx, 62 * sy);
    canvas.rotate(.20 + wing);
    canvas.drawOval(Rect.fromCenter(center: Offset(5 * sx, 14 * sy), width: 18 * sx, height: 42 * sy), navy);
    canvas.restore();
    canvas.drawOval(Rect.fromCenter(center: p(50, 81), width: 31 * sx, height: 45 * sy), belly);
    canvas.drawCircle(p(50, 38), 23 * sx, navy);
    canvas.drawOval(Rect.fromCenter(center: p(50, 42), width: 31 * sx, height: 27 * sy), belly);
    for (final x in [44.0, 56.0]) {
      final eyeHeight = (1 - blink * .88) * 8.4 * sy;
      canvas.drawOval(Rect.fromCenter(center: p(x, 37), width: 8.4 * sx, height: eyeHeight), Paint()..color = Colors.white);
      if (blink < .6) {
        canvas.drawCircle(p(x + 1, 37), 2.1 * sx, Paint()..color = Colors.black);
        canvas.drawCircle(p(x + 1.7, 36.3), .7 * sx, Paint()..color = Colors.white);
      }
    }
    final beak = Path()..moveTo(44 * sx, 46 * sy)..lineTo(56 * sx, 46 * sy)..lineTo(50 * sx, 52 * sy)..close();
    canvas.drawPath(beak, orange);
    canvas.drawOval(Rect.fromCenter(center: p(41, 108), width: 19 * sx, height: 8 * sy), orange);
    canvas.drawOval(Rect.fromCenter(center: p(59, 108), width: 19 * sx, height: 8 * sy), orange);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(31 * sx, 14 * sy, 38 * sx, 6 * sy), Radius.circular(2 * sx)), Paint()..color = AppColors.purple);
    canvas.drawLine(p(50, 15), p(50, 8), Paint()..color = AppColors.purple..strokeWidth = 2 * sx);
    canvas.drawCircle(p(50, 8), 3 * sx, orange);
    if (hovered) {
      final sparkle = Paint()..color = const Color(0xFFFFD166);
      canvas.drawCircle(p(82, 24), 2.2 * sx, sparkle);
      canvas.drawCircle(p(88, 33), 1.3 * sx, sparkle);
      canvas.drawCircle(p(76, 17), 1.1 * sx, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _PenguinPainter oldDelegate) =>
      oldDelegate.blink != blink || oldDelegate.wing != wing || oldDelegate.hovered != hovered;
}
