import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'scalar_editor.dart';

/// A widget that recursively displays and edits a YAML node (Map, List, or Scalar).
/// 
/// This widget handles the layout for nested structures and delegates scalar editing
/// to [ScalarEditor].
class YamlNodeWidget extends StatelessWidget {
  /// The YAML node to display (can be YamlMap, YamlList, or a scalar value).
  final dynamic node;
  
  /// The path to this node in the YAML structure.
  final List<dynamic> path;
  
  /// Callback triggered when a value within this node is changed.
  final Function(List<dynamic> path, dynamic value) onChanged;

  const YamlNodeWidget({
    super.key, 
    required this.node, 
    required this.path, 
    required this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    if (node is YamlMap) {
      final map = node as YamlMap;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 8.0),
                  child: Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: YamlNodeWidget(
                    node: e.value, 
                    path: [...path, e.key], 
                    onChanged: onChanged
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (node is YamlList) {
      final list = node as YamlList;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12.0, right: 8.0),
                  child: Text(
                    '- ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                Expanded(
                  child: YamlNodeWidget(
                    node: e.value, 
                    path: [...path, e.key], 
                    onChanged: onChanged
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (node is bool) {
      return Row(
        children: [
          Switch(
            value: node as bool, 
            onChanged: (value) => onChanged(path, value)
          )
        ],
      );
    } else {
      // String, int, double, null, etc.
      return ScalarEditor(
        value: node, 
        onChanged: (value) => onChanged(path, value)
      );
    }
  }
}
