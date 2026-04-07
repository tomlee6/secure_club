




import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:secureclub/viewmodels/auth_provider.dart';
import 'package:secureclub/viewmodels/ban_warning_view_model.dart';
import 'package:secureclub/widgets/top_navigation_bar.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/labelled_date_picker.dart';


class RaiseBanRequestPage extends StatefulWidget {
  final String name;
  final String id;

  const RaiseBanRequestPage({
    super.key,
    required this.name,
    required this.id,
  });

  @override
  State<RaiseBanRequestPage> createState() => _RaiseBanRequestPageState();
}

class _RaiseBanRequestPageState extends State<RaiseBanRequestPage> {
  String selectedReason         = "Select a reason...";
  String selectedReasonCategory = "";
  String selectedDuration       = "1 Month";
  bool   isCustom               = false;
  bool   _isSubmitting          = false;

  XFile?     _evidenceXFile;
  File?      _evidenceFile;
  Uint8List? _evidenceBytes;

  final firstNameController   = TextEditingController();
  final idNumberController    = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _dob;
  final genderController      = TextEditingController();
  final entryDateController   = TextEditingController();

  final Map<String, String> reasonCategoryMap = {
    "Aggressive Behavior":  "aggressive_behavior",
    "Misconduct":           "other",
    "Security Violation":   "other",
    "Unauthorized Access":  "other",
    "Suspicious Behaviour": "other",
    "Drug Use":             "drug_use",
    "Other":                "other",
  };

  List<String> get reasons => reasonCategoryMap.keys.toList();
  final List<String> durations = ["1 Month", "3 Months", "12 Months", "Custom"];

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

  @override
  void initState() {
    super.initState();
    if (widget.name.isNotEmpty) {
      firstNameController.text = widget.name.trim();
    }
    idNumberController.text = widget.id;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    idNumberController.dispose();
    descriptionController.dispose();
    genderController.dispose();
    entryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _evidenceXFile = picked;
        _evidenceBytes = bytes;
        _evidenceFile  = null;
      });
    } else {
      setState(() {
        _evidenceXFile = picked;
        _evidenceFile  = File(picked.path);
        _evidenceBytes = null;
      });
    }
  }

  Widget _buildImage({BoxFit fit = BoxFit.cover}) {
    if (kIsWeb && _evidenceBytes != null) {
      return Image.memory(_evidenceBytes!, fit: fit);
    } else if (!kIsWeb && _evidenceFile != null) {
      return Image.file(_evidenceFile!, fit: fit);
    }
    return const SizedBox.shrink();
  }

  bool get _hasImage =>
      (kIsWeb && _evidenceBytes != null) ||
          (!kIsWeb && _evidenceFile != null);

  Future<void> _submitBanRequest() async {
    if (selectedReason == "Select a reason...") {
      _showError("Please select a ban reason.");
      return;
    }
    if (firstNameController.text.trim().isEmpty) {
      _showError("Please enter the patron's name.");
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

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final token   = authProvider.token ?? '';
    final rawClub = authProvider.user?.club;
    final clubId  = (rawClub is Map) ? rawClub['id'] : (rawClub is int ? rawClub : null);
    final baseUrl = ApiConstants.baseUrl;

    final fullName = firstNameController.text.trim();
    final nameParts = fullName.split(' ');

    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName =
    nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "N/A";

    final body = <String, dynamic>{
      "club_id": clubId ?? 1,
      "person_first_name": firstName,
      "person_last_name": lastName,
      "id_number": idNumberController.text.trim(),
      "id_type": "drivers_license",
      "reason": selectedReason,
      "reason_category": reasonCategoryMap[selectedReason] ?? "other",
      "description": descriptionController.text.trim(),
      "ban_type": banType,
      "ban_expiry_date": banExpiryDate,
      "face_image_url": null,
    };

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 POST $baseUrl/api/v1/bans/request');
    debugPrint('📦 BODY:\n${const JsonEncoder.withIndent('  ').convert(body)}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/bans/request'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📥 RESPONSE [${response.statusCode}]');
      try {
        debugPrint(const JsonEncoder.withIndent('  ')
            .convert(jsonDecode(response.body)));
      } catch (_) {
        debugPrint(response.body);
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final banId = responseData['data']?['ban_id'];
        debugPrint('✅ Ban created! ban_id=$banId');

        if (_hasImage && banId != null) {
          await _uploadEvidence(banId: banId, token: token, baseUrl: baseUrl);
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          context.read<BanWarningViewModel>().fetchBanRequests(token);
          _showSuccessPopup(responseData['data'] ?? {});
        }
      } else {
        final msg = responseData['error']?['message']
            ?? responseData['message']
            ?? 'Failed to submit ban request.';
        debugPrint('❌ Failed: $msg');
        setState(() => _isSubmitting = false);
        _showError(msg);
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      setState(() => _isSubmitting = false);
      _showError('Network error: $e');
    }
  }

  Future<void> _uploadEvidence({
    required int banId,
    required String token,
    required String baseUrl,
  }) async {
    try {
      debugPrint('📤 Uploading evidence for ban_id=$banId ...');
      final req = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/api/v1/bans/$banId/evidence'));
      req.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb && _evidenceBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'file',
          _evidenceBytes!,
          filename: _evidenceXFile?.name ?? 'evidence.jpg',
        ));
      } else if (!kIsWeb && _evidenceFile != null) {
        req.files.add(
            await http.MultipartFile.fromPath('file', _evidenceFile!.path));
      }

      req.fields['file_type'] = 'photo';
      final res = await req.send();
      debugPrint('📥 Evidence upload: ${res.statusCode}');
    } catch (e) {
      debugPrint('⚠️ Evidence upload failed (non-fatal): $e');
    }
  }

  void _showSuccessPopup(Map<String, dynamic> data) {
    final person      = data['person']       as Map<String, dynamic>? ?? {};
    final club        = data['club']         as Map<String, dynamic>? ?? {};
    final requestedBy = data['requested_by'] as Map<String, dynamic>? ?? {};

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
                            "Ban Request Submitted",
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
                              "Status: ${(data['status'] ?? 'pending').toString().toUpperCase()}",
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ── last name reference fully removed ──
                                  _detailItem(
                                    "Patron Name",
                                    (person['first_name'] ?? firstNameController.text).toString().trim(),
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
                                  _detailItem("Requested By",
                                      requestedBy['name'] ?? '—'),
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
                              child: _hasImage
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImage(),
                              )
                                  : const Icon(Icons.person,
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
                        if (_hasImage) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          Text("Evidence",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: _buildImage(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
              "Raise Ban Request",
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
                        final isMobile = constraints.maxWidth < 600;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            _sectionLabel("PATRON DETAILS"),
                            const SizedBox(height: 20),

                            isMobile
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _patronNameField(),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _idNumberField()),
                                    const SizedBox(width: 16),
                                    _entryPhotoWidget(),
                                  ],
                                ),
                              ],
                            )
                                : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _patronNameField(),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 3,
                                    child: _idNumberField(),
                                  ),
                                  const SizedBox(width: 20),
                                  _entryPhotoWidget(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            _twoColumns(
                              isMobile,
                              left: LabelledDatePicker(
                                label: "Date of Birth",
                                selectedDate: _dob,
                                hintText: "dd/mm/yyyy",
                                onDateSelected: (date) => setState(() => _dob = date),
                                lastDate: DateTime.now(),
                              ),
                              right: _labeledInput(
                                "Gender",
                                genderController,
                                hint: "e.g. Male / Female",
                              ),
                            ),

                            const SizedBox(height: 20),

                            _fieldLabel("Date/Time"),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                submissionTime,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

                            _sectionLabel("INCIDENT DETAILS"),
                            const SizedBox(height: 16),
                            _fieldLabel("Ban Reason *"),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedReason,
                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                              items: [
                                const DropdownMenuItem(
                                    value: "Select a reason...",
                                    child: Text("Select a reason...", style: TextStyle(color: Colors.black87))),
                                ...reasons.map((r) =>
                                    DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.black87)))),
                              ],
                              onChanged: (v) => setState(() {
                                selectedReason = v!;
                                selectedReasonCategory =
                                    reasonCategoryMap[v] ?? '';
                              }),
                              decoration: _inputDecoration(),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel("Incident Description *"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descriptionController,
                              style: const TextStyle(color: Colors.black87),
                              maxLines: 5,
                              decoration: _inputDecoration().copyWith(
                                hintText:
                                "Provide a detailed account of the incident, including time, location, and specific actions observed...",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

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
                                  padding: const EdgeInsets.only(right: 10),
                                  child: _durationButton(d),
                                ),
                              ))
                                  .toList(),
                            ),

                            if (isCustom) ...[
                              const SizedBox(height: 24),
                              const Text("Select Custom Date Range",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
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
                                Expanded(
                                    child: LabelledDatePicker(
                                        label: "From Date",
                                        selectedDate: _fromDate,
                                        onDateSelected: (date) => setState(() => _fromDate = date)
                                    )
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                    child: LabelledDatePicker(
                                        label: "To Date",
                                        selectedDate: _toDate,
                                        onDateSelected: (date) => setState(() => _toDate = date),
                                        firstDate: _fromDate,
                                    )
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.info_outline,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  "Select the start and end date for the ban period",
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ]),
                            ],

                            const SizedBox(height: 24),

                            _fieldLabel("Ban Submission Time"),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
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
                                    "This will be recorded when you submit the ban request",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

                            Row(children: [
                              const Text("Evidence (Optional)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Text("Support your request with media",
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 13)),
                            ]),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _pickEvidence,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: _hasImage
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImage(),
                                )
                                    : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined,
                                        size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text("Capture Photo",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text("or tap to pick from gallery",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            isMobile
                                ? Column(children: [
                              SizedBox(
                                  width: double.infinity,
                                  child: _backButton()),
                              const SizedBox(height: 12),
                              SizedBox(
                                  width: double.infinity,
                                  child: _submitButton()),
                            ])
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [_backButton(), _submitButton()],
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

  Widget _patronNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Patron Name"),
        const SizedBox(height: 6),
        TextField(
          controller: firstNameController,
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDecoration().copyWith(
            hintText: "Full name",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _idNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("ID Number *"),
        const SizedBox(height: 6),
        TextField(
          controller: idNumberController,
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDecoration().copyWith(
            hintText: "e.g. NSW-12345678",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _entryPhotoWidget() {
    return GestureDetector(
      onTap: _pickEvidence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Entry Photo",
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _hasImage
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline,
                    size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 4),
                Text(
                  "Tap to add",
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
            color: isSelected ? const Color(0xFF14C38E) : Colors.grey.shade300,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              controller.text.isEmpty ? "" : controller.text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
    label: const Text("Back",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );

  Widget _submitButton() => ElevatedButton.icon(
    onPressed: _isSubmitting ? null : _submitBanRequest,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      disabledBackgroundColor: Colors.red.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: _isSubmitting
        ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.gavel, color: Colors.white, size: 18),
    label: Text(
      _isSubmitting ? "Submitting..." : "Submit Request",
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      borderSide: const BorderSide(color: Color(0xFF14C38E), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}