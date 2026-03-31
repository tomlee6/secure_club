import 'package:flutter/material.dart';
import '../../../models/entry_scan_result.dart'; // assuming location

class EntryDetailsDialog extends StatefulWidget {
  final EntryScanResult? scanResult;

  const EntryDetailsDialog({super.key, this.scanResult});

  @override
  State<EntryDetailsDialog> createState() => _EntryDetailsDialogState();
}

class _EntryDetailsDialogState extends State<EntryDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _idNoController;
  late TextEditingController _idExpiryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scanResult?.name ?? '');
    _dobController = TextEditingController(text: widget.scanResult?.dob ?? '');
    _addressController = TextEditingController(text: widget.scanResult?.address ?? '');
    _idNoController = TextEditingController(text: widget.scanResult?.idNo ?? '');
    _idExpiryController = TextEditingController(text: widget.scanResult?.idExpiry ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _idNoController.dispose();
    _idExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF152433),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    "• ENTRY DETAILS •",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white70),
                  )
                ],
              ),

              const SizedBox(height: 30),

              /// MAIN CONTENT
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    /// LEFT FORM
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _field("Full Name *", "Enter full name", _nameController),
                          _field("DOB *", "Enter DOB", _dobController),
                          _field("Address *", "Enter Address", _addressController),
                          _field("ID No *", "Enter ID no", _idNoController),
                          _field("ID Expiry *", "Enter ID Expiry", _idExpiryController),
                        ],
                      ),
                    ),

                    const Spacer(),

                    /// RIGHT ID PHOTO
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "ID Photo",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),

                          /// Matches height automatically because of IntrinsicHeight on the Row
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0XFF4A5565),

                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF6A7282),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.badge, size: 50, color: Colors.white70),
                                    SizedBox(height: 10),
                                    Text(
                                      "Ready to scan person ID",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Matches padding of the last field on the left
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  /// LEFT FORM
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _button("Save", Icons.save, () => Navigator.of(context).pop())
                      ],
                    ),
                  ),

                  const Spacer(),

                  /// RIGHT ID PHOTO
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _button("ID Photo", Icons.camera_alt, () {})
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 30,)
            ],
          ),
        ),
      ),
    );
  }

  // /// 🔥 FIELD
  Widget _field(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 6),

          Container(
            height: 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),

              // ✅ Outer border (red)
              border: Border.all(color: Color(0xFF6A7282), width: 1.3),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white70),

                // ✅ Inner fill color
                filled: true,
                fillColor: Color(0xFF4A5565),


                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }








  /// 🔥 BUTTON
  Widget _button(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
