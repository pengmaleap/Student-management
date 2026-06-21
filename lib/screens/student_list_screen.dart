import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/gender_summary_card.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  Future<List<dynamic>>? _students;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() {
    final request = _api.getStudents(search: _search.text);
    setState(() {
      _students = request;
    });
    return request.then<void>((_) {}, onError: (_) {});
  }

  void _export() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student list is ready to export.')),
    );
  }

  Future<void> _addStudent() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddStudentScreen()),
    );
    if (created == true) {
      _search.clear();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _students,
    builder: (context, snapshot) {
      final students = snapshot.data ?? [];
      final female = students
          .where((item) => item['gender'] == 'female')
          .length;
      final male = students.where((item) => item['gender'] == 'male').length;

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _StudentHero(
                    total: students.length,
                    female: female,
                    male: male,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: TextField(
                              controller: _search,
                              onSubmitted: (_) => _load(),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 31,
                                  color: Color(0xFF159DA8),
                                ),
                                hintText: 'Search...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 18,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E1E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF159DA8),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE1E1E1)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _export,
                            child: const SizedBox(
                              width: 58,
                              height: 58,
                              child: Icon(
                                Icons.file_download_outlined,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (students.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No students found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (_, index) => _StudentRow(
                        student: students[index] as Map<String, dynamic>,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 22,
            bottom: 116,
            child: FloatingActionButton.extended(
              heroTag: 'add-student',
              shape: CircleBorder(),
              backgroundColor: const Color(0xFF087D38),
              foregroundColor: Colors.white,
              onPressed: _addStudent,
              label: const Icon(Icons.person_add_alt_1),
            ),
          ),
        ],
      );
    },
  );
}

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final ApiService _api = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _studentCode = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _grade = TextEditingController();
  final TextEditingController _address = TextEditingController();
  String _gender = 'female';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _studentCode.dispose();
    _email.dispose();
    _phone.dispose();
    _grade.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _api.createStudent({
        'name': _name.text.trim(),
        'studentCode': _studentCode.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'grade': _grade.text.trim(),
        'address': _address.text.trim(),
        'gender': _gender,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAF9),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      title: const Text(
        'Add Student',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFDDF3E5),
              child: Icon(
                Icons.person_add_alt_1,
                size: 48,
                color: Color(0xFF087D38),
              ),
            ),
            const SizedBox(height: 28),
            _field(
              controller: _name,
              label: 'Full name *',
              icon: Icons.person_outline,
              validator: _required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 15),
            _field(
              controller: _studentCode,
              label: 'Student ID *',
              icon: Icons.badge_outlined,
              validator: _required,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _decoration('Gender *', Icons.people_outline),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value!),
            ),
            const SizedBox(height: 15),
            _field(
              controller: _grade,
              label: 'Grade or class *',
              icon: Icons.school_outlined,
              validator: _required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 15),
            _field(
              controller: _email,
              label: 'Email *',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (_required(value) != null) return _required(value);
                if (!value!.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 15),
            _field(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _field(
              controller: _address,
              label: 'Address',
              icon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF109447),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(_saving ? 'Adding student...' : 'Add Student'),
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF159DA8)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E4E2)),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    maxLines: maxLines,
    decoration: _decoration(label, icon),
  );
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({
    required this.total,
    required this.female,
    required this.male,
  });

  final int total;
  final int female;
  final int male;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 550,
      child: Stack(
        children: [
          Container(
            height: 320,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(25, topPadding + 24, 25, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF159447), Color(0xFF83CEAA)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/Logo.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Saby Track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
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
                            size: 29,
                          ),
                          Positioned(
                            right: 10,
                            top: 9,
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
                const Spacer(),
                const Text(
                  'Student List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'View and manage all your students.',
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 16),
                ),
                const SizedBox(height: 38),
              ],
            ),
          ),
          Positioned(
            top: 275,
            left: 20,
            right: 20,
            child: GenderSummaryCard(
              total: total,
              female: female,
              male: male,
              showTitleIcon: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFD6EEF0),
              foregroundImage: student['avatar_url'] == null
                  ? null
                  : NetworkImage(student['avatar_url'].toString()),
              child: const Icon(Icons.person),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'].toString(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272727),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student['student_code'] ?? 'No ID'} | ${student['grade']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC5C5C5)),
          ],
        ),
      ),
    ),
  );
}
