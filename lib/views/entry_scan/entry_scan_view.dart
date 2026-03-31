import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/entry_scan_view_model.dart';
import '../../viewmodels/auth_provider.dart';
import '../../widgets/top_navigation_bar.dart';
import 'widgets/entry_details_dialog.dart';
import 'package:camera/camera.dart';
import 'face_capture_view.dart';
import 'qr_scanner_view.dart';

class EntryScanView extends StatelessWidget {
  const EntryScanView({super.key});

  Color _getStatusColor(String status) {
    if (status == 'ALLOWED') return const Color(0xFF00C97B); // Green
    if (status == 'WARNING') return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFB2C36); // Red (Denied/Expired)
  }

  String _getStatusText(String status) {
    if (status == 'ALLOWED') return 'ENTRY ALLOWED';
    if (status == 'WARNING') return 'ENTRY ALLOWED (WARNING)';
    if (status == 'EXPIRED') return 'ID EXPIRED';
    return 'ENTRY DENIED';
  }

  IconData _getStatusIcon(String status) {
    if (status == 'ALLOWED') return Icons.check;
    if (status == 'WARNING') return Icons.warning_amber_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2233),
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigationBar(currentRoute: '/entry_scan'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  final viewModel = context.watch<EntryScanViewModel>();

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        /// Flash Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () {
                              // Toggle flash if needed
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_off, size: 16),
                                  SizedBox(width: 6),
                                  Text("Flash Off", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// CARDS
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _scanCard(context, viewModel)),
                              const SizedBox(width: 16),
                              Expanded(child: _captureCard(context, viewModel)),
                              const SizedBox(width: 16),
                              Expanded(child: _resultCard(context, viewModel)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Bottom Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              viewModel.retakePhoto();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF19C37D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Scan Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMMON CARD =================
  Widget _cardContainer({
    required Widget child,
    required Color color,
    required Color borderColor,
  }) {
    return AspectRatio(
      aspectRatio: 350 / 800,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.36),
          border: Border.all(color: borderColor, width: 7),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }

  // ================= SCAN CARD =================
  Widget _scanCard(BuildContext context, EntryScanViewModel viewModel) {
    bool isLoading = viewModel.isScanning && !viewModel.isFaceCaptured;

    return _cardContainer(
      color: const Color(0xFF19C37D),
      borderColor: const Color(0xFF19C37D),
      child: Column(
        children: [
          const Text("Scan ID QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.greenAccent)
                    : const Icon(Icons.qr_code, color: Colors.greenAccent, size: 60),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () async {
              final token = context.read<AuthProvider>().token;
              if (token != null) {
                // Hardcoded QR string for testing without real IDs
                const String qrData = "P<AUSSMITH<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<\nPA12345678AUS9805151M3012311<<<<<<<<<<<<<<<4";
                viewModel.scanQrCode(qrData, token);
              }
            },
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text("Scan", style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          )
        ],
      ),
    );
  }

  // ================= CAPTURE CARD =================
  Widget _captureCard(BuildContext context, EntryScanViewModel viewModel) {
    bool isLoading = viewModel.isScanning && viewModel.isFaceCaptured;

    return _cardContainer(
      color: const Color(0xFF19C37D),
      borderColor: const Color(0xFF19C37D),
      child: Column(
        children: [
          const Text("Capture live facial image", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.greenAccent)
                    : const Icon(Icons.camera_alt, color: Colors.greenAccent, size: 60),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () async {
              final token = context.read<AuthProvider>().token;
              if (token != null) {
                final XFile? photo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaceCaptureView()),
                );

                if (photo != null) {
                  await viewModel.setCapturedPhoto(photo);
                  await viewModel.processEntry(token);
                }
              }
            },
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text("Click Photo", style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          )
        ],
      ),
    );
  }

  // ================= RESULT CARD =================
  Widget _resultCard(BuildContext context, EntryScanViewModel viewModel) {
    if (viewModel.scanResult == null) {
      if (viewModel.isScanning && viewModel.isFaceCaptured) {
        return _cardContainer(
          color: Colors.white,
          borderColor: const Color(0xFF19C37D),
          child: const Center(child: CircularProgressIndicator(color: Color(0xFF19C37D))),
        );
      }
      return _cardContainer(
        color: Colors.white,
        borderColor: const Color(0xFF19C37D),  
        child: const Center(child: Text('Awaiting Scan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
      );
    }

    final result = viewModel.scanResult!;
    String timeOnly = result.entryTime.split(' ').last;
    String dateOnly = result.entryTime.split(' ').first;

    if (result.verificationStatus == 'DENIED') {
      return AspectRatio(
        aspectRatio: 350 / 800,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFB2C36), width: 6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFB2C36).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFB2C36).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB2C36).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Color(0xFFFB2C36),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "ENTRY DENIED",
                style: TextStyle(
                  color: Color(0xFFFB2C36),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This person is BANNED",
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDeniedRow("Name", result.name, Colors.black87),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildDeniedRow("Ban Status", result.banStatus ?? "ACTIVE BAN", const Color(0xFFFB2C36)),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildDeniedRow("Reason", result.banReason ?? "Aggressive behavior", Colors.black87),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildDeniedRow("Banned By", result.bannedBy ?? "Mamao Club", Colors.black87),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildDeniedRow("Expiry", result.banExpiry ?? "Permanent", const Color(0xFFFB2C36)),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 350 / 800,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor(result.verificationStatus), width: 2),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(result.verificationStatus).withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Green check circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getStatusColor(result.verificationStatus),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(result.verificationStatus), 
                color: Colors.white, 
                size: 18
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: _getStatusColor(result.verificationStatus)),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(result.verificationStatus),
                        style: TextStyle(
                          color: _getStatusColor(result.verificationStatus),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.circle, size: 5, color: _getStatusColor(result.verificationStatus)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Entry History',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Photo block
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 80,
                    color: const Color(0xFFE0E0E0),
                    child: viewModel.capturedImage != null 
                        ? (kIsWeb 
                            ? Image.network(viewModel.capturedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(viewModel.capturedImage!.path), fit: BoxFit.cover))
                        : const Icon(Icons.person, size: 45, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),

            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '1st Entry',
                            style: TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            dateOnly,
                            style: const TextStyle(
                              color: Color(0xFF6B7A8D),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '• $timeOnly',
                            style: const TextStyle(
                              color: Color(0xFF6B7A8D),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if( result.verificationStatus == 'ALLOWED')
                Positioned(
                  bottom: 10,
                  right: 25,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => EntryDetailsDialog(scanResult: result),
                      );
                    },
                    child: _buildEditButton(),
                  ),
                ),
              ],
            ),

            Expanded(
               child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person_outline, 'Name:', result.name, Colors.black87),
                      _buildInfoRow(Icons.access_time_outlined, 'DOB:', result.dob, Colors.black87),
                      _buildInfoRow(Icons.location_on_outlined, 'Address:', result.address, Colors.black87),
                      _buildInfoRow(Icons.credit_card_outlined, 'ID No.:', result.idNo, Colors.black87),
                      _buildInfoRow(Icons.access_time_outlined, 'ID Expiry:', result.idExpiry, Colors.black87),
                      _buildInfoRow(Icons.face_outlined, 'Face Match Score:', result.faceMatchScore, const Color(0xFF00C97B)),

                      const SizedBox(height: 8),

                      if( result.verificationStatus == 'ALLOWED')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(result.verificationStatus), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getStatusIcon(result.verificationStatus), color: _getStatusColor(result.verificationStatus), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                result.verificationStatus == 'ALLOWED' ? 'Entry Logged Successfully' : 'Entry Recorded',
                                style: TextStyle(
                                  color: _getStatusColor(result.verificationStatus),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ]
                 )
               )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.edit, color: Colors.white, size: 10),
          SizedBox(width: 4),
          Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeniedRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7A8D),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8A9BB0)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7A8D),
              fontSize: 10,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
