import 'package:flutter/material.dart';

class ProfileNameField extends StatefulWidget {
  const ProfileNameField({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<ProfileNameField> createState() => _ProfileNameFieldState();
}

class _ProfileNameFieldState extends State<ProfileNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void didUpdateWidget(covariant ProfileNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue == widget.initialValue) return;
    if (_controller.text == widget.initialValue) return;
    _controller.value = TextEditingValue(
      text: widget.initialValue,
      selection: TextSelection.collapsed(offset: widget.initialValue.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.words,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Your name',
        prefixIcon: const Icon(Icons.person_outline_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
