import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  List<dynamic> _noteTypes = [];
  int? _noteTypeId;
  Future<List<dynamic>>? _notes;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _dates = List.generate(
      21,
      (index) => _selectedDate.add(Duration(days: index - 3)),
    );
    _load();
    _loadNoteTypes();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() {
    final request = _api.getNotes(search: _search.text);
    setState(() {
      _notes = request;
    });
    return request.then<void>((_) {}, onError: (_) {});
  }

  Future<void> _loadNoteTypes() async {
    try {
      final noteTypes = await _api.getNoteTypes();
      if (mounted) setState(() => _noteTypes = noteTypes);
    } catch (_) {
      // Notes can still display if type metadata cannot be loaded.
    }
  }

  Future<void> _edit([Map<String, dynamic>? note]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _notes,
    builder: (context, snapshot) {
      final allNotes = snapshot.data ?? [];
      final notes = allNotes.where((item) {
        if (_noteTypeId == null) return true;
        return item['note_type_id'] == _noteTypeId;
      }).toList();

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(snapshot.error.toString())),
                  )
                else if (notes.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No notes found. Tap + to create one.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 135),
                    sliver: SliverGrid.builder(
                      itemCount: notes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemBuilder: (_, index) => _NoteCard(
                        note: notes[index] as Map<String, dynamic>,
                        color: _hex(notes[index]['color']?.toString()),
                        onTap: () =>
                            _edit(notes[index] as Map<String, dynamic>),
                        onDelete: () =>
                            _delete(notes[index] as Map<String, dynamic>),
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
              shape: CircleBorder(),
              heroTag: 'add-note',
              label: const Icon(Icons.add),
              backgroundColor: const Color(0xFF087D38),
              foregroundColor: Colors.white,
              onPressed: () => _edit(),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildHeader() {
    final topPadding = MediaQuery.paddingOf(context).top;
    final noteTypes = [
      <String, dynamic>{'id': null, 'name': 'All'},
      ..._noteTypes.map((item) => Map<String, dynamic>.from(item as Map)),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF159447), Color(0xFF72C798), Color(0xFFEAF6EF)],
          stops: [0, .52, 1],
        ),
      ),
      child: Column(
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
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 62,
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  size: 30,
                  color: Color(0xFF777777),
                ),
                hintText: 'Search for notes',
                hintStyle: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 102,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11),
              itemBuilder: (_, index) {
                final date = _dates[index];
                final selected = _sameDay(date, _selectedDate);
                return InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 68,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF087D38) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF087D38),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF087D38),
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF087D38),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 47,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: noteTypes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final noteType = noteTypes[index];
                final id = noteType['id'] as int?;
                final selected = id == _noteTypeId;
                return ChoiceChip(
                  label: Text(noteType['name'].toString()),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF087D38),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (_) => setState(() => _noteTypeId = id),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _NoteFilterButton(
                  icon: Icons.filter_list,
                  label: _sameDay(_selectedDate, DateTime.now())
                      ? 'Today'
                      : DateFormat('MMM d').format(_selectedDate),
                  onTap: _pickNoteDate,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: _NoteFilterButton(
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

  Future<void> _pickNoteDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result != null) setState(() => _selectedDate = result);
  }

  Future<void> _delete(Map<String, dynamic> note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete “${note['title']}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _api.deleteNote(note['id'] as int);
      _load();
    }
  }

  Color _hex(String? value) => Color(
    int.parse('FF${(value ?? '#FFF1B8').replaceFirst('#', '')}', radix: 16),
  );
}

class _NoteFilterButton extends StatelessWidget {
  const _NoteFilterButton({
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
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF159DA8), size: 27),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF159DA8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF159DA8)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  final Map<String, dynamic> note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['title'].toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                note['content'].toString(),
                maxLines: 9,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 15),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    DateFormat(
                      'MMM d',
                    ).format(DateTime.parse(note['note_date'].toString())),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  (note['note_type'] ?? note['category']).toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});
  final Map<String, dynamic>? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final ApiService _api = ApiService();
  late final TextEditingController _title;
  late final TextEditingController _content;
  List<dynamic> _noteTypes = [];
  int? _noteTypeId;
  bool _loadingNoteTypes = true;
  late String _color;
  late DateTime _date;
  bool _saving = false;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  TextAlign _alignment = TextAlign.left;
  static const colors = ['#FFF1B8', '#C9F7DF', '#D9E8FF', '#FFD9EA', '#E8D9FF'];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?['title']?.toString() ?? '');
    _content = TextEditingController(text: note?['content']?.toString() ?? '');
    _noteTypeId = note?['note_type_id'] as int?;
    _color = note?['color']?.toString() ?? colors.first;
    _date = note == null
        ? DateTime.now()
        : DateTime.parse(note['note_date'].toString());
    _loadNoteTypes();
  }

  Future<void> _loadNoteTypes() async {
    try {
      final noteTypes = await _api.getNoteTypes();
      if (!mounted) return;
      setState(() {
        _noteTypes = noteTypes;
        _loadingNoteTypes = false;
        _noteTypeId ??= _matchingNoteTypeId(
          widget.note?['category']?.toString() ?? 'General',
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadingNoteTypes = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  int? _matchingNoteTypeId(String name) {
    for (final item in _noteTypes) {
      if (item['name'].toString().toLowerCase() == name.toLowerCase()) {
        return item['id'] as int;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title')),
      );
      return;
    }
    if (_noteTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a note type')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.saveNote({
        'id': widget.note?['id'],
        'title': _title.text,
        'content': _content.text,
        'noteTypeId': _noteTypeId,
        'color': _color,
        'noteDate': DateFormat('yyyy-MM-dd').format(_date),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFEFE),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      toolbarHeight: 84,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left, size: 34),
      ),
      title: const Text(
        'Notepad',
        style: TextStyle(
          color: Color(0xFF505050),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          const Text(
            '1. Note Information',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 23),
          DropdownButtonFormField<int>(
            initialValue: _noteTypeId,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFAAAAAA),
            ),
            decoration: InputDecoration(
              labelText: 'Note Type *',
              labelStyle: const TextStyle(
                fontSize: 17,
                color: Color(0xFF555555),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDADADA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF109447),
                  width: 1.5,
                ),
              ),
            ),
            hint: Text(
              _loadingNoteTypes ? 'Loading note types...' : 'Select note type',
            ),
            items: _noteTypes
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item['id'] as int,
                    child: Text(item['name'].toString()),
                  ),
                )
                .toList(),
            onChanged: _loadingNoteTypes
                ? null
                : (value) => setState(() {
                    _noteTypeId = value;
                    final selected = _noteTypes.firstWhere(
                      (item) => item['id'] == value,
                    );
                    _color = selected['default_color']?.toString() ?? _color;
                  }),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(
              labelText: 'Note Title *',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 22,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDADADA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF109447),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _formattingToolbar(),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(minHeight: 430),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDADADA)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openFullEditor,
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _content.text.trim().isEmpty
                          ? 'Write your note here'
                          : _content.text,
                      maxLines: 17,
                      overflow: TextOverflow.ellipsis,
                      textAlign: _alignment,
                      style: TextStyle(
                        color: _content.text.trim().isEmpty
                            ? const Color(0xFF555555)
                            : const Color(0xFF222222),
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                        fontStyle: _italic
                            ? FontStyle.italic
                            : FontStyle.normal,
                        decoration: _underline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.visibility, color: Color(0xFF109447)),
              label: const Text(
                'Preview',
                style: TextStyle(
                  color: Color(0xFF109447),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(158, 56),
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.black12,
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF109447),
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.note == null ? 'Confirm' : 'Update',
                  style: const TextStyle(fontSize: 17),
                ),
        ),
      ),
    ),
  );

  Widget _formattingToolbar() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _FormatButton(
        label: 'B',
        selected: _bold,
        onTap: () => setState(() => _bold = !_bold),
      ),
      _FormatButton(
        label: 'I',
        italic: true,
        selected: _italic,
        onTap: () => setState(() => _italic = !_italic),
      ),
      _FormatButton(
        label: 'U',
        underline: true,
        selected: _underline,
        onTap: () => setState(() => _underline = !_underline),
      ),
      const _FormatButton(label: 'T'),
      _FormatIconButton(
        icon: Icons.format_align_left,
        selected: _alignment == TextAlign.left,
        onTap: () => setState(() => _alignment = TextAlign.left),
      ),
      _FormatIconButton(
        icon: Icons.format_align_center,
        selected: _alignment == TextAlign.center,
        onTap: () => setState(() => _alignment = TextAlign.center),
      ),
      _FormatIconButton(
        icon: Icons.format_align_right,
        selected: _alignment == TextAlign.right,
        onTap: () => setState(() => _alignment = TextAlign.right),
      ),
      _FormatIconButton(
        icon: Icons.format_align_justify,
        selected: _alignment == TextAlign.justify,
        onTap: () => setState(() => _alignment = TextAlign.justify),
      ),
    ],
  );

  Future<void> _openFullEditor() async {
    final result = await Navigator.push<_FullScreenEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenNoteEditor(
          title: _title.text.trim().isEmpty ? 'Untitled Note' : _title.text,
          content: _content.text,
          bold: _bold,
          italic: _italic,
          underline: _underline,
          alignment: _alignment,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _content.text = result.content;
      _bold = result.bold;
      _italic = result.italic;
      _underline = result.underline;
      _alignment = result.alignment;
    });
  }

  Future<void> _preview() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(_title.text.trim().isEmpty ? 'Untitled Note' : _title.text),
      content: SingleChildScrollView(
        child: Text(
          _content.text.trim().isEmpty ? 'Nothing to preview.' : _content.text,
          textAlign: _alignment,
          style: TextStyle(
            height: 1.45,
            fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
            decoration: _underline
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _FullScreenEditorResult {
  const _FullScreenEditorResult({
    required this.content,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.alignment,
  });

  final String content;
  final bool bold;
  final bool italic;
  final bool underline;
  final TextAlign alignment;
}

class FullScreenNoteEditor extends StatefulWidget {
  const FullScreenNoteEditor({
    super.key,
    required this.title,
    required this.content,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.alignment,
  });

  final String title;
  final String content;
  final bool bold;
  final bool italic;
  final bool underline;
  final TextAlign alignment;

  @override
  State<FullScreenNoteEditor> createState() => _FullScreenNoteEditorState();
}

class _FullScreenNoteEditorState extends State<FullScreenNoteEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late bool _bold;
  late bool _italic;
  late bool _underline;
  late TextAlign _alignment;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _focusNode = FocusNode();
    _bold = widget.bold;
    _italic = widget.italic;
    _underline = widget.underline;
    _alignment = widget.alignment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _FullScreenEditorResult get _result => _FullScreenEditorResult(
    content: _controller.text,
    bold: _bold,
    italic: _italic,
    underline: _underline,
    alignment: _alignment,
  );

  void _close() => Navigator.pop(context, _result);

  @override
  Widget build(BuildContext context) => PopScope<_FullScreenEditorResult>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _close,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back, size: 31),
              ),
              const SizedBox(height: 28),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 42,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlign: _alignment,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: const Color(0xFF292929),
                    fontSize: 20,
                    height: 1.5,
                    fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
                    decoration: _underline
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF109447),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FormatButton(
                label: 'B',
                selected: _bold,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _bold = !_bold),
              ),
              _FormatButton(
                label: 'I',
                italic: true,
                selected: _italic,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _italic = !_italic),
              ),
              _FormatButton(
                label: 'U',
                underline: true,
                selected: _underline,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _underline = !_underline),
              ),
              const _FormatButton(
                label: 'T',
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
              ),
              _FormatIconButton(
                icon: Icons.format_align_left,
                selected: _alignment == TextAlign.left,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _alignment = TextAlign.left),
              ),
              _FormatIconButton(
                icon: Icons.format_align_center,
                selected: _alignment == TextAlign.center,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _alignment = TextAlign.center),
              ),
              _FormatIconButton(
                icon: Icons.format_align_right,
                selected: _alignment == TextAlign.right,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _alignment = TextAlign.right),
              ),
              _FormatIconButton(
                icon: Icons.format_align_justify,
                selected: _alignment == TextAlign.justify,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
                onTap: () => setState(() => _alignment = TextAlign.justify),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.label,
    this.selected = false,
    this.italic = false,
    this.underline = false,
    this.onTap,
    this.activeColor = const Color(0xFF109447),
    this.inactiveColor = const Color(0xFFB9B9B9),
  });

  final String label;
  final bool selected;
  final bool italic;
  final bool underline;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: SizedBox(
      width: 36,
      height: 42,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : inactiveColor,
            fontSize: 29,
            fontWeight: label == 'B' ? FontWeight.w500 : FontWeight.w300,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    ),
  );
}

class _FormatIconButton extends StatelessWidget {
  const _FormatIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.activeColor = const Color(0xFF109447),
    this.inactiveColor = const Color(0xFFB9B9B9),
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: SizedBox(
      width: 36,
      height: 42,
      child: Icon(
        icon,
        size: 28,
        color: selected ? activeColor : inactiveColor,
      ),
    ),
  );
}
