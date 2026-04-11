import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:secureclub/viewmodels/auth_provider.dart';
import '../../models/ban_request_model.dart';
import '../../widgets/top_navigation_bar.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/labelled_date_picker.dart';

class EditBanRequestPage extends StatefulWidget {
  final BanRequestModel? banRequest;
  final ActiveBanModel?  activeBan;

  const EditBanRequestPage({
    super.key,
    this.banRequest,
    this.activeBan,
  });

  @override
  State<EditBanRequestPage> createState() => _EditBanRequestPageState();
}

class _EditBanRequestPageState extends State<EditBanRequestPage> {
  // ── Controllers ────────────────────────────────────────
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController idNumberController;
  late TextEditingController dobController;
  late TextEditingController genderController;
  late TextEditingController entryDateController;
  late TextEditingController descriptionController;
  DateTime? _fromDate;
  DateTime? _toDate;

  // ── State ──────────────────────────────────────────────
  String selectedReason   = "Select a reason...";
  String selectedDuration = "1 Month";
  bool   isCustom         = false;
  bool   _isSubmitting    = false;

  // ── Ban reason map ─────────────────────────────────────
  final Map<String, String> reasonCategoryMap = {
    "Aggressive Behavior":  "aggressive_behavior",
    "Misconduct":           "misconduct",
    "Security Violation":   "other",
    "Unauthorized Access":  "other",
    "Suspicious Behaviour": "other",
    "Drug Use":             "drug_use",
    "Other":                "other",
  };

  List<String> get reasons  => reasonCategoryMap.keys.toList();
  final List<String> durations = ["1 Month", "3 Months", "12 Months", "Custom"];

  // ── Derived values ─────────────────────────────────────
  String get banType =>
      (isCustom || selectedDuration != "12 Months") ? "temporary" : "permanent";

  String? get banExpiryDate {
    if (isCustom && _toDate != null) {
      return "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";
    }
    if (!isCustom && selectedDuration != "12 Months") {
      final now    = DateTime.now();
      final months = selectedDuration == "1 Month" ? 1 : 3;
      final exp    = DateTime(now.year, now.month + months, now.day);
      return "${exp.year}-${exp.month.toString().padLeft(2, '0')}-${exp.day.toString().padLeft(2, '0')}";
    }
    return null;
  }

  String get submissionTime {
    final now      = DateTime.now();
    final weekdays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    final months   = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    final wd   = weekdays[now.weekday - 1];
    final mo   = months[now.month - 1];
    final h    = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m    = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? "PM" : "AM";
    return "$wd, $mo ${now.day}, ${now.year}, $h:$m:${now.second.toString().padLeft(2, '0')} $ampm";
  }

  // ── Get ban ID from whichever model is set ─────────────
  int? get _banId {
    if (widget.banRequest != null) return int.tryParse(widget.banRequest!.id.toString());
    if (widget.activeBan != null) return widget.activeBan!.id;
    return null;
  }

  // ── initState ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (widget.banRequest != null) {
      final d = widget.banRequest!;

      // BanRequestModel fields: id, personName, idNumber, reason,
      // reasonCategory, banType, status, requestedBy, requestedAt,
      // evidenceCount, faceImageUrl
      final nameParts = d.personName.trim().split(' ');
      firstNameController   = TextEditingController(text: nameParts.first);
      lastNameController    = TextEditingController(
          text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
      idNumberController    = TextEditingController(text: d.idNumber);
      dobController         = TextEditingController(); // not in model
      genderController      = TextEditingController(); // not in model
      entryDateController   = TextEditingController(text: d.requestedAt);
      descriptionController = TextEditingController(text: d.description ?? '');
      _fromDate             = null;
      _toDate               = d.banExpiryDate != null ? DateTime.tryParse(d.banExpiryDate!) : null;

      // Pre-select reason dropdown
      if (reasonCategoryMap.containsKey(d.reason)) {
        selectedReason = d.reason!;
      } else {
        final entry = reasonCategoryMap.entries.firstWhere(
          (e) => e.value == d.reasonCategory,
          orElse: () => const MapEntry("", "")
        );
        if (entry.key.isNotEmpty) {
          selectedReason = entry.key;
        }
      }

      // Pre-select duration
      _preselectDuration(d.banType, d.banExpiryDate);

    } else if (widget.activeBan != null) {
      final d = widget.activeBan!;

      // ActiveBanModel fields: id, personName, idNumber, banType, banScope,
      // status, reason?, approvedBy?, requestedAt?, expiresAt?, faceImageUrl?
      final nameParts = d.personName.trim().split(' ');
      firstNameController   = TextEditingController(text: nameParts.first);
      lastNameController    = TextEditingController(
          text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
      idNumberController    = TextEditingController(text: d.idNumber);
      dobController         = TextEditingController(); // not in model
      genderController      = TextEditingController(); // not in model
      entryDateController   = TextEditingController(text: d.requestedAt ?? '');
      descriptionController = TextEditingController(); // not in model
      _fromDate             = null;
      _toDate               = d.expiresAt != null ? DateTime.tryParse(d.expiresAt!) : null;

      if (d.reason != null && reasonCategoryMap.containsKey(d.reason)) {
        selectedReason = d.reason!;
      }

      _preselectDuration(d.banType, d.expiresAt);

    } else {
      firstNameController   = TextEditingController();
      lastNameController    = TextEditingController();
      idNumberController    = TextEditingController();
      dobController         = TextEditingController();
      genderController      = TextEditingController();
      entryDateController   = TextEditingController();
      descriptionController = TextEditingController();
      _fromDate             = null;
      _toDate               = null;
    }
  }

  /// Decide which duration chip to pre-select
  void _preselectDuration(String? banType, String? expiryDate) {
    if (banType == 'permanent') {
      selectedDuration = "12 Months";
      isCustom = false;
    } else if (expiryDate != null) {
      // Try to guess 1 Month / 3 Months; otherwise fall back to Custom
      final expiry = DateTime.tryParse(expiryDate);
      if (expiry != null) {
        final now    = DateTime.now();
        final diff   = expiry.difference(now).inDays;
        if (diff <= 31) {
          selectedDuration = "1 Month";
        } else if (diff <= 93) {
          selectedDuration = "3 Months";
        } else {
          isCustom = true;
          selectedDuration = "Custom";
        }
      }
    }
  }

  /// "2025-07-15" → "15/07/2025"
  String _isoToDisplay(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parts = iso.split('-');
    if (parts.length == 3) return "${parts[2]}/${parts[1]}/${parts[0]}";
    return iso;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    idNumberController.dispose();
    dobController.dispose();
    entryDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ── SUBMIT (Update) ────────────────────────────────────
  Future<void> _submitUpdate() async {
    if (selectedReason == "Select a reason...") {
      _showError("Please select a ban reason.");
      return;
    }
    if (firstNameController.text.trim().isEmpty) {
      _showError("Please enter the patron's first name.");
      return;
    }
    if (idNumberController.text.trim().isEmpty) {
      _showError("Please enter the ID number.");
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      _showError("Please enter an incident description.");
      return;
    }
    if (_banId == null) {
      _showError("Ban ID not found. Cannot update.");
      return;
    }

    setState(() => _isSubmitting = true);

    final token   = context.read<AuthProvider>().token ?? '';
    final baseUrl = ApiConstants.baseUrl;

    final body = <String, dynamic>{
      "person_first_name": firstNameController.text.trim(),
      "person_last_name":  lastNameController.text.trim(),
      "id_number":         idNumberController.text.trim(),
      "reason":            selectedReason,
      "reason_category":   reasonCategoryMap[selectedReason] ?? "other",
      "description":       descriptionController.text.trim(),
      "ban_type":          banType,
      "ban_expiry_date":   banExpiryDate,
    };

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 PUT $baseUrl/api/v1/bans/$_banId');
    debugPrint('📦 BODY:\n${const JsonEncoder.withIndent('  ').convert(body)}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/bans/$_banId'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 RESPONSE [${response.statusCode}]: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessPopup(responseData['data'] ?? {});
        }
      } else {
        final msg = responseData['error']?['message']
            ?? responseData['message']
            ?? 'Failed to update ban.';
        setState(() => _isSubmitting = false);
        _showError(msg);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Network error: $e');
    }
  }

  // ── SUCCESS POPUP ──────────────────────────────────────
  void _showSuccessPopup(Map<String, dynamic> data) {
    Map<String, dynamic> person = {};
    if (data['person'] is Map) {
      person = data['person'] as Map<String, dynamic>;
    }

    Map<String, dynamic> club = {};
    if (data['club'] is Map) {
      club = data['club'] as Map<String, dynamic>;
    }

    Map<String, dynamic> requestedBy = {};
    if (data['requested_by'] is Map) {
      requestedBy = data['requested_by'] as Map<String, dynamic>;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        void closeDone() {
          Navigator.of(dialogCtx).pop();
          if (mounted) Navigator.of(context).pop();
        }
        void closeCancel() => Navigator.of(dialogCtx).pop();

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:  Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Ban Updated Successfully",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: closeCancel,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              "Status: ${(data['status'] ?? 'updated').toString().toUpperCase()}",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Scrollable body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailItem(
                                    "Patron Name",
                                    "${person['first_name'] ?? firstNameController.text} "
                                        "${person['last_name'] ?? lastNameController.text}".trim(),
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem("ID Number",
                                      person['id_number'] ?? idNumberController.text),
                                  const SizedBox(height: 12),
                                  _detailItem("Ban Reason",
                                      data['reason'] ?? selectedReason),
                                  const SizedBox(height: 12),
                                  _detailItem("Ban Type",
                                      (data['ban_type'] ?? banType).toString().toUpperCase()),
                                  const SizedBox(height: 12),
                                  _detailItem("Club", club['name'] ?? '—'),
                                  const SizedBox(height: 12),
                                  _detailItem("Updated By", requestedBy['name'] ?? '—'),
                                  if (data['ban_id'] != null) ...[
                                    const SizedBox(height: 12),
                                    _detailItem("Ban ID", "#${data['ban_id']}"),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 88,
                              height: 108,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Icon(Icons.person,
                                  size: 44, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (descriptionController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          _detailItem("Description",
                              descriptionController.text.trim()),
                        ],
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: closeCancel,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close,
                              color: Colors.black54, size: 16),
                          label: const Text("Cancel",
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: closeDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D492),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check,
                              color: Colors.black, size: 16),
                          label: const Text("Done",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenWidth       = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: TopNavigationBar(currentRoute: '/ban_warning'),
            ),
            const SizedBox(height: 10),
            Text(
              "Edit Ban Request",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth < 600 ? 24 : 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth < 600 ? 20 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 700;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ══ PATRON DETAILS ══
                            _sectionLabel("PATRON DETAILS"),
                            const SizedBox(height: 16),

                            _twoColumns(isMobile,
                              left: _labeledInput("First Name *",
                                  firstNameController,
                                  hint: "Enter first name"),
                              right: _labeledInput("Last Name",
                                  lastNameController,
                                  hint: "Enter last name"),
                            ),
                            const SizedBox(height: 16),

                            _twoColumns(isMobile,
                              left: _labeledInput("ID Number *",
                                  idNumberController,
                                  hint: "e.g. NSW-12345678"),
                              right: _labeledInput("Entry Date/Time",
                                  entryDateController,
                                  hint: "dd/mm/yyyy hh:mm"),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

                            // ══ INCIDENT DETAILS ══
                            _sectionLabel("INCIDENT DETAILS"),
                            const SizedBox(height: 16),
                            _fieldLabel("Ban Reason *"),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedReason,
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                              dropdownColor: Colors.white,
                              items: [
                                const DropdownMenuItem(
                                    value: "Select a reason...",
                                    child: Text("Select a reason...")),
                                ...reasons.map((r) =>
                                    DropdownMenuItem(value: r, child: Text(r))),
                              ],
                              onChanged: (v) => setState(() {
                                selectedReason = v!;
                              }),
                              decoration: _inputDecoration(),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel("Incident Description *"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descriptionController,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _inputDecoration().copyWith(
                                hintText:
                                "Provide a detailed account of the incident, including time, location, and specific actions observed...",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

                            // ══ BAN DURATION ══
                            _fieldLabel("Ban Duration"),
                            const SizedBox(height: 14),
                            isMobile
                                ? Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: durations.map(_durationButton).toList())
                                : Row(
                              children: durations
                                  .map((d) => Expanded(
                                child: Padding(
                                  padding:
                                  const EdgeInsets.only(right: 10),
                                  child: _durationButton(d),
                                ),
                              ))
                                  .toList(),
                            ),

                            if (isCustom) ...[
                              const SizedBox(height: 24),
                              const Text("Select Custom Date Range",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              isMobile
                                  ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LabelledDatePicker(
                                      label: "From Date",
                                      selectedDate: _fromDate,
                                      onDateSelected: (date) => setState(() => _fromDate = date),
                                    ),
                                    const SizedBox(height: 16),
                                    LabelledDatePicker(
                                      label: "To Date",
                                      selectedDate: _toDate,
                                      onDateSelected: (date) => setState(() => _toDate = date),
                                      firstDate: _fromDate,
                                    ),
                                  ])
                                  : Row(children: [
                                Expanded(child: LabelledDatePicker(
                                      label: "From Date",
                                      selectedDate: _fromDate,
                                      onDateSelected: (date) => setState(() => _fromDate = date),
                                )),
                                const SizedBox(width: 20),
                                Expanded(child: LabelledDatePicker(
                                      label: "To Date",
                                      selectedDate: _toDate,
                                      onDateSelected: (date) => setState(() => _toDate = date),
                                      firstDate: _fromDate,
                                )),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  "Select the start and end date for the ban period",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ]),
                            ],

                            const SizedBox(height: 24),

                            // Submission time
                            _fieldLabel("Ban Update Time"),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(submissionTime,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "This will be recorded when you update the ban request",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            isMobile
                                ? Column(children: [
                              SizedBox(
                                  width: double.infinity,
                                  child: _backButton()),
                              const SizedBox(height: 12),
                              SizedBox(
                                  width: double.infinity,
                                  child: _updateButton()),
                            ])
                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _backButton(),
                                _updateButton(),
                              ],
                            ),
                          ],
                        );
                      }),
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

  // ── Helpers ────────────────────────────────────────────
  Widget _twoColumns(bool isMobile,
      {required Widget left, required Widget right}) {
    return isMobile
        ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(height: 16), right])
        : Row(children: [
      Expanded(child: left),
      const SizedBox(width: 20),
      Expanded(child: right),
    ]);
  }

  Widget _labeledInput(String label, TextEditingController ctrl,
      {String hint = ""}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDecoration().copyWith(
            hintText: hint,
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12));

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14));

  Widget _durationButton(String label) {
    final isSelected = label == "Custom"
        ? isCustom
        : (selectedDuration == label && !isCustom);
    return GestureDetector(
      onTap: () => setState(() {
        if (label == "Custom") {
          isCustom = true;
          selectedDuration = "Custom";
        } else {
          isCustom = false;
          selectedDuration = label;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14C38E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14C38E)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }

  Widget _datePickerField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              controller.text =
              "${picked.day.toString().padLeft(2, '0')}/"
                  "${picked.month.toString().padLeft(2, '0')}/"
                  "${picked.year}";
            }
          },
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              controller.text.isEmpty ? "" : controller.text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backButton() => ElevatedButton.icon(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black87,
      padding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ),
    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
    label: const Text("Back",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
  );

  Widget _updateButton() => ElevatedButton.icon(
    onPressed: _isSubmitting ? null : _submitUpdate,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF14C38E),
      disabledBackgroundColor: const Color(0xFF14C38E).withOpacity(0.5),
      padding:
      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ),
    icon: _isSubmitting
        ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.save, color: Colors.white, size: 18),
    label: Text(
      _isSubmitting ? "Updating..." : "Update Ban",
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      const BorderSide(color: Color(0xFF14C38E), width: 1.5),
    ),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}