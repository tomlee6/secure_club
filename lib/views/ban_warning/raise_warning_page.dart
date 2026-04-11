
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:secureclub/viewmodels/auth_provider.dart';
import 'package:secureclub/viewmodels/ban_warning_view_model.dart';
import 'package:secureclub/widgets/top_navigation_bar.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/labelled_date_picker.dart';
import '../../widgets/labelled_date_time_picker.dart';
import '../../widgets/gender_radio_group.dart';

class RaiseWarningPage extends StatefulWidget {
  final String name;
  final String id;

  const RaiseWarningPage({
    super.key,
    required this.name,
    required this.id,
  });

  @override
  State<RaiseWarningPage> createState() => _RaiseWarningPageState();
}

class _RaiseWarningPageState extends State<RaiseWarningPage> {
  bool  _isSubmitting = false;
  XFile?     _evidenceXFile;
  File?      _evidenceFile;
  Uint8List? _evidenceBytes;

  final warningDescController = TextEditingController();
  DateTime? _dob;
  final genderController      = TextEditingController();
  DateTime? _entryDate;
  final firstNameController   = TextEditingController();
  final lastNameController    = TextEditingController();
  final idController          = TextEditingController();

  String selectedReason = "Select a reason...";
  final Map<String, String> reasonCategoryMap = {
    "Intoxicated":         "intoxication",
    "Aggressive Behavior": "aggressive_behavior",
    "Property Damage":     "property_damage",
    "Harassment":          "harassment",
    "Underage":            "underage",
    "Drug Use":            "drug_use",
    "Trespassing":         "trespassing",
    "Other":               "other",
  };
  List<String> get reasons => reasonCategoryMap.keys.toList();

  String get submissionTime {
    final now      = DateTime.now();
    final weekdays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    final months   = ["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"];
    final wd   = weekdays[now.weekday - 1];
    final mo   = months[now.month - 1];
    final h    = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m    = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? "PM" : "AM";
    return "$wd, $mo ${now.day}, ${now.year}, $h:$m:${now.second.toString().padLeft(2,'0')} $ampm";
  }

  String get _expiryDate {
    final exp = DateTime.now();
    final d   = DateTime(exp.year, exp.month + 6, exp.day);
    return "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
  }

  @override
  void initState() {
    super.initState();
    final parts = widget.name.trim().split(' ');
    firstNameController.text = parts.isNotEmpty ? parts.first : '';
    lastNameController.text  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    idController.text        = widget.id;
  }

  @override
  void dispose() {
    warningDescController.dispose();
    genderController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    idController.dispose();
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

  void _saveWarning() {
    if (selectedReason == "Select a reason...") {
      _showError("Please select a warning reason.");
      return;
    }
    if (firstNameController.text.trim().isEmpty) {
      _showError("Please enter the patron's first name.");
      return;
    }
    if (idController.text.trim().isEmpty) {
      _showError("Please enter the ID number.");
      return;
    }
    if (warningDescController.text.trim().isEmpty) {
      _showError("Please enter a warning description.");
      return;
    }

    _showConfirmationPopup();
  }

  Future<void> _executeSaveWarning() async {
    setState(() => _isSubmitting = true);

    final baseUrl = ApiConstants.baseUrl;
    final authProvider = context.read<AuthProvider>();
    final token   = authProvider.token ?? '';
    final rawClub = authProvider.user?.club;
    final clubId  = (rawClub is Map) ? rawClub['id'] : (rawClub is int ? rawClub : null);

    final body = <String, dynamic>{
      "club_id":           clubId ?? 1,
      "person_first_name": firstNameController.text.trim(),
      "person_last_name":  lastNameController.text.trim().isNotEmpty
          ? lastNameController.text.trim()
          : "",
      "id_number":         idController.text.trim(),
      "reason":            selectedReason,
      "description":       warningDescController.text.trim(),
    };

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 SAVE WARNING — POST $baseUrl/api/v1/bans/warnings');
    debugPrint('📦 BODY:');
    debugPrint(const JsonEncoder.withIndent('  ').convert(body));
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/bans/warnings'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📥 SAVE WARNING — RESPONSE [${response.statusCode}]');
      try {
        debugPrint(const JsonEncoder.withIndent('  ')
            .convert(jsonDecode(response.body)));
      } catch (_) {
        debugPrint(response.body);
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final responseData = jsonDecode(response.body);
      final isSuccess    = (response.statusCode == 200 ||
          response.statusCode == 201) &&
          (responseData['success'] == true);

      if (isSuccess) {
        final warningId = responseData['data']?['warning_id'];
        debugPrint('✅ Warning saved! warning_id=$warningId');

        if (_hasImage && warningId != null) {
          debugPrint('ℹ️  Skipping evidence upload for warnings (not supported).');
        } else {
          debugPrint('ℹ️  No evidence file or unsupported.');
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          final t = context.read<AuthProvider>().token ?? '';
          context.read<BanWarningViewModel>().fetchWarnings(t);
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        final msg = responseData['error']?['message']
            ?? responseData['message']
            ?? 'Failed to save warning.';
        debugPrint('❌ Warning save FAILED: $msg');
        setState(() => _isSubmitting = false);
        _showError(msg);
      }
    } catch (e) {
      debugPrint('💥 Warning save EXCEPTION: $e');
      setState(() => _isSubmitting = false);
      _showError('Network error: $e');
    }
  }

  Future<void> _uploadEvidence({
    required int    banId,
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

  void _showConfirmationPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        void closeDone() {
          Navigator.of(dialogCtx).pop();
          _executeSaveWarning();
        }

        void closeCancel() {
          Navigator.of(dialogCtx).pop();
        }

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
                            "Warning Submitted",
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
                  ]),
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
                                  _detailItem(
                                    "Patron Name",
                                    "${firstNameController.text} "
                                        "${lastNameController.text}"
                                        .trim(),
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem(
                                    "ID Number",
                                    idController.text,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem(
                                    "Warning Reason",
                                    selectedReason,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem(
                                    "Ban Type",
                                    'TEMPORARY',
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem(
                                    "Expires",
                                    _expiryDate,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailItem(
                                    "Description",
                                    warningDescController.text.trim(),
                                  ),
                                  const SizedBox(height: 12),
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
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: _hasImage
                                  ? ClipRRect(
                                borderRadius:
                                BorderRadius.circular(12),
                                child: _buildImage(),
                              )
                                  : const Icon(Icons.person,
                                  size: 44, color: Colors.grey),
                            ),
                          ],
                        ),

                        if (warningDescController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          _detailItem(
                            "Description",
                            warningDescController.text.trim(),
                          ),
                        ],

                        if (_hasImage) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          Text(
                            "Evidence",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: _buildImage()
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
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close,
                              color: Colors.black54, size: 16),
                          label: const Text(
                            "Cancel",
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: closeDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D492),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check,
                              color: Colors.black, size: 16),
                          label: const Text(
                            "Done",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
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
              "Add Warning",
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
                      padding: EdgeInsets.all(
                          screenWidth < 600 ? 20 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        final isMobile = constraints.maxWidth < 700;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ══ PATRON DETAILS ══
                            _sectionLabel("PATRON DETAILS"),
                            const SizedBox(height: 16),

                            // ── Entry Photo (top, like ban page) ──
                            _entryPhotoWidget(),

                            const SizedBox(height: 20),

                            // ── Patron Name + ID Number side by side ──
                            isMobile
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _patronNameField(),
                                const SizedBox(height: 16),
                                _idNumberField(),
                              ],
                            )
                                : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _patronNameField()),
                                const SizedBox(width: 20),
                                Expanded(child: _idNumberField()),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── Date of Birth + Gender ──
                            _twoColumns(isMobile,
                              left: LabelledDatePicker(
                                  label: "Date of Birth",
                                  selectedDate: _dob,
                                  onDateSelected: (date) => setState(() => _dob = date),
                                  hintText: "dd/mm/yyyy",
                                  lastDate: DateTime.now(),
                              ),
                              right: GenderRadioGroup(
                                initialValue: genderController.text.isNotEmpty ? genderController.text : null,
                                onChanged: (val) {
                                  genderController.text = val;
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Entry Date/Time (full width) ──
                            LabelledDateTimePicker(
                              label: "Entry Date/Time",
                              selectedDate: _entryDate,
                              onDateSelected: (date) => setState(() => _entryDate = date),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE)),
                            ),

                            // ══ INCIDENT DETAILS ══
                            _sectionLabel("INCIDENT DETAILS"),
                            const SizedBox(height: 16),

                            _fieldLabel("Warning Reason *"),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedReason,
                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                              items: [
                                const DropdownMenuItem(
                                    value: "Select a reason...",
                                    child: Text("Select a reason...", style: TextStyle(color: Colors.black87))),
                                ...reasons.map((r) => DropdownMenuItem(
                                    value: r, child: Text(r, style: const TextStyle(color: Colors.black87)))),
                              ],
                              onChanged: (v) =>
                                  setState(() => selectedReason = v!),
                              decoration: _inputDecoration(),
                            ),
                            const SizedBox(height: 20),

                            _fieldLabel("Warning Note Description *"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: warningDescController,
                              style: const TextStyle(color: Colors.black87),
                              maxLines: 5,
                              decoration: _inputDecoration().copyWith(
                                hintText:
                                "Provide a detailed account of the incident, "
                                    "including time, location, and specific actions observed...",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13),
                              ),
                            ),

                            const SizedBox(height: 24),

                            _fieldLabel("Warning Submission Time"),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(submissionTime,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "This will be recorded when you submit the warning",
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

                            // ══ EVIDENCE ══
                            Row(children: [
                              const Text("Evidence (Optional)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(width: 8),
                              Text("Support your request with media",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13)),
                            ]),
                            const SizedBox(height: 14),

                            GestureDetector(
                              onTap: _pickEvidence,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: _hasImage
                                    ? ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: _buildImage(),
                                )
                                    : Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons.camera_alt_outlined,
                                        size: 40,
                                        color:
                                        Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text("Capture Photo",
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "or tap to pick from gallery",
                                      style: TextStyle(
                                          color:
                                          Colors.grey.shade500,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Action Buttons ──
                            isMobile
                                ? Column(children: [
                              SizedBox(
                                  width: double.infinity,
                                  child: _backButton()),
                              const SizedBox(height: 12),
                              SizedBox(
                                  width: double.infinity,
                                  child: _saveButton()),
                            ])
                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _backButton(),
                                _saveButton(),
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

  // ─────────────────────────────────────────────────────
  // Entry Photo Widget (matches Figma — top of patron section)
  // ─────────────────────────────────────────────────────
  Widget _entryPhotoWidget() {
    return GestureDetector(
      onTap: _pickEvidence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Entry Photo"),
          const SizedBox(height: 8),
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
                    size: 44, color: Colors.grey.shade400),
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

  // ─────────────────────────────────────────────────────
  // Patron Name Field
  // ─────────────────────────────────────────────────────
  Widget _patronNameField() {
    // Combine first + last into a single display field (read-only from init,
    // but editable — mirrors ban page "Patron Name" single field)
    final combinedController = TextEditingController(
      text: [firstNameController.text, lastNameController.text]
          .where((s) => s.isNotEmpty)
          .join(' '),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Patron Name"),
        const SizedBox(height: 6),
        TextField(
          controller: firstNameController,
          style: const TextStyle(color: Colors.black87),
          onChanged: (val) {
            final parts = val.trim().split(' ');
            firstNameController.text = parts.isNotEmpty ? parts.first : '';
            lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
            // keep cursor at end
            firstNameController.selection = TextSelection.fromPosition(
                TextPosition(offset: firstNameController.text.length));
          },
          decoration: _inputDecoration().copyWith(
            hintText: "Full name",
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // ID Number Field
  // ─────────────────────────────────────────────────────
  Widget _idNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("ID Number *"),
        const SizedBox(height: 6),
        TextField(
          controller: idController,
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDecoration().copyWith(
            hintText: "e.g. NSW-12345678",
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────
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
      style: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 14));

  Widget _backButton() => ElevatedButton.icon(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ),
    icon: const Icon(Icons.arrow_back,
        color: Colors.white, size: 18),
    label: const Text("Back",
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold)),
  );

  Widget _saveButton() => ElevatedButton.icon(
    onPressed: _isSubmitting ? null : _saveWarning,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      disabledBackgroundColor: Colors.orange.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(
          horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ),
    icon: _isSubmitting
        ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.warning_amber_rounded,
        color: Colors.white, size: 18),
    label: Text(
      _isSubmitting ? "Saving..." : "Save Warning",
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
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 14),
  );
}