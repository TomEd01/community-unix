import 'package:flutter/material.dart';

class AlumnoEventosPage extends StatefulWidget {
  const AlumnoEventosPage({super.key});

  @override
  State<AlumnoEventosPage> createState() => _AlumnoEventosPageState();
}

class _AlumnoEventosPageState extends State<AlumnoEventosPage> {
  static const Color _bg = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _cardSoft = Color(0xFF0D3153);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _blue = Color(0xFF2796FF);
  static const Color _cyan = Color(0xFF22D3C5);
  static const Color _muted = Color(0xFF91A9BE);

  bool _yearView = true;
  int _selectedMonth = 10;
  int _selectedDay = 9;
  int _selectedEvent = 0;

  final List<_EventData> _events = const [
    _EventData(
      day: 9,
      month: 10,
      title: 'Taller de Linux',
      time: '16:00',
      place: 'En línea',
      type: 'Taller',
      color: _blue,
      icon: Icons.terminal_rounded,
      description:
          'Taller práctico de introducción a Linux. Conoce la terminal, '
          'comandos básicos y buenas prácticas.',
    ),
    _EventData(
      day: 16,
      month: 10,
      title: 'Introducción a Python',
      time: '17:00',
      place: 'Aula 3',
      type: 'Charla',
      color: _orange,
      icon: Icons.code_rounded,
      description:
          'Introducción al lenguaje Python y sus aplicaciones en desarrollo '
          'de software y automatización.',
    ),
    _EventData(
      day: 23,
      month: 10,
      title: 'Redes con Packet Tracer',
      time: '15:00',
      place: 'Laboratorio',
      type: 'Comunidad',
      color: _cyan,
      icon: Icons.lan_rounded,
      description:
          'Actividad práctica para aprender conceptos fundamentales de redes '
          'utilizando Cisco Packet Tracer.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool mobile = constraints.maxWidth < 760;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 28,
              mobile ? 20 : 28,
              mobile ? 16 : 28,
              45,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(mobile),
                    const SizedBox(height: 22),
                    _buildControls(mobile),
                    const SizedBox(height: 18),
                    _buildLegend(),
                    const SizedBox(height: 20),
                    if (mobile)
                      _buildMobileContent()
                    else
                      _buildDesktopContent(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eventos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mobile ? 30 : 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Encuentra talleres, charlas y actividades de la comunidad.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (!mobile)
          Container(
            width: 235,
            height: 42,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _border),
            ),
            child: const TextField(
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar eventos...',
                hintStyle: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _muted,
                  size: 19,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CONTROLES
  // ============================================================

  Widget _buildControls(bool mobile) {
    if (mobile) {
      return Column(
        children: [
          Row(
            children: [
              _navButton(Icons.chevron_left_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: _todayButton(),
              ),
              const SizedBox(width: 8),
              _navButton(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 12),
          _viewSelector(),
        ],
      );
    }

    return Row(
      children: [
        const Text(
          '2026',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 24),
        _navButton(Icons.chevron_left_rounded),
        const SizedBox(width: 7),
        _todayButton(),
        const SizedBox(width: 7),
        _navButton(Icons.chevron_right_rounded),
        const Spacer(),
        _viewSelector(),
      ],
    );
  }

  Widget _navButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: IconButton(
        onPressed: () {},
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: _muted,
          size: 22,
        ),
      ),
    );
  }

  Widget _todayButton() {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedMonth = 10;
            _selectedDay = 9;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _border),
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Hoy',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _viewSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewButton(
            'Mes',
            !_yearView,
            () {
              setState(() {
                _yearView = false;
              });
            },
          ),
          _viewButton(
            'Año',
            _yearView,
            () {
              setState(() {
                _yearView = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _viewButton(
    String text,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LEYENDA
  // ============================================================

  Widget _buildLegend() {
    return const Wrap(
      spacing: 22,
      runSpacing: 10,
      children: [
        _LegendItem(
          color: _blue,
          text: 'Taller',
        ),
        _LegendItem(
          color: _orange,
          text: 'Charla',
        ),
        _LegendItem(
          color: _cyan,
          text: 'Comunidad',
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _yearView
              ? _buildYearCalendar()
              : _buildMonthCalendar(10),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 330,
          child: Column(
            children: [
              _buildUpcomingEvents(),
              const SizedBox(height: 18),
              _buildSelectedEvent(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthCalendar(_selectedMonth),
        const SizedBox(height: 28),
        _buildUpcomingEvents(),
        const SizedBox(height: 18),
        _buildSelectedEvent(),
      ],
    );
  }

  // ============================================================
  // CALENDARIO ANUAL
  // ============================================================

  Widget _buildYearCalendar() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) {
        return _buildMiniMonth(index + 1);
      },
    );
  }

  Widget _buildMiniMonth(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final int days = _daysInMonth(month);
    final int firstWeekday = DateTime(2026, month, 1).weekday;

    final List<Widget> cells = [];

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= days; day++) {
      final event = _eventForDate(month, day);
      final bool selected =
          month == _selectedMonth && day == _selectedDay;

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
              _selectedDay = day;

              if (event != null) {
                _selectedEvent = _events.indexOf(event);
              }
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _orange,
                      width: 2,
                    ),
                  )
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 9,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                if (event != null)
                  Positioned(
                    bottom: 1,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            months[month - 1],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekLabel('L'),
              _WeekLabel('M'),
              _WeekLabel('M'),
              _WeekLabel('J'),
              _WeekLabel('V'),
              _WeekLabel('S'),
              _WeekLabel('D'),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1,
              children: cells,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALENDARIO MENSUAL
  // ============================================================

  Widget _buildMonthCalendar(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final int days = _daysInMonth(month);
    final int firstWeekday = DateTime(2026, month, 1).weekday;

    final List<Widget> cells = [];

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= days; day++) {
      final event = _eventForDate(month, day);
      final bool selected =
          month == _selectedMonth && day == _selectedDay;

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
              _selectedDay = day;

              if (event != null) {
                _selectedEvent = _events.indexOf(event);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: _orange,
                      width: 2,
                    )
                  : null,
              color: selected
                  ? _orange.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                if (event != null)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${months[month - 1]} 2026',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 17),
          const Row(
            children: [
              Expanded(child: _WeekLabel('L')),
              Expanded(child: _WeekLabel('M')),
              Expanded(child: _WeekLabel('M')),
              Expanded(child: _WeekLabel('J')),
              Expanded(child: _WeekLabel('V')),
              Expanded(child: _WeekLabel('S')),
              Expanded(child: _WeekLabel('D')),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.15,
            children: cells,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRÓXIMOS EVENTOS
  // ============================================================

  Widget _buildUpcomingEvents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Próximos eventos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Ver todos →',
                style: TextStyle(
                  color: _orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...List.generate(
            _events.length,
            (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _events.length - 1 ? 0 : 10,
                ),
                child: _buildEventListItem(
                  _events[index],
                  index,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventListItem(
    _EventData event,
    int index,
  ) {
    final bool selected = index == _selectedEvent;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEvent = index;
          _selectedMonth = event.month;
          _selectedDay = event.day;
        });
      },
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _cardSoft : _bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? event.color : _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 57,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.day.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'OCT',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      _SmallInfo(
                        icon: Icons.schedule_rounded,
                        text: event.time,
                      ),
                      _SmallInfo(
                        icon: Icons.location_on_outlined,
                        text: event.place,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETALLE
  // ============================================================

  Widget _buildSelectedEvent() {
    final event = _events[_selectedEvent];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 62,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.day.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'OCT',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.type,
                      style: TextStyle(
                        color: event.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _DetailRow(
            icon: Icons.schedule_rounded,
            text: '${event.time} - 18:00',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.location_on_outlined,
            text: event.place,
          ),
          const SizedBox(height: 12),
          const _DetailRow(
            icon: Icons.groups_outlined,
            text: 'Cupo limitado (30 participantes)',
          ),
          const SizedBox(height: 17),
          Text(
            event.description,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text(
                'Ver detalles',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _daysInMonth(int month) {
    return DateTime(2026, month + 1, 0).day;
  }

  _EventData? _eventForDate(
    int month,
    int day,
  ) {
    for (final event in _events) {
      if (event.month == month && event.day == day) {
        return event;
      }
    }

    return null;
  }
}

// =================================================================
// MODELOS / COMPONENTES
// =================================================================

class _EventData {
  final int day;
  final int month;
  final String title;
  final String time;
  final String place;
  final String type;
  final Color color;
  final IconData icon;
  final String description;

  const _EventData({
    required this.day,
    required this.month,
    required this.title,
    required this.time,
    required this.place,
    required this.type,
    required this.color,
    required this.icon,
    required this.description,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: _AlumnoEventosPageState._muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String text;

  const _WeekLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: _AlumnoEventosPageState._muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: _AlumnoEventosPageState._muted,
          size: 13,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: _AlumnoEventosPageState._muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _AlumnoEventosPageState._muted,
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _AlumnoEventosPageState._muted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}