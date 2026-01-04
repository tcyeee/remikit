import 'package:flutter/material.dart';

/// A widget for editing scalar values (String, int, double, etc.) in a YAML configuration.
/// 
/// This widget provides a text field for editing the value. It attempts to preserve
/// the original type (int, double) when submitting changes.
class ScalarEditor extends StatefulWidget {
  /// The current value to be edited.
  final dynamic value;
  
  /// Callback triggered when the value is changed and submitted.
  final ValueChanged<dynamic> onChanged;

  const ScalarEditor({
    super.key, 
    required this.value, 
    required this.onChanged
  });

  @override
  State<ScalarEditor> createState() => _ScalarEditorState();
}

class _ScalarEditorState extends State<ScalarEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant ScalarEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.toString() != _controller.text) {
      _controller.text = widget.value?.toString() ?? '';
    }
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
      decoration: const InputDecoration(
        border: OutlineInputBorder(), 
        isDense: true, 
        contentPadding: EdgeInsets.all(8)
      ),
      onSubmitted: (value) => _submit(value),
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        _submit(_controller.text);
      },
    );
  }

  void _submit(String value) {
    dynamic finalValue = value;
    // Try to preserve type
    if (widget.value is int) {
      finalValue = int.tryParse(value) ?? value;
    } else if (widget.value is double) {
      finalValue = double.tryParse(value) ?? value;
    }

    if (finalValue != widget.value) {
      widget.onChanged(finalValue);
    }
  }
}
