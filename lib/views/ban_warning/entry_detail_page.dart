import 'package:flutter/material.dart';
import 'package:secureclub/views/ban_warning/raise_ban_request_page.dart' show RaiseBanRequestPage;
import '../inspection_log/entry_logs_provider.dart' show EntryLogModel;
import '../../widgets/top_navigation_bar.dart';


class EntryDetailsPage extends StatelessWidget {
  final EntryLogModel entry;

  const EntryDetailsPage({super.key, required this.entry});

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "${dt.day}/${dt.month}/${dt.year}  $h:$m";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isAllowed = entry.status == 'allowed';

    double horizontalPadding = screenWidth < 600
        ? 16
        : screenWidth < 1100
        ? 24
        : 20;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: TopNavigationBar(currentRoute: '/entry_scan'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth < 600 ? 20 : 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1E2D),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Back to Entry Logs",
                                  style: TextStyle(
                                    color: Color(0xFF0B1E2D),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 700;
                              return isMobile
                                  ? Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  _profileImage(isMobile),
                                  const SizedBox(height: 20),
                                  _detailsSection(
                                      context, isMobile, isAllowed),
                                ],
                              )
                                  : Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _profileImage(isMobile),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: _detailsSection(
                                        context, isMobile, isAllowed),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _profileImage(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        "https://i.pravatar.cc/300",
        width: isMobile ? 140 : 180,
        height: isMobile ? 180 : 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: isMobile ? 140 : 180,
          height: isMobile ? 180 : 220,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2B3C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _detailsSection(
      BuildContext context, bool isMobile, bool isAllowed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // NAME + STATUS BADGE
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              entry.visitorName,
              style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAllowed
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAllowed ? Icons.check_circle : Icons.cancel,
                    color: isAllowed ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAllowed ? "Verified" : "Denied",
                    style: TextStyle(
                      color: isAllowed ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _infoRow("Member ID", entry.idNumber, isMobile),
        _infoRow("Club", entry.club, isMobile),
        _infoRow("Guard", entry.guard, isMobile),
        _infoRow("Entry Type", entry.entryType.toUpperCase(), isMobile),
        _infoRow("Status", entry.status.toUpperCase(), isMobile,
            valueColor: isAllowed ? Colors.green : Colors.red),

        if (!isAllowed &&
            entry.denialReason != null &&
            entry.denialReason!.isNotEmpty)
          _infoRow("Denial Reason", entry.denialReason!, isMobile,
              valueColor: Colors.red),

        const SizedBox(height: 25),

        const Text("Access Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        Wrap(
          spacing: isMobile ? 20 : 50,
          runSpacing: 20,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ENTRY TIME",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Text(_formatTime(entry.loggedAt),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ENTRY TYPE",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.entryType == 'entry'
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry.entryType.toUpperCase(),
                      style: TextStyle(
                          color: entry.entryType == 'entry'
                              ? Colors.blueAccent
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MATCH SCORE",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                const Text("N/A",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RaiseBanRequestPage(
                    name: entry.visitorName,
                    id: entry.idNumber,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.warning, color: Colors.white),
            label: const Text("Raise Ban Request",
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isMobile,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text("$label:",
                style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87)),
          ),
        ],
      ),
    );
  }
}