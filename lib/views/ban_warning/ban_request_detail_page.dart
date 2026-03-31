import 'package:flutter/material.dart';
import '../../models/ban_request_model.dart';
import '../../widgets/top_navigation_bar.dart';
import 'raise_ban_request_page.dart';/// Detail page works for both Ban Requests and Active Bans.
/// Pass either [banRequest] or [activeBan], not both.
class BanRequestDetailPage extends StatelessWidget {
  final BanRequestModel? banRequest;
  final ActiveBanModel? activeBan;

  const BanRequestDetailPage({
    super.key,
    this.banRequest,
    this.activeBan,
  }) : assert(banRequest != null || activeBan != null,
  'Provide either banRequest or activeBan');

  // ── Helpers ──
  String get _name => banRequest?.personName ?? activeBan?.personName ?? '';
  String get _idNumber => banRequest?.idNumber ?? activeBan?.idNumber ?? '';
  String get _banType => banRequest?.banType ?? activeBan?.banType ?? '';
  String get _status => banRequest?.status ?? activeBan?.status ?? '';
  String? get _reason => banRequest?.reason ?? activeBan?.reason;
  String get _requestedBy => banRequest?.requestedBy ?? '—';
  int get _evidenceCount => banRequest?.evidenceCount ?? 0;
  String? get _requestedAt => banRequest?.requestedAt;

  // ✅ FIX: ActiveBanModel uses `requestedAt` (not `bannedAt`) — matches API response
  String? get _bannedAt => activeBan?.requestedAt;
  String? get _expiresAt => activeBan?.expiresAt;

  // ✅ FIX: ActiveBanModel has `approvedBy` (not in BanRequestModel)
  String? get _approvedBy => activeBan?.approvedBy;

  String? get _faceImageUrl =>
      banRequest?.faceImageUrl ?? activeBan?.faceImageUrl;

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final h =
      dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}  ${h.toString().padLeft(2, '0')}:$min $ampm";
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _showWhiteSnackBar(BuildContext context, String message,
      {bool isError = false}) {
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
                message,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final hPad =
    screenWidth < 600 ? 16.0 : screenWidth < 1100 ? 24.0 : 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: TopNavigationBar(currentRoute: '/ban_warning'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Back ──
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1E2D),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_back,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  banRequest != null
                                      ? "Back to Ban Requests"
                                      : "Back to Warning List",
                                  style: const TextStyle(
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
                              final mob = constraints.maxWidth < 700;
                              return mob
                                  ? Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _avatar(mob),
                                  const SizedBox(height: 20),
                                  _details(context, mob),
                                ],
                              )
                                  : Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _avatar(mob),
                                  const SizedBox(width: 30),
                                  Expanded(
                                      child: _details(context, mob)),
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

  Widget _avatar(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _faceImageUrl != null
          ? Image.network(
        _faceImageUrl!,
        width: isMobile ? 140 : 180,
        height: isMobile ? 180 : 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(isMobile),
      )
          : _avatarFallback(isMobile),
    );
  }

  Widget _avatarFallback(bool isMobile) {
    return Container(
      width: isMobile ? 140 : 180,
      height: isMobile ? 180 : 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2B3C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.person, size: 60, color: Colors.white38),
    );
  }

  Widget _details(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name + status badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              _name,
              style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(_status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      color: _statusColor(_status), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _status.toUpperCase(),
                    style: TextStyle(
                        color: _statusColor(_status),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _infoRow("ID Number", _idNumber, isMobile),
        _infoRow("Ban Type", _banType.toUpperCase(), isMobile,
            valueColor: _banType == 'permanent'
                ? Colors.red[700]
                : Colors.orange[700]),

        if (_reason != null && _reason!.isNotEmpty)
          _infoRow("Reason", _reason!, isMobile),

        // ── Ban Request specific fields ──
        if (banRequest != null) ...[
          _infoRow("Requested By", _requestedBy, isMobile),
          _infoRow("Requested At", _fmt(_requestedAt), isMobile),
          _infoRow("Evidence Count", "$_evidenceCount file(s)", isMobile),
          _infoRow(
            "Reason Category",
            banRequest!.reasonCategory.replaceAll('_', ' ').toUpperCase(),
            isMobile,
          ),
        ],

        // ── Active Ban specific fields ──
        // ✅ FIX: Use `requestedAt` field (API returns requested_at, not banned_at)
        if (activeBan != null) ...[
          if (_approvedBy != null && _approvedBy!.isNotEmpty)
            _infoRow("Approved By", _approvedBy!, isMobile),
          _infoRow("Banned At", _fmt(_bannedAt), isMobile),
          _infoRow(
            "Expires",
            _banType == 'permanent'
                ? 'Never (Permanent)'
                : _fmt(_expiresAt),
            isMobile,
            valueColor:
            _banType == 'permanent' ? Colors.red[700] : null,
          ),
          if (activeBan!.banScope.isNotEmpty)
            _infoRow("Scope", activeBan!.banScope.toUpperCase(), isMobile),
        ],

        const SizedBox(height: 32),

        // ── Ban type visual card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _banType == 'permanent'
                ? Colors.red.withOpacity(0.08)
                : Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _banType == 'permanent'
                  ? Colors.red.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _banType == 'permanent' ? Icons.block : Icons.timer_off,
                color:
                _banType == 'permanent' ? Colors.red : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _banType == 'permanent'
                          ? 'Permanent Ban'
                          : 'Temporary Ban',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _banType == 'permanent'
                              ? Colors.red[700]
                              : Colors.orange[700]),
                    ),
                    Text(
                      _banType == 'permanent'
                          ? 'This person is banned indefinitely'
                          : 'This ban will expire at the set date',
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Raise / update ban button ──
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => RaiseBanRequestPage(
                    name: _name,
                    id: _idNumber,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                _showWhiteSnackBar(
                    context, 'Ban request submitted successfully!');
              }
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
            width: 140,
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