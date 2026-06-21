import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/gender_summary_card.dart';
import 'attendance_list_screen.dart';
import 'notes_screen.dart';
import 'student_list_screen.dart';

const appGreen = Color(0xFF159447);
const appBackground = Color(0xFFF4F8F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const NotesScreen(),
      const StudentListScreen(),
      TeacherProfileScreen(onBack: () => setState(() => _index = 0)),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: appBackground,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _LiquidGlassNavigationBar(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _LiquidGlassNavigationBar extends StatelessWidget {
  const _LiquidGlassNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.note_alt_rounded, label: 'Notepad'),
    (icon: Icons.assignment_rounded, label: 'Student List'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 28,
            spreadRadius: 1,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x12FFFFFF),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 78,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xEFFFFFFF), Color(0xCFF7FAF8)],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xE6FFFFFF), width: 1.2),
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = selectedIndex == index;
                return Expanded(
                  child: Semantics(
                    selected: selected,
                    button: true,
                    label: item.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => onSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xA6FFFFFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: selected
                              ? Border.all(color: const Color(0xBFFFFFFF))
                              : null,
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 5),
                                  ),
                                  BoxShadow(
                                    color: Color(0xA6FFFFFF),
                                    blurRadius: 10,
                                    offset: Offset(0, -2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.08 : 1,
                              duration: const Duration(milliseconds: 260),
                              child: Icon(
                                item.icon,
                                size: 28,
                                color: selected
                                    ? const Color(0xFF07883E)
                                    : const Color(0xFF454545),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: item.label == 'Student List'
                                    ? 11
                                    : 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFF07883E)
                                    : const Color(0xFF353535),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  final ScrollController _calendarController = ScrollController();
  late DateTime _selectedDate;
  late List<DateTime> _calendarDates;
  Future<Map<String, dynamic>>? _dashboard;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _calendarDates = List.generate(
      45,
      (index) => _selectedDate.add(Duration(days: index - 14)),
    );
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarController.hasClients) _calendarController.jumpTo(14 * 70.0);
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _load() {
    final request = _api.getDashboard(_selectedDate);
    setState(() {
      _dashboard = request;
    });
    return request.then<void>((_) {}, onError: (_) {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      _selectedDate = picked;
      if (!_calendarDates.any((date) => _sameDay(date, picked))) {
        _calendarDates = List.generate(
          45,
          (index) => picked.add(Duration(days: index - 14)),
        );
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dashboard,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _error(snapshot.error.toString());
                }
                return _dashboardBody(snapshot.data!);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 22, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF159447), Color(0xFF69BE8E)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/Logo.png',
                width: 47,
                height: 47,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Saby Track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0x35FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x99FFFFFF)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 27,
                    ),
                    Positioned(
                      right: 8,
                      top: 7,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D57),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Image.network(
                      'https://i.pravatar.cc/160?img=19',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFDDF3E5),
                        child: Icon(Icons.person, color: appGreen),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting Teacher',
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Peng Maleap',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        left: 3,
                        top: 4,
                        child: Icon(
                          Icons.wb_sunny,
                          size: 37,
                          color: Color(0xFFFFC400),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 6,
                        child: Icon(
                          Icons.cloud,
                          size: 43,
                          color: Colors.lightBlue.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 88,
            child: ListView.separated(
              controller: _calendarController,
              scrollDirection: Axis.horizontal,
              itemCount: _calendarDates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final date = _calendarDates[index];
                final selected = _sameDay(date, _selectedDate);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _selectedDate = date;
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? appGreen : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF087D38),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : appGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white70
                                : const Color(0xFF087D38),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DashboardFilterButton(
                  icon: Icons.filter_list,
                  label: _sameDay(_selectedDate, DateTime.now())
                      ? 'Today'
                      : DateFormat('MMM d').format(_selectedDate),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _DashboardFilterButton(
                  icon: Icons.apartment,
                  label: 'ComYIES1',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardBody(Map<String, dynamic> data) {
    final gender = data['gender'] as Map<String, dynamic>;
    final overview = data['attendanceOverview'] as List<dynamic>;
    final attendance = data['attendance'] as List<dynamic>;
    final schedules = data['schedules'] as List<dynamic>;
    final notes = data['notes'] as List<dynamic>;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          GenderSummaryCard(
            total: gender['total'] as int? ?? 0,
            female: gender['female'] as int? ?? 0,
            male: gender['male'] as int? ?? 0,
          ),
          const SizedBox(height: 14),
          _overviewCard(overview),
          const SizedBox(height: 14),
          _attendanceCard(attendance),
          const SizedBox(height: 14),
          _scheduleCard(schedules),
          const SizedBox(height: 14),
          _notesCard(notes),
        ],
      ),
    );
  }

  Widget _overviewCard(List<dynamic> values) {
    final counts = {
      for (final item in values)
        item['status'].toString(): item['count'] as int,
    };
    final max = counts.values.fold<int>(
      1,
      (current, value) => value > current ? value : current,
    );
    const statuses = [
      'early',
      'present',
      'on_time',
      'late',
      'on_leave',
      'missed',
      'absent',
      'early_leave',
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final status in statuses)
            _progressRow(
              _statusLabel(status),
              counts[status] ?? 0,
              max,
              _statusColor(status),
            ),
          if (values.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: Text(
                  'No attendance for this date',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _attendanceCard(List<dynamic> attendance) {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Attendance",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AttendanceListScreen(initialDate: _selectedDate),
                  ),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          if (attendance.isEmpty)
            const _EmptyMessage('No attendance records')
          else
            for (var index = 0; index < attendance.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _studentAttendanceRow(attendance[index] as Map<String, dynamic>),
            ],
        ],
      ),
    );
  }

  Widget _scheduleCard(List<dynamic> schedules) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Schedule",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (schedules.isEmpty)
            const _EmptyMessage('No classes scheduled')
          else
            for (var index = 0; index < schedules.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _scheduleRow(schedules[index] as Map<String, dynamic>),
            ],
        ],
      ),
    );
  }

  Widget _notesCard(List<dynamic> notes) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              ),
              child: const Text('Edit Board'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          _card(child: const _EmptyMessage('No notes for this date'))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, index) {
              final note = notes[index] as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _hexColor(note['color']?.toString()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note['content'].toString(),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM d',
                      ).format(DateTime.parse(note['note_date'].toString())),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );

  Widget _progressRow(String label, int value, int max, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / max,
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(25),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _studentAttendanceRow(Map<String, dynamic> item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        _Avatar(
          url: item['avatar_url']?.toString(),
          name: item['name'].toString(),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                item['grade'].toString(),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        _StatusBadge(item['status'].toString()),
      ],
    ),
  );

  Widget _scheduleRow(Map<String, dynamic> schedule) {
    final color = _hexColor(schedule['color']?.toString());
    final start = _timeLabel(schedule['start_time']?.toString());
    final end = _timeLabel(schedule['end_time']?.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule['title'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$start - $end  •  ${schedule['grade'] ?? ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String message) => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(
      children: [
        const Icon(Icons.cloud_off, size: 50, color: Colors.black38),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _DashboardFilterButton extends StatelessWidget {
  const _DashboardFilterButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF159DA8), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF159DA8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF159DA8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 38, 28, 125),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 142,
                                  height: 142,
                                  child: Image.network(
                                    'https://i.pravatar.cc/300?img=19',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(
                                      color: Color(0xFFDDF3E5),
                                      child: Icon(
                                        Icons.person,
                                        size: 82,
                                        color: appGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 1,
                                bottom: 2,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF168E48),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Peng Maleap',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Teacher',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      flex: 6,
                      child: Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileContact(
                              icon: Icons.phone_in_talk,
                              value: '0885732522',
                            ),
                            SizedBox(height: 28),
                            _ProfileContact(
                              icon: Icons.send_rounded,
                              value: '0972434688',
                              underline: true,
                            ),
                            SizedBox(height: 28),
                            _ProfileContact(
                              icon: Icons.email_outlined,
                              value: 'teacher@sabytrack.com',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Divider(thickness: 1, color: Color(0xFFE4E4E4)),
                const SizedBox(height: 22),
                for (final item in const [
                  (Icons.settings_outlined, 'Setting'),
                  (Icons.support_agent_outlined, 'Support'),
                  (Icons.share_outlined, 'Share'),
                  (Icons.help_outline, 'About us'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: ListTile(
                      minLeadingWidth: 42,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(item.$1, color: Colors.black, size: 29),
                      title: Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileContact extends StatelessWidget {
  const _ProfileContact({
    required this.icon,
    required this.value,
    this.underline = false,
  });

  final IconData icon;
  final String value;
  final bool underline;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF159DA8), size: 27),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            decoration: underline ? TextDecoration.underline : null,
          ),
        ),
      ),
    ],
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String name;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: const Color(0xFFDDF3E5),
    foregroundImage: url == null || url!.isEmpty ? null : NetworkImage(url!),
    child: Text(
      name.isEmpty ? '?' : name[0],
      style: const TextStyle(color: appGreen, fontWeight: FontWeight.bold),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _statusLabel(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

Color _statusColor(String value) => switch (value) {
  'present' || 'early' => const Color(0xFF159447),
  'on_time' => const Color(0xFF169DAC),
  'late' => const Color(0xFFFFA000),
  'on_leave' => const Color(0xFF6C63FF),
  'early_leave' => const Color(0xFFA63DFF),
  'missed' => const Color(0xFFFFC107),
  'absent' => const Color(0xFFE53935),
  _ => Colors.grey,
};

Color _hexColor(String? value) {
  final hex = (value ?? '#FFF1B8').replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

String _timeLabel(String? value) {
  if (value == null || value.isEmpty) return '--';
  final parts = value.split(':');
  final date = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat('h:mm a').format(date);
}
