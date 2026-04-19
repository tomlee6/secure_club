import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../viewmodels/ban_warning_view_model.dart';
import '../../viewmodels/auth_provider.dart';
import '../../widgets/top_navigation_bar.dart';
import '../../widgets/custom_date_picker.dart';
import 'package:go_router/go_router.dart';
import 'ban_request_detail_page.dart';
import 'edit_ban_request_popup.dart';
import 'ban_details_expand_popup.dart';

class BanWarningView extends StatefulWidget {
  const BanWarningView({super.key});

  @override
  State<BanWarningView> createState() => _BanWarningViewState();
}

class _BanWarningViewState extends State<BanWarningView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      context.read<BanWarningViewModel>().clearFilters(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigationBar(currentRoute: '/ban_warning'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Ban & Warning Requests',
                style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView( 
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth > 1000
                            ? 800
                            : constraints.maxWidth * 0.90,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Consumer<BanWarningViewModel>(
                          builder: (context, viewModel, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 16),
                                _buildTabs(viewModel),
                                const SizedBox(height: 16),
                                _buildSearchBar(viewModel),
                                const SizedBox(height: 16),
                                _buildTable(viewModel),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Ban & Warning Requests list",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                "Review and manage ban requests from guards",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              )
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                context.push('/raise_warning', extra: {'name': '', 'id': ''});
              },
              child: _topButton("Add Warning", Colors.orange),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                context.push('/raise_ban_request', extra: {'name': '', 'id': ''});
              },
              child: _topButton("Add Ban Request", Colors.blue),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTabs(BanWarningViewModel viewModel) {
    final token = context.read<AuthProvider>().token ?? '';
    return Row(
      children: [
        GestureDetector(
          onTap: () => viewModel.setTabIndex(0, token),
          child: _tabButton("Ban Request List", viewModel.selectedTabIndex == 0),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => viewModel.setTabIndex(1, token),
          child: _tabButton("Warning List", viewModel.selectedTabIndex == 1),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BanWarningViewModel viewModel) {
    bool isWarningTab = viewModel.selectedTabIndex == 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00D492),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        final token = context.read<AuthProvider>().token ?? '';
                        viewModel.setSearchQuery(val, token);
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        hintText: "Search by Name, ID, DOB...",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 2),

                        // Borders
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: isWarningTab ? 5 : 2,
            child: isWarningTab 
                ? Row(
                    children: [
                      const Text("From Date:", style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomDatePicker(
                          selectedDate: viewModel.fromDate,
                          onDateSelected: (date) {
                            final token = context.read<AuthProvider>().token ?? '';
                            viewModel.setFromDate(date, token);
                          },
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("To Date:", style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomDatePicker(
                          selectedDate: viewModel.toDate,
                          onDateSelected: (date) {
                            final token = context.read<AuthProvider>().token ?? '';
                            viewModel.setToDate(date, token);
                          },
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final token = context.read<AuthProvider>().token ?? '';
                          viewModel.clearFilters(token);
                        },
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Clear",
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _dropdown(viewModel.selectedTime, (val) {
                        final token = context.read<AuthProvider>().token ?? '';
                        viewModel.setTimeFilter(val, token);
                      }, ["All", "Today", "Yesterday", "Last 7 Days"], "Time: ")),
                      const SizedBox(width: 8),
                      Expanded(child: _dropdown(viewModel.selectedType, (val) {
                        final token = context.read<AuthProvider>().token ?? '';
                        viewModel.setTypeFilter(val, token);
                      }, ["All", "Temporary", "Permanent"], "Type: ")),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String warningId, BanWarningViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Warning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const Text("Are you sure you want to delete this warning?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final token = context.read<AuthProvider>().token ?? '';
                final success = await viewModel.deleteWarning(warningId, token);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to delete warning", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                  );
                } else if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Warning deleted successfully", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable(BanWarningViewModel viewModel) {
    bool isTabZero = viewModel.selectedTabIndex == 0;
    int itemsCount = isTabZero ? viewModel.banRequests.length : viewModel.warnings.length;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// HEADER
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text("NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                if (isTabZero)
                   const Expanded(flex: 2, child: Text("START DATE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                if (!isTabZero)
                   const Expanded(flex: 2, child: Text("REASON", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(isTabZero ? "EXPIRY DATE" : "DATE", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                if (isTabZero)
                  const Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text("ACTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          /// ROWS
          viewModel.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator(color:  Color(0xFF00D492),)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemsCount,
                itemBuilder: (context, index) {
                    if (isTabZero) {
                      final item = viewModel.banRequests[index];
                      String formattedExpiry = 'Unknown';
                      if (item.banExpiryDate != null && item.banExpiryDate!.isNotEmpty && item.banExpiryDate != 'null') {
                        try {
                          final date = DateTime.parse(item.banExpiryDate!).toLocal();
                          formattedExpiry = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        } catch (_) {
                          formattedExpiry = item.banExpiryDate!;
                        }
                      }
                      
                      String formattedRequestedOn = 'Unknown';
                      if (item.requestedAt != null && item.requestedAt!.isNotEmpty) {
                        try {
                          final date = DateTime.parse(item.requestedAt!).toLocal();
                          const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                          final monthName = months[date.month - 1].toLowerCase();
                          formattedRequestedOn = "${date.day.toString().padLeft(2, '0')} $monthName ${date.year}";
                        } catch (_) {
                          formattedRequestedOn = item.requestedAt!;
                        }
                      }

                      return TableRowNew(
                        item.name,
                        formattedRequestedOn,
                        formattedExpiry,
                        startDate: formattedRequestedOn,
                        status: item.status,
                        isBanRequest: true,
                        onView: () {
                          showDialog(
                            context: context,
                            builder: (_) => BannedDetailsPopup(banRequest: item),
                          );
                        },
                        onEdit: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => EditBanRequestPage(banRequest: item)));
                          if (mounted) {
                            final token = context.read<AuthProvider>().token ?? '';
                            viewModel.fetchBanRequests(token);
                          }
                        },
                      );
                    } else {
                      final item = viewModel.warnings[index];
                      return TableRowNew(
                        item.name,
                        item.warningReason,
                        item.date,
                        isBanRequest: false,
                        onView: () {
                          showDialog(
                            context: context,
                            builder: (_) => BannedDetailsPopup(warning: item),
                          );
                        },
                        onDelete: () => _showDeleteConfirmation(item.id, viewModel),
                      );
                    }
                  },
                ),

          /// FOOTER
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Page ${viewModel.currentPage} of ${viewModel.totalPages}", style: const TextStyle(fontSize: 12)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final token = context.read<AuthProvider>().token ?? '';
                        viewModel.changePage(-1, token);
                      },
                      child: _pageButton("<", false),
                    ),
                    const SizedBox(width: 4),
                    ..._buildPageNumbers(context, viewModel),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final token = context.read<AuthProvider>().token ?? '';
                        viewModel.changePage(1, token);
                      },
                      child: _pageButton(">", false),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// HELPERS

  Widget _topButton(String text, Color color) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tabButton(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ?   Color(0xFF00D492) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all( color: Color(0xFF00D492),),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white :  Color(0xFF00D492),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _dropdown(String value, Function(String) onChanged, List<String> options, String label) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87),

          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },

          selectedItemBuilder: (BuildContext context) {
            return options.map((String val) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: const TextStyle(
                          fontSize: 13,
                          color:  Color(0xFF64748B),
                        ),
                      ),
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              );
            }).toList();
          },

          items: options.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val, // dropdown list still shows normal values
                overflow: TextOverflow.ellipsis,

              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget _dropdown(String value, Function(String) onChanged, List<String> options) {
  //   return Container(
  //     height: 30,
  //     padding: const EdgeInsets.symmetric(horizontal: 10),
  //     decoration: BoxDecoration(
  //       color: Color(0xFFFFFFFF),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: DropdownButtonHideUnderline(
  //       child: DropdownButton<String>(
  //         value: value,
  //         isExpanded: true,
  //         icon: const Icon(Icons.keyboard_arrow_down, size: 18,color: Color(0xFF0F172A),),
  //         style: const TextStyle(fontSize: 13, color: Colors.black87),
  //         onChanged: (String? newValue) {
  //           if (newValue != null) {
  //             onChanged(newValue);
  //           }
  //         },
  //         items: options.map<DropdownMenuItem<String>>((String val) {
  //           return DropdownMenuItem<String>(
  //             value: val,
  //             child: Text(
  //               val.startsWith("Time:") || val.startsWith("Type:") ? val : val,
  //               overflow: TextOverflow.ellipsis
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ),
  //   );
  // }

  List<Widget> _buildPageNumbers(BuildContext context, BanWarningViewModel viewModel) {
    if (viewModel.totalPages < 1) return [];

    List<Widget> buttons = [];
    int start = (viewModel.currentPage - 1).clamp(1, viewModel.totalPages);
    if (start + 2 > viewModel.totalPages && viewModel.totalPages >= 3) {
      start = viewModel.totalPages - 2;
    }
    
    int end = (start + 2).clamp(1, viewModel.totalPages);
    
    for (int i = start; i <= end; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () {
              final token = context.read<AuthProvider>().token ?? '';
              viewModel.setPage(i, token);
            },
            child: _pageButton("$i", viewModel.currentPage == i),
          ),
        )
      );
    }
    return buttons;
  }

  Widget _pageButton(String text, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ?  Color(0xFF00D492) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: active ? Colors.white : Colors.black, fontSize: 12),
      ),
    );
  }
}

class TableRowNew extends StatelessWidget {
  final String name, duration, date;
  final String? startDate;
  final String? status;
  final bool isBanRequest;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TableRowNew(this.name, this.duration, this.date, {this.startDate, this.status, this.isBanRequest = true, this.onView, this.onEdit, this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          if (isBanRequest)
            Expanded(flex: 2, child: Text(startDate ?? '', style: const TextStyle(fontSize: 13))),
          if (!isBanRequest)
            Expanded(flex: 2, child: Text(duration, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13))),
          if (isBanRequest)
            Expanded(
              flex: 2, 
              child: Text(
                (status ?? '').toUpperCase(), 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: (status ?? '').toLowerCase() == 'pending' ? Colors.orange : Colors.green
                )
              )
            ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onView,
                  child: _iconBtn(Icons.visibility, const Color(0xFF00D492)),
                ),
                const SizedBox(width: 8),
                isBanRequest 
                    ? GestureDetector(
                        onTap: onEdit,
                        child: _iconBtn(Icons.edit, Colors.orange),
                      )
                    : GestureDetector(
                        onTap: onDelete,
                        child: _iconBtn(Icons.delete, Colors.red),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _iconBtn(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, color: Colors.white, size: 14),
  );
}
