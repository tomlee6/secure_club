import 'package:flutter/material.dart';
import '../../models/ban_request_model.dart';

class BannedDetailsPopup extends StatelessWidget {
  final BanRequestModel? banRequest;
  final WarningModel? warning;

  const BannedDetailsPopup({super.key, this.banRequest, this.warning});

  @override
  Widget build(BuildContext context) {
    final String patronName =
        banRequest?.name ?? warning?.name ?? "Michael Brown";

    final String idNumber =
        (banRequest?.idNumber.isNotEmpty == true) ? banRequest!.idNumber 
        : (warning?.idNumber.isNotEmpty == true) ? warning!.idNumber 
        : "NSW DL: 87654321";

    final String banReason =
        banRequest?.reason ??
            warning?.warningReason ??
            "Aggressive behavior";

    String description =
        "Patron became aggressive after being asked to leave the VIP area. Verbal threats were made to staff.";

    if (banRequest?.reasonCategory.isNotEmpty == true) {
      description = banRequest!.reasonCategory;
    } else if (warning != null && warning!.warningCount > 0) {
      description = "Warning issued by ${warning!.guardName}. Total warnings: ${warning!.warningCount}.";
    }

    final String duration = banRequest?.banDuration ?? "1 Month";

    final String imageUrl =
        banRequest?.faceImageUrl ??
            "https://randomuser.me/api/portraits/women/44.jpg";

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Banned Details",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black, // ✅ FIXED
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),

              const SizedBox(height: 3),


              Divider(
                color: Colors.grey.shade400,
                thickness: 0.3,
              ),
              const SizedBox(height: 3),

              /// CONTENT
              Flexible(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isMobile = constraints.maxWidth < 300;

                      final contentBody = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label("Patron Name"),
                          value(patronName),
                          const SizedBox(height: 10),

                          label("ID Number"),
                          value(idNumber),
                          const SizedBox(height: 10),

                          label("Ban Reason"),
                          value(banReason),
                          const SizedBox(height: 10),

                          label("Description"),
                          value(description),
                          const SizedBox(height: 10),

                          label("Duration"),
                          value(duration),
                          const SizedBox(height: 10),

                          if (banRequest != null) ...[
                            label("Start Date"),
                            value(banRequest!.requestedOn),
                            const SizedBox(height: 10),
                          ],

                          label("Evidence"),
                          const SizedBox(height: 8),

                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child:
                            const Icon(Icons.image_outlined),
                          ),
                        ],
                      );

                      final imageBody = Container(
                        width: isMobile ? double.infinity : 110,
                        height: isMobile ? 200 : 140,
                        margin: EdgeInsets.only(
                            bottom: isMobile ? 20 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.blueGrey, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            imageBody,
                            contentBody,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(child: contentBody),
                          const SizedBox(width: 20),
                          imageBody,
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// CANCEL BUTTON
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,
                      size: 18, color: Colors.white),
                  label: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// LABEL STYLE
  Widget label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
    );
  }

  /// VALUE STYLE (UPDATED)
  Widget value(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12, // ✅ UPDATED
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}