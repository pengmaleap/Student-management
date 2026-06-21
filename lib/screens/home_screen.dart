import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _buildAttendanceRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(
    String name,
    String grade,
    String status,
    Color statusColor,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  grade,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(41),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.calendar_today, size: 16, color: Colors.black54),
              Text(
                'Apr 24',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEDF7F0),
                    child: Icon(Icons.school, color: Color(0xFF1D7C3E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Good Morning Teacher',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Peng Maleap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF1D7C3E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildDateChip(context, 'Tue', '23', true),
                    _buildDateChip(context, 'Wed', '24', false),
                    _buildDateChip(context, 'Thu', '25', false),
                    _buildDateChip(context, 'Fri', '26', false),
                    _buildDateChip(context, 'Sat', '27', false),
                    _buildDateChip(context, 'Sun', '28', false),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.menu, color: Color(0xFF1D7C3E)),

                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Today',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.location_city, color: Color(0xFF1D7C3E)),

                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ComYIES1',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Gender',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Students:',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 140,
                                        width: 140,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CustomPaint(
                                              size: const Size(140, 140),
                                              painter: _RingPainter(
                                                segments: const [
                                                  _ChartSegmentValue(
                                                    color: Color(0xFF3A86FF),
                                                    value: 100,
                                                  ),
                                                  _ChartSegmentValue(
                                                    color: Color(0xFF8A2BE2),
                                                    value: 50,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: 88,
                                              width: 88,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x1A000000),
                                                    blurRadius: 16,
                                                    offset: Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Builder(
                                                  builder: (context) {
                                                    const female = 100;
                                                    const male = 50;
                                                    final total = female + male;
                                                    return Text(
                                                      total.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      _GenderLegend(
                                        color: Color(0xFF3A86FF),
                                        label: 'Female',
                                        value: '100',
                                      ),
                                      SizedBox(height: 12),
                                      _GenderLegend(
                                        color: Color(0xFF8A2BE2),
                                        label: 'Male',
                                        value: '50',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Attendance Overview',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildAttendanceRow(
                              'Early',
                              20,
                              const Color(0xFF2ECC71),
                            ),
                            _buildAttendanceRow(
                              'On Time',
                              80,
                              const Color(0xFF1D7C3E),
                            ),
                            _buildAttendanceRow(
                              'Late',
                              60,
                              const Color(0xFFF1C40F),
                            ),
                            _buildAttendanceRow(
                              'On Leave',
                              45,
                              const Color(0xFFE67E22),
                            ),
                            _buildAttendanceRow(
                              'Missed',
                              35,
                              const Color(0xFFF39C12),
                            ),
                            _buildAttendanceRow(
                              'Absent',
                              25,
                              const Color(0xFFE74C3C),
                            ),
                            _buildAttendanceRow(
                              'Early Leave',
                              50,
                              const Color(0xFF8E44AD),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(color: Color(0xFF1D7C3E)),
                            ),
                          ),
                        ],
                      ),
                      _buildStudentItem(
                        'Peng Maleap',
                        'Grade 9A',
                        'Present',
                        const Color(0xFF2ECC71),
                        'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=80',
                      ),
                      _buildStudentItem(
                        'Rin Sokim',
                        'Grade 9B',
                        'Absent',
                        const Color(0xFFE74C3C),
                        'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=80',
                      ),
                      _buildStudentItem(
                        'Phen Sokleng',
                        'Grade 9A',
                        'Present',
                        const Color(0xFF2ECC71),
                        'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=80',
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Schedule',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildScheduleItem(
                              'Mathematics',
                              '08:00 AM - 09:00 AM',
                              const Color(0xFF1D7C3E),
                            ),
                            const SizedBox(height: 10),
                            _buildScheduleItem(
                              'English Literature',
                              '09:30 AM - 10:30 AM',
                              const Color(0xFF3A86FF),
                            ),
                            const SizedBox(height: 10),
                            _buildScheduleItem(
                              'Science Lab',
                              '11:00 AM - 12:00 PM',
                              const Color(0xFFF1C40F),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'My Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Edit Board',
                            style: TextStyle(color: Color(0xFF1D7C3E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildNoteCard(
                            'Parent Meeting',
                            'Discuss quarterly progress with parents of Grade 9A. Focus on Math and Science scores.',
                            const Color(0xFFFFF3C4),
                          ),
                          _buildNoteCard(
                            'Grading',
                            'Finish grading the mid-term exams and upload results to the portal.',
                            const Color(0xFFD8F8E8),
                          ),
                          _buildNoteCard(
                            'Lesson Plan',
                            'Update lesson plan for next week. Include interactive quizzes and group activities.',
                            const Color(0xFFD7E9FF),
                          ),
                          _buildNoteCard(
                            'School Event',
                            'Prepare for the annual science fair. Coordinate with the student council.',
                            const Color(0xFFFFD6E0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 0),
              child: _BottomNavItem(
                icon: Icons.home,
                label: 'Home',
                active: _selectedIndex == 0,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: _BottomNavItem(
                icon: Icons.note_alt_outlined,
                label: 'Notepad',
                active: _selectedIndex == 1,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: _BottomNavItem(
                icon: Icons.list_alt_outlined,
                label: 'Student List',
                active: _selectedIndex == 2,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: _selectedIndex == 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    String day,
    String date,
    bool selected,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D7C3E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(color: selected ? Colors.white : Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String title, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<_ChartSegmentValue> segments;

  _RingPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;
    const gap = 0.18; // smaller visual gap between segments

    final totalValue = segments.fold<double>(0, (p, e) => p + e.value);
    final totalGaps = gap * segments.length;
    final availableAngle = math.pi * 2 - totalGaps;

    for (final segment in segments) {
      final sweep =
          (segment.value / (totalValue == 0 ? 1 : totalValue)) * availableAngle;
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartSegmentValue {
  final Color color;
  final double value;

  const _ChartSegmentValue({required this.color, required this.value});
}

class _GenderLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _GenderLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1D7C3E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.black45,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1D7C3E) : Colors.black54,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
