import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

const _attendanceTeal = Color(0xFF159DA8);
const _attendanceStatuses = [
  'present',
  'early',
  'on_time',
  'late',
  'on_leave',
  'missed',
  'absent',
  'early_leave',
];

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({
    super.key,
    required this.initialDate,
    this.classId,
  });
  final DateTime initialDate;
  final int? classId;

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late DateTime _date;
  Future<List<dynamic>>? _attendance;
  final Set<int> _savingAttendance = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() {
    final request = _api.getAttendance(
      _date,
      search: _searchController.text,
      classId: widget.classId,
    );
    setState(() {
      _attendance = request;
    });
    return request.then<void>((_) {}, onError: (_) {});
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result != null) {
      _date = result;
      _load();
    }
  }

  void _download() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance for ${DateFormat('MMM d, yyyy').format(_date)} is ready to export.',
        ),
      ),
    );
  }

  Future<void> _changeStatus(Map<String, dynamic> record) async {
    final currentStatus = record['status'].toString();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update ${record['name']} attendance',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final status in _attendanceStatuses)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: _attendanceStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(_attendanceStatusLabel(status)),
                        trailing: status == currentStatus
                            ? const Icon(Icons.check, color: Color(0xFF109447))
                            : null,
                        onTap: () => Navigator.pop(context, status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected == currentStatus || !mounted) return;

    final attendanceId = record['id'] as int;
    final clearsTimes = {'absent', 'on_leave', 'missed'}.contains(selected);
    final previousCheckIn = record['check_in'];
    final previousCheckOut = record['check_out'];
    setState(() {
      _savingAttendance.add(attendanceId);
      record['status'] = selected;
      if (clearsTimes) {
        record['check_in'] = null;
        record['check_out'] = null;
      }
    });
    try {
      await _api.updateAttendance(
        studentId: record['student_id'] as int,
        date: _api.formatDate(_date),
        status: selected,
        checkIn: clearsTimes ? null : record['check_in']?.toString(),
        checkOut: clearsTimes ? null : record['check_out']?.toString(),
        note: record['note']?.toString(),
      );
      _hasChanges = true;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${record['name']} marked ${_attendanceStatusLabel(selected)}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          record['status'] = currentStatus;
          record['check_in'] = previousCheckIn;
          record['check_out'] = previousCheckOut;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _savingAttendance.remove(attendanceId));
    }
  }

  void _close() => Navigator.pop(context, _hasChanges);

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          toolbarHeight: 82,
          centerTitle: true,
          leading: IconButton(
            onPressed: _close,
            icon: const Icon(Icons.chevron_left, size: 34),
          ),
          title: const Text(
            'Attendance List',
            style: TextStyle(
              color: Color(0xFF505050),
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 27, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Track all the attendance performance.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _load(),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 31,
                                  color: _attendanceTeal,
                                ),
                                hintText: 'Search...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 18,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E1E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _attendanceTeal,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          icon: Icons.filter_alt_outlined,
                          onTap: _pickDate,
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          icon: Icons.file_download_outlined,
                          onTap: _download,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _attendance,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorView(
                        message: snapshot.error.toString(),
                        retry: _load,
                      );
                    }
                    final records = snapshot.data ?? [];
                    if (records.isEmpty) {
                      return Center(
                        child: Text(
                          'No attendance on ${DateFormat('MMM d, yyyy').format(_date)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 15),
                        itemBuilder: (_, index) => _AttendanceCard(
                          record: records[index] as Map<String, dynamic>,
                          saving: _savingAttendance.contains(
                            (records[index] as Map<String, dynamic>)['id'],
                          ),
                          onStatusTap: () => _changeStatus(
                            records[index] as Map<String, dynamic>,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE1E1E1)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        height: 58,
        child: Icon(icon, size: 29, color: Colors.black),
      ),
    ),
  );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.record,
    required this.saving,
    required this.onStatusTap,
  });
  final Map<String, dynamic> record;
  final bool saving;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final status = record['status'].toString();
    final color = _attendanceStatusColor(status);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: const Color(0xFFE9F3F3),
                          foregroundImage: record['avatar_url'] == null
                              ? null
                              : NetworkImage(record['avatar_url'].toString()),
                          child: const Icon(Icons.person),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Student ID : ${record['student_code'] ?? 'No ID'}',
                                style: const TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: saving ? null : onStatusTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (saving)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Text(
                                      _attendanceStatusLabel(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (!saving) ...[
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 20,
                          color: _attendanceTeal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record['class_name']?.toString().isNotEmpty == true
                                ? record['class_name'].toString()
                                : 'No class assigned',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _attendanceStatusLabel(String value) => value
    .split('_')
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

Color _attendanceStatusColor(String value) => switch (value) {
  'present' || 'early' => const Color(0xFF159447),
  'on_time' => const Color(0xFF159DA8),
  'late' => const Color(0xFFFFA000),
  'on_leave' => const Color(0xFF6C63FF),
  'missed' => const Color(0xFFFFC107),
  'early_leave' => const Color(0xFFA83CFF),
  'absent' => const Color(0xFFE53935),
  _ => Colors.grey,
};

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
