import 'package:flutter/foundation.dart';

enum ActivityStatus { recruiting, draft, published }
extension ActivityStatusLabel on ActivityStatus {
  String get label => switch (this) {
    ActivityStatus.recruiting => 'Reclutando',
    ActivityStatus.draft => 'Borrador',
    ActivityStatus.published => 'Publicado',
  };
}
class AdminUser {
  AdminUser(this.id, this.name, this.email, this.role, {this.active = true});
  final String id;
  final String name;
  final String email;
  final String role;
  bool active;
}
class Candidate {
  const Candidate(this.userId, this.reason);
  final String userId;
  final String reason;
}
class EventActivity {
  EventActivity({required this.id, required this.title, required this.type,
    required this.status, this.date = 'Por definir', this.time = 'Por definir',
    this.room = 'Por definir', this.capacity = 30, this.enrolled = 0,
    this.speakerId, this.candidates = const []});
  final String id;
  String title;
  final String type;
  ActivityStatus status;
  String date;
  String time;
  String room;
  int capacity;
  final int enrolled;
  String? speakerId;
  final List<Candidate> candidates;
}
class MacroEvent {
  MacroEvent(this.id, this.title, this.date, this.activities);
  final String id;
  final String title;
  final String date;
  final List<EventActivity> activities;
}
class DemoFolio {
  const DemoFolio(this.code, this.userId, this.activity, this.kind,
    {this.expositions = 0});
  final String code;
  final String userId;
  final String activity;
  final String kind;
  final int expositions;
}
class XpEntry {
  const XpEntry(this.id, this.userId, this.reason, this.points, this.date);
  final String id;
  final String userId;
  final String reason;
  final int points;
  final String date;
}

/// Estado LOCAL de demostración. Sustituir por un repositorio HTTP autenticado.
/// No persiste tras cerrar la pantalla ni implementa permisos del servidor.
class AdminStore extends ChangeNotifier {
  AdminStore({this.adminName = 'Administrador', this.adminEmail = '',
    this.adminId = 'ADMIN-DEMO'});
  String adminName;
  final String adminEmail;
  final String adminId;
  final List<AdminUser> _users = [
    AdminUser('21530369', 'Ana López', 'ana@example.com', 'Alumno'),
    AdminUser('21530412', 'Carlos Ruiz', 'carlos@example.com', 'Alumno'),
    AdminUser('21530421', 'María González', 'maria@example.com', 'Alumno'),
    AdminUser('PROF-01', 'Luis Pérez', 'luis@example.com', 'Maestro'),
    AdminUser('EXT-01', 'Sofía Torres', 'sofia@example.com', 'Externo'),
  ];
  final List<MacroEvent> _macros = [MacroEvent('macro-1',
    'Semana de Ingeniería', '26–30 OCT 2026', [
      EventActivity(id: 'act-1', title: 'Introducción a Linux',
        type: 'Exposición', status: ActivityStatus.recruiting,
        date: '27 OCT 2026', time: '10:00–12:00', room: 'A101',
        candidates: const [
          Candidate('21530369', 'Quiero compartir los comandos básicos de Linux.'),
          Candidate('21530412', 'Tengo experiencia con terminal y software libre.'),
          Candidate('21530421', 'Me interesa apoyar a compañeros principiantes.'),
        ]),
      EventActivity(id: 'act-2', title: 'Git desde cero', type: 'Taller',
        status: ActivityStatus.draft, date: '28 OCT 2026', time: '11:00–13:00',
        room: 'Laboratorio 2', speakerId: 'PROF-01'),
      EventActivity(id: 'act-3', title: 'Fundamentos de Python', type: 'Curso',
        status: ActivityStatus.published, capacity: 40, enrolled: 18),
    ])];
  final List<DemoFolio> _folios = const [
    DemoFolio('UNIX-21530369-X9Y2A', '21530369', 'Introducción a Linux',
      'Actividad acreditada'),
    DemoFolio('UNIX-21530369-C5EXP', '21530369', 'Cinco exposiciones verificadas',
      'Candidato a liberación de crédito', expositions: 5),
  ];
  final List<XpEntry> _ledger = const [
    XpEntry('XP-001', '21530369', 'Participación en macro evento', 5, '20 OCT 2026'),
    XpEntry('XP-002', '21530412', 'Asistencia a taller', 15, '20 OCT 2026'),
    XpEntry('XP-003', '21530412', 'Ausencia registrada', -5, '21 OCT 2026'),
  ];
  List<AdminUser> get users => List.unmodifiable(_users);
  List<MacroEvent> get macros => List.unmodifiable(_macros);
  List<XpEntry> get ledger => List.unmodifiable(_ledger);
  List<EventActivity> get activities => _macros.expand((m) => m.activities).toList();
  AdminUser user(String id) => _users.firstWhere((u) => u.id == id);
  int count(ActivityStatus status) => activities.where((a) => a.status == status).length;
  int get enrolled => activities.fold(0, (sum, a) => sum + a.enrolled);
  void addMacro(String title, String date) {
    _macros.add(MacroEvent('macro-${DateTime.now().microsecondsSinceEpoch}',
      title, date, [])); notifyListeners();
  }
  void addActivity(MacroEvent macro, String title, String type) {
    macro.activities.add(EventActivity(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}', title: title,
      type: type, status: ActivityStatus.recruiting)); notifyListeners();
  }
  void assignSpeaker(EventActivity activity, String userId) {
    if (activity.status != ActivityStatus.recruiting ||
        !activity.candidates.any((c) => c.userId == userId) || !user(userId).active) {
      throw StateError('No es posible asignar este postulante.');
    }
    activity.speakerId = userId;
    activity.status = ActivityStatus.draft;
    notifyListeners();
  }
  void editActivity(EventActivity activity, {required String title,
    required String date, required String time, required String room,
    required int capacity}) {
    if (capacity < activity.enrolled || capacity < 1) {
      throw StateError('El cupo no puede ser menor a los inscritos.');
    }
    activity.title = title; activity.date = date; activity.time = time;
    activity.room = room; activity.capacity = capacity; notifyListeners();
  }
  String? publicationError(EventActivity a) {
    if (a.speakerId == null) return 'Asigna un expositor antes de publicar.';
    if (a.type != 'Curso' && [a.date, a.time, a.room].any(
      (s) => s.trim().isEmpty || s == 'Por definir')) {
      return 'Completa la fecha, el horario y el aula.';
    }
    return null;
  }
  void publish(EventActivity a) {
    if (a.status != ActivityStatus.draft) throw StateError('Solo se publica un borrador.');
    final error = publicationError(a);
    if (error != null) throw StateError(error);
    a.status = ActivityStatus.published; notifyListeners();
  }
  void toggleUser(AdminUser u) { u.active = !u.active; notifyListeners(); }
  void updateName(String value) { adminName = value; notifyListeners(); }
  DemoFolio? findFolio(String code) {
    for (final f in _folios) { if (f.code == code.trim().toUpperCase()) return f; }
    return null;
  }
}
