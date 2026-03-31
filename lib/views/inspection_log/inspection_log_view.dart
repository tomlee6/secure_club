

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureclub/viewmodels/auth_provider.dart' show AuthProvider;
import 'package:secureclub/views/inspection_log/entry_logs_provider.dart';
import 'package:secureclub/widgets/top_navigation_bar.dart';


class InspectionLogView extends StatefulWidget {
  const InspectionLogView({super.key});

  @override
  State<InspectionLogView> createState() => _InspectionLogViewState();
}

class _InspectionLogViewState extends State<InspectionLogView> {
  final _visitorNameCtrl = TextEditingController();
  final _idNumberCtrl    = TextEditingController();
  final _idStateCtrl     = TextEditingController();
  final _notesCtrl       = TextEditingController();

  String  _entryType    = 'entry';
  String  _status       = 'allowed';
  String? _denialReason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntries());
  }

  @override
  void dispose() {
    _visitorNameCtrl.dispose();
    _idNumberCtrl.dispose();
    _idStateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _loadEntries({int page = 1}) async {
    await context
        .read<EntryLogsProvider>()
        .fetchEntryLogs(token: _token, page: page);
  }

  Future<void> _submitRecord() async {
    final name    = _visitorNameCtrl.text.trim();
    final idNum   = _idNumberCtrl.text.trim();
    final idState = _idStateCtrl.text.trim();

    if (name.isEmpty || idNum.isEmpty || idState.isEmpty) {
      _showSnack('Please fill Visitor Name, ID Number and ID State.',
          isError: true);
      return;
    }
    if (_status == 'denied' &&
        (_denialReason == null || _denialReason!.isEmpty)) {
      _showSnack('Please select a denial reason.', isError: true);
      return;
    }

    final success = await context.read<EntryLogsProvider>().createEntry(
      token:        _token,
      visitorName:  name,
      idNumber:     idNum,
      idState:      idState,
      entryType:    _entryType,
      status:       _status,
      denialReason: _status == 'denied' ? _denialReason : null,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    if (success) {
      _showSnack('Visit recorded successfully!');
      _clearForm();
      _loadEntries();
    } else {
      final err =
          context.read<EntryLogsProvider>().errorMessage ?? 'Unknown error';
      _showSnack(err, isError: true);
    }
  }

  void _clearForm() {
    _visitorNameCtrl.clear();
    _idNumberCtrl.clear();
    _idStateCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _entryType    = 'entry';
      _status       = 'allowed';
      _denialReason = null;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? Colors.red.shade200 : Colors.green.shade200,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: isError ? Colors.red[800] : Colors.green[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // Tablet (≥700): full screen height, NO page scroll — cards fill viewport
  // Mobile (<700): page scrolls, cards stack vertically
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    if (isMobile) {
      // ── MOBILE: page scrolls, cards grow naturally ──
      return Scaffold(
        backgroundColor: const Color(0xFF0B1E2D),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: TopNavigationBar(currentRoute: '/inspection_log'),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Inspection Log",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _recordCard(scrollable: true),
                      const SizedBox(height: 16),
                      _recentCard(fixedHeight: null),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── TABLET: fixed full-screen height, NO outer scroll ──
    // Cards are pinned; record card scrolls its form; recent card scrolls its list.
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Nav — fixed
            const Padding(
              padding: EdgeInsets.all(16),
              child: TopNavigationBar(currentRoute: '/inspection_log'),
            ),

            const SizedBox(height: 10),

            // Title — fixed
            const Text(
              "Inspection Log",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Cards row — Expanded fills remaining screen height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHeight = constraints.maxHeight;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Record card — form scrolls inside
                            Expanded(
                              child: _recordCard(scrollable: true),
                            ),
                            const SizedBox(width: 16),
                            // Recent card — list scrolls inside
                            Expanded(
                              child: _recentCard(fixedHeight: cardHeight),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // RECORD CARD
  // scrollable: true  → form content scrolls inside the card
  // scrollable: false → card grows with content (mobile fallback)
  // ─────────────────────────────────────────────────────
  Widget _recordCard({required bool scrollable}) {
    final isSubmitting = context.watch<EntryLogsProvider>().isSubmitting;

    // The form fields section
    final formFields = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          _fieldWithIcon(
            label: "Visitor Name *",
            controller: _visitorNameCtrl,
            icon: Icons.person_outline,
            hint: "Enter visitor's full name",
          ),
          _fieldWithIcon(
            label: "ID Number *",
            controller: _idNumberCtrl,
            icon: Icons.badge_outlined,
            hint: "e.g. NSW-12345678",
          ),
          _fieldWithIcon(
            label: "ID State *",
            controller: _idStateCtrl,
            icon: Icons.location_on_outlined,
            hint: "e.g. NSW, VIC, QLD",
          ),

          _label("Entry Type"),
          _segmentRow(
            options: const ['entry', 'exit'],
            selected: _entryType,
            onChanged: (v) => setState(() => _entryType = v),
            activeColor: const Color(0xFF0B1E2D),
          ),
          const SizedBox(height: 14),

          _label("Status"),
          _segmentRow(
            options: const ['allowed', 'denied'],
            selected: _status,
            onChanged: (v) => setState(() {
              _status = v;
              if (v == 'allowed') _denialReason = null;
            }),
            activeColor: _status == 'denied' ? Colors.red : Colors.green,
          ),

          if (_status == 'denied') ...[
            const SizedBox(height: 14),
            _label("Denial Reason *"),
            DropdownButtonFormField<String>(
              value: _denialReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
              hint: const Text("Select reason"),
              items: const [
                DropdownMenuItem(value: 'banned', child: Text('Banned')),
                DropdownMenuItem(
                    value: 'underage', child: Text('Underage')),
                DropdownMenuItem(
                    value: 'id_expired', child: Text('ID Expired')),
              ],
              onChanged: (v) => setState(() => _denialReason = v),
            ),
          ],

          const SizedBox(height: 14),
          _fieldWithIcon(
            label: "Notes (optional)",
            controller: _notesCtrl,
            icon: Icons.notes_outlined,
            hint: "Enter any additional notes...",
            maxLines: 3,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    // The submit button — always visible at the bottom
    final submitBtn = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isSubmitting ? null : _submitRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D492),
            disabledBackgroundColor:
            const Color(0xFF00D492).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: isSubmitting
              ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.save_outlined,
              color: Colors.black, size: 18),
          label: Text(
            isSubmitting ? "Recording..." : "Record Visit",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [

          // ── Fixed header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Record New Visit",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  "Fill in the details of the official visit",
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable form ──
          if (scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    formFields,
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            formFields,
          ],

          // ── Fixed submit button ──
          const Divider(height: 1),
          submitBtn,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // RECENT CARD
  // fixedHeight != null → card fills that height, list scrolls inside
  // fixedHeight == null → card grows with content (mobile)
  // ─────────────────────────────────────────────────────
  Widget _recentCard({required double? fixedHeight}) {
    final provider    = context.watch<EntryLogsProvider>();
    final entries     = provider.entries;
    final isLoading   = provider.isLoading;
    final error       = provider.errorMessage;
    final currentPage = provider.currentPage;
    final totalPages  = provider.totalPages;
    final total       = provider.total;

    final isFixed = fixedHeight != null;

    // ── Scrollable list body ──
    Widget listBody;
    if (error != null) {
      listBody = Padding(
        padding: const EdgeInsets.all(16),
        child: _errorWidget(error, currentPage),
      );
    } else if (isLoading && entries.isEmpty) {
      listBody = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (entries.isEmpty) {
      listBody = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            "No visits recorded yet.",
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
        ),
      );
    } else {
      listBody = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, i) => _entryTile(entries[i]),
      );
    }

    // ── Pagination ──
    final pagination = totalPages > 1
        ? Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => _loadEntries(page: currentPage - 1)
                : null,
          ),
          Text(
            'Page $currentPage / $totalPages',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => _loadEntries(page: currentPage + 1)
                : null,
          ),
        ],
      ),
    )
        : const SizedBox(height: 12);

    return Container(
      height: fixedHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isFixed ? MainAxisSize.max : MainAxisSize.min,
        children: [

          // ── Fixed header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Recent Visits",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total > 0
                          ? "History of official visits ($total total)"
                          : "History of official visits",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black45),
                    ),
                  ],
                ),
                IconButton(
                  icon: isLoading
                      ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh,
                      color: Color(0xFF0B1E2D)),
                  onPressed: isLoading
                      ? null
                      : () => _loadEntries(page: currentPage),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable list ──
          if (isFixed)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: listBody,
              ),
            )
          else
            listBody,

          // ── Fixed pagination ──
          pagination,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Entry tile — unchanged
  // ─────────────────────────────────────────────────────
  Widget _entryTile(EntryLogModel log) {
    final isAllowed = log.status == 'allowed';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            children: [
              Expanded(
                child: Text(
                  log.visitorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllowed
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  log.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAllowed ? Colors.blue[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            log.idNumber,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: Colors.black38),
              const SizedBox(width: 4),
              Text(_fmtTime(log.loggedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(width: 14),
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.black38),
              const SizedBox(width: 4),
              Text(_fmtDate(log.loggedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),

          const SizedBox(height: 4),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _metaChip(
                icon: log.entryType == 'entry' ? Icons.login : Icons.logout,
                label: log.entryType == 'entry' ? 'Entry' : 'Exit',
                color: Colors.black38,
              ),
              if (log.denialReason != null)
                _metaChip(
                  icon: Icons.block,
                  label: 'Denied: ${log.denialReason}',
                  color: Colors.red,
                ),
              if (log.guard.isNotEmpty)
                _metaChip(
                  icon: Icons.person_outline,
                  label: log.guard,
                  color: Colors.black38,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _errorWidget(String msg, int page) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
          TextButton(
            onPressed: () => _loadEntries(page: page),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Helpers — all unchanged
  // ─────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontSize: 13, color: Colors.black54)),
  );


  Widget _fieldWithIcon({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,

            // ✅ FIX: force text color to black
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),

            // ✅ optional but recommended
            cursorColor: Colors.black,

            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.black26,
                fontSize: 13,
              ),

              // ✅ ensure white background
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black54),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Widget _fieldWithIcon({
  //   required String label,
  //   required TextEditingController controller,
  //   required IconData icon,
  //   String? hint,
  //   int maxLines = 1,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(icon, size: 14, color: Colors.black45),
  //             const SizedBox(width: 6),
  //             Text(label,
  //                 style: const TextStyle(
  //                     fontSize: 13,
  //                     color: Colors.black54,
  //                     fontWeight: FontWeight.w500)),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         TextField(
  //           controller: controller,
  //           maxLines: maxLines,
  //           decoration: InputDecoration(
  //             hintText: hint,
  //             hintStyle:
  //             const TextStyle(color: Colors.black26, fontSize: 13),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //               borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //               borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
  //             ),
  //             contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 12, vertical: 14),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _segmentRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                opt[0].toUpperCase() + opt.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmtTime(String raw) {
    try {
      final dt   = DateTime.parse(raw).toLocal();
      final h    = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0 ? 12 : dt.hour;
      final min  = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:$min $ampm';
    } catch (_) {
      return raw;
    }
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}