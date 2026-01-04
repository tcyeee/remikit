import 'package:flutter/material.dart';
import 'yaml_node_widget.dart';

/// A high-level widget for editing a YAML configuration.
/// 
/// This widget serves as the entry point for the YAML editor, taking the root
/// node and handling updates.
class ConfigEditorWidget extends StatelessWidget {
  /// The root node of the YAML configuration.
  final dynamic node;
  
  /// The base path for the configuration (usually empty).
  final List<dynamic> path;
  
  /// Callback triggered when any value in the configuration is changed.
  final Function(List<dynamic> path, dynamic value) onChanged;

  const ConfigEditorWidget({
    super.key, 
    required this.node, 
    required this.path, 
    required this.onChanged
  });

  @override
  /// Builds the [YamlNodeWidget] with the root node.
  Widget build(BuildContext context) {
    return YamlNodeWidget(node: node, path: path, onChanged: onChanged);
  }
}
