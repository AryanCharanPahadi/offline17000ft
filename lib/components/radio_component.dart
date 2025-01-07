import 'package:flutter/material.dart';

class CustomRadioButton extends StatelessWidget {
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  final String label;
  final double screenWidth;
  final bool showError;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    required this.screenWidth,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.1),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
              ),
              Text(label),
            ],
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Please select an option',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }
}
