import 'package:flutter/material.dart';
import '../models/inspection_record_model.dart';

class InspectionLogViewModel extends ChangeNotifier {
  // Form controllers
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final nameController = TextEditingController();
  final rankController = TextEditingController();
  final departmentController = TextEditingController();
  final reasonController = TextEditingController();
  final managerController = TextEditingController();

  // Mock list of recent visits
  List<InspectionRecordModel> _recentVisits = [
    InspectionRecordModel(
      id: '1',
      officialName: 'Officer John Smith',
      title: 'Senior Sergeant',
      type: 'Police',
      time: '10:30 AM',
      date: 'Feb 26, 2026',
      reason: 'Routine inspection',
      managerOnDuty: 'Sarah Williams',
    ),
    InspectionRecordModel(
      id: '2',
      officialName: 'Sarah Johnson',
      title: 'Inspector',
      type: 'Victoria Police Licensing (LRD)',
      time: '02:15 PM',
      date: 'Feb 25, 2026',
      reason: 'License compliance check',
      managerOnDuty: 'Michael Chen',
    ),
  ];

  List<InspectionRecordModel> get recentVisits => _recentVisits;

  void recordVisit() {
    // Collect data from controllers
    final newVisit = InspectionRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      officialName: nameController.text.isNotEmpty ? nameController.text : 'Unknown',
      title: rankController.text.isNotEmpty ? rankController.text : 'Unknown',
      type: departmentController.text.isNotEmpty ? departmentController.text : 'Other',
      time: timeController.text.isNotEmpty ? timeController.text : 'Now',
      date: dateController.text.isNotEmpty ? dateController.text : 'Today',
      reason: reasonController.text.isNotEmpty ? reasonController.text : 'None provided',
      managerOnDuty: managerController.text.isNotEmpty ? managerController.text : 'Unknown',
    );

    _recentVisits.insert(0, newVisit);
    
    // Clear form
    dateController.clear();
    timeController.clear();
    nameController.clear();
    rankController.clear();
    departmentController.clear();
    reasonController.clear();
    managerController.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    nameController.dispose();
    rankController.dispose();
    departmentController.dispose();
    reasonController.dispose();
    managerController.dispose();
    super.dispose();
  }
}
