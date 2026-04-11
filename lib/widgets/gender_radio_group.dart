import 'package:flutter/material.dart';

class GenderRadioGroup extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const GenderRadioGroup({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<GenderRadioGroup> createState() => _GenderRadioGroupState();
}

class _GenderRadioGroupState extends State<GenderRadioGroup> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue ?? 'Male';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selectedValue!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadio('Male'),
            const SizedBox(width: 16),
            _buildRadio('Female'),
            const SizedBox(width: 16),
            _buildRadio('Others'),
          ],
        ),
      ],
    );
  }

  Widget _buildRadio(String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedValue = value;
          widget.onChanged(value);
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _selectedValue,
            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF00D492);
              }
              return Colors.grey.shade700;
            }),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedValue = newValue;
                  widget.onChanged(newValue);
                });
              }
            },
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          )
        ],
      ),
    );
  }
}
