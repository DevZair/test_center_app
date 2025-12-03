import 'package:flutter/material.dart';

class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.hint,
    required this.options,
    required this.onChanged,
    required this.labelBuilder,
    this.value,
    this.validator,
  });

  final String hint;
  final List<T> options;
  final T? value;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?> onChanged;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      decoration: InputDecoration(hintText: hint),
      items: options.map((option) {
        return DropdownMenuItem<T>(
          value: option,
          child: Text(labelBuilder(option)),
        );
      }).toList(),
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
